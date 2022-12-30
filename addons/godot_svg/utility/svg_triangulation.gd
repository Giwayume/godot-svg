class_name SVGTriangulation

const PathCommand = SVGValueConstant.PathCommand
const TriangulationMethod = SVGValueConstant.TriangulationMethod

static func evaluate_point_bounding_box(bounding_box: Dictionary, point: Vector2):
	if point.x < bounding_box.left:
		bounding_box.left = point.x
	if point.x > bounding_box.right:
		bounding_box.right = point.x
	if point.y < bounding_box.top:
		bounding_box.top = point.y
	if point.y > bounding_box.bottom:
		bounding_box.bottom = point.y

static func evaluate_rect_bounding_box(bounding_box: Dictionary, rect: Rect2):
	if rect.position.x < bounding_box.left:
		bounding_box.left = rect.position.x
	if rect.position.x + rect.size.x > bounding_box.right:
		bounding_box.right = rect.position.x + rect.size.x
	if rect.position.y < bounding_box.top:
		bounding_box.top = rect.position.y
	if rect.position.y + rect.size.y > bounding_box.bottom:
		bounding_box.bottom = rect.position.y + rect.size.y

static func generate_uv_at_point(bounding_box: Dictionary, point: Vector2) -> Vector2:
	var x_denominator = (bounding_box.right - bounding_box.left)
	var y_denominator = (bounding_box.bottom - bounding_box.top)
	if x_denominator != 0.0 and y_denominator != 0.0:
		return Vector2(
			(point.x - bounding_box.left) / x_denominator,
			(point.y - bounding_box.top) / y_denominator
		)
	else:
		return Vector2(0.0, 0.0)

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
		for i in range(subdivision_count, 0, -1):
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
			var is_curve_1_segment = (curve_1_triangle[0] == curve_1_triangle[1])
			var is_curve_2_segment = (curve_2_triangle[0] == curve_2_triangle[1])
			if is_curve_1_segment and is_curve_2_segment:
				return false
			elif is_curve_1_segment:
				if (
					SVGMath.segment_intersects_triangle(curve_1_triangle[0], curve_1_triangle[2], curve_2_triangle) and
					not curve_1_triangle[0].is_equal_approx(curve_2_triangle[2]) and
					not curve_1_triangle[2].is_equal_approx(curve_2_triangle[0]) and
					not curve_1_triangle[0].is_equal_approx(curve_2_triangle[0]) and 
					not curve_1_triangle[2].is_equal_approx(curve_2_triangle[2])
				):
					return true
			elif is_curve_2_segment:
				if (
					SVGMath.segment_intersects_triangle(curve_2_triangle[0], curve_2_triangle[2], curve_1_triangle) and
					not curve_1_triangle[0].is_equal_approx(curve_2_triangle[2]) and
					not curve_1_triangle[2].is_equal_approx(curve_2_triangle[0]) and
					not curve_1_triangle[0].is_equal_approx(curve_2_triangle[0]) and 
					not curve_1_triangle[2].is_equal_approx(curve_2_triangle[2])
				):
					return true
			elif SVGMath.triangle_intersects_triangle(curve_1_triangle, curve_2_triangle):
				var main_path_intersection_point = Geometry.segment_intersects_segment_2d(
					curve_1_triangle[0], curve_1_triangle[2], curve_2_triangle[0], curve_2_triangle[2]
				)
				return true
	return false

static func find_path_direction_at(path: Array, path_index: int, is_start: bool, closed: bool):
	var epsilon = 0.00001
	var passed_point = null
	var p0 = null
	var p1 = null
	var p2 = null
	var p3 = null
	var path_size = path.size()
	for unused_index in range(0, path_size):
		if path_index >= 0 and path_index < path_size:
			var instruction = path[path_index]
			if p1 != null and p0 == null:
				if instruction.command == PathCommand.MOVE_TO or instruction.command == PathCommand.LINE_TO:
					p0 = instruction.points[0]
				elif instruction.command == PathCommand.QUADRATIC_BEZIER_CURVE:
					p0 = instruction.points[1]
				elif instruction.command == PathCommand.CUBIC_BEZIER_CURVE:
					p0 = instruction.points[2]
			if p1 != null and p3 == null: # Quadratic
				if is_start:
					return SVGMath.quadratic_bezier_at(p0, p1, p2, 0.0 - epsilon).direction_to(SVGMath.quadratic_bezier_at(p0, p1, p2, epsilon))
				else:
					return SVGMath.quadratic_bezier_at(p0, p1, p2, 1.0 - epsilon).direction_to(SVGMath.quadratic_bezier_at(p0, p1, p2, 1.0 + epsilon))
			elif p3 != null: # Cubic
				if is_start:
					return SVGMath.cubic_bezier_at(p0, p1, p2, p3, 0.0 - epsilon).direction_to(SVGMath.cubic_bezier_at(p0, p1, p2, p3, epsilon))
				else:
					return SVGMath.cubic_bezier_at(p0, p1, p2, p3, 1.0 - epsilon).direction_to(SVGMath.cubic_bezier_at(p0, p1, p2, p3, 1.0 + epsilon))
			else:
				match instruction.command:
					PathCommand.MOVE_TO, PathCommand.LINE_TO:
						if instruction.command == PathCommand.MOVE_TO and is_start:
							if path_index < path_size - 1:
								var next_instruction = path[path_index + 1]
								match next_instruction.command:
									PathCommand.LINE_TO:
										return instruction.points[0].direction_to(path[path_index + 1].points[0])
									PathCommand.QUADRATIC_BEZIER_CURVE:
										return SVGMath.quadratic_bezier_at(instruction.points[0], next_instruction.points[0], next_instruction.points[1], 0.0 - epsilon).direction_to(
											SVGMath.quadratic_bezier_at(instruction.points[0], next_instruction.points[0], next_instruction.points[1], epsilon)
										)
									PathCommand.CUBIC_BEZIER_CURVE:
										return SVGMath.cubic_bezier_at(instruction.points[0], next_instruction.points[0], next_instruction.points[1], next_instruction.points[2], 0.0 - epsilon).direction_to(
											SVGMath.cubic_bezier_at(instruction.points[0], next_instruction.points[0], next_instruction.points[1], next_instruction.points[2], epsilon)
										)
							else:
								return Vector2.ZERO
						elif passed_point != null: # Line
							if not instruction.points[0].is_equal_approx(passed_point):
								return instruction.points[0].direction_to(passed_point)
						else:
							passed_point = instruction.points[0]
					PathCommand.QUADRATIC_BEZIER_CURVE:
						p1 = instruction.points[0]
						p2 = instruction.points[1]
					PathCommand.CUBIC_BEZIER_CURVE:
						p1 = instruction.points[0]
						p2 = instruction.points[1]
						p3 = instruction.points[2]
			path_index -= 1
		if path_index < 0:
			if closed:
				path_index = path_size - 1
			else:
				return Vector2.ZERO
		elif path_index > path_size - 1:
			if closed:
				path_index = 0
			else:
				return Vector2.ZERO
	return Vector2.ZERO

# Intersects two path commands and joins them at their ends
static func intersect_inside_path_corner(previous_points, current_points):
	var new_previous_points = null
	var new_current_points = null
	if previous_points == null:
		new_current_points = current_points
	else:
		var previous_shape = null
		match previous_points.size():
			2: previous_shape = SVGPathSolver.PathSegment.new(previous_points[0], previous_points[1])
			3: previous_shape = SVGPathSolver.PathQuadraticBezier.new(previous_points[0], previous_points[1], previous_points[2])
			4: previous_shape = SVGPathSolver.PathCubicBezier.new(previous_points[0], previous_points[1], previous_points[2], previous_points[3])
		var current_shape = null
		match current_points.size():
			2: current_shape = SVGPathSolver.PathSegment.new(current_points[0], current_points[1])
			3: current_shape = SVGPathSolver.PathQuadraticBezier.new(current_points[0], current_points[1], current_points[2])
			4: current_shape = SVGPathSolver.PathCubicBezier.new(current_points[0], current_points[1], current_points[2], current_points[3])
		var intersections = previous_shape.intersect_with(current_shape)
		if intersections.size() > 0:
			var winning_intersection = null
			var winning_other_t = INF
			for intersection in intersections:
				if intersection.other_t < winning_other_t:
					winning_intersection = intersection
					winning_other_t = intersection.other_t
			new_previous_points = previous_shape.slice(0.0, winning_intersection.self_t).to_array()
			new_current_points = current_shape.slice(winning_intersection.other_t, 1.0).to_array()
		else:
			new_previous_points = previous_points
			new_current_points = current_points
	return {
		"previous": new_previous_points,
		"current": new_current_points
	}

static func circle_segment_to_quadratic_bezier(start_point, end_point, start_direction, end_direction, point_width, angle):
	var abs_angle = abs(angle)
	var bezier_segments = (2.0 * PI) / abs_angle
	var handle_offset_unit = (4.0/3.0) * tan(PI / (2 * bezier_segments))
	return {
		"command": PathCommand.CUBIC_BEZIER_CURVE,
		"type": "Circle Cap",
		"points": [
			start_point + (start_direction * handle_offset_unit * (point_width / 2)),
			end_point + (-end_direction * handle_offset_unit * (point_width / 2)),
			end_point,
		],
		"start_point": start_point,
	}

# This method assumes a simple shape with no self-intersections
# path is an array of dictionaries following the format:
# { "command": PathCommand, "points": [Vector()] }
# It only supports a subset of PathCommand. Points are absolute coordinates.
static func triangulate_fill_path(path: Array, holes: Array = [], override_clockwise_check = null, triangulation_method = TriangulationMethod.EARCUT):
#	print_debug(SVGAttributeParser.serialize_d(path))
	var current_point = Vector2()
	var current_path_start_point = current_point
	var has_holes = holes.size() > 0

	# Combine base fill path instruction with hole instructions for the following intersection checks.
	var all_paths = []
	var path_group_holes_start_index = null
	if has_holes:
		all_paths.append_array(path)
		for hole_path in holes:
			all_paths.append_array(hole_path)
	else:
		all_paths = path
	var all_path_size = all_paths.size()
	
	# 1. Check if the polygon is clockwise or counter-clockwise. Used to determine the inside of the path.
	# 2. Build a list of triangle intersection checks.
	# 3. Evaluate the bounding box of the overall shape for texture mapping.
	var clockwise_check_polygons = []
	var clockwise_check_polygon = []
	var path_intersection_checks = []
	var clockwise_check_encountered_path_index = 0
	var bounding_box = {
		"left": INF,
		"right": -INF,
		"top": INF,
		"bottom": -INF,
	}
	for i in range(0, all_path_size):
		var instruction = all_paths[i]
		var next_instruction = all_paths[i + 1] if i < all_path_size - 1 else instruction
		var control_points = []
		var triangles_to_check = []
		var current_split_count = 1
		match instruction.command:
			PathCommand.MOVE_TO:
				current_point = instruction.points[0]
				current_path_start_point = current_point
				if override_clockwise_check == null and not [PathCommand.MOVE_TO, PathCommand.CLOSE_PATH].has(next_instruction.command):
					clockwise_check_polygon.push_back(current_point)
			PathCommand.LINE_TO:
				control_points = [current_point, current_point, instruction.points[0]]
				triangles_to_check.push_back([current_point, current_point, instruction.points[0]])
				current_point = instruction.points[0]
				if override_clockwise_check == null: clockwise_check_polygon.push_back(current_point)
				evaluate_point_bounding_box(bounding_box, current_point)
				evaluate_point_bounding_box(bounding_box, instruction.points[0])
			PathCommand.QUADRATIC_BEZIER_CURVE:
				control_points = [current_point, instruction.points[0], instruction.points[1]]
				triangles_to_check = subdivide_quadratic_bezier_triangles(current_point, instruction.points[0], instruction.points[1], 1)
				current_point = instruction.points[1]
				if override_clockwise_check == null: clockwise_check_polygon.push_back(current_point)
				evaluate_rect_bounding_box(bounding_box, SVGMath.quadratic_bezier_bounds(control_points[0], control_points[1], control_points[2]))
			PathCommand.CUBIC_BEZIER_CURVE:
				control_points = [current_point, instruction.points[0], instruction.points[1], instruction.points[2]]
				triangles_to_check = subdivide_cubic_bezier_triangles(current_point, instruction.points[0], instruction.points[1], instruction.points[2], 1)
				current_point = instruction.points[2]
				if override_clockwise_check == null: clockwise_check_polygon.push_back(current_point)
				evaluate_rect_bounding_box(bounding_box, SVGMath.cubic_bezier_bounds(control_points[0], control_points[1], control_points[2], control_points[3]))
			PathCommand.CLOSE_PATH:
				if override_clockwise_check == null and not current_path_start_point.is_equal_approx(current_point):
					clockwise_check_polygon.push_back(current_path_start_point)
				clockwise_check_polygons.push_back(clockwise_check_polygon)
				clockwise_check_polygon = []
				if path_group_holes_start_index == null and i >= path.size() - 1:
					path_group_holes_start_index = clockwise_check_encountered_path_index + 1
				clockwise_check_encountered_path_index += 1
		
		# Split up bezier curves based on triangle bounding box collisions
		if control_points.size() > 0:
			var other_path_check_index = 0
			for other_path_check in path_intersection_checks:
				if other_path_check.control_points.size() > 0:
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
							print("[godot-svg] Infinite loop encountered during bezier tessellation. ", control_points, " ", other_path_check.control_points)
							break
				other_path_check_index += 1
		
		path_intersection_checks.push_back({
			"control_points": control_points,
			"split_count": current_split_count,
			"triangles": triangles_to_check,
		})
	
	var clockwise_checks = []
	var check_polygon_index = 0
	for check_polygon in clockwise_check_polygons:
		if override_clockwise_check != null:
			clockwise_checks.push_back(
				override_clockwise_check
				if check_polygon_index == 0 else
				not override_clockwise_check
			)
		else:
			# This method must work in a different coordinate space than Godot 2D, it gives the OPPOSITE result.
			clockwise_checks.push_back(
				!Geometry.is_polygon_clockwise(PoolVector2Array(check_polygon))
			)
		check_polygon_index += 1
	
	# Rebuild path based on new tessellation from triangle intersections.
	var cubic_evaluations = {}
	var old_path = all_paths
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
	var interior_uv = PoolVector2Array()
	var quadratic_vertices = PoolVector2Array()
	var quadratic_implicit_coordinates = PoolVector2Array()
	var quadratic_signs = PoolIntArray()
	var quadratic_uv = PoolVector2Array()
	var cubic_vertices = PoolVector2Array()
	var cubic_implicit_coordinates = PoolVector3Array()
	var cubic_signs = PoolIntArray()
	var cubic_uv = PoolVector2Array()
	var antialias_edge_vertices = PoolVector2Array()
	var antialias_edge_implicit_coordinates = PoolVector2Array()
	var antialias_edge_uv = PoolVector2Array()
	var polygon_break_indices = []
	var duplicate_edges = {}
	var current_path_index = 0
	
	if path.size() > 0 and path[path.size() - 1].command != PathCommand.CLOSE_PATH:
		path.push_back({ "command": PathCommand.CLOSE_PATH })
	
	for i in range(0, path.size()):
		var instruction = path[i]
		var next_instruction = path[i + 1] if i < path.size() - 1 else instruction
		var is_clockwise = clockwise_checks[current_path_index]
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
				var is_interior = false
				if SVGMath.is_point_right_of_segment(current_point, end_point, control_point) == is_clockwise:
					is_interior = true
					interior_polygon.push_back(control_point)
					add_duplicate_edge(duplicate_edges, current_point, control_point)
					add_duplicate_edge(duplicate_edges, control_point, end_point)
				else:
					add_duplicate_edge(duplicate_edges, current_point, end_point)
				interior_polygon.push_back(end_point)
				
				quadratic_vertices.push_back(current_point)
				quadratic_implicit_coordinates.push_back(Vector2(0.0, 0.0))
				quadratic_uv.push_back(generate_uv_at_point(bounding_box, current_point))
				quadratic_vertices.push_back(control_point)
				quadratic_implicit_coordinates.push_back(Vector2(0.5, 0.0))
				quadratic_uv.push_back(generate_uv_at_point(bounding_box, control_point))
				quadratic_vertices.push_back(end_point)
				quadratic_implicit_coordinates.push_back(Vector2(1.0, 1.0))
				quadratic_uv.push_back(generate_uv_at_point(bounding_box, end_point))
				for ti in range(0, 3):
					# 0 flips the sign (clockwise curves look correct by default), 1 keeps the sign.
					quadratic_signs.push_back(1 if is_interior else 0)
				
				current_point = end_point
			PathCommand.CUBIC_BEZIER_CURVE:
				var start_point = current_point
				var control_point_1 = instruction.points[0]
				var control_point_2 = instruction.points[1]
				var end_point = instruction.points[2]
				var control_intersection = Geometry.segment_intersects_segment_2d(start_point, end_point, control_point_1, control_point_2)
				# If the control points intersect the start/end points, interior polygon can vary wildly
				if control_intersection != null and not control_intersection == start_point and not control_intersection == end_point:
					var control_point_1_distance = SVGMath.point_distance_along_segment(start_point, end_point, control_point_1)
					var control_point_2_distance = SVGMath.point_distance_along_segment(start_point, end_point, control_point_2)
					var first_control_point = control_point_1 if control_point_1_distance < control_point_2_distance else control_point_2
					var second_control_point = control_point_2 if control_point_1_distance < control_point_2_distance else control_point_1
					if SVGMath.is_point_right_of_segment(start_point, end_point, first_control_point) == is_clockwise:
						interior_polygon.push_back(first_control_point)
						add_duplicate_edge(duplicate_edges, start_point, first_control_point)
						add_duplicate_edge(duplicate_edges, first_control_point, control_intersection)
					else:
						add_duplicate_edge(duplicate_edges, start_point, control_intersection)
					interior_polygon.push_back(control_intersection)
					if SVGMath.is_point_right_of_segment(start_point, end_point, second_control_point) == is_clockwise:
						interior_polygon.push_back(second_control_point)
						add_duplicate_edge(duplicate_edges, control_intersection, second_control_point)
						add_duplicate_edge(duplicate_edges, second_control_point, end_point)
					else:
						add_duplicate_edge(duplicate_edges, control_intersection, end_point)
				# Both control points are inside the polygon
				elif (
					(start_point != control_point_1 and end_point != control_point_1 and SVGMath.is_point_right_of_segment(start_point, end_point, control_point_1) == is_clockwise) or
					(start_point != control_point_2 and end_point != control_point_2 and SVGMath.is_point_right_of_segment(start_point, end_point, control_point_2) == is_clockwise)
				):
					interior_polygon.push_back(control_point_1)
					interior_polygon.push_back(control_point_2)
					add_duplicate_edge(duplicate_edges, start_point, control_point_1)
					add_duplicate_edge(duplicate_edges, control_point_1, control_point_2)
					add_duplicate_edge(duplicate_edges, control_point_2, end_point)
				# Both control points are outside the polygon
				else:
					add_duplicate_edge(duplicate_edges, start_point, end_point)
				interior_polygon.push_back(end_point)
				
				var cubic_evaluation = (
					cubic_evaluations[i]
					if cubic_evaluations.has(i) else
					SVGCubics.evaluate_control_points([start_point, control_point_1, control_point_2, end_point])
				)
				cubic_vertices.append_array(cubic_evaluation.vertices)
				for vertex in cubic_evaluation.vertices:
					cubic_uv.push_back(generate_uv_at_point(bounding_box, vertex))
				cubic_implicit_coordinates.append_array(cubic_evaluation.implicit_coordinates)
				for ti in range(0, cubic_evaluation.implicit_coordinates.size()):
					# 0 flips the sign (clockwise curves look correct by default), 1 keeps the sign.
					cubic_signs.push_back(1 if is_clockwise else 0)
				
				current_point = instruction.points[2]
			PathCommand.CLOSE_PATH:
				if not current_path_start_point.is_equal_approx(current_point):
					interior_polygon.push_back(current_path_start_point)
				polygon_break_indices.push_back(interior_polygon.size())
				# break # For some reason multiple paths are being passed in some cases?
	
	# Triangulate the interior polygon(s).
	var interior_vertices = PoolVector2Array()
	var interior_implicit_coordinates = PoolVector3Array()
	var interior_triangulation = PoolIntArray()
	var last_break_index = 0
	var hole_start_break_index = polygon_break_indices[path_group_holes_start_index - 1]
	
	for path_index in range(0, polygon_break_indices.size()): # range(0, path_group_holes_start_index):
		var break_index = polygon_break_indices[path_index]
		if path_index == path_group_holes_start_index:
			break
		var sliced_polygon = SVGHelper.array_slice(interior_polygon, last_break_index, break_index)
		var triangulation = []
		if has_holes:
			var hole_indices = []
			var sliced_polygon_with_holes = []
			var interior_hole_polygons = []
			interior_hole_polygons = SVGHelper.array_slice(interior_polygon, hole_start_break_index)
			
			sliced_polygon_with_holes.append_array(sliced_polygon)
			for hole_path_index in range(path_group_holes_start_index - 1, polygon_break_indices.size() - 1):
				var hole_break_index = polygon_break_indices[hole_path_index]
				hole_indices.push_back(hole_break_index)
			sliced_polygon_with_holes.append_array(interior_hole_polygons)
			
			if triangulation_method == TriangulationMethod.EARCUT:
				triangulation = SVGEarcut.earcut_polygon_2d(sliced_polygon_with_holes, hole_indices)
			elif triangulation_method == TriangulationMethod.DELAUNAY:
				triangulation = SVGDelaunay.delaunay_polygon_2d(sliced_polygon_with_holes, hole_indices)
		else:
			triangulation = Geometry.triangulate_polygon(sliced_polygon)
			if triangulation.size() == 0:
				if triangulation_method == TriangulationMethod.EARCUT:
					triangulation = SVGEarcut.earcut_polygon_2d(sliced_polygon, [])
				else:
					triangulation = SVGDelaunay.delaunay_polygon_2d(sliced_polygon, [])
		interior_triangulation.append_array(
			SVGHelper.array_add(
				triangulation,
				last_break_index
			)
		)
		last_break_index = break_index
	
	# Remove triangles with zero area (TODO - find out why this happens)
	var interior_polygon_size = interior_polygon.size()
	for i in range(interior_triangulation.size() - 3, -1, -3):
		var ti0 = interior_triangulation[i]
		var ti1 = interior_triangulation[i + 1]
		var ti2 = interior_triangulation[i + 2]
		if (
			interior_polygon_size > max(max(ti0, ti1), ti2) and
			(
				interior_polygon[ti0].is_equal_approx(interior_polygon[ti1]) or
				interior_polygon[ti1].is_equal_approx(interior_polygon[ti2])
			)
		):
			interior_triangulation.remove(i)
			interior_triangulation.remove(i)
			interior_triangulation.remove(i)
	
	# Build edge list and vertex arrays
	for i in range(0, interior_triangulation.size(), 3):
		
		# Build edge list to determine outer edges for current triangle
		var is_outer_edge = [false, false, false]
		var edges_to_recalculate = []
		for j in range(0, 3):
			var check_polygon_0 = interior_triangulation[i + j]
			var check_polygon_1 = interior_triangulation[i + j + 1] if j < 2 else interior_triangulation[i]
			if check_polygon_0 >= interior_polygon_size or check_polygon_1 >= interior_polygon_size:
				continue
			var p0 = interior_polygon[check_polygon_0]
			var p1 = interior_polygon[check_polygon_1]
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
			if vertex_index >= interior_polygon_size:
				continue
			interior_vertices.push_back(interior_polygon[vertex_index])
			interior_uv.push_back(generate_uv_at_point(bounding_box, interior_polygon[vertex_index]))
			var index_mod = j % 3
			match index_mod:
				0:
					interior_implicit_coordinates.push_back(Vector3(0.0, 0.0, 0.0))
				1:
					interior_implicit_coordinates.push_back(Vector3(1.0, 0.0, 0.0))
				2:
					interior_implicit_coordinates.push_back(Vector3(0.0, 1.0, 0.0))
	
	# FOR DEBUGGING - Create antialiasing lines for edges on the outside of the shape
#	for i in range(1, interior_polygon.size()):
#		var p0 = interior_polygon[i - 1]
#		var p1 = interior_polygon[i]
#		var direction = p0.direction_to(p1)
#		var edge_size = 1.0
#		var ae0 = p0 + (direction.rotated(-PI / 2.0) * edge_size)
#		var ae1 = p1 + (direction.rotated(-PI / 2.0) * edge_size)
#		var ae2 = p1 + (direction.rotated(PI / 2.0) * edge_size)
#		var ae3 = p0 + (direction.rotated(PI / 2.0) * edge_size)
#		antialias_edge_vertices.push_back(ae0)
#		antialias_edge_vertices.push_back(ae1)
#		antialias_edge_vertices.push_back(ae2)
#		antialias_edge_vertices.push_back(ae0)
#		antialias_edge_vertices.push_back(ae2)
#		antialias_edge_vertices.push_back(ae3)
#		antialias_edge_implicit_coordinates.push_back(Vector2(0.0, 0.0))
#		antialias_edge_implicit_coordinates.push_back(Vector2(1.0, 0.0))
#		antialias_edge_implicit_coordinates.push_back(Vector2(1.0, 1.0))
#		antialias_edge_implicit_coordinates.push_back(Vector2(0.0, 0.0))
#		antialias_edge_implicit_coordinates.push_back(Vector2(1.0, 1.0))
#		antialias_edge_implicit_coordinates.push_back(Vector2(0.0, 1.0))
#		antialias_edge_uv.push_back(generate_uv_at_point(bounding_box, ae0))
#		antialias_edge_uv.push_back(generate_uv_at_point(bounding_box, ae1))
#		antialias_edge_uv.push_back(generate_uv_at_point(bounding_box, ae2))
#		antialias_edge_uv.push_back(generate_uv_at_point(bounding_box, ae0))
#		antialias_edge_uv.push_back(generate_uv_at_point(bounding_box, ae2))
#		antialias_edge_uv.push_back(generate_uv_at_point(bounding_box, ae3))
#
	if duplicate_edges.size() > 0:
		for edge_key in duplicate_edges:
			if duplicate_edges[edge_key].size() == 1:
				var p0 = duplicate_edges[edge_key][0][1]
				var p1 = duplicate_edges[edge_key][0][2]
				var direction = p0.direction_to(p1)
				var edge_size = 1.0
				var ae0 = p0 + (direction.rotated(-PI / 2.0) * edge_size)
				var ae1 = p1 + (direction.rotated(-PI / 2.0) * edge_size)
				var ae2 = p1 + (direction.rotated(PI / 2.0) * edge_size)
				var ae3 = p0 + (direction.rotated(PI / 2.0) * edge_size)
				antialias_edge_vertices.push_back(ae0)
				antialias_edge_vertices.push_back(ae1)
				antialias_edge_vertices.push_back(ae2)
				antialias_edge_vertices.push_back(ae0)
				antialias_edge_vertices.push_back(ae2)
				antialias_edge_vertices.push_back(ae3)
				antialias_edge_implicit_coordinates.push_back(Vector2(0.0, 0.0))
				antialias_edge_implicit_coordinates.push_back(Vector2(1.0, 0.0))
				antialias_edge_implicit_coordinates.push_back(Vector2(1.0, 1.0))
				antialias_edge_implicit_coordinates.push_back(Vector2(0.0, 0.0))
				antialias_edge_implicit_coordinates.push_back(Vector2(1.0, 1.0))
				antialias_edge_implicit_coordinates.push_back(Vector2(0.0, 1.0))
				antialias_edge_uv.push_back(generate_uv_at_point(bounding_box, ae0))
				antialias_edge_uv.push_back(generate_uv_at_point(bounding_box, ae1))
				antialias_edge_uv.push_back(generate_uv_at_point(bounding_box, ae2))
				antialias_edge_uv.push_back(generate_uv_at_point(bounding_box, ae0))
				antialias_edge_uv.push_back(generate_uv_at_point(bounding_box, ae2))
				antialias_edge_uv.push_back(generate_uv_at_point(bounding_box, ae3))
		
	var triangulation_result = {
		"bounding_box": Rect2(bounding_box.left, bounding_box.top, bounding_box.right - bounding_box.left, bounding_box.bottom - bounding_box.top),
		"interior_vertices": interior_vertices,
		"interior_implicit_coordinates": interior_implicit_coordinates,
		"interior_uv": interior_uv,
		"quadratic_vertices": quadratic_vertices,
		"quadratic_implicit_coordinates": quadratic_implicit_coordinates,
		"quadratic_signs": quadratic_signs,
		"quadratic_uv": quadratic_uv,
		"cubic_vertices": cubic_vertices,
		"cubic_implicit_coordinates": cubic_implicit_coordinates,
		"cubic_signs": cubic_signs,
		"cubic_uv": cubic_uv,
		"antialias_edge_vertices": antialias_edge_vertices,
		"antialias_edge_implicit_coordinates": antialias_edge_implicit_coordinates,
		"antialias_edge_uv": antialias_edge_uv,
	}
	return triangulation_result

static func combine_triangulation(triangulation1, triangulation2):
	var bounding_box = triangulation1.bounding_box
	var interior_vertices = []
	var interior_implicit_coordinates = []
	var interior_uv
	var quadratic_vertices = []
	var quadratic_implicit_coordinates = []
	var quadratic_signs = []
	var quadratic_uv = []
	var cubic_vertices = []
	var cubic_implicit_coordinates = []
	var cubic_signs = []
	var cubic_uv = []
	var antialias_edge_vertices = []
	var antialias_edge_implicit_coordinates = []
	var antialias_edge_uv = []
	if triangulation2 != null:
		if triangulation2.bounding_box.position.x < bounding_box.position.x:
			bounding_box.position.x = triangulation2.bounding_box.position.x
		if triangulation2.bounding_box.position.x + triangulation2.bounding_box.size.x > bounding_box.position.x + bounding_box.size.x:
			bounding_box.size.x = (triangulation2.bounding_box.position.x + triangulation2.bounding_box.size.x) - bounding_box.position.x
		if triangulation2.bounding_box.position.y < bounding_box.position.y:
			bounding_box.position.y = triangulation2.bounding_box.position.y
		if triangulation2.bounding_box.position.y + triangulation2.bounding_box.size.y > bounding_box.position.y + bounding_box.size.y:
			bounding_box.size.y = (triangulation2.bounding_box.position.y + triangulation2.bounding_box.size.y) - bounding_box.position.y
		interior_vertices.append_array(triangulation1.interior_vertices)
		interior_vertices.append_array(triangulation2.interior_vertices)
		interior_implicit_coordinates.append_array(triangulation1.interior_implicit_coordinates)
		interior_implicit_coordinates.append_array(triangulation2.interior_implicit_coordinates)
		interior_uv.append_array(triangulation1.interior_uv)
		interior_uv.append_array(triangulation2.interior_uv)
		quadratic_vertices.append_array(triangulation1.quadratic_vertices)
		quadratic_vertices.append_array(triangulation2.quadratic_vertices)
		quadratic_implicit_coordinates.append_array(triangulation1.quadratic_implicit_coordinates)
		quadratic_implicit_coordinates.append_array(triangulation2.quadratic_implicit_coordinates)
		quadratic_signs.append_array(triangulation1.quadratic_signs)
		quadratic_signs.append_array(triangulation2.quadratic_signs)
		quadratic_uv.append_array(triangulation1.quadratic_uv)
		quadratic_uv.append_array(triangulation2.quadratic_uv)
		cubic_vertices.append_array(triangulation1.cubic_vertices)
		cubic_vertices.append_array(triangulation2.cubic_vertices)
		cubic_implicit_coordinates.append_array(triangulation1.cubic_implicit_coordinates)
		cubic_implicit_coordinates.append_array(triangulation2.cubic_implicit_coordinates)
		cubic_signs.append_array(triangulation1.cubic_signs)
		cubic_signs.append_array(triangulation2.cubic_signs)
		cubic_uv.append_array(triangulation1.cubic_uv)
		cubic_uv.append_array(triangulation2.cubic_uv)
		antialias_edge_vertices.append_array(triangulation1.antialias_edge_vertices)
		antialias_edge_vertices.append_array(triangulation2.antialias_edge_vertices)
		antialias_edge_implicit_coordinates.append_array(triangulation1.antialias_edge_implicit_coordinates)
		antialias_edge_implicit_coordinates.append_array(triangulation2.antialias_edge_implicit_coordinates)
		antialias_edge_uv.append_array(triangulation1.antialias_edge_uv)
		antialias_edge_uv.append_array(triangulation2.antialias_edge_uv)
	
	return {
		"bounding_box": bounding_box,
		"interior_vertices": interior_vertices,
		"interior_implicit_coordinates": interior_implicit_coordinates,
		"interior_uv": interior_uv,
		"quadratic_vertices": quadratic_vertices,
		"quadratic_implicit_coordinates": quadratic_implicit_coordinates,
		"quadratic_signs": quadratic_signs,
		"quadratic_uv": quadratic_uv,
		"cubic_vertices": cubic_vertices,
		"cubic_implicit_coordinates": cubic_implicit_coordinates,
		"cubic_signs": cubic_signs,
		"cubic_uv": cubic_uv,
		"antialias_edge_vertices": antialias_edge_vertices,
		"antialias_edge_implicit_coordinates": antialias_edge_implicit_coordinates,
		"antialias_edge_uv": antialias_edge_uv,
	}

static func offset_segment(segment_points, curve, handle_normal, offset):
	var is_first = segment_points[1] == curve.p0
	var offset_vector = curve.find_direction_at(0 if is_first else 1).rotated(PI / 2) * offset
	var point = segment_points[1] + offset_vector
	var new_segment = [point, point, point]
	var handle_index = 2 if is_first else 0
	new_segment[handle_index] = segment_points[handle_index] + ((handle_normal + offset_vector) / 2.0)
	return new_segment

static func adaptive_offset_curve(curve_points, offset, recursion_count = 0):
	var h_normal = SVGPathSolver.PathCubicBezier.new(
		curve_points[0] + curve_points[1], Vector2.ZERO, Vector2.ZERO, curve_points[2] + curve_points[3]
	).find_direction_at(0.5).rotated(PI / 2) * offset
	var curve = SVGPathSolver.PathCubicBezier.new(curve_points[0], curve_points[1], curve_points[2], curve_points[3])
	var segment1 = offset_segment([-curve_points[1], curve_points[0], curve_points[1]], curve, h_normal, offset)
	var segment2 = offset_segment([curve_points[2], curve_points[3], -curve_points[2]], curve, h_normal, offset)
	var offset_curve = SVGPathSolver.PathCubicBezier.new(segment1[1], segment1[2], segment2[0], segment2[1])
	if recursion_count < 16 and offset_curve.find_self_intersections().size() == 0:
		var threshold = min(abs(offset) / 10.0, 1.0)
		var mid_offset = SVGMath.cubic_bezier_at(offset_curve.p0, offset_curve.p1, offset_curve.p2, offset_curve.p3, 0.5).distance_to(
			SVGMath.cubic_bezier_at(curve.p0, curve.p1, curve.p2, curve.p3, 0.5)
		)
		if abs(mid_offset - abs(offset)) > threshold:
			var curve_split = SVGMath.split_cubic_bezier(curve.p0, curve.p1, curve.p2, curve.p3, 0.5)
			var return_splits = []
			return_splits.append_array(adaptive_offset_curve([curve_split[0], curve_split[1], curve_split[2], curve_split[3]], offset, recursion_count + 1))
			return_splits.append_array(adaptive_offset_curve([curve_split[3], curve_split[4], curve_split[5], curve_split[6]], offset, recursion_count + 1))
	return [segment1[1], segment1[2], segment2[0], segment2[1]]

# Outlines a path with specified width and other line join attributes.
# path is an array of dictionaries following the format:
# { "command": PathCommand, "points": [Vector()] }
# It only supports a subset of PathCommand. Points are absolute coordinates.
static func triangulate_stroke_path(path: Array, width, cap_mode, joint_mode, sharp_limit, closed: bool):
	var is_path_start = true
	var working_path = []
	var triangulation_result = null
	var current_instruction_index = 0
	var end_instruction_index = path.size() - 1
	for instruction in path:
		var path_to_triangulate = null
		var is_check_from_end = false
		match instruction.command:
			PathCommand.MOVE_TO:
				if working_path.size() > 0:
					path_to_triangulate = working_path
					working_path = []
					if is_path_start and closed:
						is_check_from_end = current_instruction_index < end_instruction_index
				working_path.push_back(instruction)
			PathCommand.CLOSE_PATH:
				working_path.push_back(instruction)
				if working_path.size() > 0:
					path_to_triangulate = working_path
					working_path = []
					if is_path_start and closed:
						is_check_from_end = current_instruction_index < end_instruction_index
			_:
				working_path.push_back(instruction)
		if current_instruction_index == end_instruction_index and path_to_triangulate == null:
			path_to_triangulate = working_path
		if is_check_from_end:
			var is_encountered_close = false
			for i in range(end_instruction_index, -1, -1):
				var end_instruction = path[i]
				var break_at_index = null
				match end_instruction.command:
					PathCommand.MOVE_TO:
						path_to_triangulate.push_front(end_instruction)
						break_at_index = i - 1
					PathCommand.CLOSE_PATH:
						if is_encountered_close:
							break_at_index = i
						else:
							if path_to_triangulate[0].command == PathCommand.MOVE_TO:
								path_to_triangulate.push_front({
									"command": PathCommand.LINE_TO,
									"points": [path_to_triangulate[0].points[0]]
								})
					_:
						path_to_triangulate.push_front(end_instruction)
				if break_at_index != null:
					end_instruction_index = break_at_index
					break
				is_encountered_close = true
		if path_to_triangulate != null:
			var subpath_triangulation = triangulate_stroke_subpath(path_to_triangulate, width, cap_mode, joint_mode, sharp_limit, closed and is_path_start)
			if triangulation_result == null:
				triangulation_result = subpath_triangulation
			else:
				triangulation_result = combine_triangulation(subpath_triangulation, triangulation_result)
			is_path_start = false
		if current_instruction_index >= end_instruction_index:
			break
		current_instruction_index += 1
	return triangulation_result

# Does the work to outline a single subpath (no internal move or close commands)
static func triangulate_stroke_subpath(path: Array, width, cap_mode, joint_mode, sharp_limit, closed: bool):
	var half_width = width / 2.0
	
	if path.size() < 2 or not path[0].has("points"):
		return triangulate_fill_path([])
	
	var current_point = path[0].points[0]
	var full_path_start_point = current_point
	
	# Create a LINE_TO command when path closes at different point from start
	var path_begin = path[0]
	var path_end = path[path.size() - 1]
	if path_end.command == PathCommand.CLOSE_PATH and path.size() > 2:
		var second_last_instruction = path[path.size() - 2]
		if second_last_instruction.has("points"):
			var last_point = second_last_instruction.points[second_last_instruction.points.size() - 1]
			if not last_point.is_equal_approx(full_path_start_point):
				var close_instruction = path.pop_back()
				path.push_back({
					"command": PathCommand.LINE_TO,
					"points": [full_path_start_point]
				})
				path.push_back(close_instruction)
	
	var path_size = path.size()
	
	var last_instruction_index = -1 if closed else 0
	if closed:
		for i in range(path_size - 1, -1, -1):
			if path[i].command != PathCommand.CLOSE_PATH:
				last_instruction_index = (i - path_size) - 1
				if abs(last_instruction_index) > path_size:
					last_instruction_index = 0
				break
	
	var left_path = []
	var right_path = []
	
	var circular_handle_offset_unit = (4.0/3.0) * tan(PI / (8.0))
	
	var previous_inside_points = null
	var previous_outside_points = null
	var previous_outside_is_right = false
	var inside_points = null
	var outside_points = null
	var outside_is_right = false
	
	for i in range(last_instruction_index, path_size):
		var instruction = path[i]
		
		var previous_direction = find_path_direction_at(path, i - 1, false, closed)
		var current_direction = find_path_direction_at(path, i, true, closed)
		var next_direction = find_path_direction_at(path, i, false, closed)
		
		if current_direction.length() == 0:
			current_direction = Vector2(1.0, 0.0)
		if previous_direction == Vector2.ZERO:
			previous_direction = current_direction
		
		# Create begin line caps
		if not closed and i == 0:
			match cap_mode:
				SVGValueConstant.SQUARE:
					left_path.push_back({
						"command": PathCommand.LINE_TO,
						"points": [current_point + (current_direction.rotated(-PI / 2) * half_width) - (current_direction * half_width)],
						"start_point": current_point - (current_direction * half_width),
					})
					left_path.push_back({
						"command": PathCommand.LINE_TO,
						"points": [current_point + (current_direction.rotated(-PI / 2) * half_width)],
						"start_point": current_point + (current_direction.rotated(-PI / 2) * half_width) - (current_direction * half_width),
					})
					right_path.push_back({
						"command": PathCommand.LINE_TO,
						"points": [current_point + (current_direction.rotated(PI / 2) * half_width) - (current_direction * half_width)],
						"start_point": current_point - (current_direction * half_width),
					})
					right_path.push_back({
						"command": PathCommand.LINE_TO,
						"points": [current_point + (current_direction.rotated(PI / 2) * half_width)],
						"start_point": current_point + (current_direction.rotated(PI / 2) * half_width) - (current_direction * half_width),
					})
				SVGValueConstant.ROUND:
					var start_point = current_point + current_direction.rotated(PI / 2) * half_width
					var end_point = current_point + current_direction.rotated(-PI / 2) * half_width
					full_path_start_point = start_point
					var new_circle_segment = circle_segment_to_quadratic_bezier(
						start_point,
						end_point,
						-current_direction,
						current_direction,
						width,
						PI
					)
					left_path.push_back(new_circle_segment)
		
		# Create interior lines and joints
		if not (instruction.command == PathCommand.MOVE_TO or instruction.command == PathCommand.CLOSE_PATH):
			var corner_angle = previous_direction.angle_to(current_direction)
			previous_outside_is_right = outside_is_right
			outside_is_right = corner_angle <= 0
			
			var inside_path = left_path if outside_is_right else right_path
			var outside_path = right_path if outside_is_right else left_path
			var inside_90_rotation = -PI / 2 if outside_is_right else PI / 2
			var outside_90_rotation = PI / 2 if outside_is_right else -PI / 2
			
			var temp_previous_inside_points = previous_inside_points
			var temp_previous_outside_points = previous_outside_points
			previous_inside_points = temp_previous_inside_points if outside_is_right == previous_outside_is_right else temp_previous_outside_points
			previous_outside_points = temp_previous_outside_points if outside_is_right == previous_outside_is_right else temp_previous_inside_points
			
			inside_points = [current_point + current_direction.rotated(inside_90_rotation) * half_width]
			outside_points = [current_point + current_direction.rotated(outside_90_rotation) * half_width]
			
			match instruction.command:
				PathCommand.LINE_TO:
					inside_points.push_back(instruction.points[0] + current_direction.rotated(inside_90_rotation) * half_width)
					outside_points.push_back(instruction.points[0] + current_direction.rotated(outside_90_rotation) * half_width)
				PathCommand.QUADRATIC_BEZIER_CURVE, PathCommand.CUBIC_BEZIER_CURVE:
					var curve_points = [current_point, instruction.points[0]]
					curve_points.push_back(instruction.points[0] if instruction.command == PathCommand.QUADRATIC_BEZIER_CURVE else instruction.points[1])
					curve_points.push_back(instruction.points[1] if instruction.command == PathCommand.QUADRATIC_BEZIER_CURVE else instruction.points[2])
					var inside_offset = -half_width if outside_is_right else half_width
					var outside_offset = -inside_offset
					inside_points = adaptive_offset_curve(curve_points, inside_offset)
					outside_points = adaptive_offset_curve(curve_points.duplicate(), outside_offset)

			var inside_intersection_point = inside_points[0]
			if previous_inside_points != null and i >= 0:
				var inside_intersection = intersect_inside_path_corner(previous_inside_points, inside_points)
				
				if inside_path.size() > 0:
					inside_path[inside_path.size() - 1].points[inside_path[inside_path.size() - 1].points.size() - 1] = inside_intersection.previous.back()
				inside_points = inside_intersection.current
				inside_intersection_point = inside_intersection.previous[inside_intersection.previous.size() - 1]
			
			if previous_outside_points != null and i >= 0:
				var use_joint_mode = joint_mode
				if use_joint_mode == SVGValueConstant.ARCS: # TODO - implement arcs
					use_joint_mode = SVGValueConstant.MITER
				
				var miter_outside_intersection = outside_points[0]
				var calculated_miter_limit = 0
				if use_joint_mode == SVGValueConstant.MITER or use_joint_mode == SVGValueConstant.MITER_CLIP:
					miter_outside_intersection = Geometry.line_intersects_line_2d(
						current_point + previous_direction.rotated(outside_90_rotation) * half_width, previous_direction,
						current_point + current_direction.rotated(outside_90_rotation) * half_width, -current_direction
					)
					if miter_outside_intersection != null:
						var miter_length = inside_intersection_point.distance_to(miter_outside_intersection)
						calculated_miter_limit = (miter_length / width)
						if sharp_limit < calculated_miter_limit and use_joint_mode == SVGValueConstant.MITER:
							use_joint_mode = SVGValueConstant.BEVEL
				
				if previous_direction.is_equal_approx(current_direction):
					use_joint_mode = null
				
				match use_joint_mode:
					SVGValueConstant.BEVEL:
						outside_path.push_back({
							"type": "Bevel End",
							"command": PathCommand.LINE_TO,
							"points": [outside_points[0]],
							"start_point": previous_outside_points[previous_outside_points.size() - 1],
						})
					SVGValueConstant.MITER:
						if miter_outside_intersection != null:
							outside_path.push_back({
								"type": "Miter Corner Intersected",
								"command": PathCommand.LINE_TO,
								"points": [miter_outside_intersection],
								"start_point": previous_outside_points[previous_outside_points.size() - 1],
							})
						else:
							outside_path.push_back({
								"type": "Miter Corner",
								"command": PathCommand.LINE_TO,
								"points": [current_point + current_direction.rotated(outside_90_rotation) * half_width],
								"start_point": previous_outside_points[previous_outside_points.size() - 1],
							})
						outside_path.push_back({
							"type": "Miter End",
							"command": PathCommand.LINE_TO,
							"points": [outside_points[0]],
							"start_point": outside_path[outside_path.size() - 1].points[0],
						})
					SVGValueConstant.MITER_CLIP: # TODO - not sure this meets the spec? https://www.w3.org/TR/SVG2/painting.html#LineJoin
						if sharp_limit < calculated_miter_limit:
							var clip_length = (sharp_limit / 2) * width
							var corner_direction = inside_intersection_point.direction_to(miter_outside_intersection)
							var clip_point = current_point + (corner_direction * clip_length)
							var clip_direction = corner_direction.rotated(PI / 2)
							var outside_edge_start = Geometry.line_intersects_line_2d(
								current_point + previous_direction.rotated(outside_90_rotation) * half_width,
								previous_direction,
								clip_point,
								clip_direction
							)
							var outside_edge_end = Geometry.line_intersects_line_2d(
								current_point + current_direction.rotated(outside_90_rotation) * half_width,
								-current_direction,
								clip_point,
								clip_direction
							)
							outside_path.push_back({
								"type": "Miter Clip Corner 1",
								"command": PathCommand.LINE_TO,
								"points": [outside_edge_start],
								"start_point": previous_outside_points[previous_outside_points.size() - 1],
							})
							outside_path.push_back({
								"type": "Miter Clip Corner 2",
								"command": PathCommand.LINE_TO,
								"points": [outside_edge_end],
								"start_point": outside_edge_start,
							})
						else:
							if miter_outside_intersection != null:
								outside_path.push_back({
									"type": "Miter Fallback Corner Intersected",
									"command": PathCommand.LINE_TO,
									"points": [miter_outside_intersection],
									"start_point": previous_outside_points[previous_outside_points.size() - 1],
								})
							else:
								outside_path.push_back({
									"type": "Miter Fallback Corner",
									"command": PathCommand.LINE_TO,
									"points": [current_point + current_direction.rotated(outside_90_rotation) * half_width],
									"start_point": previous_outside_points[previous_outside_points.size() - 1],
								})
						outside_path.push_back({
							"type": "Miter Fallback End",
							"command": PathCommand.LINE_TO,
							"points": [outside_points[0]],
							"start_point": outside_path[outside_path.size() - 1].points[0],
						})
					SVGValueConstant.ROUND:
						var new_outside_path_segment = circle_segment_to_quadratic_bezier(
							current_point + previous_direction.rotated(outside_90_rotation) * half_width,
							current_point + current_direction.rotated(outside_90_rotation) * half_width,
							previous_direction,
							current_direction,
							width,
							corner_angle
						)
						new_outside_path_segment.type = "Round Corner"
						outside_path.push_back(new_outside_path_segment)
			
			if i >= 0:
				match inside_points.size():
					2: inside_path.push_back({
						"command": PathCommand.LINE_TO,
						"points": SVGHelper.array_slice(inside_points, 1),
						"start_point": inside_points[0],
					})
					3: inside_path.push_back({
						"command": PathCommand.QUADRATIC_BEZIER_CURVE,
						"points": SVGHelper.array_slice(inside_points, 1),
						"start_point": inside_points[0],
					})
					4: inside_path.push_back({
						"command": PathCommand.CUBIC_BEZIER_CURVE,
						"points": SVGHelper.array_slice(inside_points, 1),
						"start_point": inside_points[0],
					})
					_: # Assume multiple cubic beziers
						for k in range(0, inside_points.size(), 4):
							inside_path.push_back({
								"command": PathCommand.CUBIC_BEZIER_CURVE,
								"points": SVGHelper.array_slice(inside_points, k + 1, k + 4),
								"start_point": inside_points[k],
							})
				match outside_points.size():
					2: outside_path.push_back({
						"command": PathCommand.LINE_TO,
						"points": SVGHelper.array_slice(outside_points, 1),
						"start_point": outside_points[0],
					})
					3: outside_path.push_back({
						"command": PathCommand.QUADRATIC_BEZIER_CURVE,
						"points": SVGHelper.array_slice(outside_points, 1),
						"start_point": outside_points[0],
					})
					4: outside_path.push_back({
						"command": PathCommand.CUBIC_BEZIER_CURVE,
						"points": SVGHelper.array_slice(outside_points, 1),
						"start_point": outside_points[0],
					})
					_: # Assume multiple cubic beziers
						for k in range(0, outside_points.size(), 4):
							outside_path.push_back({
								"command": PathCommand.CUBIC_BEZIER_CURVE,
								"points": SVGHelper.array_slice(outside_points, k + 1, k + 4),
								"start_point": outside_points[k],
							})
			
			previous_inside_points = inside_points
			previous_outside_points = outside_points
		
		# Reset current point to end of current line
		match instruction.command:
			PathCommand.MOVE_TO, PathCommand.LINE_TO:
				current_point = instruction.points[0]
			PathCommand.QUADRATIC_BEZIER_CURVE:
				current_point = instruction.points[1]
			PathCommand.CUBIC_BEZIER_CURVE:
				current_point = instruction.points[2]
		
		# Create end line caps
		if not closed and i == path_size - 1:
			match cap_mode:
				SVGValueConstant.SQUARE:
					left_path.push_back({
						"command": PathCommand.LINE_TO,
						"points": [current_point + (current_direction.rotated(-PI / 2) * half_width) + (current_direction * half_width)],
						"start_point": current_point + (current_direction.rotated(-PI / 2) * half_width),
					})
					left_path.push_back({
						"command": PathCommand.LINE_TO,
						"points": [current_point + (current_direction * half_width)],
						"start_point": current_point + (current_direction.rotated(-PI / 2) * half_width) + (current_direction * half_width),
					})
					right_path.push_back({
						"command": PathCommand.LINE_TO,
						"points": [current_point + (current_direction.rotated(PI / 2) * half_width) + (current_direction * half_width)],
						"start_point": current_point + (current_direction.rotated(PI / 2) * half_width),
					})
					right_path.push_back({
						"command": PathCommand.LINE_TO,
						"points": [current_point + (current_direction * half_width)],
						"start_point": current_point + (current_direction.rotated(PI / 2) * half_width) + (current_direction * half_width),
					})
				SVGValueConstant.ROUND:
					var start_point = current_point + current_direction.rotated(PI / 2) * half_width
					var end_point = current_point + current_direction.rotated(-PI / 2) * half_width
					right_path.push_back(
						circle_segment_to_quadratic_bezier(
							start_point,
							end_point,
							current_direction,
							-current_direction,
							width,
							PI
						)
					)
				_:
					left_path.push_back({
						"command": PathCommand.LINE_TO,
						"points": [right_path[right_path.size() - 1].points[right_path[right_path.size() - 1].points.size() - 1]],
						"start_point": current_point,
					})
	
	var all_paths = [
		{
			"command": PathCommand.MOVE_TO,
			"points": [left_path[0].start_point if left_path[0].has("start_point") else full_path_start_point]
		}
	]
	all_paths.append_array(left_path)
	var reversed_right_path = []
	for path_index in range(right_path.size() - 1, -1, -1):
		match right_path[path_index].command:
			PathCommand.LINE_TO:
				right_path[path_index].points = [right_path[path_index].start_point]
			PathCommand.QUADRATIC_BEZIER_CURVE:
				right_path[path_index].points = [
					right_path[path_index].points[0],
					right_path[path_index].start_point,
				]
			PathCommand.CUBIC_BEZIER_CURVE:
				right_path[path_index].points = [
					right_path[path_index].points[1],
					right_path[path_index].points[0],
					right_path[path_index].start_point,
				]
		reversed_right_path.push_back(right_path[path_index])
	if closed:
		reversed_right_path.push_front({
			"command": PathCommand.LINE_TO,
			"points": [reversed_right_path[reversed_right_path.size() - 1].points[reversed_right_path[reversed_right_path.size() - 1].points.size() - 1]],
		})
	all_paths.append_array(reversed_right_path)
	all_paths.push_back({
		"command": PathCommand.CLOSE_PATH,
	})
	
	return triangulate_fill_path(all_paths)
	

