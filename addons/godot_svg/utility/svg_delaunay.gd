class_name SVGDelaunay

# Adapted from robust-predicates.js
# License: Unlicense License
# https://github.com/mourner/robust-predicates/blob/main/LICENSE

const EPSILON = pow(2, -52)
const ccwerrbound_a = (3 + 16 * EPSILON) * EPSILON
const ccwerrbound_b = (2 + 12 * EPSILON) * EPSILON
const ccwerrbound_c = (9 + 64 * EPSILON) * EPSILON * EPSILON
const resulterrbound = (3 + 8 * EPSILON) * EPSILON;

static func split(a):
	var c = 134217729 * a
	var ahi = c - (c - a)
	return [
		ahi,
		a - a - ahi
	]

static func two_sum(a, b):
	var x = a + b
	var bvirt = x - a
	var y = a - (x - bvirt) + (b - bvirt)
	return [x, y]

static func fast_two_sum(a, b):
	var x = a + b
	var y = b - (x - a)
	return [x, y]

static func two_diff(a, b):
	var x = a - b
	var bvirt = a - x
	var y = a - (x + bvirt) + (bvirt - b)
	return [x, y]

static func two_diff_tail(a, b, x):
	var bvirt = a - x
	var y = a - (x + bvirt) + (bvirt - b)
	return x

static func two_one_diff(a1, a0, b):
	var a0_diff = two_diff(a0, b)
	var a1_sum = two_sum(a1, a0_diff[0])
	return [a1_sum[0], a1_sum[1], a0_diff[1]]

static func two_two_diff(a1, a0, b1, b0):
	var a_diff = two_one_diff(a1, a0, b0)
	var b_diff = two_one_diff(a_diff[0], a_diff[1], b1)
	return [b_diff[0], b_diff[1], b_diff[2], a_diff[2]]

static func two_product(a, b):
	var x = a * b
	var split_a = split(a)
	var split_b = split(b)
	var y = split_a[1] * split_b[1] - (x - split_a[0] * split_b[0] - split_a[1] * split_b[0] - split_a[0] * split_b[1])
	return [x, y]

static func cross_product(a, b, c, d, D):
	var prod_s = two_product(a, b)
	var prod_t = two_product(c, d)
	var st_diff = two_two_diff(prod_s[0], prod_s[1], prod_t[0], prod_t[1])
	D[0] = st_diff[3]
	D[1] = st_diff[2]
	D[2] = st_diff[1]
	D[3] = st_diff[0]

static func estimate(elen, e):
	var Q = e[0]
	for i in range(1, elen):
		Q += e[i]
	return Q

static func fast_expansion_sum_zeroelim(elen, e, flen, f, h):
	var Q
	var Qnew
	var hh
	var bvirt
	var enow = e[0]
	var fnow = f[0]
	var eindex = 0
	var findex = 0
	if (fnow > enow) == (fnow > -enow):
		Q = enow
		eindex += 1
		enow = e[eindex]
	else:
		Q = fnow
		findex += 1
		fnow = f[findex]
	var hindex = 0
	if eindex < elen and findex < flen:
		if (fnow > enow) == (fnow > -enow):
			var enow_sum = fast_two_sum(enow, Q)
			Qnew = enow_sum[0]
			hh = enow_sum[1]
			eindex += 1
			enow = e[eindex]
		else:
			var fnow_sum = fast_two_sum(fnow, Q)
			Qnew = fnow_sum[0]
			hh = fnow_sum[1]
			findex += 1
			fnow = f[findex]
		
		Q = Qnew
		if hh != 0:
			h[hindex] = hh
			hindex += 1
		while eindex < elen and findex < flen:
			if (fnow > enow) == (fnow > -enow):
				var enow_sum = two_sum(Q, enow)
				Qnew = enow_sum[0]
				hh = enow_sum[1]
				eindex += 1
				enow = e[eindex]
			else:
				var fnow_sum = two_sum(Q, fnow)
				Qnew = fnow_sum[0]
				hh = fnow_sum[1]
				findex += 1
				fnow = f[findex]
			
			Q = Qnew
			if hh != 0:
				h[hindex] = hh
				hindex += 1

	while eindex < elen:
		var enow_sum = two_sum(Q, enow)
		Qnew = enow_sum[0]
		hh = enow_sum[1]
		eindex += 1
		enow = e[eindex]
		Q = Qnew
		if hh != 0:
			h[hindex] = hh
			hindex += 1
	
	while findex < flen:
		var fnow_sum = two_sum(Q, fnow)
		Qnew = fnow_sum[0]
		hh = fnow_sum[1]
		findex += 1
		fnow = f[findex]
		Q = Qnew
		if hh != 0:
			h[hindex] = hh
			hindex += 1
	
	if Q != 0 or hindex == 0:
		h[hindex] = Q
		hindex += 1
	return hindex;

static func orient2dadapt(ax, ay, bx, by, cx, cy, detsum):
	var B = PoolRealArray()
	B.resize(4)
	var C1 = PoolRealArray()
	C1.resize(8)
	var C2 = PoolRealArray()
	C2.resize(12)
	var D = PoolRealArray()
	D.resize(16)
	var u = PoolRealArray()
	u.resize(4)

	var acxtail
	var acytail
	var bcxtail
	var bcytail
	var bvirt
	var c
	var ahi
	var alo
	var bhi
	var blo
	var _i
	var _j
	var _0
	var s1
	var s0
	var t1
	var t0
	var u3

	var acx = ax - cx
	var bcx = bx - cx
	var acy = ay - cy
	var bcy = by - cy

	cross_product(acx, bcx, acy, bcy, B)

	var det = estimate(4, B)
	var errbound = ccwerrbound_b * detsum
	if det >= errbound or -det >= errbound:
		return det

	acxtail = two_diff_tail(ax, cx, acx)
	bcxtail = two_diff_tail(bx, cx, bcx)
	acytail = two_diff_tail(ay, cy, acy)
	bcytail = two_diff_tail(by, cy, bcy)

	if acxtail == 0 and acytail == 0 and bcxtail == 0 and bcytail == 0:
		return det

	errbound = ccwerrbound_c * detsum + resulterrbound * abs(det)
	det += (acx * bcytail + bcy * acxtail) - (acy * bcxtail + bcx * acytail)
	if det >= errbound or -det >= errbound:
		return det

	cross_product(acxtail, bcx, acytail, bcy, u)
	var C1len = fast_expansion_sum_zeroelim(4, B, 4, u, C1)

	cross_product(acx, bcxtail, acy, bcytail, u)
	var C2len = fast_expansion_sum_zeroelim(C1len, C1, 4, u, C2)

	cross_product(acxtail, bcxtail, acytail, bcytail, u)
	var Dlen = fast_expansion_sum_zeroelim(C2len, C2, 4, u, D)

	return D[Dlen - 1]


static func orient2d(ax, ay, bx, by, cx, cy):
	var detleft = (ay - cy) * (bx - cx)
	var detright = (ax - cx) * (by - cy)
	var det = detleft - detright

	if detleft == 0 or detright == 0 or (detleft > 0) != (detright > 0):
		return det

	var detsum = abs(detleft + detright);
	if abs(det) >= ccwerrbound_a * detsum:
		return det

	return -orient2dadapt(ax, ay, bx, by, cx, cy, detsum)

# Adapted from delaunator.js
# Copyright (c) 2021, Mapbox
# License: ISC License
# https://github.com/mapbox/delaunator/blob/main/LICENSE
# 
# The original library code has been modified to fit the goals of this project.

const EDGE_STACK = PoolIntArray()

class Delaunator:
	func _init():
		EDGE_STACK.resize(512)
