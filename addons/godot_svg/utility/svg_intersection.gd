class_name SVGIntersection

# SVG path segment intersection utilities.

# These functions have been adapted from:
# http://www.kevlindev.com/gui/math/intersection/Intersection.js
# License: BSD 3 Clause
# Copyright (c) 2000-2004, Kevin Lindsey
# All rights reserved.

const LN10 = 2.302585092994046
const LN2 = 0.6931471805599453

class Polynomial:
	static var TOLERANCE = 1e-6
	static var ACCURACY = 6.0
	
	var coefficients: Array
	
	var _s: float = 0.0
	
	func _init(new_coefficients):
		coefficients = []
		coefficients.resize(len(new_coefficients))
		for i in range(0, len(new_coefficients)):
			coefficients[i] = new_coefficients[len(new_coefficients) - 1 - i]
	
	func get_degree() -> int:
		return len(coefficients) - 1
	
	func eval(x: float):
		var result: float = 0.0
		for i in range(len(coefficients) - 1, -1, -1):
			result = result * x + coefficients[i]
		return result
	
	func bisection(min: float, max: float):
		var min_value: float = eval(min)
		var max_value: float = eval(max)
		var result = null
		if abs(min_value) <= Polynomial.TOLERANCE: result = min
		elif abs(max_value) <= Polynomial.TOLERANCE: result = max
		elif min_value * max_value <= 0:
			var tmp1: float = log(max - min)
			var tmp2: float = LN10 * Polynomial.ACCURACY
			var iters: float = ceil((tmp1 + tmp2) / LN2)
			for i in range(0, iters):
				result = 0.5 * (min + max)
				var value: float = eval(result)
				if abs(value) <= Polynomial.TOLERANCE:
					break
				if value * min_value < 0.0:
					max = result
					max_value = value
				else:
					min = result
					min_value = value
		return result
	
	func get_derivative():
		var derivative = Polynomial.new([])
		for i in range(1, len(coefficients)):
			derivative.coefficients.push_back(i * coefficients[i])
		return derivative
	
	func get_roots_in_interval(min: float, max: float) -> PackedFloat32Array:
		var roots: PackedFloat32Array = []
		var root = null
		if get_degree() == 1:
			root = bisection(min, max)
			if root != null: roots.push_back(root)
		else:
			var deriv = get_derivative()
			var droots: PackedFloat32Array = deriv.get_roots_in_interval(min, max)
			if len(droots) > 0:
				root = bisection(min, droots[0])
				if root != null: roots.push_back(root)
				for i in range(0, len(droots) - 3):
					root = bisection(droots[i], droots[i + 1])
					if root != null: roots.push_back(root)
				root = bisection(droots[len(droots) - 1], max)
				if root != null: roots.push_back(root)
			else:
				root = bisection(min, max)
				if root != null: roots.push_back(root)
		return roots
	
	func simplify():
		for i in range(get_degree(), -1, -1):
			if abs(coefficients[i]) <= Polynomial.TOLERANCE:
				coefficients.pop_back()
			else:
				break
	
	func get_linear_root() -> PackedFloat32Array:
		var result: PackedFloat32Array = PackedFloat32Array()
		var a = coefficients[1]
		if not is_zero_approx(a): result.push_back(-coefficients[0] / a)
		return result
	
	func get_quadratic_roots() -> PackedFloat32Array:
		var results: PackedFloat32Array = PackedFloat32Array()
		if get_degree() == 2:
			var a: float = coefficients[2]
			if is_zero_approx(a):
				return results
			var b: float = coefficients[1] / a
			var c: float = coefficients[0] / a
			var d: float = b * b - 4 * c
			if is_zero_approx(d):
				results.push_back(0.5 * -b)
			elif d > 0.0:
				var e = sqrt(d)
				results.push_back(0.5 * (-b + e))
				results.push_back(0.5 * (-b - e))
		return results
	
	func get_cubic_roots() -> PackedFloat32Array:
		var results: PackedFloat32Array = PackedFloat32Array()
		if get_degree() == 3:
			var c3: float = coefficients[3]
			if is_zero_approx(c3):
				return results
			var c2: float = coefficients[2] / c3
			var c1: float = coefficients[1] / c3
			var c0: float = coefficients[0] / c3
			var a: float = (3.0 * c1 - c2 * c2) / 3.0
			var b: float = (2.0 * c2 * c2 * c2 - 9.0 * c1 * c2 + 27.0 * c0) / 27.0
			var offset: float = c2 / 3
			var discrim: float = b * b / 4.0 + a * a * a / 27.0
			var half_b: float = b / 2.0
			if abs(discrim) <= Polynomial.TOLERANCE: discrim = 0.0
			if discrim > 0.0:
				var e: float = sqrt(discrim)
				var tmp: float
				var root: float
				tmp = -half_b + e
				if tmp >= 0.0: root = pow(tmp, 1.0 / 3.0)
				else: root = -pow(-tmp, 1.0 / 3.0)
				tmp = -half_b - e
				if tmp >= 0.0: root += pow(tmp, 1.0 / 3.0)
				else: root -= pow(-tmp, 1.0 / 3.0)
				results.push_back(root - offset)
			elif discrim < 0.0:
				var distance: float = sqrt(-a / 3.0)
				var angle: float = atan2(sqrt(-discrim), -half_b) / 3.0
				var cos: float = cos(angle)
				var sin: float = sin(angle)
				var sqrt3: float = sqrt(3.0)
				results.push_back(2.0 * distance * cos - offset)
				results.push_back(-distance * (cos + sqrt3 * sin) - offset)
				results.push_back(-distance * (cos - sqrt3 * sin) - offset)
			else:
				var tmp: float
				if half_b >= 0: tmp = -pow(half_b, 1.0 / 3.0)
				else: tmp = pow(-half_b, 1.0 / 3.0)
				results.push_back(2.0 * tmp - offset)
				results.push_back(-tmp - offset)
		return results
	
	func get_roots():
		var result: PackedFloat32Array
		simplify()
		match get_degree():
			0: result = PackedFloat32Array()
			1: result = get_linear_root()
			2: result = get_quadratic_roots()
			3: result = get_cubic_roots()
			_: result = PackedFloat32Array()
		return result

static func intersect_cubic_bezier_with_cubic_bezier(
	a1: Vector2, a2: Vector2, a3: Vector2, a4: Vector2,
	b1: Vector2, b2: Vector2, b3: Vector2, b4: Vector2
):
	var a: Vector2
	var b: Vector2
	var c: Vector2
	var d: Vector2
	var c13: Vector2
	var c12: Vector2
	var c11: Vector2
	var c10: Vector2
	var c23: Vector2
	var c22: Vector2
	var c21: Vector2
	var c20: Vector2
	var result = []

	a = a1 * -1.0
	b = a2 * 3.0
	c = a3 * -3.0
	d = a + b + c + a4
	c13 = Vector2(d.x, d.y)

	a = a1 * 3.0
	b = a2 * -6.0
	c = a3 * 3.0
	d = a + b + c
	c12 = Vector2(d.x, d.y)

	a = a1 * -3.0
	b = a2 * 3.0
	c = a + b
	c11 = Vector2(c.x, c.y)
	c10 = Vector2(a1.x, a1.y)

	a = b1 * -1.0
	b = b2 * 3.0
	c = b3 * -3.0
	d = a + b + c + b4
	c23 = Vector2(d.x, d.y)

	a = b1 * 3.0
	b = b2 * -6.0
	c = b3 * 3.0
	d = a + b + c
	c22 = Vector2(d.x, d.y)

	a = b1 * -3.0
	b = b2 * 3.0
	c = a + b
	c21 = Vector2(c.x, c.y)
	c20 = Vector2(b1.x, b1.y)

	var c10x2: float = c10.x * c10.x
	var c10x3: float = c10.x * c10.x * c10.x
	var c10y2: float = c10.y * c10.y
	var c10y3: float = c10.y * c10.y * c10.y
	var c11x2: float = c11.x * c11.x
	var c11x3: float = c11.x * c11.x * c11.x
	var c11y2: float = c11.y * c11.y
	var c11y3: float = c11.y * c11.y * c11.y
	var c12x2: float = c12.x * c12.x
	var c12x3: float = c12.x * c12.x * c12.x
	var c12y2: float = c12.y * c12.y
	var c12y3: float = c12.y * c12.y * c12.y
	var c13x2: float = c13.x * c13.x
	var c13x3: float = c13.x * c13.x * c13.x
	var c13y2: float = c13.y * c13.y
	var c13y3: float = c13.y * c13.y * c13.y
	var c20x2: float = c20.x * c20.x
	var c20x3: float = c20.x * c20.x * c20.x
	var c20y2: float = c20.y * c20.y
	var c20y3: float = c20.y * c20.y * c20.y
	var c21x2: float = c21.x * c21.x
	var c21x3: float = c21.x * c21.x * c21.x
	var c21y2: float = c21.y * c21.y
	var c22x2: float = c22.x * c22.x
	var c22x3: float = c22.x * c22.x * c22.x
	var c22y2: float = c22.y * c22.y
	var c23x2: float = c23.x * c23.x
	var c23x3: float = c23.x * c23.x * c23.x
	var c23y2: float = c23.y * c23.y
	var c23y3: float = c23.y * c23.y * c23.y
	var poly = Polynomial.new([
		-c13x3 * c23y3 + c13y3 * c23x3 - 3 * c13.x * c13y2 * c23x2 * c23.y +
			3 * c13x2 * c13.y * c23.x * c23y2,
		-6 * c13.x * c22.x * c13y2 * c23.x * c23.y + 6 * c13x2 * c13.y * c22.y * c23.x * c23.y + 3 * c22.x * c13y3 * c23x2 -
			3 * c13x3 * c22.y * c23y2 - 3 * c13.x * c13y2 * c22.y * c23x2 + 3 * c13x2 * c22.x * c13.y * c23y2,
		-6 * c21.x * c13.x * c13y2 * c23.x * c23.y - 6 * c13.x * c22.x * c13y2 * c22.y * c23.x + 6 * c13x2 * c22.x * c13.y * c22.y * c23.y +
			3 * c21.x * c13y3 * c23x2 + 3 * c22x2 * c13y3 * c23.x + 3 * c21.x * c13x2 * c13.y * c23y2 - 3 * c13.x * c21.y * c13y2 * c23x2 -
			3 * c13.x * c22x2 * c13y2 * c23.y + c13x2 * c13.y * c23.x * (6 * c21.y * c23.y + 3 * c22y2) + c13x3 * (-c21.y * c23y2 -
			2 * c22y2 * c23.y - c23.y * (2 * c21.y * c23.y + c22y2)),
		c11.x * c12.y * c13.x * c13.y * c23.x * c23.y - c11.y * c12.x * c13.x * c13.y * c23.x * c23.y + 6 * c21.x * c22.x * c13y3 * c23.x +
			3 * c11.x * c12.x * c13.x * c13.y * c23y2 + 6 * c10.x * c13.x * c13y2 * c23.x * c23.y - 3 * c11.x * c12.x * c13y2 * c23.x * c23.y -
			3 * c11.y * c12.y * c13.x * c13.y * c23x2 - 6 * c10.y * c13x2 * c13.y * c23.x * c23.y - 6 * c20.x * c13.x * c13y2 * c23.x * c23.y +
			3 * c11.y * c12.y * c13x2 * c23.x * c23.y - 2 * c12.x * c12y2 * c13.x * c23.x * c23.y - 6 * c21.x * c13.x * c22.x * c13y2 * c23.y -
			6 * c21.x * c13.x * c13y2 * c22.y * c23.x - 6 * c13.x * c21.y * c22.x * c13y2 * c23.x + 6 * c21.x * c13x2 * c13.y * c22.y * c23.y +
			2 * c12x2 * c12.y * c13.y * c23.x * c23.y + c22x3 * c13y3 - 3 * c10.x * c13y3 * c23x2 + 3 * c10.y * c13x3 * c23y2 +
			3 * c20.x * c13y3 * c23x2 + c12y3 * c13.x * c23x2 - c12x3 * c13.y * c23y2 - 3 * c10.x * c13x2 * c13.y * c23y2 +
			3 * c10.y * c13.x * c13y2 * c23x2 - 2 * c11.x * c12.y * c13x2 * c23y2 + c11.x * c12.y * c13y2 * c23x2 - c11.y * c12.x * c13x2 * c23y2 +
			2 * c11.y * c12.x * c13y2 * c23x2 + 3 * c20.x * c13x2 * c13.y * c23y2 - c12.x * c12y2 * c13.y * c23x2 -
			3 * c20.y * c13.x * c13y2 * c23x2 + c12x2 * c12.y * c13.x * c23y2 - 3 * c13.x * c22x2 * c13y2 * c22.y +
			c13x2 * c13.y * c23.x * (6 * c20.y * c23.y + 6 * c21.y * c22.y) + c13x2 * c22.x * c13.y * (6 * c21.y * c23.y + 3 * c22y2) +
			c13x3 * (-2 * c21.y * c22.y * c23.y - c20.y * c23y2 - c22.y * (2 * c21.y * c23.y + c22y2) - c23.y * (2 * c20.y * c23.y + 2 * c21.y * c22.y)),
		6 * c11.x * c12.x * c13.x * c13.y * c22.y * c23.y + c11.x * c12.y * c13.x * c22.x * c13.y * c23.y + c11.x * c12.y * c13.x * c13.y * c22.y * c23.x -
			c11.y * c12.x * c13.x * c22.x * c13.y * c23.y - c11.y * c12.x * c13.x * c13.y * c22.y * c23.x - 6 * c11.y * c12.y * c13.x * c22.x * c13.y * c23.x -
			6 * c10.x * c22.x * c13y3 * c23.x + 6 * c20.x * c22.x * c13y3 * c23.x + 6 * c10.y * c13x3 * c22.y * c23.y + 2 * c12y3 * c13.x * c22.x * c23.x -
			2 * c12x3 * c13.y * c22.y * c23.y + 6 * c10.x * c13.x * c22.x * c13y2 * c23.y + 6 * c10.x * c13.x * c13y2 * c22.y * c23.x +
			6 * c10.y * c13.x * c22.x * c13y2 * c23.x - 3 * c11.x * c12.x * c22.x * c13y2 * c23.y - 3 * c11.x * c12.x * c13y2 * c22.y * c23.x +
			2 * c11.x * c12.y * c22.x * c13y2 * c23.x + 4 * c11.y * c12.x * c22.x * c13y2 * c23.x - 6 * c10.x * c13x2 * c13.y * c22.y * c23.y -
			6 * c10.y * c13x2 * c22.x * c13.y * c23.y - 6 * c10.y * c13x2 * c13.y * c22.y * c23.x - 4 * c11.x * c12.y * c13x2 * c22.y * c23.y -
			6 * c20.x * c13.x * c22.x * c13y2 * c23.y - 6 * c20.x * c13.x * c13y2 * c22.y * c23.x - 2 * c11.y * c12.x * c13x2 * c22.y * c23.y +
			3 * c11.y * c12.y * c13x2 * c22.x * c23.y + 3 * c11.y * c12.y * c13x2 * c22.y * c23.x - 2 * c12.x * c12y2 * c13.x * c22.x * c23.y -
			2 * c12.x * c12y2 * c13.x * c22.y * c23.x - 2 * c12.x * c12y2 * c22.x * c13.y * c23.x - 6 * c20.y * c13.x * c22.x * c13y2 * c23.x -
			6 * c21.x * c13.x * c21.y * c13y2 * c23.x - 6 * c21.x * c13.x * c22.x * c13y2 * c22.y + 6 * c20.x * c13x2 * c13.y * c22.y * c23.y +
			2 * c12x2 * c12.y * c13.x * c22.y * c23.y + 2 * c12x2 * c12.y * c22.x * c13.y * c23.y + 2 * c12x2 * c12.y * c13.y * c22.y * c23.x +
			3 * c21.x * c22x2 * c13y3 + 3 * c21x2 * c13y3 * c23.x - 3 * c13.x * c21.y * c22x2 * c13y2 - 3 * c21x2 * c13.x * c13y2 * c23.y +
			c13x2 * c22.x * c13.y * (6 * c20.y * c23.y + 6 * c21.y * c22.y) + c13x2 * c13.y * c23.x * (6 * c20.y * c22.y + 3 * c21y2) +
			c21.x * c13x2 * c13.y * (6 * c21.y * c23.y + 3 * c22y2) + c13x3 * (-2 * c20.y * c22.y * c23.y - c23.y * (2 * c20.y * c22.y + c21y2) -
			c21.y * (2 * c21.y * c23.y + c22y2) - c22.y * (2 * c20.y * c23.y + 2 * c21.y * c22.y)),
		c11.x * c21.x * c12.y * c13.x * c13.y * c23.y + c11.x * c12.y * c13.x * c21.y * c13.y * c23.x + c11.x * c12.y * c13.x * c22.x * c13.y * c22.y -
			c11.y * c12.x * c21.x * c13.x * c13.y * c23.y - c11.y * c12.x * c13.x * c21.y * c13.y * c23.x - c11.y * c12.x * c13.x * c22.x * c13.y * c22.y -
			6 * c11.y * c21.x * c12.y * c13.x * c13.y * c23.x - 6 * c10.x * c21.x * c13y3 * c23.x + 6 * c20.x * c21.x * c13y3 * c23.x +
			2 * c21.x * c12y3 * c13.x * c23.x + 6 * c10.x * c21.x * c13.x * c13y2 * c23.y + 6 * c10.x * c13.x * c21.y * c13y2 * c23.x +
			6 * c10.x * c13.x * c22.x * c13y2 * c22.y + 6 * c10.y * c21.x * c13.x * c13y2 * c23.x - 3 * c11.x * c12.x * c21.x * c13y2 * c23.y -
			3 * c11.x * c12.x * c21.y * c13y2 * c23.x - 3 * c11.x * c12.x * c22.x * c13y2 * c22.y + 2 * c11.x * c21.x * c12.y * c13y2 * c23.x +
			4 * c11.y * c12.x * c21.x * c13y2 * c23.x - 6 * c10.y * c21.x * c13x2 * c13.y * c23.y - 6 * c10.y * c13x2 * c21.y * c13.y * c23.x -
			6 * c10.y * c13x2 * c22.x * c13.y * c22.y - 6 * c20.x * c21.x * c13.x * c13y2 * c23.y - 6 * c20.x * c13.x * c21.y * c13y2 * c23.x -
			6 * c20.x * c13.x * c22.x * c13y2 * c22.y + 3 * c11.y * c21.x * c12.y * c13x2 * c23.y - 3 * c11.y * c12.y * c13.x * c22x2 * c13.y +
			3 * c11.y * c12.y * c13x2 * c21.y * c23.x + 3 * c11.y * c12.y * c13x2 * c22.x * c22.y - 2 * c12.x * c21.x * c12y2 * c13.x * c23.y -
			2 * c12.x * c21.x * c12y2 * c13.y * c23.x - 2 * c12.x * c12y2 * c13.x * c21.y * c23.x - 2 * c12.x * c12y2 * c13.x * c22.x * c22.y -
			6 * c20.y * c21.x * c13.x * c13y2 * c23.x - 6 * c21.x * c13.x * c21.y * c22.x * c13y2 + 6 * c20.y * c13x2 * c21.y * c13.y * c23.x +
			2 * c12x2 * c21.x * c12.y * c13.y * c23.y + 2 * c12x2 * c12.y * c21.y * c13.y * c23.x + 2 * c12x2 * c12.y * c22.x * c13.y * c22.y -
			3 * c10.x * c22x2 * c13y3 + 3 * c20.x * c22x2 * c13y3 + 3 * c21x2 * c22.x * c13y3 + c12y3 * c13.x * c22x2 +
			3 * c10.y * c13.x * c22x2 * c13y2 + c11.x * c12.y * c22x2 * c13y2 + 2 * c11.y * c12.x * c22x2 * c13y2 -
			c12.x * c12y2 * c22x2 * c13.y - 3 * c20.y * c13.x * c22x2 * c13y2 - 3 * c21x2 * c13.x * c13y2 * c22.y +
			c12x2 * c12.y * c13.x * (2 * c21.y * c23.y + c22y2) + c11.x * c12.x * c13.x * c13.y * (6 * c21.y * c23.y + 3 * c22y2) +
			c21.x * c13x2 * c13.y * (6 * c20.y * c23.y + 6 * c21.y * c22.y) + c12x3 * c13.y * (-2 * c21.y * c23.y - c22y2) +
			c10.y * c13x3 * (6 * c21.y * c23.y + 3 * c22y2) + c11.y * c12.x * c13x2 * (-2 * c21.y * c23.y - c22y2) +
			c11.x * c12.y * c13x2 * (-4 * c21.y * c23.y - 2 * c22y2) + c10.x * c13x2 * c13.y * (-6 * c21.y * c23.y - 3 * c22y2) +
			c13x2 * c22.x * c13.y * (6 * c20.y * c22.y + 3 * c21y2) + c20.x * c13x2 * c13.y * (6 * c21.y * c23.y + 3 * c22y2) +
			c13x3 * (-2 * c20.y * c21.y * c23.y - c22.y * (2 * c20.y * c22.y + c21y2) - c20.y * (2 * c21.y * c23.y + c22y2) -
			c21.y * (2 * c20.y * c23.y + 2 * c21.y * c22.y)),
		-c10.x * c11.x * c12.y * c13.x * c13.y * c23.y + c10.x * c11.y * c12.x * c13.x * c13.y * c23.y + 6 * c10.x * c11.y * c12.y * c13.x * c13.y * c23.x -
			6 * c10.y * c11.x * c12.x * c13.x * c13.y * c23.y - c10.y * c11.x * c12.y * c13.x * c13.y * c23.x + c10.y * c11.y * c12.x * c13.x * c13.y * c23.x +
			c11.x * c11.y * c12.x * c12.y * c13.x * c23.y - c11.x * c11.y * c12.x * c12.y * c13.y * c23.x + c11.x * c20.x * c12.y * c13.x * c13.y * c23.y +
			c11.x * c20.y * c12.y * c13.x * c13.y * c23.x + c11.x * c21.x * c12.y * c13.x * c13.y * c22.y + c11.x * c12.y * c13.x * c21.y * c22.x * c13.y -
			c20.x * c11.y * c12.x * c13.x * c13.y * c23.y - 6 * c20.x * c11.y * c12.y * c13.x * c13.y * c23.x - c11.y * c12.x * c20.y * c13.x * c13.y * c23.x -
			c11.y * c12.x * c21.x * c13.x * c13.y * c22.y - c11.y * c12.x * c13.x * c21.y * c22.x * c13.y - 6 * c11.y * c21.x * c12.y * c13.x * c22.x * c13.y -
			6 * c10.x * c20.x * c13y3 * c23.x - 6 * c10.x * c21.x * c22.x * c13y3 - 2 * c10.x * c12y3 * c13.x * c23.x + 6 * c20.x * c21.x * c22.x * c13y3 +
			2 * c20.x * c12y3 * c13.x * c23.x + 2 * c21.x * c12y3 * c13.x * c22.x + 2 * c10.y * c12x3 * c13.y * c23.y - 6 * c10.x * c10.y * c13.x * c13y2 * c23.x +
			3 * c10.x * c11.x * c12.x * c13y2 * c23.y - 2 * c10.x * c11.x * c12.y * c13y2 * c23.x - 4 * c10.x * c11.y * c12.x * c13y2 * c23.x +
			3 * c10.y * c11.x * c12.x * c13y2 * c23.x + 6 * c10.x * c10.y * c13x2 * c13.y * c23.y + 6 * c10.x * c20.x * c13.x * c13y2 * c23.y -
			3 * c10.x * c11.y * c12.y * c13x2 * c23.y + 2 * c10.x * c12.x * c12y2 * c13.x * c23.y + 2 * c10.x * c12.x * c12y2 * c13.y * c23.x +
			6 * c10.x * c20.y * c13.x * c13y2 * c23.x + 6 * c10.x * c21.x * c13.x * c13y2 * c22.y + 6 * c10.x * c13.x * c21.y * c22.x * c13y2 +
			4 * c10.y * c11.x * c12.y * c13x2 * c23.y + 6 * c10.y * c20.x * c13.x * c13y2 * c23.x + 2 * c10.y * c11.y * c12.x * c13x2 * c23.y -
			3 * c10.y * c11.y * c12.y * c13x2 * c23.x + 2 * c10.y * c12.x * c12y2 * c13.x * c23.x + 6 * c10.y * c21.x * c13.x * c22.x * c13y2 -
			3 * c11.x * c20.x * c12.x * c13y2 * c23.y + 2 * c11.x * c20.x * c12.y * c13y2 * c23.x + c11.x * c11.y * c12y2 * c13.x * c23.x -
			3 * c11.x * c12.x * c20.y * c13y2 * c23.x - 3 * c11.x * c12.x * c21.x * c13y2 * c22.y - 3 * c11.x * c12.x * c21.y * c22.x * c13y2 +
			2 * c11.x * c21.x * c12.y * c22.x * c13y2 + 4 * c20.x * c11.y * c12.x * c13y2 * c23.x + 4 * c11.y * c12.x * c21.x * c22.x * c13y2 -
			2 * c10.x * c12x2 * c12.y * c13.y * c23.y - 6 * c10.y * c20.x * c13x2 * c13.y * c23.y - 6 * c10.y * c20.y * c13x2 * c13.y * c23.x -
			6 * c10.y * c21.x * c13x2 * c13.y * c22.y - 2 * c10.y * c12x2 * c12.y * c13.x * c23.y - 2 * c10.y * c12x2 * c12.y * c13.y * c23.x -
			6 * c10.y * c13x2 * c21.y * c22.x * c13.y - c11.x * c11.y * c12x2 * c13.y * c23.y - 2 * c11.x * c11y2 * c13.x * c13.y * c23.x +
			3 * c20.x * c11.y * c12.y * c13x2 * c23.y - 2 * c20.x * c12.x * c12y2 * c13.x * c23.y - 2 * c20.x * c12.x * c12y2 * c13.y * c23.x -
			6 * c20.x * c20.y * c13.x * c13y2 * c23.x - 6 * c20.x * c21.x * c13.x * c13y2 * c22.y - 6 * c20.x * c13.x * c21.y * c22.x * c13y2 +
			3 * c11.y * c20.y * c12.y * c13x2 * c23.x + 3 * c11.y * c21.x * c12.y * c13x2 * c22.y + 3 * c11.y * c12.y * c13x2 * c21.y * c22.x -
			2 * c12.x * c20.y * c12y2 * c13.x * c23.x - 2 * c12.x * c21.x * c12y2 * c13.x * c22.y - 2 * c12.x * c21.x * c12y2 * c22.x * c13.y -
			2 * c12.x * c12y2 * c13.x * c21.y * c22.x - 6 * c20.y * c21.x * c13.x * c22.x * c13y2 - c11y2 * c12.x * c12.y * c13.x * c23.x +
			2 * c20.x * c12x2 * c12.y * c13.y * c23.y + 6 * c20.y * c13x2 * c21.y * c22.x * c13.y + 2 * c11x2 * c11.y * c13.x * c13.y * c23.y +
			c11x2 * c12.x * c12.y * c13.y * c23.y + 2 * c12x2 * c20.y * c12.y * c13.y * c23.x + 2 * c12x2 * c21.x * c12.y * c13.y * c22.y +
			2 * c12x2 * c12.y * c21.y * c22.x * c13.y + c21x3 * c13y3 + 3 * c10x2 * c13y3 * c23.x - 3 * c10y2 * c13x3 * c23.y +
			3 * c20x2 * c13y3 * c23.x + c11y3 * c13x2 * c23.x - c11x3 * c13y2 * c23.y - c11.x * c11y2 * c13x2 * c23.y +
			c11x2 * c11.y * c13y2 * c23.x - 3 * c10x2 * c13.x * c13y2 * c23.y + 3 * c10y2 * c13x2 * c13.y * c23.x - c11x2 * c12y2 * c13.x * c23.y +
			c11y2 * c12x2 * c13.y * c23.x - 3 * c21x2 * c13.x * c21.y * c13y2 - 3 * c20x2 * c13.x * c13y2 * c23.y + 3 * c20y2 * c13x2 * c13.y * c23.x +
			c11.x * c12.x * c13.x * c13.y * (6 * c20.y * c23.y + 6 * c21.y * c22.y) + c12x3 * c13.y * (-2 * c20.y * c23.y - 2 * c21.y * c22.y) +
			c10.y * c13x3 * (6 * c20.y * c23.y + 6 * c21.y * c22.y) + c11.y * c12.x * c13x2 * (-2 * c20.y * c23.y - 2 * c21.y * c22.y) +
			c12x2 * c12.y * c13.x * (2 * c20.y * c23.y + 2 * c21.y * c22.y) + c11.x * c12.y * c13x2 * (-4 * c20.y * c23.y - 4 * c21.y * c22.y) +
			c10.x * c13x2 * c13.y * (-6 * c20.y * c23.y - 6 * c21.y * c22.y) + c20.x * c13x2 * c13.y * (6 * c20.y * c23.y + 6 * c21.y * c22.y) +
			c21.x * c13x2 * c13.y * (6 * c20.y * c22.y + 3 * c21y2) + c13x3 * (-2 * c20.y * c21.y * c22.y - c20y2 * c23.y -
			c21.y * (2 * c20.y * c22.y + c21y2) - c20.y * (2 * c20.y * c23.y + 2 * c21.y * c22.y)),
		-c10.x * c11.x * c12.y * c13.x * c13.y * c22.y + c10.x * c11.y * c12.x * c13.x * c13.y * c22.y + 6 * c10.x * c11.y * c12.y * c13.x * c22.x * c13.y -
			6 * c10.y * c11.x * c12.x * c13.x * c13.y * c22.y - c10.y * c11.x * c12.y * c13.x * c22.x * c13.y + c10.y * c11.y * c12.x * c13.x * c22.x * c13.y +
			c11.x * c11.y * c12.x * c12.y * c13.x * c22.y - c11.x * c11.y * c12.x * c12.y * c22.x * c13.y + c11.x * c20.x * c12.y * c13.x * c13.y * c22.y +
			c11.x * c20.y * c12.y * c13.x * c22.x * c13.y + c11.x * c21.x * c12.y * c13.x * c21.y * c13.y - c20.x * c11.y * c12.x * c13.x * c13.y * c22.y -
			6 * c20.x * c11.y * c12.y * c13.x * c22.x * c13.y - c11.y * c12.x * c20.y * c13.x * c22.x * c13.y - c11.y * c12.x * c21.x * c13.x * c21.y * c13.y -
			6 * c10.x * c20.x * c22.x * c13y3 - 2 * c10.x * c12y3 * c13.x * c22.x + 2 * c20.x * c12y3 * c13.x * c22.x + 2 * c10.y * c12x3 * c13.y * c22.y -
			6 * c10.x * c10.y * c13.x * c22.x * c13y2 + 3 * c10.x * c11.x * c12.x * c13y2 * c22.y - 2 * c10.x * c11.x * c12.y * c22.x * c13y2 -
			4 * c10.x * c11.y * c12.x * c22.x * c13y2 + 3 * c10.y * c11.x * c12.x * c22.x * c13y2 + 6 * c10.x * c10.y * c13x2 * c13.y * c22.y +
			6 * c10.x * c20.x * c13.x * c13y2 * c22.y - 3 * c10.x * c11.y * c12.y * c13x2 * c22.y + 2 * c10.x * c12.x * c12y2 * c13.x * c22.y +
			2 * c10.x * c12.x * c12y2 * c22.x * c13.y + 6 * c10.x * c20.y * c13.x * c22.x * c13y2 + 6 * c10.x * c21.x * c13.x * c21.y * c13y2 +
			4 * c10.y * c11.x * c12.y * c13x2 * c22.y + 6 * c10.y * c20.x * c13.x * c22.x * c13y2 + 2 * c10.y * c11.y * c12.x * c13x2 * c22.y -
			3 * c10.y * c11.y * c12.y * c13x2 * c22.x + 2 * c10.y * c12.x * c12y2 * c13.x * c22.x - 3 * c11.x * c20.x * c12.x * c13y2 * c22.y +
			2 * c11.x * c20.x * c12.y * c22.x * c13y2 + c11.x * c11.y * c12y2 * c13.x * c22.x - 3 * c11.x * c12.x * c20.y * c22.x * c13y2 -
			3 * c11.x * c12.x * c21.x * c21.y * c13y2 + 4 * c20.x * c11.y * c12.x * c22.x * c13y2 - 2 * c10.x * c12x2 * c12.y * c13.y * c22.y -
			6 * c10.y * c20.x * c13x2 * c13.y * c22.y - 6 * c10.y * c20.y * c13x2 * c22.x * c13.y - 6 * c10.y * c21.x * c13x2 * c21.y * c13.y -
			2 * c10.y * c12x2 * c12.y * c13.x * c22.y - 2 * c10.y * c12x2 * c12.y * c22.x * c13.y - c11.x * c11.y * c12x2 * c13.y * c22.y -
			2 * c11.x * c11y2 * c13.x * c22.x * c13.y + 3 * c20.x * c11.y * c12.y * c13x2 * c22.y - 2 * c20.x * c12.x * c12y2 * c13.x * c22.y -
			2 * c20.x * c12.x * c12y2 * c22.x * c13.y - 6 * c20.x * c20.y * c13.x * c22.x * c13y2 - 6 * c20.x * c21.x * c13.x * c21.y * c13y2 +
			3 * c11.y * c20.y * c12.y * c13x2 * c22.x + 3 * c11.y * c21.x * c12.y * c13x2 * c21.y - 2 * c12.x * c20.y * c12y2 * c13.x * c22.x -
			2 * c12.x * c21.x * c12y2 * c13.x * c21.y - c11y2 * c12.x * c12.y * c13.x * c22.x + 2 * c20.x * c12x2 * c12.y * c13.y * c22.y -
			3 * c11.y * c21x2 * c12.y * c13.x * c13.y + 6 * c20.y * c21.x * c13x2 * c21.y * c13.y + 2 * c11x2 * c11.y * c13.x * c13.y * c22.y +
			c11x2 * c12.x * c12.y * c13.y * c22.y + 2 * c12x2 * c20.y * c12.y * c22.x * c13.y + 2 * c12x2 * c21.x * c12.y * c21.y * c13.y -
			3 * c10.x * c21x2 * c13y3 + 3 * c20.x * c21x2 * c13y3 + 3 * c10x2 * c22.x * c13y3 - 3 * c10y2 * c13x3 * c22.y + 3 * c20x2 * c22.x * c13y3 +
			c21x2 * c12y3 * c13.x + c11y3 * c13x2 * c22.x - c11x3 * c13y2 * c22.y + 3 * c10.y * c21x2 * c13.x * c13y2 -
			c11.x * c11y2 * c13x2 * c22.y + c11.x * c21x2 * c12.y * c13y2 + 2 * c11.y * c12.x * c21x2 * c13y2 + c11x2 * c11.y * c22.x * c13y2 -
			c12.x * c21x2 * c12y2 * c13.y - 3 * c20.y * c21x2 * c13.x * c13y2 - 3 * c10x2 * c13.x * c13y2 * c22.y + 3 * c10y2 * c13x2 * c22.x * c13.y -
			c11x2 * c12y2 * c13.x * c22.y + c11y2 * c12x2 * c22.x * c13.y - 3 * c20x2 * c13.x * c13y2 * c22.y + 3 * c20y2 * c13x2 * c22.x * c13.y +
			c12x2 * c12.y * c13.x * (2 * c20.y * c22.y + c21y2) + c11.x * c12.x * c13.x * c13.y * (6 * c20.y * c22.y + 3 * c21y2) +
			c12x3 * c13.y * (-2 * c20.y * c22.y - c21y2) + c10.y * c13x3 * (6 * c20.y * c22.y + 3 * c21y2) +
			c11.y * c12.x * c13x2 * (-2 * c20.y * c22.y - c21y2) + c11.x * c12.y * c13x2 * (-4 * c20.y * c22.y - 2 * c21y2) +
			c10.x * c13x2 * c13.y * (-6 * c20.y * c22.y - 3 * c21y2) + c20.x * c13x2 * c13.y * (6 * c20.y * c22.y + 3 * c21y2) +
			c13x3 * (-2 * c20.y * c21y2 - c20y2 * c22.y - c20.y * (2 * c20.y * c22.y + c21y2)),
		-c10.x * c11.x * c12.y * c13.x * c21.y * c13.y + c10.x * c11.y * c12.x * c13.x * c21.y * c13.y + 6 * c10.x * c11.y * c21.x * c12.y * c13.x * c13.y -
			6 * c10.y * c11.x * c12.x * c13.x * c21.y * c13.y - c10.y * c11.x * c21.x * c12.y * c13.x * c13.y + c10.y * c11.y * c12.x * c21.x * c13.x * c13.y -
			c11.x * c11.y * c12.x * c21.x * c12.y * c13.y + c11.x * c11.y * c12.x * c12.y * c13.x * c21.y + c11.x * c20.x * c12.y * c13.x * c21.y * c13.y +
			6 * c11.x * c12.x * c20.y * c13.x * c21.y * c13.y + c11.x * c20.y * c21.x * c12.y * c13.x * c13.y - c20.x * c11.y * c12.x * c13.x * c21.y * c13.y -
			6 * c20.x * c11.y * c21.x * c12.y * c13.x * c13.y - c11.y * c12.x * c20.y * c21.x * c13.x * c13.y - 6 * c10.x * c20.x * c21.x * c13y3 -
			2 * c10.x * c21.x * c12y3 * c13.x + 6 * c10.y * c20.y * c13x3 * c21.y + 2 * c20.x * c21.x * c12y3 * c13.x + 2 * c10.y * c12x3 * c21.y * c13.y -
			2 * c12x3 * c20.y * c21.y * c13.y - 6 * c10.x * c10.y * c21.x * c13.x * c13y2 + 3 * c10.x * c11.x * c12.x * c21.y * c13y2 -
			2 * c10.x * c11.x * c21.x * c12.y * c13y2 - 4 * c10.x * c11.y * c12.x * c21.x * c13y2 + 3 * c10.y * c11.x * c12.x * c21.x * c13y2 +
			6 * c10.x * c10.y * c13x2 * c21.y * c13.y + 6 * c10.x * c20.x * c13.x * c21.y * c13y2 - 3 * c10.x * c11.y * c12.y * c13x2 * c21.y +
			2 * c10.x * c12.x * c21.x * c12y2 * c13.y + 2 * c10.x * c12.x * c12y2 * c13.x * c21.y + 6 * c10.x * c20.y * c21.x * c13.x * c13y2 +
			4 * c10.y * c11.x * c12.y * c13x2 * c21.y + 6 * c10.y * c20.x * c21.x * c13.x * c13y2 + 2 * c10.y * c11.y * c12.x * c13x2 * c21.y -
			3 * c10.y * c11.y * c21.x * c12.y * c13x2 + 2 * c10.y * c12.x * c21.x * c12y2 * c13.x - 3 * c11.x * c20.x * c12.x * c21.y * c13y2 +
			2 * c11.x * c20.x * c21.x * c12.y * c13y2 + c11.x * c11.y * c21.x * c12y2 * c13.x - 3 * c11.x * c12.x * c20.y * c21.x * c13y2 +
			4 * c20.x * c11.y * c12.x * c21.x * c13y2 - 6 * c10.x * c20.y * c13x2 * c21.y * c13.y - 2 * c10.x * c12x2 * c12.y * c21.y * c13.y -
			6 * c10.y * c20.x * c13x2 * c21.y * c13.y - 6 * c10.y * c20.y * c21.x * c13x2 * c13.y - 2 * c10.y * c12x2 * c21.x * c12.y * c13.y -
			2 * c10.y * c12x2 * c12.y * c13.x * c21.y - c11.x * c11.y * c12x2 * c21.y * c13.y - 4 * c11.x * c20.y * c12.y * c13x2 * c21.y -
			2 * c11.x * c11y2 * c21.x * c13.x * c13.y + 3 * c20.x * c11.y * c12.y * c13x2 * c21.y - 2 * c20.x * c12.x * c21.x * c12y2 * c13.y -
			2 * c20.x * c12.x * c12y2 * c13.x * c21.y - 6 * c20.x * c20.y * c21.x * c13.x * c13y2 - 2 * c11.y * c12.x * c20.y * c13x2 * c21.y +
			3 * c11.y * c20.y * c21.x * c12.y * c13x2 - 2 * c12.x * c20.y * c21.x * c12y2 * c13.x - c11y2 * c12.x * c21.x * c12.y * c13.x +
			6 * c20.x * c20.y * c13x2 * c21.y * c13.y + 2 * c20.x * c12x2 * c12.y * c21.y * c13.y + 2 * c11x2 * c11.y * c13.x * c21.y * c13.y +
			c11x2 * c12.x * c12.y * c21.y * c13.y + 2 * c12x2 * c20.y * c21.x * c12.y * c13.y + 2 * c12x2 * c20.y * c12.y * c13.x * c21.y +
			3 * c10x2 * c21.x * c13y3 - 3 * c10y2 * c13x3 * c21.y + 3 * c20x2 * c21.x * c13y3 + c11y3 * c21.x * c13x2 - c11x3 * c21.y * c13y2 -
			3 * c20y2 * c13x3 * c21.y - c11.x * c11y2 * c13x2 * c21.y + c11x2 * c11.y * c21.x * c13y2 - 3 * c10x2 * c13.x * c21.y * c13y2 +
			3 * c10y2 * c21.x * c13x2 * c13.y - c11x2 * c12y2 * c13.x * c21.y + c11y2 * c12x2 * c21.x * c13.y - 3 * c20x2 * c13.x * c21.y * c13y2 +
			3 * c20y2 * c21.x * c13x2 * c13.y,
		c10.x * c10.y * c11.x * c12.y * c13.x * c13.y - c10.x * c10.y * c11.y * c12.x * c13.x * c13.y + c10.x * c11.x * c11.y * c12.x * c12.y * c13.y -
			c10.y * c11.x * c11.y * c12.x * c12.y * c13.x - c10.x * c11.x * c20.y * c12.y * c13.x * c13.y + 6 * c10.x * c20.x * c11.y * c12.y * c13.x * c13.y +
			c10.x * c11.y * c12.x * c20.y * c13.x * c13.y - c10.y * c11.x * c20.x * c12.y * c13.x * c13.y - 6 * c10.y * c11.x * c12.x * c20.y * c13.x * c13.y +
			c10.y * c20.x * c11.y * c12.x * c13.x * c13.y - c11.x * c20.x * c11.y * c12.x * c12.y * c13.y + c11.x * c11.y * c12.x * c20.y * c12.y * c13.x +
			c11.x * c20.x * c20.y * c12.y * c13.x * c13.y - c20.x * c11.y * c12.x * c20.y * c13.x * c13.y - 2 * c10.x * c20.x * c12y3 * c13.x +
			2 * c10.y * c12x3 * c20.y * c13.y - 3 * c10.x * c10.y * c11.x * c12.x * c13y2 - 6 * c10.x * c10.y * c20.x * c13.x * c13y2 +
			3 * c10.x * c10.y * c11.y * c12.y * c13x2 - 2 * c10.x * c10.y * c12.x * c12y2 * c13.x - 2 * c10.x * c11.x * c20.x * c12.y * c13y2 -
			c10.x * c11.x * c11.y * c12y2 * c13.x + 3 * c10.x * c11.x * c12.x * c20.y * c13y2 - 4 * c10.x * c20.x * c11.y * c12.x * c13y2 +
			3 * c10.y * c11.x * c20.x * c12.x * c13y2 + 6 * c10.x * c10.y * c20.y * c13x2 * c13.y + 2 * c10.x * c10.y * c12x2 * c12.y * c13.y +
			2 * c10.x * c11.x * c11y2 * c13.x * c13.y + 2 * c10.x * c20.x * c12.x * c12y2 * c13.y + 6 * c10.x * c20.x * c20.y * c13.x * c13y2 -
			3 * c10.x * c11.y * c20.y * c12.y * c13x2 + 2 * c10.x * c12.x * c20.y * c12y2 * c13.x + c10.x * c11y2 * c12.x * c12.y * c13.x +
			c10.y * c11.x * c11.y * c12x2 * c13.y + 4 * c10.y * c11.x * c20.y * c12.y * c13x2 - 3 * c10.y * c20.x * c11.y * c12.y * c13x2 +
			2 * c10.y * c20.x * c12.x * c12y2 * c13.x + 2 * c10.y * c11.y * c12.x * c20.y * c13x2 + c11.x * c20.x * c11.y * c12y2 * c13.x -
			3 * c11.x * c20.x * c12.x * c20.y * c13y2 - 2 * c10.x * c12x2 * c20.y * c12.y * c13.y - 6 * c10.y * c20.x * c20.y * c13x2 * c13.y -
			2 * c10.y * c20.x * c12x2 * c12.y * c13.y - 2 * c10.y * c11x2 * c11.y * c13.x * c13.y - c10.y * c11x2 * c12.x * c12.y * c13.y -
			2 * c10.y * c12x2 * c20.y * c12.y * c13.x - 2 * c11.x * c20.x * c11y2 * c13.x * c13.y - c11.x * c11.y * c12x2 * c20.y * c13.y +
			3 * c20.x * c11.y * c20.y * c12.y * c13x2 - 2 * c20.x * c12.x * c20.y * c12y2 * c13.x - c20.x * c11y2 * c12.x * c12.y * c13.x +
			3 * c10y2 * c11.x * c12.x * c13.x * c13.y + 3 * c11.x * c12.x * c20y2 * c13.x * c13.y + 2 * c20.x * c12x2 * c20.y * c12.y * c13.y -
			3 * c10x2 * c11.y * c12.y * c13.x * c13.y + 2 * c11x2 * c11.y * c20.y * c13.x * c13.y + c11x2 * c12.x * c20.y * c12.y * c13.y -
			3 * c20x2 * c11.y * c12.y * c13.x * c13.y - c10x3 * c13y3 + c10y3 * c13x3 + c20x3 * c13y3 - c20y3 * c13x3 -
			3 * c10.x * c20x2 * c13y3 - c10.x * c11y3 * c13x2 + 3 * c10x2 * c20.x * c13y3 + c10.y * c11x3 * c13y2 +
			3 * c10.y * c20y2 * c13x3 + c20.x * c11y3 * c13x2 + c10x2 * c12y3 * c13.x - 3 * c10y2 * c20.y * c13x3 - c10y2 * c12x3 * c13.y +
			c20x2 * c12y3 * c13.x - c11x3 * c20.y * c13y2 - c12x3 * c20y2 * c13.y - c10.x * c11x2 * c11.y * c13y2 +
			c10.y * c11.x * c11y2 * c13x2 - 3 * c10.x * c10y2 * c13x2 * c13.y - c10.x * c11y2 * c12x2 * c13.y + c10.y * c11x2 * c12y2 * c13.x -
			c11.x * c11y2 * c20.y * c13x2 + 3 * c10x2 * c10.y * c13.x * c13y2 + c10x2 * c11.x * c12.y * c13y2 +
			2 * c10x2 * c11.y * c12.x * c13y2 - 2 * c10y2 * c11.x * c12.y * c13x2 - c10y2 * c11.y * c12.x * c13x2 + c11x2 * c20.x * c11.y * c13y2 -
			3 * c10.x * c20y2 * c13x2 * c13.y + 3 * c10.y * c20x2 * c13.x * c13y2 + c11.x * c20x2 * c12.y * c13y2 - 2 * c11.x * c20y2 * c12.y * c13x2 +
			c20.x * c11y2 * c12x2 * c13.y - c11.y * c12.x * c20y2 * c13x2 - c10x2 * c12.x * c12y2 * c13.y - 3 * c10x2 * c20.y * c13.x * c13y2 +
			3 * c10y2 * c20.x * c13x2 * c13.y + c10y2 * c12x2 * c12.y * c13.x - c11x2 * c20.y * c12y2 * c13.x + 2 * c20x2 * c11.y * c12.x * c13y2 +
			3 * c20.x * c20y2 * c13x2 * c13.y - c20x2 * c12.x * c12y2 * c13.y - 3 * c20x2 * c20.y * c13.x * c13y2 + c12x2 * c20y2 * c12.y * c13.x
	])
	var roots = poly.get_roots_in_interval(0.0, 1.0)

	for i in range(0, len(roots)):
		var s: float = roots[i]
		var x_roots = Polynomial.new([
			c13.x,
			c12.x,
			c11.x,
			c10.x - c20.x - s * c21.x - s * s * c22.x - s * s * s * c23.x
		]).get_roots()
		var y_roots = Polynomial.new([
			c13.y,
			c12.y,
			c11.y,
			c10.y - c20.y - s * c21.y - s * s * c22.y - s * s * s * c23.y
		]).get_roots()

		if len(x_roots) > 0 and len(y_roots) > 0:
			var TOLERANCE = 1e-4

			var break_check_roots: bool = false
			for j in range(0, len(x_roots)):
				var x_root: float = x_roots[j]
				if 0.0 <= x_root and x_root <= 1.0:
					for k in range(0, len(y_roots)):
						if abs(x_root - y_roots[k]) < TOLERANCE:
							result.push_back({
								"t0": x_root,
								"t1": s,
								"point": c23 * (s * s * s) + c22 * (s * s) + c21 * s + c20
							})
							break_check_roots = true
							break
				if break_check_roots:
					break

	return result

static func intersect_cubic_bezier_with_line(
	p1: Vector2, p2: Vector2, p3: Vector2, p4: Vector2, a1: Vector2, a2: Vector2
):
	var a: Vector2
	var b: Vector2
	var c: Vector2
	var d: Vector2
	var c3: Vector2
	var c2: Vector2
	var c1: Vector2
	var c0: Vector2
	var cl: float
	var n: Vector2
	var min = Vector2(min(a1.x, a2.x), min(a1.y, a2.y))
	var max = Vector2(max(a1.x, a2.x), max(a1.y, a2.y))
	var result = []
	
	a = p1 * -1.0
	b = p2 * 3.0
	c = p3 * -3.0
	d = a + b + c + p4
	c3 = Vector2(d.x, d.y)

	a = p1 * 3.0
	b = p2 * -6.0
	c = p3 * 3.0
	d = a + b + c
	c2 = Vector2(d.x, d.y)

	a = p1 * -3.0
	b = p2 * 3.0
	c = a + b
	c1 = Vector2(c.x, c.y)

	c0 = Vector2(p1.x, p1.y)
	
	n = Vector2(a1.y - a2.y, a2.x - a1.x)
	
	cl = a1.x * a2.y - a2.x * a1.y

	var roots = Polynomial.new([
		n.dot(c3),
		n.dot(c2),
		n.dot(c1),
		n.dot(c0) + cl
	]).get_roots()

	for i in range(0, len(roots)):
		var t = roots[i]

		if 0 <= t and t <= 1:
			var p5 = p1.lerp(p2, t)
			var p6 = p2.lerp(p3, t)
			var p7 = p3.lerp(p4, t)

			var p8 = p5.lerp(p6, t)
			var p9 = p6.lerp(p7, t)

			var p10 = p8.lerp(p9, t)
			
			var line_length = a1.distance_to(a2)
			var line_t = a1.distance_to(p10) / line_length if line_length != 0 else 0.0

			if is_equal_approx(a1.x, a2.x):
				if min.y <= p10.y and p10.y <= max.y:
					result.push_back({
						"t0": t,
						"t1": line_t,
						"point": p10,
					})
			elif is_equal_approx(a1.y, a2.y):
				if min.x <= p10.x and p10.x <= max.x:
					result.push_back({
						"t0": t,
						"t1": line_t,
						"point": p10,
					})
			elif p10.x >= min.x and p10.y >= min.y and p10.x <= max.x and p10.y <= max.y:
				result.push_back({
					"t0": t,
					"t1": line_t,
					"point": p10,
				})
	
	return result

static func intersect_quadratic_bezier_with_cubic_bezier(
	a1: Vector2, a2: Vector2, a3: Vector2, b1: Vector2, b2: Vector2, b3: Vector2, b4: Vector2,
):
	var a: Vector2
	var b: Vector2
	var c: Vector2
	var d: Vector2
	var c12: Vector2
	var c11: Vector2
	var c10: Vector2
	var c23: Vector2
	var c22: Vector2
	var c21: Vector2
	var c20: Vector2
	var result = []

	a = a2 * -2.0
	c12 = a1 + a + a3

	a = a1 * -2.0
	b = a2 * 2.0
	c11 = a + b

	c10 = Vector2(a1.x, a1.y)

	a = b1 * -1.0
	b = b2 * 3.0
	c = b3 * -3.0
	d = a + b + c + b4
	c23 = Vector2(d.x, d.y)

	a = b1 * 3.0
	b = b2 * -6.0
	c = b3 * 3.0
	d = a + b + c
	c22 = Vector2(d.x, d.y)

	a = b1 * -3.0
	b = b2 * 3.0
	c = a + b
	c21 = Vector2(c.x, c.y)

	c20 = Vector2(b1.x, b1.y)

	var c10x2: float = c10.x * c10.x;
	var c10y2: float = c10.y * c10.y;
	var c11x2: float = c11.x * c11.x;
	var c11y2: float = c11.y * c11.y;
	var c12x2: float = c12.x * c12.x;
	var c12y2: float = c12.y * c12.y;
	var c20x2: float = c20.x * c20.x;
	var c20y2: float = c20.y * c20.y;
	var c21x2: float = c21.x * c21.x;
	var c21y2: float = c21.y * c21.y;
	var c22x2: float = c22.x * c22.x;
	var c22y2: float = c22.y * c22.y;
	var c23x2: float = c23.x * c23.x;
	var c23y2: float = c23.y * c23.y;

	var poly = Polynomial.new([
		-2 * c12.x * c12.y * c23.x * c23.y + c12x2 * c23y2 + c12y2 * c23x2,
		-2 * c12.x * c12.y * c22.x * c23.y - 2 * c12.x * c12.y * c22.y * c23.x + 2 * c12y2 * c22.x * c23.x +
			2 * c12x2 * c22.y * c23.y,
		-2 * c12.x * c21.x * c12.y * c23.y - 2 * c12.x * c12.y * c21.y * c23.x - 2 * c12.x * c12.y * c22.x * c22.y +
			2 * c21.x * c12y2 * c23.x + c12y2 * c22x2 + c12x2 * (2 * c21.y * c23.y + c22y2),
		2 * c10.x * c12.x * c12.y * c23.y + 2 * c10.y * c12.x * c12.y * c23.x + c11.x * c11.y * c12.x * c23.y +
			c11.x * c11.y * c12.y * c23.x - 2 * c20.x * c12.x * c12.y * c23.y - 2 * c12.x * c20.y * c12.y * c23.x -
			2 * c12.x * c21.x * c12.y * c22.y - 2 * c12.x * c12.y * c21.y * c22.x - 2 * c10.x * c12y2 * c23.x -
			2 * c10.y * c12x2 * c23.y + 2 * c20.x * c12y2 * c23.x + 2 * c21.x * c12y2 * c22.x -
			c11y2 * c12.x * c23.x - c11x2 * c12.y * c23.y + c12x2 * (2 * c20.y * c23.y + 2 * c21.y * c22.y),
		2 * c10.x * c12.x * c12.y * c22.y + 2 * c10.y * c12.x * c12.y * c22.x + c11.x * c11.y * c12.x * c22.y +
			c11.x * c11.y * c12.y * c22.x - 2 * c20.x * c12.x * c12.y * c22.y - 2 * c12.x * c20.y * c12.y * c22.x -
			2 * c12.x * c21.x * c12.y * c21.y - 2 * c10.x * c12y2 * c22.x - 2 * c10.y * c12x2 * c22.y +
			2 * c20.x * c12y2 * c22.x - c11y2 * c12.x * c22.x - c11x2 * c12.y * c22.y + c21x2 * c12y2 +
			c12x2 * (2 * c20.y * c22.y + c21y2),
		2 * c10.x * c12.x * c12.y * c21.y + 2 * c10.y * c12.x * c21.x * c12.y + c11.x * c11.y * c12.x * c21.y +
			c11.x * c11.y * c21.x * c12.y - 2 * c20.x * c12.x * c12.y * c21.y - 2 * c12.x * c20.y * c21.x * c12.y -
			2 * c10.x * c21.x * c12y2 - 2 * c10.y * c12x2 * c21.y + 2 * c20.x * c21.x * c12y2 -
			c11y2 * c12.x * c21.x - c11x2 * c12.y * c21.y + 2 * c12x2 * c20.y * c21.y,
		-2 * c10.x * c10.y * c12.x * c12.y - c10.x * c11.x * c11.y * c12.y - c10.y * c11.x * c11.y * c12.x +
			2 * c10.x * c12.x * c20.y * c12.y + 2 * c10.y * c20.x * c12.x * c12.y + c11.x * c20.x * c11.y * c12.y +
			c11.x * c11.y * c12.x * c20.y - 2 * c20.x * c12.x * c20.y * c12.y - 2 * c10.x * c20.x * c12y2 +
			c10.x * c11y2 * c12.x + c10.y * c11x2 * c12.y - 2 * c10.y * c12x2 * c20.y -
			c20.x * c11y2 * c12.x - c11x2 * c20.y * c12.y + c10x2 * c12y2 + c10y2 * c12x2 +
			c20x2 * c12y2 + c12x2 * c20y2
	]);
	var roots = poly.get_roots_in_interval(0.0, 1.0)

	for i in range(0, len(roots)):
		var s = roots[i]
		var x_roots = Polynomial.new([
			c12.x,
			c11.x,
			c10.x - c20.x - s * c21.x - s * s * c22.x - s * s * s * c23.x
		]).get_roots()
		var y_roots = Polynomial.new([
			c12.y,
			c11.y,
			c10.y - c20.y - s * c21.y - s * s * c22.y - s * s * s * c23.y
		]).get_roots()

		if len(x_roots) > 0 and len(y_roots) > 0:
			var TOLERANCE = 1e-4

			var break_check_roots: bool = false
			for j in range(0, len(x_roots)):
				var x_root = x_roots[j]
				
				if 0.0 <= x_root and x_root <= 1.0:
					for k in range(0, len(y_roots)):
						if abs(x_root - y_roots[k]) < TOLERANCE:
							result.push_back({
								"t0": x_root,
								"t1": s,
								"point": c23 * (s * s * s) + c22 * (s * s) + c21 * (s) + c20
							})
							break_check_roots = true
							break
				if break_check_roots:
					break
	
	return result

static func intersect_quadratic_bezier_with_quadratic_bezier(
	a1: Vector2, a2: Vector2, a3: Vector2, b1: Vector2, b2: Vector2, b3: Vector2
):
	var a: Vector2
	var b: Vector2
	var c12: Vector2
	var c11: Vector2
	var c10: Vector2
	var c22: Vector2
	var c21: Vector2
	var c20: Vector2
	var result = []
	var poly;

	a = a2 * -2.0
	c12 = a1 + a + a3

	a = a1 * -2.0
	b = a2 * 2.0
	c11 = a + b

	c10 = Vector2(a1.x, a1.y)

	a = b2 * -2.0
	c22 = b1 + a + b3

	a = b1 * -2.0
	b = b2 * 2.0
	c21 = a + b

	c20 = Vector2(b1.x, b1.y)
	
	if is_zero_approx(c12.y):
		var v0: float = c12.x * (c10.y - c20.y)
		var v1: float = v0 - c11.x * c11.y
		var v2: float = v0 + v1
		var v3: float = c11.y * c11.y

		poly = Polynomial.new([
			c12.x * c22.y * c22.y,
			2 * c12.x * c21.y * c22.y,
			c12.x * c21.y * c21.y - c22.x * v3 - c22.y * v0 - c22.y * v1,
			-c21.x * v3 - c21.y * v0 - c21.y * v1,
			(c10.x - c20.x) * v3 + (c10.y - c20.y) * v1
		])
	else:
		var v0: float = c12.x * c22.y - c12.y * c22.x
		var v1: float = c12.x * c21.y - c21.x * c12.y
		var v2: float = c11.x * c12.y - c11.y * c12.x
		var v3: float = c10.y - c20.y
		var v4: float = c12.y * (c10.x - c20.x) - c12.x * v3
		var v5: float = -c11.y * v2 + c12.y * v4
		var v6: float = v2 * v2

		poly = Polynomial.new([
			v0 * v0,
			2 * v0 * v1,
			(-c22.y * v6 + c12.y * v1 * v1 + c12.y * v0 * v4 + v0 * v5) / c12.y,
			(-c21.y * v6 + c12.y * v1 * v4 + v1 * v5) / c12.y,
			(v3 * v6 + v4 * v5) / c12.y
		])

	var roots = poly.get_roots()
	for i in range(0, len(roots)):
		var s = roots[i]

		if 0.0 <= s and s <= 1.0:
			var x_roots = Polynomial.new([
				c12.x,
				c11.x,
				c10.x - c20.x - s * c21.x - s * s * c22.x
			]).get_roots()
			var y_roots = Polynomial.new([
				c12.y,
				c11.y,
				c10.y - c20.y - s * c21.y - s * s * c22.y
			]).get_roots()

			if len(x_roots) > 0 and len(y_roots) > 0:
				var TOLERANCE = 1e-4

				var break_check_roots: bool = false
				for j in range(0, len(x_roots)):
					var x_root = x_roots[j]

					if 0.0 <= x_root and x_root <= 1.0:
						for k in range(0, len(y_roots)):
							if abs(x_root - y_roots[k]) < TOLERANCE:
								result.push_back({
									"t0": x_root,
									"t1": s,
									"point": c22 * (s * s) + c21 * (s) + c20
								})
								break_check_roots = true
								break
					
					if break_check_roots:
						break

	return result

static func intersect_quadratic_bezier_with_line(
	p1: Vector2, p2: Vector2, p3: Vector2, a1: Vector2, a2: Vector2
):
	var a: Vector2
	var b: Vector2
	var c2: Vector2
	var c1: Vector2
	var c0: Vector2
	var cl: float
	var n: Vector2
	var min: Vector2 = Vector2(min(a1.x, a2.x), min(a1.y, a2.y))
	var max: Vector2 = Vector2(max(a1.x, a2.x), max(a1.y, a2.y))
	var result = []
	
	a = p2 * -2.0
	c2 = p1 + a + p3

	a = p1 * -2.0
	b = p2 * 2.0
	c1 = a + b

	c0 = Vector2(p1.x, p1.y)

	n = Vector2(a1.y - a2.y, a2.x - a1.x)
	
	cl = a1.x * a2.y - a2.x * a1.y

	var roots = Polynomial.new([
		n.dot(c2),
		n.dot(c1),
		n.dot(c0) + cl
	]).get_roots()

	for i in range(0, len(roots)):
		var t = roots[i]

		if 0 <= t and t <= 1:
			var p4 = p1.lerp(p2, t)
			var p5 = p2.lerp(p3, t)

			var p6 = p4.lerp(p5, t)

			var line_length = a1.distance_to(a2)
			var line_t = a1.distance_to(p6) / line_length if line_length != 0 else 0.0

			if is_equal_approx(a1.x, a2.x):
				if min.y <= p6.y and p6.y <= max.y:
					result.push_back({
						"t0": t,
						"t1": line_t,
						"point": p6,
					})
			elif is_equal_approx(a1.y, a2.y):
				if min.x <= p6.x and p6.x <= max.x:
					result.push_back({
						"t0": t,
						"t1": line_t,
						"point": p6,
					})
			elif p6.x >= min.x and p6.y >= min.y and p6.x <= max.x and p6.y <= max.y:
				result.push_back({
					"t0": t,
					"t1": line_t,
					"point": p6,
				})

	return result

static func intersect_segment_with_segment(
	a0, a1, b0, b1
):
	var result = []
	var intersection = Geometry2D.segment_intersects_segment(a0, a1, b0, b1)
	
	if intersection != null:
		var a_length = a0.distance_to(a1)
		var a_t = a0.distance_to(intersection) / a_length
		var b_length = b0.distance_to(b1)
		var b_t = b0.distance_to(intersection) / b_length
		result.push_back({
			"t0": a_t,
			"t1": b_t,
			"point": intersection,
		})
	
	return result
