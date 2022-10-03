class_name SVGMath

# Gives a position vector for 3 points and timestamp that form a quadratic beizer curve
# p0 - start, p1 - control, p2 - end, t - timestamp from 0 to 1
# Excellent explanation here https://gamedev.stackexchange.com/questions/157642/moving-a-2d-object-along-circular-arc-between-two-points
static func quadratic_bezier_at(p0: Vector2, p1: Vector2, p2: Vector2, t: float):
	var q0 = p0.linear_interpolate(p1, t)
	var q1 = p1.linear_interpolate(p2, t)
	var r = q0.linear_interpolate(q1, t)
	return r

static func quadratic_bezier_length(p0: Vector2, p1: Vector2, p2: Vector2):
	var a = 0.0
	var b = 0.0
	var c = 0.0
	var u = 0.0
	
	var v0x = p1.x * 2.0
	var v0y = p1.y * 2.0
	var d = p0.x - v0x + p2.x
	var d1 = p0.y - v0y + p2.y
	var e = v0x - 2.0 * p0.x
	var e1 = v0y - 2.0 * p0.y
	a = 4.0 * (d * d + d1 * d1)
	var c1 = a
	b = 4.0 * (d * e + d1 * e1)
	c1 += b
	c = e * e + e1 * e1
	c1 += c
	c1 = 2.0 * sqrt(c1)
	u = sqrt(a)
	var a1 = 2 * a * u
	if a1 == 0.0:
		a1 = 0.0000001
	if u == 0.0:
		u = 0.0000001
	var u1 = b / u
	a = 4.0 * c * a - b * b
	c = 2.0 * sqrt(c)
	if u1 + c == 0.0:
		c += 0.0000001
	return (
		(a1 * c1 + u * b * (c1 - c) + a * log((2.0 * u + u1 + c1) / (u1 + c))) /
		(4.0 * a1)
	)

# Splits quadratic bezier curve into 2, returning the new positions and control points
static func split_quadratic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float):
	var x1 = p0.x
	var y1 = p0.y
	var x2 = p1.x
	var y2 = p1.y
	var x3 = p2.x
	var y3 = p2.y
	
	var x12 = (x2 - x1) * t + x1
	var y12 = (y2 - y1) * t + y1
	
	var x23 = (x3 - x2) * t + x2
	var y23 = (y3 - y2) * t + y2
	
	var x123 = (x23 - x12) * t + x12
	var y123 = (y23 - y12) * t + y12
	
	return [
		Vector2(x1, y1),
		Vector2(x12, y12),
		Vector2(x123, y123),
		Vector2(x23, y23),
		Vector2(x3, y3),
	]

# Gives a position vector for 4 points and timestamp that form a cubic bezier curve
# p0 - start, p1 - start control, p2 - end control, p3 - end, t - timestamp from 0 to 1
# https://en.wikipedia.org/wiki/B%C3%A9zier_curve
static func cubic_bezier_at(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float):
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

# Splits cubic bezier curve into 2, returning the new positions and control points
# https://stackoverflow.com/questions/8369488/splitting-a-bezier-curve
static func split_cubic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float):
	var x1 = p0.x
	var y1 = p0.y
	var x2 = p1.x
	var y2 = p1.y
	var x3 = p2.x
	var y3 = p2.y
	var x4 = p3.x
	var y4 = p3.y
	
	var x12 = (x2 - x1) * t + x1
	var y12 = (y2 - y1) * t + y1

	var x23 = (x3 - x2) * t + x2
	var y23 = (y3 - y2) * t + y2

	var x34 = (x4 - x3) * t + x3
	var y34 = (y4 - y3) * t + y3

	var x123 = (x23 - x12) * t + x12
	var y123 = (y23 - y12) * t + y12

	var x234 = (x34 - x23) * t + x23
	var y234 = (y34 - y23) * t + y23

	var x1234 = (x234 - x123) * t + x123
	var y1234 = (y234 - y123) * t + y123
	
	return [
		Vector2(x1, y1),
		Vector2(x12, y12),
		Vector2(x123, y123),
		Vector2(x1234, y1234),
		Vector2(x234, y234),
		Vector2(x34, y34),
		Vector2(x4, y4),
	]

# Find which side of a segment a point is on, left or right. Assuming straight is the direction from start to end.
static func is_point_right_of_segment(segment_start: Vector2, segment_end: Vector2, point: Vector2):
	var bx = segment_end.x - segment_start.x
	var by = segment_end.y - segment_start.y
	var px = point.x - segment_start.x
	var py = point.y - segment_start.y
	
	var cross_product = bx * py - by * px
	
	if cross_product > 0:
		return true
	
	return false

# If you have the coordinate of a point along a segment, finds the distance from the start of the segment to that point.
# If the point isn't on the segment:
# Projects a line perpendicular to the specified segment that intersects "point".
# The distance from the start of the segment to the intersection point of the segment & the perpendicular is returned.
static func point_distance_along_segment(segment_start: Vector2, segment_end: Vector2, point: Vector2):
	var x1 = segment_start.x
	var y1 = segment_start.y
	var x2 = segment_end.x
	var y2 = segment_end.y
	var x3 = point.x
	var y3 = point.y
	var px = x2 - x1
	var py = y2 - y1
	var dab = px * px + py * py
	var u = ((x3 - x1) * px + (y3 - y1) * py) / dab
	var x = x1 + u * px
	var y = y1 + u * py
	return segment_start.distance_to(Vector2(x, y))

static func triangle_intersects_triangle_cross(points, triangle):
	var pa = points[0]
	var pb = points[1]
	var pc = points[2]
	var p0 = triangle[0]
	var p1 = triangle[1]
	var p2 = triangle[2]
	var dxa = pa.x - p2.x
	var dya = pa.y - p2.y
	var dxb = pb.x - p2.x
	var dyb = pb.y - p2.y
	var dxc = pc.x - p2.x
	var dyc = pc.y - p2.y
	var dx21 = p2.x - p1.x
	var dy12 = p1.y - p2.y
	var d = dy12 * (p0.x - p2.x) + dx21 * (p0.y - p2.y)
	var sa = dy12 * dxa + dx21 + dya
	var sb = dy12 * dxb + dx21 * dyb
	var sc = dy12 * dxc + dx21 * dyc
	var ta = (p2.y - p0.y) * dxa + (p0.x - p2.x) * dya
	var tb = (p2.y - p0.y) * dxb + (p0.x - p2.x) * dyb
	var tc = (p2.y - p0.y) * dxc + (p0.x - p2.x) * dyc
	if d < 0.0:
		return (
			(sa >= 0 and sb >= 0 and sc >= 0) or
			(ta >=0 and tb >= 0 and tc >= 0) or
			(sa + ta <= d and sb + tb <= d and sc + tc <= d)
		)
	return (
		(sa <= 0 and sb <= 0 and sc <= 0) or
		(ta <= 0 and tb <= 0 and tc <= 0) or
		(sa + ta >= d and sb + tb >= d and sc + tc >= d)
	)

static func triangle_intersects_triangle(t0, t1):
	return not (triangle_intersects_triangle_cross(t0, t1) or triangle_intersects_triangle_cross(t1, t0))

static func triangle_area(t):
	var side1 = t[0].distance_to(t[1])
	var side2 = t[1].distance_to(t[2])
	var side3 = t[0].distance_to(t[2])
	var s = (side1 + side2 + side3) / 2.0
	return sqrt(s * ((s - side1) * (s - side2) * (s - side3)))
