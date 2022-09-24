class_name SVGTriangulation

const PathCommand = SVGValueConstant.PathCommand

# This method assumes a simple shape with no self-intersections
# path is an array of dictionaries following the format:
# { "command": PathCommand, "points": [Vector()] }
# It only supports a subset of PathCommand. Points are absolute coordinates.
static func triangulate_fill_path(path: Array):
	var current_point = Vector2()
	var current_path_start_point = current_point

	var clockwise_check_polygon = []
	for i in range(0, path.size()):
		var instruction = path[i]
		var next_instruction = path[i + 1] if i < path.size() - 1 else instruction
		match instruction.command:
			PathCommand.MOVE_TO:
				current_point = instruction.points[0]
				current_path_start_point = current_point
				if not [PathCommand.MOVE_TO, PathCommand.CLOSE_PATH].has(next_instruction.command):
					clockwise_check_polygon.push_back(current_point)
			PathCommand.LINE_TO:
				current_point = instruction.points[0]
				clockwise_check_polygon.push_back(current_point)
			PathCommand.QUADRATIC_BEZIER_CURVE:
				current_point = instruction.points[1]
				clockwise_check_polygon.push_back(current_point)
			PathCommand.CUBIC_BEZIER_CURVE:
				current_point = instruction.points[2]
				clockwise_check_polygon.push_back(current_point)
			PathCommand.CLOSE_PATH:
				if not current_path_start_point.is_equal_approx(current_point):
					clockwise_check_polygon.push_back(current_path_start_point)
	
	var is_clockwise = Geometry.is_polygon_clockwise(PoolVector2Array(clockwise_check_polygon))
	var interior_polygon = []
	var quadratic_vertices = PoolVector2Array()
	var quadratic_implicit_coordinates = PoolVector2Array()
	var cubic_vertices = PoolVector2Array()
	var cubic_implicit_coordinates = PoolVector3Array()
	
	for i in range(0, path.size()):
		var instruction = path[i]
		var next_instruction = path[i + 1] if i < path.size() - 1 else instruction
		match instruction.command:
			PathCommand.MOVE_TO:
				current_point = instruction.points[0]
				current_path_start_point = current_point
				if not [PathCommand.MOVE_TO, PathCommand.CLOSE_PATH].has(next_instruction.command):
					interior_polygon.push_back(current_point)
			PathCommand.LINE_TO:
				current_point = instruction.points[0]
				interior_polygon.push_back(current_point)
			PathCommand.QUADRATIC_BEZIER_CURVE:
				var control_point = instruction.points[0]
				var end_point = instruction.points[1]
				if SVGMath.is_point_right_of_segment(current_point, end_point, control_point) and is_clockwise:
					interior_polygon.push_back(control_point)
				interior_polygon.push_back(end_point)
				
				quadratic_vertices.push_back(current_point)
				quadratic_implicit_coordinates.push_back(Vector2(0.0, 0.0))
				quadratic_vertices.push_back(control_point)
				quadratic_implicit_coordinates.push_back(Vector2(0.5, 0.0))
				quadratic_vertices.push_back(end_point)
				quadratic_implicit_coordinates.push_back(Vector2(1.0, 1.0))
				
				current_point = end_point
			PathCommand.CUBIC_BEZIER_CURVE:
				var control_point_1 = instruction.points[0]
				var control_point_2 = instruction.points[1]
				var end_point = instruction.points[2]
				var control_intersection = Geometry.segment_intersects_segment_2d(current_point, end_point, control_point_1, control_point_2)
				if control_intersection != null:
					var control_point_1_distance = SVGMath.point_distance_along_segment(current_point, end_point, control_point_1)
					var control_point_2_distance = SVGMath.point_distance_along_segment(current_point, end_point, control_point_2)
					var first_control_point = control_point_1 if control_point_1_distance < control_point_2_distance else control_point_2
					var second_control_point = control_point_2 if control_point_1_distance < control_point_2_distance else control_point_1
					if SVGMath.is_point_right_of_segment(current_point, end_point, first_control_point) and is_clockwise:
						interior_polygon.push_back(first_control_point)
					interior_polygon.push_back(control_intersection)
					if SVGMath.is_point_right_of_segment(current_point, end_point, second_control_point) and is_clockwise:
						interior_polygon.push_back(second_control_point)
				elif SVGMath.is_point_right_of_segment(current_point, end_point, control_point_1) and is_clockwise:
					interior_polygon.push_back(control_point_1)
					interior_polygon.push_back(control_point_2)
				interior_polygon.push_back(end_point)
				
				var cubic_evaluation = SVGCubics.evaluate_control_points([current_point, control_point_1, control_point_2, end_point])
				cubic_vertices = cubic_vertices.append_array(cubic_evaluation[0].vertices)
				cubic_implicit_coordinates = cubic_implicit_coordinates.append_array(cubic_evaluation[0].implicit_coordinates)
				
				current_point = end_point
			PathCommand.CLOSE_PATH:
				if not current_path_start_point.is_equal_approx(current_point):
					interior_polygon.push_back(current_path_start_point)
	
	var interior_vertices = PoolVector2Array()
	var interior_triangulation = Geometry.triangulate_polygon(interior_polygon)
	for index in interior_triangulation:
		interior_vertices.push_back(interior_polygon[index])
	
	return {
		"interior_vertices": interior_vertices,
		"quadratic_vertices": quadratic_vertices,
		"quadratic_implicit_coordinates": quadratic_implicit_coordinates,
		"cubic_vertices": cubic_vertices,
		"cubic_implicit_coordinates": cubic_implicit_coordinates,
	}


