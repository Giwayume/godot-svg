class_name SVGPaintServer

const radial_gradient_shader = preload("../render/shader/svg_paint_radial_gradient_shader.tres")
const ELLIPSE_RATIO = 1.0
const TILING = 1.0

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
		"texture": viewport_texture
	}

static func pow_2_texture_size(size: Vector2):
	return Vector2(
		pow(2, ceil(log(size.x) / log(2))),
		pow(2, ceil(log(size.y) / log(2)))
	)
