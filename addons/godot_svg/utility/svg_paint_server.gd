class_name SVGPaintServer

const radial_gradient_shader = preload("../render/shader/svg_paint_radial_gradient_shader.tres")
const ELLIPSE_RATIO = 1.0
const TILING = 1.0

# Generates a radial gradient texture immediately on the CPU (blocks the main thread, slow)
# First four arguments are defined in a range of 0-1 relative to texture_size
static func generate_radial_gradient(
	gradient: Gradient,
	start_center: Vector2,
	start_radius: float,
	end_center: Vector2,
	end_radius: float,
	texture_size: Vector2,
	repeat: int = 0
) -> ImageTexture:
	var width = int(texture_size.x)
	var height = int(texture_size.y)
	var data = PoolByteArray()
	
	var center = end_center * texture_size
	var end_point = center + Vector2(end_radius * texture_size.x, 0.0)
	var focus = start_center * texture_size
	var axis = end_point - center
	var l2 = axis.dot(axis)
	var diff = focus - center
	var radius = (end_radius - start_radius) * texture_size.x
	var start_radius_applied = start_radius * texture_size.x
	
	for y in range(0, height):
		for x in range(0, width):
			var coord = Vector2(x, y)
			
			# Apply ellipse modifier
			if l2 != 0.0:
				var d = (coord - center).dot(axis) / l2
				var proj = center + d * axis
				coord = proj - (proj - coord) * ELLIPSE_RATIO
				
				var d2 = (focus - center).dot(axis) / l2
				var proj2 = center + d2 * axis
				focus = proj2 - (proj2 - focus) * ELLIPSE_RATIO
			
			# Apply focus modifier
			var grad_length = 1.0
			var ray_dir = (coord - focus).normalized()
			var a = ray_dir.dot(ray_dir)
			var b = 2.0 * ray_dir.dot(diff)
			var c = diff.dot(diff) - (radius * radius)
			var disc = (b * b) - (4.0 * a * c)
			if disc >= 0.0 and a != 0:
				var t = (-b + sqrt(abs(disc))) / (2.0 * a)
				var projection = focus + ray_dir * t
				grad_length = projection.distance_to(focus)
			else:
				pass # Gradient is undefined for this coordinate
			
			# Output
			var grad = (coord.distance_to(focus) - start_radius_applied) / (grad_length * TILING)
			var col
			if repeat == GradientTexture2D.REPEAT:
				col = gradient.interpolate(fposmod(grad, 1.0))
			elif repeat == GradientTexture2D.REPEAT_MIRROR:
				var is_mirror = fposmod(grad, 2.0) < 1.0
				if is_mirror:
					col = gradient.interpolate(fposmod(grad, 1.0))
				else:
					col = gradient.interpolate(1.0 - fposmod(grad, 1.0))
			else: # GradientTexture2D.REPEAT_NONE
				col = gradient.interpolate(grad)
			
			data.push_back(int(col.r * 255))
			data.push_back(int(col.g * 255))
			data.push_back(int(col.b * 255))
			data.push_back(int(col.a * 255))
			
	var image = Image.new()
	image.create_from_data(width, height, false, Image.FORMAT_RGBA8, data)
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	
	return texture

# Generates a radial gradient on the GPU by using a viewport with a viewport texture.
# Since this does not happen immediately, the shape may be invisible for a bit at first.
static func generate_radial_gradient_server(
	gradient: Gradient,
	start_center: Vector2,
	start_radius: float,
	end_center: Vector2,
	end_radius: float,
	texture_size: Vector2,
	repeat: int = 0
) -> Dictionary:
	var gradient_texture = GradientTexture.new()
	gradient_texture.gradient = gradient
	
	var viewport = Viewport.new()
	viewport.size = texture_size
	viewport.render_target_v_flip = true
	viewport.hdr = false
	viewport.usage = Viewport.USAGE_2D_NO_SAMPLING
	viewport.transparent_bg = true
	var gradient_rect = ColorRect.new()
	gradient_rect.rect_position = Vector2()
	gradient_rect.rect_size = texture_size
	gradient_rect.material = ShaderMaterial.new()
	gradient_rect.material.shader = radial_gradient_shader
	gradient_rect.material.set_shader_param("gradient", gradient_texture)
	gradient_rect.material.set_shader_param("start_center", start_center)
	gradient_rect.material.set_shader_param("start_radius", start_radius)
	gradient_rect.material.set_shader_param("end_center", end_center)
	gradient_rect.material.set_shader_param("end_radius", end_radius)
	gradient_rect.material.set_shader_param("texture_size", texture_size)
	gradient_rect.material.set_shader_param("repeat", repeat)
	viewport.add_child(gradient_rect)
	viewport.update_worlds()
	viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	var viewport_texture = viewport.get_texture()
	viewport_texture.flags = Texture.FLAGS_DEFAULT
	return {
		"texture_rect": gradient_rect,
		"viewport": viewport,
		"texture": viewport_texture,
	}

static func generate_pattern_server(
	pattern_renderer,
	inherited_view_box: Rect2
) -> Dictionary:
	var viewport = pattern_renderer._baking_viewport
	viewport.size = Vector2(2.0, 2.0)
	viewport.render_target_v_flip = true
	viewport.hdr = false
	viewport.usage = Viewport.USAGE_2D_NO_SAMPLING
	viewport.transparent_bg = true
	# TODO - wait for delayed resources such as mask/other paint servers to draw?
	var viewport_texture = viewport.get_texture()
	viewport_texture.flags = Texture.FLAGS_DEFAULT
	return {
		"view_box": inherited_view_box,
		"renderer": pattern_renderer,
		"viewport": viewport,
		"texture": viewport_texture,
	}

static func pow_2_texture_size(size: Vector2):
	return Vector2(
		pow(2, ceil(log(size.x) / log(2))),
		pow(2, ceil(log(size.y) / log(2)))
	)

static func resolve_paint(reference_renderer, attr_paint, server_name: String):
	var svg_node = reference_renderer.svg_node
	var inherited_view_box = reference_renderer.inherited_view_box
	var paint = {
		"color": Color(1, 1, 1, 1),
		"texture": null,
		"texture_units": null,
		"texture_uv_transform": Transform2D(),
	}
	if attr_paint is SVGPaint:
		if attr_paint.url != null:
			var result = svg_node._resolve_resource_locator(attr_paint.url)
			var renderer = result.renderer
			if renderer == null:
				paint.color = attr_paint.color
			elif renderer.node_name == "linearGradient" or renderer.node_name == "radialGradient":
				renderer = renderer.resolve_href()
				var stops = svg_node._find_elements_by_name("stop", renderer.element_resource)
				var gradient = Gradient.new()
				gradient.colors = []
				gradient.offsets = []
				for stop in stops:
					var offset = stop.renderer.attr_offset.get_length(1)
					var color = stop.renderer.attr_stop_color
					var opacity = stop.renderer.attr_stop_opacity
					if opacity < 1.0:
						color.a = opacity
					gradient.add_point(offset, color)
				var gradient_texture = null
				var gradient_transform = renderer.attr_gradient_transform
				var texture_repeat_mode = {
					SVGValueConstant.PAD: GradientTexture2D.REPEAT_NONE,
					SVGValueConstant.REPEAT: GradientTexture2D.REPEAT,
					SVGValueConstant.REFLECT: GradientTexture2D.REPEAT_MIRROR,
				}[renderer.attr_spread_method]
				paint.texture_units = renderer.attr_gradient_units
				if renderer.node_name == "linearGradient":
					free_paint_server_texture(reference_renderer, server_name)
					gradient_texture = GradientTexture2D.new()
					gradient_texture.gradient = gradient
					gradient_texture.fill = GradientTexture2D.FILL_LINEAR
					gradient_texture.repeat = texture_repeat_mode
					if renderer.attr_gradient_units == SVGValueConstant.OBJECT_BOUNDING_BOX:
						gradient_texture.fill_from = gradient_transform.xform(Vector2(
							renderer.attr_x1.get_length(1),
							renderer.attr_y1.get_length(1)
						))
						gradient_texture.fill_to = gradient_transform.xform(Vector2(
							renderer.attr_x2.get_length(1),
							renderer.attr_y2.get_length(1)
						))
					else: # USER_SPACE_ON_USE
						var transformed_fill_from = gradient_transform.xform(
							Vector2(renderer.attr_x1.get_length(1), renderer.attr_y1.get_length(1))
						)
						gradient_texture.fill_from = Vector2(
							SVGLengthPercentage.calculate_normalized_length(transformed_fill_from.x, inherited_view_box.size.x, inherited_view_box.position.x),
							SVGLengthPercentage.calculate_normalized_length(transformed_fill_from.y, inherited_view_box.size.y, inherited_view_box.position.y)
						)
						var transformed_fill_to = gradient_transform.xform(
							Vector2(renderer.attr_x2.get_length(1), renderer.attr_y2.get_length(1))
						)
						gradient_texture.fill_to = Vector2(
							SVGLengthPercentage.calculate_normalized_length(transformed_fill_to.x, inherited_view_box.size.x, inherited_view_box.position.x),
							SVGLengthPercentage.calculate_normalized_length(transformed_fill_to.y, inherited_view_box.size.y, inherited_view_box.position.y)
						)
				else: # "radialGradient"
					var start_center
					var end_center
					var start_radius = renderer.attr_fr.get_normalized_length(inherited_view_box.size.x)
					var end_radius = renderer.attr_r.get_normalized_length(inherited_view_box.size.x)
					var texture_size = Vector2(64.0, 64.0)
					if renderer.attr_gradient_units == SVGValueConstant.OBJECT_BOUNDING_BOX:
						var bounding_box = reference_renderer.get_bounding_box()
						texture_size = pow_2_texture_size(Vector2(1.0, 1.0) * min(4096, max(bounding_box.size.x, bounding_box.size.y)))
						start_center = gradient_transform.xform(Vector2(
							renderer.attr_cx.get_length(1),
							renderer.attr_cy.get_length(1)
						))
						var attr_fx = renderer.attr_cx if renderer.attr_fx is String else renderer.attr_fx
						var attr_fy = renderer.attr_cy if renderer.attr_fy is String else renderer.attr_fy
						end_center = gradient_transform.xform(Vector2(
							attr_fx.get_length(1),
							attr_fy.get_length(1)
						))
						start_radius = renderer.attr_fr.get_length(1)
						end_radius = renderer.attr_r.get_length(1)
					else: # USER_SPACE_ON_USE
						var transformed_start_center = gradient_transform.xform(
							Vector2(renderer.attr_cx.get_length(1), renderer.attr_cy.get_length(1))
						)
						start_center = Vector2(
							SVGLengthPercentage.calculate_normalized_length(transformed_start_center.x, inherited_view_box.size.x, inherited_view_box.position.x),
							SVGLengthPercentage.calculate_normalized_length(transformed_start_center.y, inherited_view_box.size.y, inherited_view_box.position.y)
						)
						var attr_fx = renderer.attr_cx if renderer.attr_fx is String else renderer.attr_fx
						var attr_fy = renderer.attr_cy if renderer.attr_fy is String else renderer.attr_fy
						var transformed_end_center = gradient_transform.xform(
							Vector2(attr_fx.get_length(1), attr_fy.get_length(1))
						)
						end_center = Vector2(
							SVGLengthPercentage.calculate_normalized_length(transformed_end_center.x, inherited_view_box.size.x, inherited_view_box.position.x),
							SVGLengthPercentage.calculate_normalized_length(transformed_end_center.y, inherited_view_box.size.y, inherited_view_box.position.y)
						)
						start_radius = renderer.attr_fr.get_normalized_length(inherited_view_box.size.x)
						end_radius = renderer.attr_r.get_normalized_length(inherited_view_box.size.x)

						texture_size = inherited_view_box.size
					
					var gradient_texture_param = GradientTexture.new()
					gradient_texture_param.gradient = gradient
					
					gradient_texture = store_paint_server_texture(reference_renderer, server_name, {
						"texture": null,
						"shader_params": {
							"gradient_type": 2,
							"gradient_start_center": start_center,
							"gradient_start_radius": start_radius,
							"gradient_end_center": end_center,
							"gradient_end_radius": end_radius,
							"gradient_repeat": texture_repeat_mode,
							"gradient_texture": gradient_texture_param,
						}
					})
				paint.texture = gradient_texture
				if renderer._is_href_duplicate:
					renderer.queue_free()
			elif renderer.node_name == "pattern":
				renderer = renderer.resolve_href()
				var pattern_texture = store_paint_server_texture(reference_renderer, server_name,
					generate_pattern_server(
						renderer,
						inherited_view_box
					)
				)
				if renderer.attr_pattern_units == SVGValueConstant.USER_SPACE_ON_USE:
					paint.texture_units = Rect2(
						0.0,
						0.0,
						renderer._baking_viewport.size.x,
						renderer._baking_viewport.size.y
					)
				else:
					paint.texture_units = renderer.attr_pattern_units
				paint.texture_uv_transform = renderer.attr_pattern_transform
				paint.texture = pattern_texture
		else:
			free_paint_server_texture(reference_renderer, server_name)
			paint.color = attr_paint.color
	elif typeof(attr_paint) == TYPE_STRING:
		if attr_paint == SVGValueConstant.CURRENT_COLOR:
			paint = resolve_paint(reference_renderer, reference_renderer.attr_color, server_name)
	return paint

static func store_paint_server_texture(reference_renderer, store_name: String, server_response: Dictionary):
	free_paint_server_texture(reference_renderer, store_name)
	reference_renderer._paint_server_textures[store_name] = server_response
	if server_response.has("viewport") or server_response.has("renderer"):
		if reference_renderer._paint_server_container_node == null:
			reference_renderer._paint_server_container_node = Node2D.new()
			reference_renderer._paint_server_container_node.set_name("PaintServerAssets")
			reference_renderer._add_child_direct(reference_renderer._paint_server_container_node)
		if server_response.has("renderer"):
			reference_renderer._paint_server_container_node.add_child(server_response.renderer)
			if server_response.has("view_box") and server_response.renderer.has_method("update_as_user"):
				server_response.renderer.update_as_user(server_response.view_box)
		else:
			reference_renderer._paint_server_container_node.add_child(server_response.viewport)
	return server_response.texture

static func free_paint_server_texture(reference_renderer, store_name: String):
	if reference_renderer._paint_server_textures.has(store_name):
		var old_store = reference_renderer._paint_server_textures[store_name]
		if old_store.has("renderer") and is_instance_valid(old_store.renderer):
			old_store.renderer.queue_free()
		if old_store.has("viewport") and is_instance_valid(old_store.viewport):
			old_store.viewport.queue_free()
		if old_store.has("texture_rect") and is_instance_valid(old_store.texture_rect):
			old_store.texture_rect.queue_free()
	reference_renderer._paint_server_textures.erase(store_name)

static func apply_shader_params(reference_renderer, store_name: String, shape_node):
	var needs_reset_params = false
	if reference_renderer._paint_server_textures.has(store_name):
		var server_response = reference_renderer._paint_server_textures[store_name]
		if server_response.has("shader_params"):
			for shader_param_name in server_response.shader_params:
				shape_node.material.set_shader_param(shader_param_name, server_response.shader_params[shader_param_name])
		else:
			needs_reset_params = true
	else:
		needs_reset_params = true
	if needs_reset_params:
		shape_node.material.set_shader_param("gradient_type", 0)
