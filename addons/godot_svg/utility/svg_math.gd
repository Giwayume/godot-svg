class_name SVGMath

# Gives a position vector for 3 points and timestamp that form a quadratic beizer curve
# p0 - start, p1 - control, p2 - end, t - timestamp from 0 to 1
# Excellent explanation here https://gamedev.stackexchange.com/questions/157642/moving-a-2d-object-along-circular-arc-between-two-points
static func quadratic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float):
	var q0 = p0.linear_interpolate(p1, t)
	var q1 = p1.linear_interpolate(p2, t)
	var r = q0.linear_interpolate(q1, t)
	return r

# Gives a position vector for 4 points and timestamp that form a cubic bezier curve
# p0 - start, p1 - start control, p2 - end control, p3 - end, t - timestamp from 0 to 1
# https://en.wikipedia.org/wiki/B%C3%A9zier_curve
static func cubic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float):
	var q0 = pow(1 - t, 3) * p0
	var q1 = 3 * pow(1 - t, 2) * t * p1
	var q2 = 3 * (1 - t) * pow(t, 2) * p2
	var q3 = pow(t, 3) * p3
	return q0 + q1 + q2 + q3

# Estimates the length of a cubic bezier curve
static func cubic_bezier_length(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2):
	return cubic_bezier_length_recurse(p0, p1, p2, p3)

static func cubic_bezier_length_recurse(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, subdiv: float = 5.0):
	var length = 0
	if subdiv > 0:
		var a = p0 + (p1 - p0) * 0.5
		var b = p1 + (p2 - p1) * 0.5
		var c = p2 + (p3 - p2) * 0.5
		var d = a + (b - a) * 0.5
		var e = b + (c - b) * 0.5
		var f = d + (e - d) * 0.5
		
		length += cubic_bezier_length_recurse(p0, a, d, f, subdiv - 1)
		length += cubic_bezier_length_recurse(f, e, c, p3, subdiv - 1)
	else:
		var control_net_length = (p1 - p0).length() + (p2 - p1).length() + (p3 - p2).length()
		var chord_length = (p3 - p0).length()
		length += (chord_length + control_net_length) / 2.0
	return length

static func is_point_right_of_segment(segment_start: Vector2, segment_end: Vector2, point: Vector2):
	var bx = segment_end.x - segment_start.x
	var by = segment_end.y - segment_start.y
	var px = point.x - segment_start.x
	var py = point.y - segment_start.y
	
	var cross_product = bx * py - by * px
	
	if cross_product > 0:
		return true
	
	return false

static func point_distance_along_segment(segment_start: Vector2, segment_end: Vector2, point: Vector2):
	var x_axis_angle = segment_start.angle_to_point(segment_end)
	var rotate_transform = Transform2D().rotated(x_axis_angle)
	segment_start = rotate_transform.xform(segment_start)
	segment_end = rotate_transform.xform(segment_end)
	point = rotate_transform.xform(point)
	return point.x - segment_start.x
