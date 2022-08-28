class_name SVGDrawing

static func stroke_circle_arc(canvas_item, center, radius, angle_from, angle_to, color, texture = null, width = 1.0, nb_points = 32):
	var points_arc = PoolVector2Array()

	for i in range(nb_points + 1):
		var angle_point = angle_from + i * (angle_to-angle_from) / nb_points - PI
		points_arc.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * radius)

	for index_point in range(nb_points):
		canvas_item.draw_polyline(points_arc, color, width, true)

static func fill_circle_arc(canvas_item, center, radius, angle_from, angle_to, color, texture = null, nb_points = 32):
	var points_arc = PoolVector2Array()
	points_arc.push_back(center)
	var colors = PoolColorArray([color])

	for i in range(nb_points + 1):
		var angle_point = angle_from + i * (angle_to - angle_from) / nb_points - PI
		points_arc.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * radius)
	canvas_item.draw_polygon(points_arc, colors, PoolVector2Array(), null, null, true)
