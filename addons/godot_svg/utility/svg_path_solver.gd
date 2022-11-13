class_name SVGPathSolver

const PATH_SEGMENTATION_MIN = 5
const PATH_SEGMENTATION_MAX = 1024
const PATH_SEGMENTATION_SEGMENT_SIZE = 5.0
const PathCommand = SVGValueConstant.PathCommand

enum FillRule {
	EVEN_ODD,
	NON_ZERO,
	POSITIVE,
	NEGATIVE
}

class PathShape:
	var length
	var segments = []
	var intersection_check_length
	var bounding_box
	var intersections = []
	var exit_direction = Vector2.ZERO
	var pend
	var path_end_is_close = false # This shape closes the path, special handling needed here to prevent intersection artifacts
	
	func intersect_with(other_shape, is_include_self_start_point = false, is_include_other_start_point = false):
		var new_intersections = []
		if (
			bounding_box.position.x + bounding_box.size.x < other_shape.bounding_box.position.x or
			bounding_box.position.x > other_shape.bounding_box.position.x + other_shape.bounding_box.size.x or
			bounding_box.position.y + bounding_box.size.y < other_shape.bounding_box.position.y or
			bounding_box.position.y > other_shape.bounding_box.position.y + other_shape.bounding_box.size.y
		):
			return new_intersections
		
		var self_segment_range = segments.size() - 1
		var a_length = 0.0
		for i in range(0, self_segment_range):
			var a0 = segments[i]
			var a1 = segments[i + 1]
			var other_segment_range = other_shape.segments.size() - 1
			var b_length = 0.0
			for j in range(0, other_segment_range):
				var b0 = other_shape.segments[j]
				var b1 = other_shape.segments[j + 1]
				var intersection = Geometry.segment_intersects_segment_2d(a0, a1, b0, b1)
				if (
					intersection != null and
					((is_include_self_start_point and i == 0) or not intersection.is_equal_approx(a0)) and
					((is_include_other_start_point and j == 0) or not intersection.is_equal_approx(b0)) and
					not (path_end_is_close and intersection.is_equal_approx(a1))
				):
					var new_intersection = {
						"point": intersection,
						"self_t": (a_length / intersection_check_length) + SVGMath.point_distance_along_segment(a0, a1, intersection) / intersection_check_length,
						"other_t": (b_length / other_shape.intersection_check_length) + SVGMath.point_distance_along_segment(b0, b1, intersection) / other_shape.intersection_check_length,
					}
					new_intersections.push_back(new_intersection)
					intersections.push_back(new_intersection)
					other_shape.intersections.push_back({
						"point": intersection,
						"self_t": new_intersection.other_t,
						"other_t": new_intersection.self_t,
					})
				b_length += b0.distance_to(b1)
			a_length += a0.distance_to(a1)
		return new_intersections
	
	func find_self_intersections():
		var self_intersections = []
		var self_segment_range = segments.size() - 1
		for i in range(0, self_segment_range):
			var a0 = segments[i]
			var a1 = segments[i + 1]
			for j in range(i + 1, self_segment_range):
				var b0 = segments[j]
				var b1 = segments[j + 1]
				var intersection = Geometry.segment_intersects_segment_2d(a0, a1, b0, b1)
				if intersection != null and not intersection.is_equal_approx(a0) and not intersection.is_equal_approx(b0):
					var new_intersection = {
						"point": intersection,
						"t1": (i / (self_segment_range + 1)) + SVGMath.point_distance_along_segment(a0, a1, intersection) / intersection_check_length,
						"t2": (j / (self_segment_range + 1)) + SVGMath.point_distance_along_segment(b0, b1, intersection) / intersection_check_length,
					}
		return self_intersections
	
	func find_next_intersection(t, traverse_direction = 1):
		var closest_t = INF
		var closest_intersection = null
		for intersection in intersections:
			if (
				(traverse_direction > 0 and intersection.self_t > t and intersection.self_t - t < closest_t) or
				(traverse_direction < 0 and intersection.self_t < t and t - intersection.self_t < closest_t)
			):
				closest_t = intersection.self_t
				closest_intersection = intersection
		return closest_intersection

class PathSegment extends PathShape:
	var p0
	var p1
	
	func _init(new_p0, new_p1, is_closing_line = false):
		p0 = new_p0
		p1 = new_p1
		pend = new_p1
		path_end_is_close = is_closing_line
		length = p0.distance_to(p1)
		intersection_check_length = length
		segments = [p0, p1]
		_compute_bounding_box()
		exit_direction = find_direction_at(1.0)
	
	func _compute_bounding_box():
		bounding_box = SVGHelper.get_point_list_bounds(segments)
	
	func find_direction_at(_t):
		return p0.direction_to(p1)
	
	func slice(start_t, end_t):
		var is_reversed = false
		if start_t > end_t:
			is_reversed = true
			var tmp = end_t
			end_t = start_t
			start_t = tmp
		if start_t == 0.0 and end_t == 1.0:
			if is_reversed:
				return PathSegment.new(p1, p0)
			else:
				return PathSegment.new(p0, p1)
		else:
			var path_direction = p1 - p0
			var new_p0 = p0 + path_direction * start_t
			var new_p1 = p0 + path_direction * end_t
			return PathSegment.new(
				new_p1 if is_reversed else new_p0,
				new_p0 if is_reversed else new_p1
			)
	
	func to_array():
		return [p0, p1]
	
	func to_string():
		return "segment(" + JSON.print(to_array()) + ")"
	
	func get_inside_check_point(rotation_direction):
		return (
			p0 +
			(find_direction_at(0.0).rotated(rotation_direction * PI / 128) *
			(pend - p0).length() / 128)
		)
	
class PathQuadraticBezier extends PathShape:
	var p0
	var p1
	var p2
	
	func _init(new_p0, new_p1, new_p2):
		p0 = new_p0
		p1 = new_p1
		p2 = new_p2
		pend = new_p2
		length = SVGMath.quadratic_bezier_length(p0, p1, p2)
		_compute_segments()
		_compute_bounding_box()
		exit_direction = find_direction_at(1.0)
	
	func _compute_segments():
		intersection_check_length = 0.0
		var resolution = min(PATH_SEGMENTATION_MAX, max(PATH_SEGMENTATION_MIN, floor(length / PATH_SEGMENTATION_SEGMENT_SIZE)))
		var previous_segment = p0
		for i in range(0, resolution + 1):
			var new_segment = SVGMath.quadratic_bezier_at(p0, p1, p2, i / resolution)
			intersection_check_length += previous_segment.distance_to(new_segment)
			segments.push_back(new_segment)
			previous_segment = new_segment
	
	func _compute_bounding_box():
		var control_points = [p0, p1, p2]
		bounding_box = SVGHelper.get_point_list_bounds(control_points)
	
	func find_direction_at(t):
		var epsilon = 0.00001
		if t == 0.0:
			var control_point = p1 if p1 != p0 else p2
			return p0.direction_to(control_point)
		if t == 1.0:
			var control_point = p1 if p1 != p2 else p0
			return control_point.direction_to(p2)
		var start_t = min(1, max(0, t - epsilon))
		var end_t = min(1, max(0, t + epsilon))
		return SVGMath.quadratic_bezier_at(p0, p1, p2, start_t).direction_to(SVGMath.quadratic_bezier_at(p0, p1, p2, end_t))
	
	func slice(start_t, end_t):
		var is_reversed = false
		if start_t > end_t:
			is_reversed = true
			var tmp = end_t
			end_t = start_t
			start_t = tmp
		if start_t == 0.0 and end_t == 1.0:
			if is_reversed:
				return PathQuadraticBezier.new(p2, p1, p0)
			else:
				return PathQuadraticBezier.new(p0, p1, p2)
		else:
			var left_split = SVGMath.split_quadratic_bezier(p0, p1, p2, start_t)
			var right_split = SVGMath.split_quadratic_bezier(left_split[2], left_split[3], left_split[4], (end_t - start_t) / (1.0 - start_t))
			if is_reversed:
				return PathQuadraticBezier.new(right_split[2], right_split[1], right_split[20])
			else:
				return PathQuadraticBezier.new(right_split[0], right_split[1], right_split[2])
	
	func to_array():
		return [p0, p1, p2]
	
	func to_string():
		return "quadratic(" + JSON.print(to_array()) + ")"
	
	func get_inside_check_point(rotation_direction):
		return (
			segments[0] +
			((segments[0].direction_to(segments[1])).rotated(rotation_direction * PI / 128) *
			(segments[1] - segments[0]).length() / 64)
		)

class PathCubicBezier extends PathShape:
	var p0
	var p1
	var p2
	var p3
	
	func _init(new_p0, new_p1, new_p2, new_p3):
		p0 = new_p0
		p1 = new_p1
		p2 = new_p2
		p3 = new_p3
		pend = new_p3
		length = SVGMath.cubic_bezier_length(p0, p1, p2, p3)
		_compute_segments()
		_compute_bounding_box()
		exit_direction = find_direction_at(1.0)
	
	func _compute_segments():
		intersection_check_length = 0.0
		var resolution = min(PATH_SEGMENTATION_MAX, max(PATH_SEGMENTATION_MIN, floor(length / PATH_SEGMENTATION_SEGMENT_SIZE)))
		var previous_segment = p0
		for i in range(0, resolution + 1):
			var new_segment = SVGMath.cubic_bezier_at(p0, p1, p2, p3, i / resolution)
			intersection_check_length += previous_segment.distance_to(new_segment)
			segments.push_back(new_segment)
			previous_segment = new_segment
	
	func _compute_bounding_box():
		var control_points = [p0, p1, p2, p3]
		bounding_box = SVGHelper.get_point_list_bounds(control_points)
	
	func find_direction_at(t):
		var epsilon = 0.00001
		if t == 0.0:
			var control_point = p1 if p1 != p0 else p2
			return p0.direction_to(control_point)
		if t == 1.0:
			var control_point = p2 if p2 != p3 else p1
			return control_point.direction_to(p3)
		var start_t = min(1, max(0, t - epsilon))
		var end_t = min(1, max(0, t + epsilon))
		return SVGMath.cubic_bezier_at(p0, p1, p2, p3, start_t).direction_to(SVGMath.cubic_bezier_at(p0, p1, p2, p3, end_t))
	
	func slice(start_t, end_t):
		var is_reversed = false
		if start_t > end_t:
			is_reversed = true
			var tmp = end_t
			end_t = start_t
			start_t = tmp
		if start_t == 0.0 and end_t == 1.0:
			if is_reversed:
				return PathCubicBezier.new(p3, p2, p1, p0)
			else:
				return PathCubicBezier.new(p0, p1, p2, p3)
		else:
			var left_split = SVGMath.split_cubic_bezier(p0, p1, p2, p3, start_t)
			var right_split = (
				SVGMath.split_cubic_bezier(left_split[3], left_split[4], left_split[5], left_split[6], (end_t - start_t) / (1.0 - start_t))
				if start_t < 1.0 else
				[p3, p3, p3, p3, p3, p3, p3]
			)
			if is_reversed:
				return PathCubicBezier.new(right_split[3], right_split[2], right_split[1], right_split[0])
			else:
				return PathCubicBezier.new(right_split[0], right_split[1], right_split[2], right_split[3])
	
	func to_array():
		return [p0, p1, p2, p3]
	
	func to_string():
		return "cubic(" + JSON.print(to_array()) + ")"
	
	func get_inside_check_point(rotation_direction):
		return (
			segments[0] +
			((segments[0].direction_to(segments[1])).rotated(rotation_direction * PI / 128) *
			(segments[1] - segments[0]).length() / 64)
		)

static func get_path_loop_range(loop_ranges, current_index):
	for loop_range in loop_ranges:
		if current_index >= loop_range.start and current_index <= loop_range.end:
			return loop_range
	return null

static func create_new_bounding_box():
	return {
		"left": INF,
		"right": -INF,
		"top": INF,
		"bottom": -INF,
	}

static func apply_shape_to_bounding_box(bounding_box, path_shape):
	if path_shape.bounding_box.position.x < bounding_box.left:
		bounding_box.left = path_shape.bounding_box.position.x
	if path_shape.bounding_box.position.x + path_shape.bounding_box.size.x > bounding_box.right:
		bounding_box.right = path_shape.bounding_box.position.x + path_shape.bounding_box.size.x
	if path_shape.bounding_box.position.y < bounding_box.top:
		bounding_box.top = path_shape.bounding_box.position.y
	if path_shape.bounding_box.position.y + path_shape.bounding_box.size.y > bounding_box.bottom:
		bounding_box.bottom = path_shape.bounding_box.position.y + path_shape.bounding_box.size.y
	return bounding_box

static func is_bounding_box_inside_other_bounding_box(expect_inside, expect_outside):
	if (
		expect_inside.left <= expect_outside.left or
		expect_inside.top <= expect_outside.top or
		expect_inside.right >= expect_outside.right or
		expect_inside.bottom >= expect_outside.bottom
	):
		return false
	return true

# During path intersection traversal, some shapes may be formed in self-intersecting loops that
# are just smaller versions of a larger shape outline. This checks for that so they aren't included.
static func is_path_subset_of_path(find, in_path):
	var match_index = 0
	var find_size = find.size()
	var is_subset = false
	if find_size < in_path.size(): # if array is same size, could be same points in different order. Don't care.
		for value in in_path:
			if find[match_index] == value:
				match_index += 1
			else:
				match_index = 0
			if match_index >= find_size:
				is_subset = true
				break
	return is_subset

static func generate_loop_ranges(paths: Array):
	var loop_ranges = []
	var current_loop_start = 0
	for i in range(0, paths.size()):
		if (
			paths[i].command == PathCommand.CLOSE_PATH or
			(i == paths.size() - 1 and current_loop_start < i)
		):
			loop_ranges.push_back({
				"start": current_loop_start,
				"end": i,
			})
			current_loop_start = i + 1
	return loop_ranges

static func convert_path_shapes_to_instructions(path_shapes):
	var instructions = []
	instructions.push_back({
		"command": PathCommand.MOVE_TO,
		"points": [path_shapes[0].p0],
	})
	for shape in path_shapes:
		if shape is PathSegment:
			instructions.push_back({
				"command": PathCommand.LINE_TO,
				"points": [shape.p1],
			})
		elif shape is PathQuadraticBezier:
			instructions.push_back({
				"command": PathCommand.QUADRATIC_BEZIER_CURVE,
				"points": [shape.p1, shape.p2],
			})
		elif shape is PathCubicBezier:
			instructions.push_back({
				"command": PathCommand.CUBIC_BEZIER_CURVE,
				"points": [shape.p1, shape.p2, shape.p3],
			})
	instructions.push_back({
		"command": PathCommand.CLOSE_PATH,
	})
	return instructions

static func find_solved_paths_that_use_shape_index(solved_paths, closest_hit_shape_index):
	var found_path_indices = []
	for i in range(0, solved_paths.size()):
		var path_ranges = solved_paths[i].path_ranges
		for path_range in path_ranges:
			if closest_hit_shape_index >= path_range[0] and closest_hit_shape_index < path_range[1]:
				found_path_indices.push_back(i)
				break
	return found_path_indices

# Attempt to resolve self-intersections in a list of multiple path commands by...
# ...splitting one path into multiple shapes at the intersections.
# Paths is an array of command dictionaries.
static func simplify(paths: Array, fill_rule = FillRule.EVEN_ODD):
	var intersections = []
	var intersections_at_positions = {}
	var solved_paths = []
	var path_shapes = []
	
	# Determine the looping ranges for each path
	var path_loop_ranges = []
	var shape_loop_ranges = []
	var current_loop_start = 0
	var current_point = Vector2()
	var current_loop_start_point = Vector2()
	
	for i in range(0, paths.size()):
		var previous_instruction = paths[i - 1] if i > 0 else null
		var command = paths[i].command
		var points = paths[i].points if paths[i].has("points") else []
		var is_implicit_path_close = previous_instruction != null and paths[i].command == PathCommand.MOVE_TO and previous_instruction.command != PathCommand.CLOSE_PATH
		
		match command:
			PathCommand.MOVE_TO:
				if is_implicit_path_close and not current_point.is_equal_approx(current_loop_start_point):
					path_shapes.push_back(PathSegment.new(current_point, current_loop_start_point, true))
				current_point = points[0]
			PathCommand.LINE_TO:
				path_shapes.push_back(PathSegment.new(current_point, points[0]))
				current_point = points[0]
			PathCommand.QUADRATIC_BEZIER_CURVE:
				path_shapes.push_back(PathQuadraticBezier.new(current_point, points[0], points[1]))
				current_point = points[1]
			PathCommand.CUBIC_BEZIER_CURVE:
				path_shapes.push_back(PathCubicBezier.new(current_point, points[0], points[1], points[2]))
				current_point = points[2]
		
		var is_end_of_paths = (i == paths.size() - 1 and current_loop_start < i)
		if (
			paths[i].command == PathCommand.CLOSE_PATH or
			is_implicit_path_close or
			is_end_of_paths
		):
			if is_end_of_paths and not current_point.is_equal_approx(current_loop_start_point):
				path_shapes.push_back(PathSegment.new(current_point, current_loop_start_point))
			shape_loop_ranges.push_back({
				"start": current_loop_start,
				"end": path_shapes.size() - 1,
			})
			current_loop_start = path_shapes.size()
		
		if command == PathCommand.MOVE_TO:
			current_loop_start_point = points[0]
	
	# Loop through the path commands and build a list of intersection points,
	# As well as a list of paths that don't intersect with anything else
	var current_loop_range_index = 0
	var current_loop_range_has_any_intersection = false
	var current_loop_range_rotation = 0.0
	var path_shapes_size = path_shapes.size()
	var current_path_bounding_box = create_new_bounding_box()
	for i in range(0, path_shapes_size):
		var path_shape = path_shapes[i]
		var next_path_shape = path_shapes[i + 1 if i < path_shapes_size - 1 else 0]
		var current_loop_range = shape_loop_ranges[current_loop_range_index]
		current_path_bounding_box = apply_shape_to_bounding_box(current_path_bounding_box, path_shape)
		if i >= current_loop_range.start + 1:
			for j in range(current_loop_range.start, i):
				var other_path_shape = path_shapes[j]
				var new_intersections = path_shape.intersect_with(other_path_shape, j != i - 1, true)
				if new_intersections.size() > 0:
					current_loop_range_has_any_intersection = true
					for new_intersection in new_intersections:
						var is_existing_intersection = false
						# Check if intersection point already exists, and modify it with new paths
						for existing_intersection in intersections:
							if existing_intersection.point.is_equal_approx(new_intersection.point):
								existing_intersection.intersected_shape_indices.push_back(j)
								existing_intersection.intersected_shape_t.push_back(new_intersection.other_t)
								if not intersections_at_positions.has(j):
									intersections_at_positions[j] = []
								if not intersections_at_positions.has(existing_intersection):
									intersections_at_positions[j].push_back(existing_intersection)
						# Don't count path start touching path end as an intersection
						if i == current_loop_range.end and j == current_loop_range.start and new_intersection.self_t == 1.0 and new_intersection.other_t == 0.0:
							is_existing_intersection = true
							if new_intersections.size() == 1:
								current_loop_range_has_any_intersection = false
						# Add new intersection definition to intersections array for later use
						if not is_existing_intersection:
							var intersection = {
								"point": new_intersection.point,
								"intersected_shape_indices": [i, j],
								"intersected_shape_t": [new_intersection.self_t, new_intersection.other_t],
								"solved": {},
							}
							intersections.push_back(intersection)
							if not intersections_at_positions.has(i):
								intersections_at_positions[i] = []
							if not intersections_at_positions.has(j):
								intersections_at_positions[j] = []
							intersections_at_positions[i].push_back(intersection)
							intersections_at_positions[j].push_back(intersection)
		current_loop_range_rotation += path_shape.find_direction_at(0.0).angle_to(
			next_path_shape.find_direction_at(0.0)
		)
		if i >= current_loop_range.end:
			if not current_loop_range_has_any_intersection:
				solved_paths.push_back({
					"path": SVGHelper.array_slice(path_shapes, current_loop_range.start, current_loop_range.end + 1),
					"path_ranges": [[current_loop_range.start, current_loop_range.end]],
					"bounding_box": current_path_bounding_box,
					"is_clockwise": current_loop_range_rotation > 0.0,
				})
			current_loop_range_index += 1
			current_loop_range_has_any_intersection = false
			current_loop_range_rotation = 0.0
			current_path_bounding_box = create_new_bounding_box()
	
	# For each intersection point, follow the intersection lines forward, then take right turns until it comes back to the initial point
	if intersections.size() > 0:
		current_path_bounding_box = create_new_bounding_box()
		for intersection in intersections:
			for shape_start_array_index in range(0, intersection.intersected_shape_indices.size()):
				var shape_start_index = intersection.intersected_shape_indices[shape_start_array_index]
				var shape_start_t = intersection.intersected_shape_t[shape_start_array_index]
				var last_passed_intersection = intersection
				var last_passed_intersection_start_shape_index = shape_start_index
				var has_looped_from_beginning = false
				var traverse_direction = 1
				var check_t = shape_start_t
				var current_shape_index = shape_start_index
				var new_path = []
				var new_path_ranges = []
				var new_path_current_range = [current_shape_index, -1]
				var final_rotation = 0.0
				var infinite_loop_iterator = 0
				var existing_solutions = []
				var encountered_intersections = [intersection]
				var did_path_return_to_start = false
				while infinite_loop_iterator < 1000: # If you need paths with 1000+ instructions open an issue. Performance is bad.
					infinite_loop_iterator += 1
					var next_intersection = null
					var next_intersection_t = 0.0
					
					# Gather information about the current path traced position in the current shape
					var current_shape = path_shapes[current_shape_index]
					
					# Find the next intersection at the current path segment, if applicable
					if intersections_at_positions.has(current_shape_index):
						var next_intersection_info = current_shape.find_next_intersection(check_t, traverse_direction)
						if next_intersection_info != null:
							for check_intersection in intersections_at_positions[current_shape_index]:
								if check_intersection.point.is_equal_approx(next_intersection_info.point):
									next_intersection = check_intersection
									next_intersection_t = next_intersection_info.self_t
									break
					
					# If next intersection is our starting intersection, we're done
					if encountered_intersections.has(next_intersection):
						if next_intersection == intersection:
							# TODO - add rest of shape to path?
							did_path_return_to_start = true
							new_path_current_range[1] = current_shape_index
							new_path_ranges.push_back(new_path_current_range)
						break
					
					# Find which path at the intersection is the closest right turn, and take it
					elif next_intersection:
						new_path.push_back(
							current_shape.slice(
								check_t,
								next_intersection_t
							)
						)
						encountered_intersections.push_back(next_intersection)
						
						var entry_direction = traverse_direction * current_shape.find_direction_at(next_intersection_t)
						var closest_angle = INF
						var winning_index = -1
						var winning_t = 0.0
						for check_shape_array_index in range(0, next_intersection.intersected_shape_indices.size()):
							var check_shape_index = next_intersection.intersected_shape_indices[check_shape_array_index]
							var current_check_t = next_intersection.intersected_shape_t[check_shape_array_index]
							var check_direction = path_shapes[check_shape_index].find_direction_at(current_check_t)
							var check_loop_range = get_path_loop_range(shape_loop_ranges, check_shape_index)
							var is_check_positive_angle = not (current_check_t < 1.0 and check_shape_index == check_loop_range.end)
							var is_check_negative_angle = not (current_check_t > 0.0 and check_shape_index == check_loop_range.start)
							var positive_angle = check_direction.angle_to(-entry_direction)
							var negative_angle = -check_direction.angle_to(-entry_direction)
							if positive_angle < 0.0:
								positive_angle = PI + abs(positive_angle)
							if negative_angle < 0.0:
								negative_angle = PI + abs(negative_angle)
							if is_check_positive_angle and positive_angle > 0 and positive_angle < closest_angle:
								closest_angle = positive_angle
								winning_index = check_shape_index
								winning_t = current_check_t
								traverse_direction = 1
							elif is_check_negative_angle and negative_angle > 0 and negative_angle < closest_angle:
								closest_angle = negative_angle
								winning_index = check_shape_index
								winning_t = current_check_t
								traverse_direction = -1
						if winning_index > -1:
							current_path_bounding_box = apply_shape_to_bounding_box(current_path_bounding_box, current_shape)
							final_rotation += sign(closest_angle) * (PI - abs(closest_angle))
							new_path_current_range[1] = current_shape_index
							new_path_ranges.push_back(new_path_current_range)
							current_shape_index = winning_index
							new_path_current_range = [winning_index, -1]
							check_t = winning_t
							has_looped_from_beginning = false
							last_passed_intersection = next_intersection
							last_passed_intersection_start_shape_index = winning_index
							if (
								traverse_direction > 0 and last_passed_intersection.solved.has(
									str(last_passed_intersection_start_shape_index) + "_" + str(winning_t)
								)
							):
								existing_solutions.push_back({
									"intersection": last_passed_intersection,
									"shape_index": last_passed_intersection_start_shape_index,
									"shape_t": winning_t,
								})
						else:
							print("Error solving simple shape: no valid direction found")
							break
					
					# No intersection found, keep looping through current path segments
					else:
						if check_t > 0.014967 and check_t < 0.014969:
							check_t = 0.14968
						var new_sliced_shape = current_shape.slice(
							check_t,
							(1.0 if traverse_direction > 0.0 else 0.0)
						)
						new_path.push_back(new_sliced_shape)
						
						current_path_bounding_box = apply_shape_to_bounding_box(current_path_bounding_box, current_shape)
						
						var path_loop_range = get_path_loop_range(shape_loop_ranges, current_shape_index)
						current_shape_index += traverse_direction
						if current_shape_index > path_loop_range.end:
							current_shape_index = path_loop_range.start
							has_looped_from_beginning = true
						elif current_shape_index < path_loop_range.start:
							current_shape_index = path_loop_range.end
							has_looped_from_beginning = true
						
						var next_shape = path_shapes[current_shape_index]
						var check_t_half_to_end = ((1.0 if traverse_direction > 0.0 else 0.0) + check_t) / 2.0
						final_rotation += current_shape.find_direction_at(check_t).angle_to(
							current_shape.find_direction_at(check_t_half_to_end)
						)
						final_rotation += current_shape.find_direction_at(1.0 if traverse_direction > 0.0 else 0.0).angle_to(
							traverse_direction * next_shape.find_direction_at(0.0 if traverse_direction > 0.0 else 1.0)
						)
						final_rotation += current_shape.find_direction_at(1.0 if traverse_direction > 0.0 else 0.0).angle_to(
							traverse_direction * next_shape.find_direction_at(0.0 if traverse_direction > 0.0 else 1.0)
						)
						check_t = 0.0 if traverse_direction > 0.0 else 1.0
				
				if did_path_return_to_start:
					var trumps_all_existing_solutions = true
					if existing_solutions.size() > 0:
						for existing_solution in existing_solutions:
							if not is_path_subset_of_path(
								existing_solution.intersection.solved[str(existing_solution.shape_index) + "_" + str(existing_solution.shape_t)].path,
								new_path
							):
								trumps_all_existing_solutions = false
								break
						if trumps_all_existing_solutions:
							for existing_solution in existing_solutions:
								existing_solution.intersection.solved.erase(str(existing_solution.shape_index) + "_" + str(existing_solution.shape_t))
					if trumps_all_existing_solutions:
						print_debug("final clockwise ", final_rotation)
						intersection.solved[str(shape_start_index) + "_" + str(shape_start_t)] = {
							"path": new_path,
							"path_ranges": new_path_ranges,
							"bounding_box": current_path_bounding_box,
							"is_clockwise": final_rotation > 0.0,
						}
						current_path_bounding_box = create_new_bounding_box()
		
		for intersection in intersections:
			for solved_key in intersection.solved:
				solved_paths.push_back(intersection.solved[solved_key])
	
	# Apply fill rule
	var filled_paths = []
	var filled_paths_clockwise_checks = []
	var filled_paths_solved_path_indices = []
	var hole_paths = []
	var hole_candidates = []
	var current_solved_path_index = 0
	for solved_path_info in solved_paths:
		var solved_path = solved_path_info.path
		var is_clockwise = solved_path_info.is_clockwise
		var check_point = solved_path[0].get_inside_check_point(1.0 if is_clockwise else -1.0)
		var insideness = 0
		var is_hole_candidate = false
		var closest_hit_shape_index = -1
		var closest_hit_shape_distance = INF
		var second_closest_hit_shape_index = -1
		var second_closest_hit_shape_distance = INF
		for shape_index in range(0, path_shapes.size()):
			var shape = path_shapes[shape_index]
			# Count collisions for a line that starts at check point and travels infinitely in -y direction
			if (
				check_point.x >= shape.bounding_box.position.x and
				check_point.x <= shape.bounding_box.position.x + shape.bounding_box.size.x and
				check_point.y >= shape.bounding_box.position.y
			):
				var check_collision_segment = PathSegment.new(check_point, Vector2(check_point.x, shape.bounding_box.position.y - 1.0))
				var line_intersections = check_collision_segment.intersect_with(shape)
				var line_intersections_size = line_intersections.size()
				for line_intersection in line_intersections:
					var line_intersection_distance = check_point.distance_to(line_intersection.point)
					if line_intersection_distance < closest_hit_shape_distance:
						second_closest_hit_shape_index = closest_hit_shape_index
						second_closest_hit_shape_distance = closest_hit_shape_distance
						closest_hit_shape_distance = line_intersection_distance
						closest_hit_shape_index = shape_index
				if line_intersections_size > 0:
					is_hole_candidate = true
				if line_intersections_size % 2 == 1:
					if shape.p0.x <= check_point.x and shape.pend.x >= check_point.x:
						insideness += 1
					elif shape.p0.x >= check_point.x and shape.pend.x <= check_point.x:
						insideness -= 1
		
		var is_filled = false
		match fill_rule:
			FillRule.EVEN_ODD:
				if int(abs(insideness)) % 2 == 1:
					is_filled = true
			FillRule.NON_ZERO:
				if insideness != 0:
					is_filled = true
		
		is_filled = true # TODO - remove
		if is_filled:
			filled_paths.push_back(solved_path)
			filled_paths_clockwise_checks.push_back(is_clockwise)
			filled_paths_solved_path_indices.push_back(current_solved_path_index)
			hole_paths.push_back([])
		elif is_hole_candidate:
			hole_candidates.push_back({
				"second_closest_hit_shape_index": second_closest_hit_shape_index,
				"solved_path_info": solved_path_info,
			})
		
		current_solved_path_index += 1
	
	# For shapes that appear to be holes, find the parent shapes containing the holes.
	for hole_candidate in hole_candidates:
		var paths_that_use_shape = find_solved_paths_that_use_shape_index(solved_paths, hole_candidate.second_closest_hit_shape_index)
		for solved_path_index in paths_that_use_shape:
			var found_index = filled_paths_solved_path_indices.find(solved_path_index)
			if (
				found_index > -1 and
				is_bounding_box_inside_other_bounding_box(
					hole_candidate.solved_path_info.bounding_box,
					solved_paths[solved_path_index].bounding_box
				)
			):
				hole_paths[found_index].push_back(hole_candidate.solved_path_info.path)
				break
	
	# Translate shape classes back into instruction commands.
	var instruction_groups = []
	for path_index in range(0, filled_paths.size()):
		var fill_instructions = convert_path_shapes_to_instructions(filled_paths[path_index])
		var hole_instructions = []
		for hole_path in hole_paths[path_index]:
			hole_instructions.push_back(
				convert_path_shapes_to_instructions(hole_path)
			)
		instruction_groups.push_back({
			"fill_instructions": fill_instructions,
			"is_clockwise": filled_paths_clockwise_checks[path_index],
			"hole_instructions": hole_instructions,
		})
	return instruction_groups

static func dash_array(path_reference: Array, dash_array: Array, dash_offset: float):
	# Figure out starting offset for dash
	var current_dash_size_index = 0
	var current_dash_size = 0.0
	var current_distance_traversed = 0.0
	var is_dash_render = true
	if dash_offset != 0:
		var repeat_size = 0
		for size in dash_array:
			repeat_size += size
		var repeat_count = floor(abs(dash_offset / repeat_size))
		var cumulative_offset = repeat_count * dash_offset
		if int(repeat_count) % 2 == 1:
			is_dash_render = false
		if dash_offset > 0:
			for current_index in range(0, dash_array.size()):
				var size = float(dash_array[current_index])
				cumulative_offset += size
				if cumulative_offset > dash_offset:
					current_dash_size_index = current_index
					current_distance_traversed = cumulative_offset - dash_offset
					break
		else:
			cumulative_offset *= -1
			for current_index in range(dash_array.size() - 1, -1, -1):
				var size = float(dash_array[current_index])
				cumulative_offset -= size
				if cumulative_offset < dash_offset:
					current_dash_size_index = current_index
					current_distance_traversed = cumulative_offset - dash_offset
					break
	current_dash_size = float(dash_array[current_dash_size_index])
	
	# Loop through path shapes and create new paths based on size
	var current_reference_index = 0
	var current_reference_size_total = 0
	var previous_reference_size_used = 0
	var current_reference_size_used = 0
	var loop_count = 0
	var current_point = Vector2.ZERO
	var dashed_path = []
	var was_dash_render = false
	while current_reference_index < path_reference.size():
		if loop_count > 65536: # Prevent infinite loop
			break
		loop_count += 1
		
		var reference_instruction = path_reference[current_reference_index]
		if reference_instruction.command == PathCommand.MOVE_TO:
			current_point = reference_instruction.points[0]
			current_reference_index += 1
			continue
		if reference_instruction.command == PathCommand.CLOSE_PATH:
			current_reference_index += 1
			continue
		
		# Calculate length of the referenced segment of the path
		if current_reference_size_total == 0:
			match reference_instruction.command:
				PathCommand.LINE_TO:
					current_reference_size_total = current_point.distance_to(reference_instruction.points[0])
				PathCommand.QUADRATIC_BEZIER_CURVE:
					current_reference_size_total = SVGMath.quadratic_bezier_length(current_point, reference_instruction.points[0], reference_instruction.points[1])
				PathCommand.CUBIC_BEZIER_CURVE:
					current_reference_size_total = SVGMath.cubic_bezier_length(current_point, reference_instruction.points[0], reference_instruction.points[1], reference_instruction.points[2])
		
		previous_reference_size_used = current_reference_size_used
		current_reference_size_used += current_dash_size - current_distance_traversed
		current_reference_size_used = min(current_reference_size_used, current_reference_size_total)
		current_distance_traversed += current_reference_size_used
		
		# Add a segment of the current shape as necessary
		match reference_instruction.command:
			PathCommand.LINE_TO:
				var end_point = current_point + (current_point.direction_to(reference_instruction.points[0]) * current_reference_size_used)
				if is_dash_render:
					if not was_dash_render:
						was_dash_render = true
						dashed_path.push_back({
							"command": PathCommand.MOVE_TO,
							"points": [current_point + (current_point.direction_to(reference_instruction.points[0]) * previous_reference_size_used)]
						})
					dashed_path.push_back({
						"command": PathCommand.LINE_TO,
						"points": [end_point]
					})
			PathCommand.QUADRATIC_BEZIER_CURVE:
				var sliced_quadratic = SVGMath.slice_quadratic_bezier(
					current_point,
					reference_instruction.points[0],
					reference_instruction.points[1],
					previous_reference_size_used / current_reference_size_total,
					current_reference_size_used / current_reference_size_total
				)
				if is_dash_render:
					if not was_dash_render:
						was_dash_render = true
						dashed_path.push_back({
							"command": PathCommand.MOVE_TO,
							"points": [sliced_quadratic[0]]
						})
					dashed_path.push_back({
						"command": PathCommand.QUADRATIC_BEZIER_CURVE,
						"points": SVGHelper.array_slice(sliced_quadratic, 1)
					})
			PathCommand.CUBIC_BEZIER_CURVE:
				var sliced_cubic = SVGMath.slice_cubic_bezier(
					current_point,
					reference_instruction.points[0],
					reference_instruction.points[1],
					reference_instruction.points[2],
					previous_reference_size_used / current_reference_size_total,
					current_reference_size_used / current_reference_size_total
				)
				if is_dash_render:
					if not was_dash_render:
						was_dash_render = true
						dashed_path.push_back({
							"command": PathCommand.MOVE_TO,
							"points": [sliced_cubic[0]]
						})
					dashed_path.push_back({
						"command": PathCommand.CUBIC_BEZIER_CURVE,
						"points": SVGHelper.array_slice(sliced_cubic, 1)
					})
		
		# Jump to next size in dash array when current size is exhausted
		if current_distance_traversed >= current_dash_size:
			if current_dash_size_index < dash_array.size() - 1:
				current_dash_size_index += 1
			else:
				current_dash_size_index = 0
			current_distance_traversed = 0.0
			current_dash_size = float(dash_array[current_dash_size_index])
			was_dash_render = is_dash_render
			is_dash_render = not is_dash_render
		
		# Jump to next reference shape when reached end of current one
		if current_reference_size_used >= current_reference_size_total:
			previous_reference_size_used = 0.0
			current_reference_size_used = 0.0
			current_reference_size_total = 0.0
			match reference_instruction.command:
				PathCommand.LINE_TO:
					current_point = reference_instruction.points[0]
				PathCommand.QUADRATIC_BEZIER_CURVE:
					current_point = reference_instruction.points[1]
				PathCommand.CUBIC_BEZIER_CURVE:
					current_point = reference_instruction.points[2]
			current_reference_index += 1
	
	if dashed_path.size() > 0:
		return dashed_path
	else:
		return path_reference
