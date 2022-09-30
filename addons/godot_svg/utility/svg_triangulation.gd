class_name SVGTriangulation

const PathCommand = SVGValueConstant.PathCommand

static func get_outer_edge_implicit_coordinate(is_outer_edge_array):
	var a = is_outer_edge_array[2]
	var b = is_outer_edge_array[0]
	var c = is_outer_edge_array[1]
	if not a and not b and not c:
		return 0.0
	elif a and not b and not c:
		return 0.08
	elif a and b and not c:
		return 0.25
	elif a and b and c:
		return 0.42
	elif not a and b and not c:
		return 0.58
	elif not a and b and c:
		return 0.75
	else:
		return 0.92

static func generate_edge_compare_key(p0, p1):
	var difference = (p0.x + p0.y) - (p1.x + p1.y)
	if difference == 0.0:
		difference = (abs(p0.x) + abs(p0.y)) - (abs(p1.x) + abs(p1.y))
	if difference < 0.0:
		return str(p0.x).pad_decimals(2) + "_" + str(p0.y).pad_decimals(2) + "_" + str(p1.x).pad_decimals(2) + "_" + str(p1.y).pad_decimals(2)
	else:
		return str(p1.x).pad_decimals(2) + "_" + str(p1.y).pad_decimals(2) + "_" + str(p0.x).pad_decimals(2) + "_" + str(p0.y).pad_decimals(2)

static func add_duplicate_edge(duplicate_edges, p0, p1, index = -1):
	var edge_key = generate_edge_compare_key(p0, p1)
	if not duplicate_edges.has(edge_key):
		duplicate_edges[edge_key] = []
	duplicate_edges[edge_key].push_back([index, p0, p1])

# This method assumes a simple shape with no self-intersections
# path is an array of dictionaries following the format:
# { "command": PathCommand, "points": [Vector()] }
# It only supports a subset of PathCommand. Points are absolute coordinates.
static func triangulate_fill_path(path: Array):
	var current_point = Vector2()
	var current_path_start_point = current_point

	# Check if the polygon is clockwise or counter-clockwise. Used to determine the inside of the path.
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
	
	# Build an "interior" polygon with straight edges, and other triangles to draw the bezier curves.
	var is_clockwise = Geometry.is_polygon_clockwise(PoolVector2Array(clockwise_check_polygon))
	var interior_polygon = []
	var quadratic_vertices = PoolVector2Array()
	var quadratic_implicit_coordinates = PoolVector2Array()
	var quadratic_signs = PoolIntArray()
	var cubic_vertices = PoolVector2Array()
	var cubic_implicit_coordinates = PoolVector3Array()
	var cubic_signs = PoolIntArray()
	var antialias_edge_vertices = PoolVector2Array()
	var antialias_edge_implicit_coordinates = PoolVector2Array()
	var polygon_break_indices = []
	var duplicate_edges = {}
	
	if path[path.size() - 1].command != PathCommand.CLOSE_PATH:
		path.push_back({ "command": PathCommand.CLOSE_PATH })
	
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
				var is_concave = false
				
				if SVGMath.is_point_right_of_segment(current_point, end_point, control_point) != is_clockwise:
					interior_polygon.push_back(control_point)
					add_duplicate_edge(duplicate_edges, current_point, control_point)
					add_duplicate_edge(duplicate_edges, control_point, end_point)
				else:
					add_duplicate_edge(duplicate_edges, current_point, end_point)
				interior_polygon.push_back(end_point)
				
				quadratic_vertices.push_back(current_point)
				quadratic_implicit_coordinates.push_back(Vector2(0.0, 0.0))
				quadratic_vertices.push_back(control_point)
				quadratic_implicit_coordinates.push_back(Vector2(0.5, 0.0))
				quadratic_vertices.push_back(end_point)
				quadratic_implicit_coordinates.push_back(Vector2(1.0, 1.0))
				for ti in range(0, 3):
					quadratic_signs.push_back(1 if is_concave else 0)
				
				current_point = end_point
			PathCommand.CUBIC_BEZIER_CURVE:
				var start_point = current_point
				var control_point_1 = instruction.points[0]
				var control_point_2 = instruction.points[1]
				var end_point = instruction.points[2]
				var is_concave = false
				var control_intersection = Geometry.segment_intersects_segment_2d(start_point, end_point, control_point_1, control_point_2)
				if control_intersection != null:
					var control_point_1_distance = SVGMath.point_distance_along_segment(start_point, end_point, control_point_1)
					var control_point_2_distance = SVGMath.point_distance_along_segment(start_point, end_point, control_point_2)
					var first_control_point = control_point_1 if control_point_1_distance < control_point_2_distance else control_point_2
					var second_control_point = control_point_2 if control_point_1_distance < control_point_2_distance else control_point_1
					if SVGMath.is_point_right_of_segment(start_point, end_point, first_control_point) != is_clockwise:
						interior_polygon.push_back(first_control_point)
						add_duplicate_edge(duplicate_edges, start_point, first_control_point)
						add_duplicate_edge(duplicate_edges, first_control_point, control_intersection)
					else:
						add_duplicate_edge(duplicate_edges, start_point, control_intersection)
					interior_polygon.push_back(control_intersection)
					if SVGMath.is_point_right_of_segment(start_point, end_point, second_control_point) != is_clockwise:
						interior_polygon.push_back(second_control_point)
						add_duplicate_edge(duplicate_edges, control_intersection, second_control_point)
						add_duplicate_edge(duplicate_edges, second_control_point, end_point)
					else:
						add_duplicate_edge(duplicate_edges, control_intersection, end_point)
				elif SVGMath.is_point_right_of_segment(start_point, end_point, control_point_1) != is_clockwise:
					is_concave = true
					interior_polygon.push_back(control_point_1)
					interior_polygon.push_back(control_point_2)
					add_duplicate_edge(duplicate_edges, start_point, control_point_1)
					add_duplicate_edge(duplicate_edges, control_point_1, control_point_2)
					add_duplicate_edge(duplicate_edges, control_point_2, end_point)
				else:
					add_duplicate_edge(duplicate_edges, start_point, end_point)
				interior_polygon.push_back(end_point)
				
				var cubic_evaluation = (
					SVGCubics.evaluate_control_points([end_point, control_point_2, control_point_1, start_point])
					if is_clockwise != is_concave else
					SVGCubics.evaluate_control_points([start_point, control_point_1, control_point_2, end_point])
				)
				cubic_vertices.append_array(cubic_evaluation[0].vertices)
				cubic_implicit_coordinates.append_array(cubic_evaluation[0].implicit_coordinates)
				for ti in range(0, cubic_evaluation[0].implicit_coordinates.size()):
					cubic_signs.push_back(0 if is_concave else 1)
				
				current_point = instruction.points[2]
			PathCommand.CLOSE_PATH:
				if not current_path_start_point.is_equal_approx(current_point):
					interior_polygon.push_back(current_path_start_point)
				polygon_break_indices.push_back(interior_polygon.size())
	
	# Triangulate the interior polygon(s).
	var interior_vertices = PoolVector2Array()
	var interior_implicit_coordinates = PoolVector3Array()
	var interior_triangulation = PoolIntArray()
	var last_break_index = 0
	for break_index in polygon_break_indices:
		interior_triangulation.append_array(
			SVGHelper.array_add(
				Geometry.triangulate_polygon(
					SVGHelper.array_slice(interior_polygon, last_break_index, break_index)
				),
				last_break_index
			)
		)
		last_break_index = break_index
	
	# Remove triangles with zero area (TODO - find out why this happens)
	for i in range(interior_triangulation.size() - 3, -1, -3):
		if (
			interior_polygon[interior_triangulation[i]].is_equal_approx(interior_polygon[interior_triangulation[i + 1]]) or
			interior_polygon[interior_triangulation[i + 1]].is_equal_approx(interior_polygon[interior_triangulation[i + 2]])
		):
			interior_triangulation.remove(i)
			interior_triangulation.remove(i)
			interior_triangulation.remove(i)
	
	for i in range(0, interior_triangulation.size(), 3):
		
		# Build edge list to determine outer edges for current triangle
		var is_outer_edge = [false, false, false]
		var edges_to_recalculate = []
		for j in range(0, 3):
			var p0 = interior_polygon[interior_triangulation[i + j]]
			var p1 = interior_polygon[interior_triangulation[i + j + 1] if j < 2 else interior_triangulation[i]]
			var edge_key = generate_edge_compare_key(p0, p1)
			if not duplicate_edges.has(edge_key):
				duplicate_edges[edge_key] = []
			var existing_edge_size = duplicate_edges[edge_key].size()
			is_outer_edge[j] = existing_edge_size == 0
			if existing_edge_size >= 1:
				for edge_info in duplicate_edges[edge_key]:
					var triangle_index = edge_info[0]
					if triangle_index >= 0 and not edges_to_recalculate.has(triangle_index):
						edges_to_recalculate.push_back(triangle_index)
			duplicate_edges[edge_key].push_back([i, p0, p1])
		
		# Recalculate edge implicit coordinate for duplicate edges that were found in previous triangles
		for triangle_index in edges_to_recalculate:
			var is_prev_outer_edge = [false, false, false]
			for j in range(0, 3):
				var p0 = interior_polygon[interior_triangulation[triangle_index + j]]
				var p1 = interior_polygon[interior_triangulation[triangle_index + j + 1] if j < 2 else interior_triangulation[triangle_index]]
				var edge_key = generate_edge_compare_key(p0, p1)
				var existing_edge_size = duplicate_edges[edge_key].size()
				is_prev_outer_edge[j] = existing_edge_size <= 1
			var prev_edge_implicit_coordinate = get_outer_edge_implicit_coordinate(is_prev_outer_edge)
			prev_edge_implicit_coordinate = 0.0
			var interior_implicit_coordinates_size = interior_implicit_coordinates.size()
			for j in range(0, 3):
				if triangle_index + j < interior_implicit_coordinates_size:
					interior_implicit_coordinates[triangle_index + j].z = prev_edge_implicit_coordinate
				else:
					print("\nError when recalculating implicit coordinate ", triangle_index + j)
		
		# Build vertex arrays
		var edge_implicit_coordinate = get_outer_edge_implicit_coordinate(is_outer_edge)
		edge_implicit_coordinate = 0.0
		for j in range(0, 3):
			var vertex_index = interior_triangulation[i + j]
			interior_vertices.push_back(interior_polygon[vertex_index])
			var index_mod = j % 3
			match index_mod:
				0:
					interior_implicit_coordinates.push_back(Vector3(0.0, 0.0, edge_implicit_coordinate))
				1:
					interior_implicit_coordinates.push_back(Vector3(1.0, 0.0, edge_implicit_coordinate))
				2:
					interior_implicit_coordinates.push_back(Vector3(0.0, 1.0, edge_implicit_coordinate))
	
	for edge_key in duplicate_edges:
		if duplicate_edges[edge_key].size() == 1:
			var p0 = duplicate_edges[edge_key][0][1]
			var p1 = duplicate_edges[edge_key][0][2]
			var direction = p0.direction_to(p1)
			var edge_size = 1.0
			antialias_edge_vertices.push_back(p0 + (direction.rotated(-PI / 2.0) * edge_size))
			antialias_edge_vertices.push_back(p1 + (direction.rotated(-PI / 2.0) * edge_size))
			antialias_edge_vertices.push_back(p1 + (direction.rotated(PI / 2.0) * edge_size))
			antialias_edge_vertices.push_back(p0 + (direction.rotated(-PI / 2.0) * edge_size))
			antialias_edge_vertices.push_back(p1 + (direction.rotated(PI / 2.0) * edge_size))
			antialias_edge_vertices.push_back(p0 + (direction.rotated(PI / 2.0) * edge_size))
			antialias_edge_implicit_coordinates.push_back(Vector2(0.0, 0.0))
			antialias_edge_implicit_coordinates.push_back(Vector2(1.0, 0.0))
			antialias_edge_implicit_coordinates.push_back(Vector2(1.0, 1.0))
			antialias_edge_implicit_coordinates.push_back(Vector2(0.0, 0.0))
			antialias_edge_implicit_coordinates.push_back(Vector2(1.0, 1.0))
			antialias_edge_implicit_coordinates.push_back(Vector2(0.0, 1.0))
	
	return {
		"interior_vertices": interior_vertices,
		"interior_implicit_coordinates": interior_implicit_coordinates,
		"quadratic_vertices": quadratic_vertices,
		"quadratic_implicit_coordinates": quadratic_implicit_coordinates,
		"quadratic_signs": quadratic_signs,
		"cubic_vertices": cubic_vertices,
		"cubic_implicit_coordinates": cubic_implicit_coordinates,
		"cubic_signs": cubic_signs,
		"antialias_edge_vertices": antialias_edge_vertices,
		"antialias_edge_implicit_coordinates": antialias_edge_implicit_coordinates,
	}


