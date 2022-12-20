class_name SVGPolygonSolver

enum FillRule {
	EVEN_ODD,
	NON_ZERO,
	POSITIVE,
	NEGATIVE
}

static func is_polygon_subset_of_polygon(find, in_polygon):
	var match_index = 0
	var find_size = find.size()
	var is_subset = false
	if find_size < in_polygon.size(): # if array is same size, could be same points in different order. Don't care.
		for value in in_polygon:
			if find[match_index].is_equal_approx(value):
				match_index += 1
			else:
				match_index = 0
			if match_index >= find_size:
				is_subset = true
				break
	return is_subset

static func get_polygon_bounds(polygon: PoolVector2Array):
	var left = INF
	var right = -INF
	var top = INF
	var bottom = -INF
	for point in polygon:
		if point.x < left:
			left = point.x
		if point.x > right:
			right = point.x
		if point.y < top:
			top = point.y
		if point.y > bottom:
			bottom = point.y
	return Rect2(left, top, right - left, bottom - top)

static func simplify(input_points, fill_rule = FillRule.EVEN_ODD):
	input_points = Array(input_points)
	if not input_points[input_points.size() - 1].is_equal_approx(input_points[0]):
		input_points.push_back(input_points[0])
	
	var intersections = []
	var intersections_at_positions = {}
	var solved_polygons = []
	
	# Loop through the line segments and build a list of intersection points
	for i in range(0, input_points.size() - 1):
		var segment_start = input_points[i]
		var segment_end = input_points[i + 1]
		if i > 1:
			for j in range(0, i - 1):
				var prev_segment_start = input_points[j]
				var prev_segment_end = input_points[j + 1]
				var intersection_point = Geometry.segment_intersects_segment_2d(
					segment_start,
					segment_end,
					prev_segment_start,
					prev_segment_end
				)
				if intersection_point != null:
					var is_existing_intersection = false
					for existing_intersection in intersections:
						if existing_intersection.point.is_equal_approx(intersection_point):
							existing_intersection.line_positions.push_back(j)
							if not intersections_at_positions.has(j):
								intersections_at_positions[j] = []
							if not intersections_at_positions[j].has(existing_intersection):
								intersections_at_positions[j].push_back(existing_intersection)
					if not is_existing_intersection:
						var intersection = {
							"point": intersection_point,
							"line_positions": [i, j],
							"solved": {},
						}
						intersections.push_back(intersection)
						if not intersections_at_positions.has(i):
							intersections_at_positions[i] = []
						if not intersections_at_positions.has(j):
							intersections_at_positions[j] = []
						intersections_at_positions[i].push_back(intersection)
						intersections_at_positions[j].push_back(intersection)
	
	# For each intersection point, follow the intersection lines forward, then take right turns until it comes back to the initial point
	for intersection in intersections:
		for line_start_position in intersection.line_positions:
			var last_passed_intersection = intersection
			var last_passed_intersection_start_position = line_start_position
			var has_looped_from_beginning = false
			var traverse_direction = 1
			var current_position = line_start_position
			var new_polygon = [intersection.point]
			var next_point = input_points[0] if line_start_position == input_points.size() - 1 else input_points[line_start_position + 1]
			var infinite_loop_iterator = 0
			var existing_solutions = []
			while infinite_loop_iterator < 1000000:
				infinite_loop_iterator += 1
				var next_intersection = null
				
				# Find the next intersection at the current path segment, if applicable
				if intersections_at_positions.has(current_position):
					var current_input_point = input_points[current_position]
					var current_intersection_point = last_passed_intersection.point if last_passed_intersection_start_position == current_position else current_input_point
					var current_segment_direction = (
						input_points[current_position] if current_position > 1 else input_points[input_points.size() - 1]
					).direction_to(
						input_points[current_position + 1] if current_position < input_points.size() - 1 else input_points[0]
					)
					var winning_distance = INF
					for other_intersection in intersections_at_positions[current_position]:
						if current_intersection_point.is_equal_approx(other_intersection.point):
							continue
						var intersection_to_intersection_direction = current_intersection_point.direction_to(other_intersection.point)
						var travel_angle = current_segment_direction.angle_to(intersection_to_intersection_direction)
						if (
							((travel_angle > -PI / 2 and travel_angle < PI / 2) and traverse_direction > 0) or
							((travel_angle < -PI / 2 or travel_angle > PI / 2) and traverse_direction < 0)
						):
							var intersection_distance = current_intersection_point.distance_to(other_intersection.point)
							if intersection_distance < winning_distance:
								winning_distance = intersection_distance
								next_intersection = other_intersection
				
				# If next intersection is our starting intersection, we're done
				if next_intersection == intersection:
					break
				
				# Find which path at the intersection is the closest right turn, and take it
				elif next_intersection:
					if not new_polygon.back().is_equal_approx(next_intersection.point):
						new_polygon.push_back(next_intersection.point)
					var entry_segment_start = input_points[current_position]
					var entry_segment_end = input_points[current_position + 1] if current_position < input_points.size() - 1 else input_points[0]
					var entry_direction = traverse_direction * entry_segment_start.direction_to(entry_segment_end)
					var closest_angle = INF
					var winning_position = -1
					for check_line_position in next_intersection.line_positions:
						var check_segment_start = input_points[check_line_position]
						var check_segment_end = input_points[check_line_position + 1] if check_line_position < input_points.size() - 1 else input_points[0]
						var check_direction = check_segment_start.direction_to(check_segment_end)
						var positive_angle = check_direction.angle_to(-entry_direction)
						var negative_angle = -check_direction.angle_to(-entry_direction)
						if positive_angle > 0 and positive_angle < closest_angle:
							closest_angle = positive_angle
							winning_position = check_line_position
							traverse_direction = 1
						elif negative_angle > 0 and negative_angle < closest_angle:
							closest_angle = negative_angle
							winning_position = check_line_position
							traverse_direction = -1
					if winning_position > -1:
						current_position = winning_position
						has_looped_from_beginning = false
						last_passed_intersection = next_intersection
						last_passed_intersection_start_position = winning_position
						if traverse_direction > 0 and last_passed_intersection.solved.has(last_passed_intersection_start_position):
							existing_solutions.push_back({
								"intersection": last_passed_intersection,
								"line_position": last_passed_intersection_start_position,
							})
					else:
						print("[godot-svg] Error solving simple shape: no valid direction found")
						break
				# No intersection found, keep looping through current path segments
				else:
					next_point = input_points[current_position + 1] if current_position < input_points.size() - 1 else input_points[0]
					if not new_polygon.back().is_equal_approx(next_point):
						new_polygon.push_back(next_point)
					current_position += traverse_direction
					if current_position >= input_points.size():
						current_position = 0
						has_looped_from_beginning = true
					elif current_position < 0:
						current_position = input_points.size() - 1
						has_looped_from_beginning = true
			if existing_solutions.size() > 0:
				var trumps_all_existing_solutions = true
				for existing_solution in existing_solutions:
					if not is_polygon_subset_of_polygon(
						existing_solution.intersection.solved[existing_solution.line_position],
						new_polygon
					):
						trumps_all_existing_solutions = false
						break
				if trumps_all_existing_solutions:
					for existing_solution in existing_solutions:
						existing_solution.intersection.solved.erase(existing_solution.line_position)
					intersection.solved[line_start_position] = new_polygon
			else:
				intersection.solved[line_start_position] = new_polygon

	for intersection in intersections:
		for solved_number in intersection.solved:
			solved_polygons.push_back(intersection.solved[solved_number])
	
	# Apply fill rule
	var filled_polygons = []
	for solved_polygon in solved_polygons:
		if solved_polygon.size() > 2:
			var is_clockwise = Geometry.is_polygon_clockwise(solved_polygon)
			var check_point = (
				solved_polygon[0] +
				(solved_polygon[0].direction_to(solved_polygon[1]).rotated(-PI / 128 if is_clockwise else PI / 128)) *
				(solved_polygon[1] - solved_polygon[0]).length() / 128
			)
			var insideness = 0
			for point_index in range(0, input_points.size()):
				var segment_start = input_points[point_index]
				var segment_end = input_points[point_index + 1] if point_index < input_points.size() - 1 else input_points[0]
				if segment_start.is_equal_approx(segment_end):
					continue
				if (
					(segment_start.y <= check_point.y and segment_end.y <= check_point.y) or
					(
						(check_point.y <= segment_start.y or check_point.y <= segment_end.y) and
						Geometry.segment_intersects_segment_2d(segment_start, segment_end, check_point, check_point - Vector2(0.0, 99999999.0))
					)
				):
					if segment_start.x <= check_point.x and segment_end.x > check_point.x:
						insideness += 1
					elif segment_start.x >= check_point.x and segment_end.x < check_point.x:
						insideness -= 1
			
			var is_filled = false
			match fill_rule:
				FillRule.EVEN_ODD:
					if int(abs(insideness)) % 2 == 1:
						is_filled = true
				FillRule.NON_ZERO:
					if insideness != 0:
						is_filled = true
			
			if is_filled:
				filled_polygons.push_back(solved_polygon)
	
	return filled_polygons
