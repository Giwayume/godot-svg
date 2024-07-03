class_name SVGPaintServer

const radial_gradient_shader = preload("../render/shader/svg_paint_radial_gradient_shader.tres")
const ELLIPSE_RATIO = 1.0
const TILING = 1.0

static func srgb_channel_to_linear_srgb_channel(value):
	if value < 0.04045: return float(value) / 12.92
	return pow((float(value) + 0.055) / 1.055, 2.4)

static func linear_srgb_channel_to_srgb_channel(value):
	if value <= 0: return 0.0
	if value >= 1: return 1.0
	if value < 0.0031308: return (float(value) * 12.92)
	return (pow(float(value), 1 / 2.4) * 1.055 - 0.055)

static func srgb_to_linear_srgb(color):
	return Color(
		srgb_channel_to_linear_srgb_channel(color.r),
		srgb_channel_to_linear_srgb_channel(color.g),
		srgb_channel_to_linear_srgb_channel(color.b),
		color.a
	)

static func linear_srgb_to_srgb(color):
	return Color(
		linear_srgb_channel_to_srgb_channel(color.r),
		linear_srgb_channel_to_srgb_channel(color.g),
		linear_srgb_channel_to_srgb_channel(color.b),
		color.a
	)

static func generate_gradient_texture_1d(
	gradient: Gradient,
	color_interpolation: String,
	texture_repeat_mode: int,
	width: int = 2048
) -> ImageTexture:
	var gradient_image = Image.new()
	var data = PackedByteArray()
	var offset_count = gradient.offsets.size()
	var current_offset_index = -1
	var current_offset = 0
	var next_offset_index = 0
	if offset_count > 1:
		next_offset_index = current_offset_index + 1
	var next_offset = gradient.offsets[next_offset_index] if next_offset_index < offset_count else current_offset
	var current_color = gradient.colors[0] if gradient.colors.size() > 0 else Color.BLACK
	var next_color = gradient.colors[next_offset_index] if next_offset_index < offset_count else current_color
	var color = Color()
	if color_interpolation == SVGValueConstant.LINEAR_RGB:
		current_color = srgb_to_linear_srgb(current_color)
		next_color = srgb_to_linear_srgb(next_color)
	for i in range(0, width):
		var pixel_offset = float(i) / float(width)
		if current_offset == next_offset:
			color = current_color
		else:
			color = current_color.lerp(next_color, (pixel_offset - current_offset) / (next_offset - current_offset))
		if color_interpolation == SVGValueConstant.LINEAR_RGB:
			color = linear_srgb_to_srgb(color)
		data.push_back(int(color.r * 255))
		data.push_back(int(color.g * 255))
		data.push_back(int(color.b * 255))
		data.push_back(int(color.a * 255))
		if pixel_offset > next_offset and current_offset_index < offset_count - 1:
			current_offset_index += 1
			if current_offset_index < offset_count - 1:
				next_offset_index = current_offset_index + 1
			current_offset = gradient.offsets[current_offset_index]
			next_offset = gradient.offsets[next_offset_index]
			current_color = gradient.colors[current_offset_index]
			next_color = gradient.colors[next_offset_index]
			if color_interpolation == SVGValueConstant.LINEAR_RGB:
				current_color = srgb_to_linear_srgb(current_color)
				next_color = srgb_to_linear_srgb(next_color)

	gradient_image = gradient_image.create_from_data(width, 1, false, Image.FORMAT_RGBA8, data)
	var gradient_texture = ImageTexture.new()
#	if texture_repeat_mode == GradientTexture2D.REPEAT:
#		flags |= Texture2D.FLAG_REPEAT
#	elif texture_repeat_mode == GradientTexture2D.REPEAT_MIRROR:
#		flags |= Texture2D.FLAG_REPEAT | Texture2D.FLAG_MIRRORED_REPEAT
	gradient_texture = gradient_texture.create_from_image(gradient_image) #,flags
	return gradient_texture

static func generate_linear_gradient_shader_params(
	reference_controller,
	params: Dictionary
) -> Dictionary:
	var gradient_controller = params.gradient_controller
	var gradient_transform = params.gradient_transform
	var inherited_view_box = reference_controller.inherited_view_box

	var start_center
	var end_center
	var uv_position_in_container = Vector2(0.0, 0.0)
	var uv_size_in_container = Vector2(1.0, 1.0)
	var ellipse_ratio = Vector2(1.0, 1.0)

	var uv_transform = Transform2D()

	# OBJECT_BOUNDING_BOX
	if gradient_controller.attr_gradient_units == SVGValueConstant.OBJECT_BOUNDING_BOX:
		start_center = Vector2(
			gradient_controller.attr_x1.get_length(1),
			gradient_controller.attr_y1.get_length(1)
		) * gradient_transform
		end_center = Vector2(
			gradient_controller.attr_x2.get_length(1),
			gradient_controller.attr_y2.get_length(1)
		) * gradient_transform
	
	# USER_SPACE_ON_USE
	else:
		var bounding_box = reference_controller.get_bounding_box()

		ellipse_ratio = Vector2(inherited_view_box.size.y / inherited_view_box.size.x, 1.0)

		uv_transform *= gradient_transform.affine_inverse() * gradient_transform * gradient_transform.affine_inverse()
		uv_transform.origin = Vector2(
			(uv_transform.origin.x) / inherited_view_box.size.x,
			(uv_transform.origin.y) / inherited_view_box.size.y
		)

		uv_size_in_container = Vector2(
			bounding_box.size.x / inherited_view_box.size.x,
			bounding_box.size.y / inherited_view_box.size.y
		)
		uv_position_in_container = Vector2(
			(bounding_box.position.x / inherited_view_box.size.x),
			(bounding_box.position.y / inherited_view_box.size.y)
		)

		start_center = Vector2(
			SVGLengthPercentage.calculate_normalized_length(
				gradient_controller.attr_x1.get_length(inherited_view_box.size.x),
				inherited_view_box.size.x
			),
			SVGLengthPercentage.calculate_normalized_length(
				gradient_controller.attr_y1.get_length(inherited_view_box.size.y),
				inherited_view_box.size.y
			)
		)
		end_center = Vector2(
			SVGLengthPercentage.calculate_normalized_length(
				gradient_controller.attr_x2.get_length(inherited_view_box.size.x),
				inherited_view_box.size.x
			),
			SVGLengthPercentage.calculate_normalized_length(
				gradient_controller.attr_y2.get_length(inherited_view_box.size.y),
				inherited_view_box.size.y
			)
		)

	return {
		"gradient_type": 1,
		"gradient_start_center": start_center,
		"gradient_end_center": end_center,
		"gradient_repeat": params.gradient_repeat,
		"gradient_texture": params.gradient_texture,
		"uv_position_in_container": uv_position_in_container,
		"uv_size_in_container": uv_size_in_container,
		"uv_transform_column_1": Vector3(uv_transform.x.x, uv_transform.y.x, uv_transform.origin.x),
		"uv_transform_column_2": Vector3(uv_transform.x.y, uv_transform.y.y, uv_transform.origin.y)
	}

static func generate_radial_gradient_shader_params(
	reference_controller,
	params: Dictionary
) -> Dictionary:
	var gradient_controller = params.gradient_controller
	var gradient_transform = params.gradient_transform
	var inherited_view_box = reference_controller.inherited_view_box

	var start_center
	var end_center
	var start_radius = gradient_controller.attr_fr.get_normalized_length(inherited_view_box.size.x)
	var end_radius = gradient_controller.attr_r.get_normalized_length(inherited_view_box.size.x)
	var uv_position_in_container = Vector2(0.0, 0.0)
	var uv_size_in_container = Vector2(1.0, 1.0)
	var ellipse_ratio = Vector2(1.0, 1.0)

	var uv_transform = Transform2D()

	# OBJECT_BOUNDING_BOX
	if gradient_controller.attr_gradient_units == SVGValueConstant.OBJECT_BOUNDING_BOX:
		start_center = Vector2(
			gradient_controller.attr_cx.get_length(1),
			gradient_controller.attr_cy.get_length(1)
		) * gradient_transform
		var attr_fx = gradient_controller.attr_cx if gradient_controller.attr_fx is String else gradient_controller.attr_fx
		var attr_fy = gradient_controller.attr_cy if gradient_controller.attr_fy is String else gradient_controller.attr_fy
		end_center = Vector2(
			attr_fx.get_length(1),
			attr_fy.get_length(1)
		) * gradient_transform
		start_radius = gradient_controller.attr_fr.get_length(1)
		end_radius = gradient_controller.attr_r.get_length(1)
	
	# USER_SPACE_ON_USE
	else:
		var bounding_box = reference_controller.get_bounding_box()

		ellipse_ratio = Vector2(inherited_view_box.size.y / inherited_view_box.size.x, 1.0)

		uv_transform *= gradient_transform.affine_inverse() * gradient_transform * gradient_transform.affine_inverse()
		uv_transform.origin = Vector2(
			(uv_transform.origin.x) / inherited_view_box.size.x,
			(uv_transform.origin.y) / inherited_view_box.size.y
		)

		uv_size_in_container = Vector2(
			bounding_box.size.x / inherited_view_box.size.x,
			bounding_box.size.y / inherited_view_box.size.y
		)
		uv_position_in_container = Vector2(
			(bounding_box.position.x / inherited_view_box.size.x),
			(bounding_box.position.y / inherited_view_box.size.y)
		)

		start_center = Vector2(
			SVGLengthPercentage.calculate_normalized_length(
				gradient_controller.attr_cx.get_length(inherited_view_box.size.x),
				inherited_view_box.size.x
			),
			SVGLengthPercentage.calculate_normalized_length(
				gradient_controller.attr_cy.get_length(inherited_view_box.size.y),
				inherited_view_box.size.y
			)
		)
		var attr_fx = gradient_controller.attr_cx if gradient_controller.attr_fx is String else gradient_controller.attr_fx
		var attr_fy = gradient_controller.attr_cy if gradient_controller.attr_fy is String else gradient_controller.attr_fy
		end_center = Vector2(
			SVGLengthPercentage.calculate_normalized_length(
				attr_fx.get_length(inherited_view_box.size.x),
				inherited_view_box.size.x
			),
			SVGLengthPercentage.calculate_normalized_length(
				attr_fy.get_length(inherited_view_box.size.y),
				inherited_view_box.size.y
			)
		)
		start_radius = SVGLengthPercentage.calculate_normalized_length(
			gradient_controller.attr_fr.get_length(inherited_view_box.size.x),
			inherited_view_box.size.x
		)
		end_radius = SVGLengthPercentage.calculate_normalized_length(
			gradient_controller.attr_r.get_length(inherited_view_box.size.y),
			inherited_view_box.size.x
		)

	return {
		"gradient_type": 2,
		"gradient_start_center": start_center,
		"gradient_start_radius": Vector2(ellipse_ratio.x * start_radius, ellipse_ratio.y * start_radius),
		"gradient_end_center": end_center,
		"gradient_end_radius": Vector2(ellipse_ratio.x * end_radius, ellipse_ratio.y * end_radius),
		"gradient_repeat": params.gradient_repeat,
		"gradient_texture": params.gradient_texture,
		"uv_position_in_container": uv_position_in_container,
		"uv_size_in_container": uv_size_in_container,
		"uv_transform_column_1": Vector3(uv_transform.x.x, uv_transform.y.x, uv_transform.origin.x),
		"uv_transform_column_2": Vector3(uv_transform.x.y, uv_transform.y.y, uv_transform.origin.y)
	}

static func generate_pattern_server(
	pattern_controller,
	inherited_view_box: Rect2
) -> Dictionary:
	var viewport = pattern_controller._baking_viewport
	viewport.size = Vector2(2.0, 2.0)
	viewport.use_hdr_2d = false
	viewport.transparent_bg = true
	# TODO - wait for delayed resources such as mask/other paint servers to draw?
	var viewport_texture = viewport.get_texture()
#	viewport_texture.flags = Texture2D.FLAGS_DEFAULT
	return {
		"view_box": inherited_view_box,
		"controller": pattern_controller,
		"viewport": viewport,
		"texture": viewport_texture,
		"generate_shader_params": {
			"method": "generate_pattern_shader_params",
			"params": {
				"pattern_controller": pattern_controller,
				"pattern_transform": pattern_controller.attr_pattern_transform
			}
		}
	}

static func generate_pattern_shader_params(
	reference_controller,
	params: Dictionary
) -> Dictionary:
	var pattern_controller = params.pattern_controller
	var pattern_transform = params.pattern_transform
	var inherited_view_box = reference_controller.inherited_view_box

	var pattern_width = pattern_controller.attr_width.get_length(inherited_view_box.size.x)
	var pattern_height = pattern_controller.attr_height.get_length(inherited_view_box.size.y)

	var uv_position_in_container = Vector2(0.0, 0.0)
	var uv_size_in_container = Vector2(1.0, 1.0)
	var uv_transform = Transform2D()

	# USER_SPACE_ON_USE
	if pattern_controller.attr_pattern_units == SVGValueConstant.USER_SPACE_ON_USE:
		var bounding_box = reference_controller.get_bounding_box()

		uv_transform = Transform2D().scaled(Vector2(inherited_view_box.size.x / pattern_width, inherited_view_box.size.y / pattern_height))

		uv_transform *= pattern_transform.affine_inverse() * pattern_transform * pattern_transform.affine_inverse()
		uv_transform.origin = Vector2(
			(uv_transform.origin.x) / inherited_view_box.size.x,
			(uv_transform.origin.y) / inherited_view_box.size.y
		)

		uv_size_in_container = Vector2(
			bounding_box.size.x / inherited_view_box.size.x,
			bounding_box.size.y / inherited_view_box.size.y
		)
		uv_position_in_container = Vector2(
			(bounding_box.position.x / inherited_view_box.size.x),
			(bounding_box.position.y / inherited_view_box.size.y)
		)

	return {
		"uv_position_in_container": uv_position_in_container,
		"uv_size_in_container": uv_size_in_container,
		"uv_transform_column_1": Vector3(uv_transform.x.x, uv_transform.y.x, uv_transform.origin.x),
		"uv_transform_column_2": Vector3(uv_transform.x.y, uv_transform.y.y, uv_transform.origin.y)
	}

static func pow_2_texture_size(size: Vector2):
	return Vector2(
		pow(2, ceil(log(size.x) / log(2))),
		pow(2, ceil(log(size.y) / log(2)))
	)

static func resolve_paint(reference_controller, attr_paint, server_name: String):
	var root_controller = reference_controller.root_controller
	var inherited_view_box = reference_controller.inherited_view_box
	var paint = {
		"color": Color(1, 1, 1, 1),
		"texture": null,
		"texture_units": null,
		"texture_uv_transform": Transform2D(),
	}

	if attr_paint is SVGPaint:
		if attr_paint.url != null:
			var result = root_controller.resolve_url(attr_paint.url)
			var controller = result.controller
			if controller == null:
				paint.color = attr_paint.color
						
			# Gradient
			elif controller.node_name == "linearGradient" or controller.node_name == "radialGradient":
				controller = controller.resolve_href()
				var stops = root_controller.get_elements_by_name("stop", controller.element_resource)
				var gradient = Gradient.new()
				gradient.colors = []
				gradient.offsets = []
				for stop in stops:
					var offset = stop.controller.attr_offset.get_length(1)
					var color = stop.controller.attr_stop_color if stop.controller.attr_stop_color else Color.BLACK
					var opacity = stop.controller.attr_stop_opacity
					if opacity < 1.0:
						color.a = opacity
					gradient.add_point(offset, color)
				var gradient_texture = null
				var gradient_transform = controller.attr_gradient_transform
				var texture_repeat_mode = {
					SVGValueConstant.PAD: GradientTexture2D.REPEAT_NONE,
					SVGValueConstant.REPEAT: GradientTexture2D.REPEAT,
					SVGValueConstant.REFLECT: GradientTexture2D.REPEAT_MIRROR,
				}[controller.attr_spread_method]
				paint.texture_units = controller.attr_gradient_units
				var color_interpolation = controller.attr_color_interpolation
				if color_interpolation == SVGValueConstant.AUTO:
					color_interpolation = SVGValueConstant.SRGB

				# Linear Gradient
				if controller.node_name == "linearGradient":
					# free_paint_server_texture(reference_controller, server_name)
					# gradient_texture = GradientTexture2D.new()
					# gradient_texture.gradient = gradient
					# gradient_texture.fill = GradientTexture2D.FILL_LINEAR
					# gradient_texture.repeat = texture_repeat_mode
					# if controller.attr_gradient_units == SVGValueConstant.OBJECT_BOUNDING_BOX:
					# 	gradient_texture.fill_from = Vector2(
					# 		controller.attr_x1.get_length(1),
					# 		controller.attr_y1.get_length(1)
					# 	) * gradient_transform
					# 	gradient_texture.fill_to = Vector2(
					# 		controller.attr_x2.get_length(1),
					# 		controller.attr_y2.get_length(1)
					# 	) * gradient_transform
					# else: # USER_SPACE_ON_USE
					# 	var transformed_fill_from = (
					# 		Vector2(controller.attr_x1.get_length(1), controller.attr_y1.get_length(1))
					# 	) * gradient_transform
					# 	gradient_texture.fill_from = Vector2(
					# 		SVGLengthPercentage.calculate_normalized_length(transformed_fill_from.x, inherited_view_box.size.x, inherited_view_box.position.x),
					# 		SVGLengthPercentage.calculate_normalized_length(transformed_fill_from.y, inherited_view_box.size.y, inherited_view_box.position.y)
					# 	)
					# 	var transformed_fill_to = (
					# 		Vector2(controller.attr_x2.get_length(1), controller.attr_y2.get_length(1))
					# 	) * gradient_transform
					# 	gradient_texture.fill_to = Vector2(
					# 		SVGLengthPercentage.calculate_normalized_length(transformed_fill_to.x, inherited_view_box.size.x, inherited_view_box.position.x),
					# 		SVGLengthPercentage.calculate_normalized_length(transformed_fill_to.y, inherited_view_box.size.y, inherited_view_box.position.y)
					# 	)
					paint.texture_units = null
					var gradient_texture_1d = generate_gradient_texture_1d(
						gradient,
						color_interpolation,
						texture_repeat_mode
					)

					gradient_texture = store_paint_server_texture(reference_controller, server_name, {
						"texture": null,
						"generate_shader_params": {
							"method": "generate_linear_gradient_shader_params",
							"params": {
								"gradient_controller": controller,
								"gradient_transform": gradient_transform,
								"gradient_repeat": texture_repeat_mode,
								"gradient_texture": gradient_texture_1d
							}
						}
					})
				
				# Radial Gradient
				else:
					paint.texture_units = null
					var gradient_texture_1d = generate_gradient_texture_1d(
						gradient,
						color_interpolation,
						texture_repeat_mode
					)
					
					gradient_texture = store_paint_server_texture(reference_controller, server_name, {
						"texture": null,
						"generate_shader_params": {
							"method": "generate_radial_gradient_shader_params",
							"params": {
								"gradient_controller": controller,
								"gradient_transform": gradient_transform,
								"gradient_repeat": texture_repeat_mode,
								"gradient_texture": gradient_texture_1d
							}
						}
					})
				
				paint.texture = gradient_texture
				if controller._is_href_duplicate and controller.controlled_node != null:
					controller.controlled_node.queue_free()
			
			# Pattern
			elif controller.node_name == "pattern":
				controller = controller.resolve_href()
				var pattern_texture = store_paint_server_texture(reference_controller, server_name,
					generate_pattern_server(
						controller,
						inherited_view_box
					)
				)
				# if controller.attr_pattern_units == SVGValueConstant.USER_SPACE_ON_USE:
				# 	paint.texture_units = Rect2(
				# 		0.0,
				# 		0.0,
				# 		controller._baking_viewport.size.x,
				# 		controller._baking_viewport.size.y
				# 	)
				# else:
				# 	paint.texture_units = controller.attr_pattern_units
				# paint.texture_uv_transform = controller.attr_pattern_transform
				paint.texture = pattern_texture
		else:
			free_paint_server_texture(reference_controller, server_name)
			paint.color = attr_paint.color
	elif typeof(attr_paint) == TYPE_STRING:
		if attr_paint == SVGValueConstant.CURRENT_COLOR:
			paint = resolve_paint(reference_controller, reference_controller.attr_color, server_name)
	return paint

static func store_paint_server_texture(reference_controller, store_name: String, server_response: Dictionary):
	free_paint_server_texture(reference_controller, store_name)
	reference_controller._paint_server_textures[store_name] = server_response
	if server_response.has("viewport") or server_response.has("controller"):
		if reference_controller._paint_server_container_node == null:
			reference_controller._paint_server_container_node = Node2D.new()
			reference_controller._paint_server_container_node.set_name("PaintServerAssets")
			reference_controller.controlled_node.add_child_to_root(reference_controller._paint_server_container_node)
		if server_response.has("controller"):
			reference_controller._paint_server_container_node.add_child(server_response.controller.controlled_node)
			if server_response.has("view_box") and server_response.controller.has_method("update_as_user"):
				server_response.controller.update_as_user(server_response.view_box)
		else:
			reference_controller._paint_server_container_node.add_child(server_response.viewport)
	return server_response.texture

static func free_paint_server_texture(reference_controller, store_name: String):
	if reference_controller._paint_server_textures.has(store_name):
		var old_store = reference_controller._paint_server_textures[store_name]
		if old_store.has("controller") and is_instance_valid(old_store.controller):
			old_store.controller.controlled_node.queue_free()
		if old_store.has("viewport") and is_instance_valid(old_store.viewport):
			old_store.viewport.queue_free()
		if old_store.has("texture_rect") and is_instance_valid(old_store.texture_rect):
			old_store.texture_rect.queue_free()
	reference_controller._paint_server_textures.erase(store_name)

static func apply_shader_params(reference_controller, store_name: String, shape_node):
	var needs_reset_params = false
	if reference_controller._paint_server_textures.has(store_name):
		var server_response = reference_controller._paint_server_textures[store_name]
		if server_response.has("generate_shader_params"):
			var shader_params = {}
			if server_response.generate_shader_params.method == "generate_linear_gradient_shader_params":
				shader_params = generate_linear_gradient_shader_params(
					reference_controller,
					server_response.generate_shader_params.params
				)
			elif server_response.generate_shader_params.method == "generate_radial_gradient_shader_params":
				shader_params = generate_radial_gradient_shader_params(
					reference_controller,
					server_response.generate_shader_params.params
				)
			elif server_response.generate_shader_params.method == "generate_pattern_shader_params":
				shader_params = generate_pattern_shader_params(
					reference_controller,
					server_response.generate_shader_params.params
				)
			for shader_param_name in shader_params:
				shape_node.material.set_shader_parameter(shader_param_name, shader_params[shader_param_name])
		else:
			needs_reset_params = true
	else:
		needs_reset_params = true
	if needs_reset_params:
		if shape_node is MeshInstance2D:
			shape_node.material.set_shader_parameter("gradient_type", 0)
		else:
			pass # TODO - 3D counterpart?
