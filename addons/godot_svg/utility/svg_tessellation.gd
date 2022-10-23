class_name SVGTessellation

static func generate_rect_points(x, y, width, height) -> PoolVector2Array:
	return PoolVector2Array([
		Vector2(x, y),
		Vector2(x + width, y),
		Vector2(x + width, y + height),
		Vector2(x, y + height),
		Vector2(x, y)
	])

static func generate_rect_uv(x, y, width, height, size = 1.0) -> PoolVector2Array:
	return PoolVector2Array([
		Vector2(0.0, 0.0) * size,
		Vector2(1.0, 0.0) * size,
		Vector2(1.0, 1.0) * size,
		Vector2(0.0, 1.0) * size,
		Vector2(0.0, 0.0) * size
	])

static func generate_circle_arc_points(center, radius, angle_from, angle_to, nb_points = 32) -> PoolVector2Array:
	var points_arc = PoolVector2Array()
	for i in range(nb_points + 1):
		var angle_point = angle_from + i * (angle_to - angle_from) / nb_points - PI
		points_arc.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * radius)
	return points_arc

static func generate_circle_arc_uv(angle_from, angle_to, offset = Vector2(), size = 1.0, nb_points = 32) -> PoolVector2Array:
	var uv_arc = PoolVector2Array()
	var center = Vector2(1, 1) * size / 2
	for i in range(nb_points + 1):
		var angle_point = angle_from + i * (angle_to - angle_from) / nb_points - PI
		uv_arc.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * size / 2)
	return uv_arc

static func generate_ellipse_arc_points(center, radius_x, radius_y, angle_from, angle_to, nb_points = 32) -> PoolVector2Array:
	var points_arc = PoolVector2Array()
	for i in range(nb_points + 1):
		var angle_point = angle_from + i * (angle_to - angle_from) / nb_points - PI
		points_arc.push_back(center + Vector2(cos(angle_point) * radius_x, sin(angle_point) * radius_y))
	return points_arc

