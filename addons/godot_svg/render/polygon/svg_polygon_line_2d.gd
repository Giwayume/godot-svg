tool
extends Polygon2D

const circular_handle_offset_90 = 0.552284749831

export(bool) var closed = false setget _set_closed
export(String) var joint_mode = SVGValueConstant.MITER setget _set_joint_mode
export(PoolVector2Array) var points = PoolVector2Array() setget _set_points
export(float) var sharp_limit = 4.0 setget _set_sharp_limit
export(float) var width = 10.0 setget _set_width

var _is_creating_polygon = false

# Lifecycle

# Internal methods

func _create_polygon():
	if not _is_creating_polygon:
		_is_creating_polygon = true
		call_deferred("_create_polygon_deferred")

func _create_polygon_deferred():
	var left_points = []
	var right_points = []
	
	var polygons = []
	
	var point_count = points.size()
	if point_count < 2:
		return
	
	for i in range(0, point_count):
		var previous_point = points[i - 1] if i > 0 else (points[point_count - 1] if closed else points[0])
		var current_point = points[i]
		var next_point = points[i + 1] if i < point_count - 1 else (points[0] if closed else points[point_count - 1])
		
		var previous_direction = previous_point.direction_to(current_point)
		var current_direction = current_point.direction_to(next_point)
		if i == point_count - 1:
			if closed:
				current_direction = points[0].direction_to(points[1])
			else:
				current_direction = previous_direction
		if i == 0:
			if closed:
				previous_direction = points[point_count - 2].direction_to(points[point_count - 1])
			else:
				previous_direction = current_direction
		
		var point_width = width
		var corner_angle = previous_direction.angle_to(current_direction)
		if corner_angle != 0:
			var inside_points = right_points if corner_angle > 0 else left_points
			var outside_points = left_points if corner_angle > 0 else right_points
			var inside_90_rotation = PI / 2 if corner_angle > 0 else -PI / 2
			var outside_90_rotation = -PI / 2 if corner_angle > 0 else PI / 2
			
			var inside_intersection = Geometry.line_intersects_line_2d(
				current_point + previous_direction.rotated(inside_90_rotation) * point_width / 2, previous_direction,
				current_point + current_direction.rotated(inside_90_rotation) * point_width / 2, -current_direction
			)
			if inside_intersection != null:
				inside_points.push_back(inside_intersection)
			else:
				inside_points.push_back(current_point + current_direction.rotated(inside_90_rotation) * point_width / 2)
			
			var use_joint_mode = joint_mode
			if use_joint_mode == SVGValueConstant.ARCS:
				use_joint_mode = SVGValueConstant.MITER
			
			match use_joint_mode:
				SVGValueConstant.BEVEL:
					var outside_edge_start = current_point + previous_direction.rotated(outside_90_rotation) * point_width / 2
					var outside_edge_end = current_point + current_direction.rotated(outside_90_rotation) * point_width / 2
					outside_points.push_back(outside_edge_start)
					outside_points.push_back(outside_edge_end)
				SVGValueConstant.MITER:
					var outside_intersection = Geometry.line_intersects_line_2d(
						current_point + previous_direction.rotated(outside_90_rotation) * point_width / 2, previous_direction,
						current_point + current_direction.rotated(outside_90_rotation) * point_width / 2, -current_direction
					)
					if outside_intersection != null:
						outside_points.push_back(outside_intersection)
					else:
						outside_points.push_back(current_point + current_direction.rotated(outside_90_rotation) * point_width / 2)
				SVGValueConstant.ROUND:
					var outside_curve = Curve2D.new()
					var outside_edge_start = current_point + previous_direction.rotated(outside_90_rotation) * point_width / 2
					var outside_edge_end = current_point + current_direction.rotated(outside_90_rotation) * point_width / 2
					var abs_corner_angle = abs(corner_angle)
					var bezier_segments = (2.0 * PI) / abs_corner_angle
					var handle_offset_unit = (4.0/3.0) * tan(PI / (2 * bezier_segments))
					outside_curve.add_point(
						outside_edge_start,
						-previous_direction * handle_offset_unit * (point_width / 2),
						previous_direction * handle_offset_unit * (point_width / 2)
					)
					outside_curve.add_point(
						outside_edge_end,
						-current_direction * handle_offset_unit * (point_width / 2),
						current_direction * handle_offset_unit * (point_width / 2)
					)
					var curve_length = outside_curve.get_baked_length()
					var curve_resolution = float(max(4, floor(curve_length / 5)))
					outside_points.push_back(outside_edge_start)
					for point_index in range(1, curve_resolution):
						var curve_point = outside_curve.interpolate_baked((float(point_index) / curve_resolution) * curve_length)
						outside_points.push_back(curve_point)
					outside_points.push_back(outside_edge_end)
				_:
					outside_points.push_back(current_point + current_direction.rotated(outside_90_rotation) * point_width / 2)
		else:
			left_points.push_back(current_point + current_direction.rotated(-PI / 2) * point_width / 2)
			right_points.push_back(current_point + current_direction.rotated(PI / 2) * point_width / 2)
	
	var all_points = PoolVector2Array()
	all_points.append_array(left_points)
	right_points.invert()
	all_points.append_array(right_points)
	polygon = all_points
	update()

# Getters / Setters

func _set_closed(new_closed):
	closed = new_closed
	_create_polygon()

func _set_joint_mode(new_joint_mode):
	joint_mode = new_joint_mode
	_create_polygon()

func _set_points(new_points):
	points = new_points
	_create_polygon()

func _set_sharp_limit(new_sharp_limit):
	sharp_limit = new_sharp_limit
	_create_polygon()

func _set_width(new_width):
	width = new_width
	_create_polygon()
