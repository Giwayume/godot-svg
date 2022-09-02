tool
extends Polygon2D

const circular_handle_offset_90 = 0.552284749831

export(String) var cap_mode = SVGValueConstant.BUTT setget _set_cap_mode
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
	if not _is_creating_polygon:
		return
	
	var left_points = []
	var right_points = []
	
	var circular_handle_offset_unit = (4.0/3.0) * tan(PI / (8.0))
	
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
		
		# Create begin line caps
		if not closed and i == 0:
			match cap_mode:
				SVGValueConstant.SQUARE:
					left_points.push_back(current_point + (current_direction.rotated(-PI / 2) * point_width / 2) - (current_direction * point_width / 2) )
					right_points.push_back(current_point + (current_direction.rotated(PI / 2) * point_width / 2) - (current_direction * point_width / 2) )
				SVGValueConstant.ROUND:
					var start_point = current_point + current_direction.rotated(PI / 2) * point_width / 2
					var end_point = current_point + current_direction.rotated(-PI / 2) * point_width / 2
					var curve_points = _generate_curve_points(
						start_point,
						end_point,
						-current_direction,
						current_direction,
						point_width,
						PI,
						false
					)
					var half_mark = floor(curve_points.size() / 2)
					for point_index in range(half_mark - 1, -1, -1):
						right_points.push_back(curve_points[point_index])
					for point_index in range(half_mark, curve_points.size()):
						left_points.push_back(curve_points[point_index])
		
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
			if use_joint_mode == SVGValueConstant.ARCS: # TODO - implement arcs
				use_joint_mode = SVGValueConstant.MITER
			
			var miter_outside_intersection = Vector2()
			var calculated_miter_limit = 0
			if use_joint_mode == SVGValueConstant.MITER or use_joint_mode == SVGValueConstant.MITER_CLIP:
				miter_outside_intersection = Geometry.line_intersects_line_2d(
					current_point + previous_direction.rotated(outside_90_rotation) * point_width / 2, previous_direction,
					current_point + current_direction.rotated(outside_90_rotation) * point_width / 2, -current_direction
				)
				var miter_length = inside_intersection.distance_to(miter_outside_intersection)
				calculated_miter_limit = (miter_length / point_width)
				if sharp_limit < calculated_miter_limit and use_joint_mode == SVGValueConstant.MITER:
					use_joint_mode = SVGValueConstant.BEVEL
			
			match use_joint_mode:
				SVGValueConstant.BEVEL:
					var outside_edge_start = current_point + previous_direction.rotated(outside_90_rotation) * point_width / 2
					var outside_edge_end = current_point + current_direction.rotated(outside_90_rotation) * point_width / 2
					outside_points.push_back(outside_edge_start)
					outside_points.push_back(outside_edge_end)
				SVGValueConstant.MITER:
					if miter_outside_intersection != null:
						outside_points.push_back(miter_outside_intersection)
					else:
						outside_points.push_back(current_point + current_direction.rotated(outside_90_rotation) * point_width / 2)
				SVGValueConstant.MITER_CLIP: # TODO - not sure this meets the spec? https://www.w3.org/TR/SVG2/painting.html#LineJoin
					if sharp_limit < calculated_miter_limit:
						var clip_length = (sharp_limit / 2) * point_width
						var corner_direction = inside_intersection.direction_to(miter_outside_intersection)
						var clip_point = current_point + (corner_direction * clip_length)
						var clip_direction = corner_direction.rotated(PI / 2)
						var outside_edge_start = Geometry.line_intersects_line_2d(
							current_point + previous_direction.rotated(outside_90_rotation) * point_width / 2,
							previous_direction,
							clip_point,
							clip_direction
						)
						var outside_edge_end = Geometry.line_intersects_line_2d(
							current_point + current_direction.rotated(outside_90_rotation) * point_width / 2,
							-current_direction,
							clip_point,
							clip_direction
						)
						outside_points.push_back(outside_edge_start)
						outside_points.push_back(outside_edge_end)
					else:
						if miter_outside_intersection != null:
							outside_points.push_back(miter_outside_intersection)
						else:
							outside_points.push_back(current_point + current_direction.rotated(outside_90_rotation) * point_width / 2)
				SVGValueConstant.ROUND:
					outside_points.append_array(
						_generate_curve_points(
							current_point + previous_direction.rotated(outside_90_rotation) * point_width / 2,
							current_point + current_direction.rotated(outside_90_rotation) * point_width / 2,
							previous_direction,
							current_direction,
							point_width,
							corner_angle,
							true
						)
					)
				_:
					outside_points.push_back(current_point)
		else:
			left_points.push_back(current_point + current_direction.rotated(-PI / 2) * point_width / 2)
			right_points.push_back(current_point + current_direction.rotated(PI / 2) * point_width / 2)
	
		# Create end line caps
		if not closed and i == point_count - 1:
			match cap_mode:
				SVGValueConstant.SQUARE:
					left_points.push_back(current_point + (current_direction.rotated(-PI / 2) * point_width / 2) + (current_direction * point_width / 2) )
					right_points.push_back(current_point + (current_direction.rotated(PI / 2) * point_width / 2) + (current_direction * point_width / 2) )
				SVGValueConstant.ROUND:
					var start_point = current_point + current_direction.rotated(-PI / 2) * point_width / 2
					var end_point = current_point + current_direction.rotated(PI / 2) * point_width / 2
					var curve_points = _generate_curve_points(
						start_point,
						end_point,
						current_direction,
						-current_direction,
						point_width,
						PI,
						false
					)
					var half_mark = floor(curve_points.size() / 2)
					for point_index in range(curve_points.size() - 1, half_mark - 1, -1):
						right_points.push_back(curve_points[point_index])
					for point_index in range(0, half_mark):
						left_points.push_back(curve_points[point_index])
	
	var all_points = PoolVector2Array()
	all_points.append_array(left_points)
	right_points.invert()
	all_points.append_array(right_points)
	polygon = all_points
	
	_is_creating_polygon = false
	
	update()

func _generate_curve_points(start_point, end_point, start_direction, end_direction, point_width, angle, include_ends = true):
	var points = PoolVector2Array()
	var curve = Curve2D.new()
	var abs_angle = abs(angle)
	var bezier_segments = (2.0 * PI) / abs_angle
	var handle_offset_unit = (4.0/3.0) * tan(PI / (2 * bezier_segments))
	curve.add_point(
		start_point,
		-start_direction * handle_offset_unit * (point_width / 2),
		start_direction * handle_offset_unit * (point_width / 2)
	)
	curve.add_point(
		end_point,
		-end_direction * handle_offset_unit * (point_width / 2),
		end_direction * handle_offset_unit * (point_width / 2)
	)
	var curve_length = curve.get_baked_length()
	var curve_resolution = float(max(4, floor(curve_length / 5)))
	if include_ends:
		points.push_back(start_point)
	for point_index in range(1, curve_resolution):
		var curve_point = curve.interpolate_baked((float(point_index) / curve_resolution) * curve_length)
		points.push_back(curve_point)
	if include_ends:
		points.push_back(end_point)
	return points

# Public Methods

func draw_now():
	_is_creating_polygon = true
	_create_polygon_deferred()

# Getters / Setters

func _set_cap_mode(new_cap_mode):
	cap_mode = new_cap_mode
	_create_polygon()

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
