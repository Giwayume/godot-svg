# Adapted from https://github.com/colinmeinke/svg-arc-to-cubic-bezier/blob/master/src/index.js
# Copyright (c) `2017`, `Colin Meinke`
# LICENSE: Internet Systems Consortium license
# https://raw.githubusercontent.com/colinmeinke/svg-arc-to-cubic-bezier/master/LICENSE.md

class_name SVGArcs

const PathCommand = SVGValueConstant.PathCommand

static func map_to_ellipse(position: Vector2, radius: Vector2, cosphi: float, sinphi: float, center: Vector2):
	var p = position * radius
	var xp = cosphi * p.x - sinphi * p.y
	var yp = sinphi * p.x + cosphi * p.y
	return Vector2(xp + center.x, yp + center.y)

static func approx_unit_arc(ang1: float, ang2: float):
	var a = 0.551915024494 if ang2 == 1.5707963267948966 else (
		-0.551915024494 if ang2 == -1.5707963267948966 else 4.0 / 3.0 * tan(ang2 / 4.0)
	)
	
	var x1 = cos(ang1)
	var y1 = sin(ang1)
	var x2 = cos(ang1 + ang2)
	var y2 = sin(ang1 + ang2)
	
	return [
		Vector2(x1 - y1 * a, y1 + x1 * a),
		Vector2(x2 + y2 * a, y2 - x2 * a),
		Vector2(x2, y2),
	]

static func vector_angle(u: Vector2, v: Vector2):
	var uv_sign = -1 if (u.x * v.y - u.y * v.x < 0.0) else 1
	var dot = max(-1.0, min(1.0, u.x * v.x + u.y * v.y))
	return uv_sign * acos(dot)

static func get_arc_center(
	p: Vector2, c: Vector2, r: Vector2, large_arc_flag: int, sweep_flag:int,
	sinphi: float, cosphi: float, pp: Vector2
):
	var rxsq = pow(r.x, 2)
	var rysq = pow(r.y, 2)
	var pxpsq = pow(pp.x, 2)
	var pypsq = pow(pp.y, 2)
	
	var radicant = max(0.0, (rxsq * rysq) - (rxsq * pypsq) - (rysq * pxpsq))
	
	radicant /= (rxsq * pypsq) + (rysq * pxpsq)
	radicant = sqrt(radicant) * (-1 if large_arc_flag == sweep_flag else 1)
	
	var centerxp = radicant * r.x / r.y * pp.y
	var centeryp = radicant * -r.y / r.x * pp.x
	
	var centerx = cosphi * centerxp - sinphi * centeryp + (p.x + c.x) / 2.0
	var centery = sinphi * centerxp + cosphi * centeryp + (p.y + c.y) / 2.0
	
	var vx1 = (pp.x - centerxp) / r.x
	var vy1 = (pp.y - centeryp) / r.y
	var vx2 = (-pp.x - centerxp) / r.x
	var vy2 = (-pp.y - centeryp) / r.y
	
	var ang1 = vector_angle(Vector2(1.0, 0.0), Vector2(vx1, vy1))
	var ang2 = vector_angle(Vector2(vx1, vy1), Vector2(vx2, vy2))
	
	if sweep_flag == 0 and ang2 > 0:
		ang2 -= TAU
	
	if sweep_flag == 1 and ang2 < 0:
		ang2 += TAU
	
	return [
		Vector2(centerx, centery),
		ang1,
		ang2,
	]

static func arc_to_cubic_bezier(
	p: Vector2, c: Vector2, r: Vector2, x_axis_rotation: float = 0, large_arc_flag: int = 0, sweep_flag: int = 0
):
	var curves = []
	
	if r.x == 0.0 or r.y == 0.0:
		return []
	
	var sinphi = sin(x_axis_rotation * TAU / 360.0)
	var cosphi = cos(x_axis_rotation * TAU / 360.0)
	
	var pp = Vector2(
		cosphi * (p.x - c.x) / 2.0 + sinphi * (p.y - c.y) / 2.0,
		-sinphi * (p.x - c.x) / 2.0 + cosphi * (p.y - c.y) / 2.0
	)
	
	if pp.x == 0.0 and pp.y == 0.0:
		return []
	
	r = Vector2(abs(r.x), abs(r.y))
	
	var lambda = pow(pp.x, 2) / pow(r.x, 2) + pow(pp.y, 2) / pow(r.y, 2)
	
	if lambda > 1.0:
		r *= sqrt(lambda)
	
	var arc_center = get_arc_center(p, c, r, large_arc_flag, sweep_flag, sinphi, cosphi, pp)
	var center = arc_center[0]
	var ang1 = arc_center[1]
	var ang2 = arc_center[2]
	
	var ratio = abs(ang2) / (TAU / 4.0)
	if abs(1.0 - ratio) < 0.0000001:
		ratio = 1.0
	
	var segments = max(ceil(ratio), 1.0)
	
	ang2 /= segments
	
	for i in range(0, segments):
		curves.push_back(approx_unit_arc(ang1, ang2))
		ang1 += ang2
	
	var commands = []
	for curve in curves:
		var control1 = map_to_ellipse(curve[0], r, cosphi, sinphi, center)
		var control2 = map_to_ellipse(curve[1], r, cosphi, sinphi, center)
		var end = map_to_ellipse(curve[2], r, cosphi, sinphi, center)
		commands.push_back({
			"command": PathCommand.CUBIC_BEZIER_CURVE,
			"points": [control1, control2, end],
		})
	return commands
