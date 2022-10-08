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

static func subdivide_quadratic_bezier_triangles(p0, p1, p2, subdivision_count = 1):
	var triangles = []
	if subdivision_count > 1:
		for i in range(subdivision_count + 1, 0, -1):
			var t = 1.0 / float(i)
			var subdivide_results = SVGMath.split_quadratic_bezier(p0, p1, p2, t)
			triangles.push_back([
				subdivide_results[0],
				subdivide_results[1],
				subdivide_results[2],
			])
			p0 = subdivide_results[2]
			p1 = subdivide_results[3]
	else:
		triangles = [[p0, p1, p2]]
	return triangles

static func subdivide_quadratic_bezier_path(p0, p1, p2, subdivision_count = 1):
	var instructions = []
	if subdivision_count > 1:
		for i in range(subdivision_count + 1, 0, -1):
			var t = 1.0 / float(i)
			var subdivide_results = SVGMath.split_quadratic_bezier(p0, p1, p2, t)
			instructions.push_back({
				"command": PathCommand.QUADRATIC_BEZIER_CURVE,
				"points": [subdivide_results[1], subdivide_results[2]]
			})
			p0 = subdivide_results[2]
			p1 = subdivide_results[3]
	else:
		instructions.push_back({
			"command": PathCommand.QUADRATIC_BEZIER_CURVE,
			"points": [p1, p2],
		})
	return instructions

static func subdivide_cubic_bezier_triangles(p0, p1, p2, p3, subdivision_count = 1):
	var triangles = []
	if subdivision_count > 1:
		for i in range(subdivision_count + 1, 0, -1):
			var t = 1.0 / float(i)
			var subdivide_results = SVGMath.split_cubic_bezier(p0, p1, p2, p3, t)
			triangles.push_back([
				subdivide_results[0],
				subdivide_results[1],
				subdivide_results[2],
			])
			triangles.push_back([
				subdivide_results[0],
				subdivide_results[2],
				subdivide_results[3],
			])
			p0 = subdivide_results[3]
			p1 = subdivide_results[4]
			p2 = subdivide_results[5]
	else:
		triangles = [[p0, p1, p2], [p0, p2, p3]]
	return triangles

static func subdivide_cubic_bezier_path(p0, p1, p2, p3, subdivision_count = 1):
	var instructions = []
	if subdivision_count > 1:
		for i in range(subdivision_count + 1, 0, -1):
			var t = 1.0 / float(i)
			var subdivide_results = SVGMath.split_cubic_bezier(p0, p1, p2, p3, t)
			instructions.push_back({
				"command": PathCommand.CUBIC_BEZIER_CURVE,
				"points": [subdivide_results[1], subdivide_results[2], subdivide_results[3]],
				"current_point": subdivide_results[0],
			})
			p0 = subdivide_results[3]
			p1 = subdivide_results[4]
			p2 = subdivide_results[5]
	else:
		instructions.push_back({
			"command": PathCommand.CUBIC_BEZIER_CURVE,
			"points": [p1, p2, p3],
			"current_point": p0,
		})
	return instructions

static func is_curve_triangles_intersects_other_curve_triangles(curve_1_triangles, curve_2_triangles):
	for curve_1_triangle in curve_1_triangles:
		for curve_2_triangle in curve_2_triangles:
			if SVGMath.triangle_intersects_triangle(curve_1_triangle, curve_2_triangle):
				return true
	return false

# This method assumes a simple shape with no self-intersections
# path is an array of dictionaries following the format:
# { "command": PathCommand, "points": [Vector()] }
# It only supports a subset of PathCommand. Points are absolute coordinates.
static func triangulate_fill_path(path: Array, holes: Array = []):
	var current_point = Vector2()
	var current_path_start_point = current_point

	# Check if the polygon is clockwise or counter-clockwise. Used to determine the inside of the path.
	# Also build a list of triangle intersection checks.
	var clockwise_check_polygon = []
	var path_intersection_checks = []
	for i in range(0, path.size()):
		var instruction = path[i]
		var next_instruction = path[i + 1] if i < path.size() - 1 else instruction
		var control_points = []
		var triangles_to_check = []
		var current_split_count = 1
		match instruction.command:
			PathCommand.MOVE_TO:
				current_point = instruction.points[0]
				current_path_start_point = current_point
				if not [PathCommand.MOVE_TO, PathCommand.CLOSE_PATH].has(next_instruction.command):
					clockwise_check_polygon.push_back(current_point)
			PathCommand.LINE_TO:
				control_points = [current_point, current_point, instruction.points[0]]
				triangles_to_check.push_back([current_point, current_point, instruction.points[0]])
				current_point = instruction.points[0]
				clockwise_check_polygon.push_back(current_point)
			PathCommand.QUADRATIC_BEZIER_CURVE:
				control_points = [current_point, instruction.points[0], instruction.points[1]]
				triangles_to_check = subdivide_quadratic_bezier_triangles(current_point, instruction.points[0], instruction.points[1], 1)
				current_point = instruction.points[1]
				clockwise_check_polygon.push_back(current_point)
			PathCommand.CUBIC_BEZIER_CURVE:
				control_points = [current_point, instruction.points[0], instruction.points[1], instruction.points[2]]
				triangles_to_check = subdivide_cubic_bezier_triangles(current_point, instruction.points[0], instruction.points[1], instruction.points[2], 1)
				current_point = instruction.points[2]
				clockwise_check_polygon.push_back(current_point)
			PathCommand.CLOSE_PATH:
				if not current_path_start_point.is_equal_approx(current_point):
					clockwise_check_polygon.push_back(current_path_start_point)
		
		# Split up bezier curves based on triangle bounding box collisions
		for other_path_check in path_intersection_checks:
			var tessellation_counter = 0
			while is_curve_triangles_intersects_other_curve_triangles(triangles_to_check, other_path_check.triangles):
				if SVGMath.triangle_area(triangles_to_check[0]) > SVGMath.triangle_area(other_path_check.triangles[0]):
					current_split_count += 1
					triangles_to_check = (
						subdivide_quadratic_bezier_triangles(control_points[0], control_points[1], control_points[2], current_split_count)
						if control_points.size() == 3 else
						subdivide_cubic_bezier_triangles(control_points[0], control_points[1], control_points[2], control_points[3], current_split_count)
					)
				else:
					other_path_check.split_count += 1
					other_path_check.triangles = (
						subdivide_quadratic_bezier_triangles(other_path_check.control_points[0], other_path_check.control_points[1], other_path_check.control_points[2], other_path_check.split_count)
						if other_path_check.control_points.size() == 3 else
						subdivide_cubic_bezier_triangles(other_path_check.control_points[0], other_path_check.control_points[1], other_path_check.control_points[2], other_path_check.control_points[3], other_path_check.split_count)
					)
				tessellation_counter += 1
				if tessellation_counter >= 32: # Prevent infinite loop if things go terribly wrong
					print("Infinite loop encountered during bezier tessellation.")
					break
		
		path_intersection_checks.push_back({
			"control_points": control_points,
			"split_count": current_split_count,
			"triangles": triangles_to_check,
		})
	
	# This method must work in a different coordinate space than Godot 2D, it gives the OPPOSITE result.
	var is_clockwise = !Geometry.is_polygon_clockwise(PoolVector2Array(clockwise_check_polygon)) 
	
	# Rebuild path based on new tessellation from triangle intersections.
	var cubic_evaluations = {}
	var old_path = path
	path = []
	for i in range(0, old_path.size()):
		var instruction = old_path[i]
		var split_count = path_intersection_checks[i].split_count
		if split_count > 1 or instruction.command == PathCommand.CUBIC_BEZIER_CURVE:
			var control_points = path_intersection_checks[i].control_points
			if instruction.command == PathCommand.QUADRATIC_BEZIER_CURVE:
				path.append_array(
					subdivide_quadratic_bezier_path(control_points[0], control_points[1], control_points[2], split_count)
				)
			elif instruction.command == PathCommand.CUBIC_BEZIER_CURVE:
				var subdivided_paths = subdivide_cubic_bezier_path(control_points[0], control_points[1], control_points[2], control_points[3], split_count)
				var final_subdivided_paths = []
				var subdivide_index = 0
				for subdivided_path in subdivided_paths:
					var cubic_evaluation = SVGCubics.evaluate_control_points([subdivided_path.current_point, subdivided_path.points[0], subdivided_path.points[1], subdivided_path.points[2]])
					var subdivided_evaluations = []
					if cubic_evaluation.needs_subdivision_at.size() > 0:
						cubic_evaluation.needs_subdivision_at.push_back(1.0)
						var last_subdivide_at = 0.0
						var subdivide_results = [0.0, 0.0, 0.0, subdivided_path.current_point, subdivided_path.points[0], subdivided_path.points[1], subdivided_path.points[2]]
						for subdivide_t in cubic_evaluation.needs_subdivision_at:
							subdivide_results = SVGMath.split_cubic_bezier(
								subdivide_results[3], subdivide_results[4], subdivide_results[5], subdivide_results[6],
								(subdivide_t - last_subdivide_at) / (1.0 - last_subdivide_at)
							)
							final_subdivided_paths.push_back({
								"command": PathCommand.CUBIC_BEZIER_CURVE,
								"points": [subdivide_results[1], subdivide_results[2], subdivide_results[3]],
							})
					else:
						final_subdivided_paths.push_back(subdivided_path)
						cubic_evaluations[path.size() + subdivide_index] = cubic_evaluation
					subdivide_index += 1
				path.append_array(final_subdivided_paths)
		else:
			path.push_back(instruction)
	
	# Build an "interior" polygon with straight edges, and other triangles to draw the bezier curves.
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
				elif (
					(start_point != control_point_1 and end_point != control_point_1 and SVGMath.is_point_right_of_segment(start_point, end_point, control_point_1) == is_clockwise) or
					(start_point != control_point_2 and end_point != control_point_2 and SVGMath.is_point_right_of_segment(start_point, end_point, control_point_2) == is_clockwise)
				):
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
					cubic_evaluations[i]
					if cubic_evaluations.has(i) else
					SVGCubics.evaluate_control_points([start_point, control_point_1, control_point_2, end_point])
				)
				cubic_vertices.append_array(cubic_evaluation.vertices)
				cubic_implicit_coordinates.append_array(cubic_evaluation.implicit_coordinates)
				for ti in range(0, cubic_evaluation.implicit_coordinates.size()):
					# 0 flips the sign (clockwise curves look correct by default), 1 keeps the sign.
					cubic_signs.push_back(1 if is_clockwise else 0)
				
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
		
		# Build vertex arrays
		for j in range(0, 3):
			var vertex_index = interior_triangulation[i + j]
			interior_vertices.push_back(interior_polygon[vertex_index])
			var index_mod = j % 3
			match index_mod:
				0:
					interior_implicit_coordinates.push_back(Vector3(0.0, 0.0, 0.0))
				1:
					interior_implicit_coordinates.push_back(Vector3(1.0, 0.0, 0.0))
				2:
					interior_implicit_coordinates.push_back(Vector3(0.0, 1.0, 0.0))
	
	# Create antialiasing lines for edges on the outside of the shape
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


