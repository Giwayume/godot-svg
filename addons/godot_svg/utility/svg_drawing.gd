class_name SVGDrawing

#static func stroke_circle_arc(canvas_item, center, radius, angle_from, angle_to, color, texture = null, width = 1.0, nb_points = 32):
#	var points_arc = PoolVector2Array()
#
#	for i in range(nb_points + 1):
#		var angle_point = angle_from + i * (angle_to - angle_from) / nb_points - PI
#		points_arc.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * radius)
#
##	for index_point in range(nb_points):
#	canvas_item.draw_polyline(points_arc, color, width, true)
#
#static func fill_circle_arc(canvas_item, center, radius, angle_from, angle_to, color, texture = null, nb_points = 32):
#	var points_arc = PoolVector2Array()
#	points_arc.push_back(center)
#	var colors = PoolColorArray([color])
#
#	for i in range(nb_points + 1):
#		var angle_point = angle_from + i * (angle_to - angle_from) / nb_points - PI
#		points_arc.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * radius)
#	canvas_item.draw_polygon(points_arc, colors, PoolVector2Array(), null, null, true)

static func generate_fill_rect_points(x, y, width, height) -> PoolVector2Array:
	return PoolVector2Array([
		Vector2(x, y),
		Vector2(x + width, y),
		Vector2(x + width, y + height),
		Vector2(x, y + height),
		Vector2(x, y)
	])

static func generate_fill_rect_uv(x, y, width, height, size = 1.0) -> PoolVector2Array:
	return PoolVector2Array([
		Vector2(0.0, 0.0) * size,
		Vector2(1.0, 0.0) * size,
		Vector2(1.0, 1.0) * size,
		Vector2(0.0, 1.0) * size,
		Vector2(0.0, 0.0) * size
	])

static func generate_stroke_rect_points(x, y, width, height) -> PoolVector2Array:
	return PoolVector2Array([
		Vector2(x, y),
		Vector2(x + width, y),
		Vector2(x + width, y + height),
		Vector2(x, y + height),
		Vector2(x, y)
	])

static func generate_fill_circle_arc_points(center, radius, angle_from, angle_to, nb_points = 32) -> PoolVector2Array:
	var points_arc = PoolVector2Array()
	for i in range(nb_points + 1):
		var angle_point = angle_from + i * (angle_to - angle_from) / nb_points - PI
		points_arc.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * radius)
	return points_arc

static func generate_fill_circle_arc_uv(angle_from, angle_to, offset = Vector2(), size = 1.0, nb_points = 32) -> PoolVector2Array:
	var uv_arc = PoolVector2Array()
	var center = Vector2(1, 1) * size / 2
	for i in range(nb_points + 1):
		var angle_point = angle_from + i * (angle_to - angle_from) / nb_points - PI
		uv_arc.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * size / 2)
	return uv_arc

static func generate_stroke_circle_arc_points(center, radius, angle_from, angle_to, nb_points = 32) -> PoolVector2Array:
	var points_arc = PoolVector2Array()
	for i in range(nb_points + 1):
		var angle_point = angle_from + i * (angle_to - angle_from) / nb_points - PI
		points_arc.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * radius)
	return points_arc

static func generate_fill_ellipse_arc_points(center, radius_x, radius_y, angle_from, angle_to, nb_points = 32) -> PoolVector2Array:
	var points_arc = PoolVector2Array()
	for i in range(nb_points + 1):
		var angle_point = angle_from + i * (angle_to - angle_from) / nb_points - PI
		points_arc.push_back(center + Vector2(cos(angle_point) * radius_x, sin(angle_point) * radius_y))
	return points_arc

static func generate_stroke_ellipse_arc_points(center, radius_x, radius_y, angle_from, angle_to, nb_points = 32) -> PoolVector2Array:
	var points_arc = PoolVector2Array()
	for i in range(nb_points + 1):
		var angle_point = angle_from + i * (angle_to - angle_from) / nb_points - PI
		points_arc.push_back(center + Vector2(cos(angle_point) * radius_x, sin(angle_point) * radius_y))
	return points_arc

static func generate_texture_uv(polygon: PoolVector2Array, view_box: Rect2, bounding_box: Rect2, texture_size: Vector2, texture_units: String):
	var top_left = bounding_box.position if texture_units == SVGValueConstant.OBJECT_BOUNDING_BOX else view_box.position
	var bottom_right = bounding_box.position + bounding_box.size if texture_units == SVGValueConstant.OBJECT_BOUNDING_BOX else view_box.position + view_box.size
	var uv = PoolVector2Array()
	for point in polygon:
		uv.push_back(
			((point - top_left) / (bottom_right - top_left)) * texture_size
		)
	return uv
