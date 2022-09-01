class_name SVGMath

# Gives a position vector for 3 points and timestamp that form a quadratic beizer curve
# Excellent explanation here https://gamedev.stackexchange.com/questions/157642/moving-a-2d-object-along-circular-arc-between-two-points
static func quadratic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float):
	var q0 = p0.linear_interpolate(p1, t)
	var q1 = p1.linear_interpolate(p2, t)
	var r = q0.linear_interpolate(q1, t)
	return r

