class_name SVGDelaunay

# The subsequent code is adapted from robust-predicates.js
# License: Unlicense License
# https://github.com/mourner/robust-predicates/blob/main/LICENSE

const EPSILON = pow(2, -52)
const ccwerrbound_a = (3 + 16 * EPSILON) * EPSILON
const ccwerrbound_b = (2 + 12 * EPSILON) * EPSILON
const ccwerrbound_c = (9 + 64 * EPSILON) * EPSILON * EPSILON
const iccerrbound_a = (10 + 96 * EPSILON) * EPSILON;
const iccerrbound_b = (4 + 48 * EPSILON) * EPSILON;
const iccerrbound_c = (44 + 576 * EPSILON) * EPSILON * EPSILON;
const resulterrbound = (3 + 8 * EPSILON) * EPSILON;

class RobustPredicates:

	static func split(a):
		var c = 134217729 * a
		var ahi = c - (c - a)
		return [
			ahi,
			a - a - ahi
		]
	
	static func two_product_presplit(a, b, bhi, blo):
		var x = a * b
		var split_result = split(a)
		var y = split_result[1] * blo - (x - split_result[0] * bhi - split_result[1] * bhi - split_result[0] * blo)
		return [x, y]

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

	static func two_one_sum(a1, a0, b):
		var a0_sum = two_sum(a0, b)
		var a1_sum = two_sum(a1, a0_sum[0])
		return [a1_sum[0], a1_sum[1], a0_sum[1]]

	static func two_two_sum(a1, a0, b1, b0):
		var a_sum = two_one_sum(a1, a0, b0)
		var b_sum = two_one_sum(a_sum[0], a_sum[1], b1)
		return [b_sum[0], b_sum[1], b_sum[2], a_sum[2]]

	static func two_product(a, b):
		var x = a * b
		var split_a = split(a)
		var split_b = split(b)
		var y = split_a[1] * split_b[1] - (x - split_a[0] * split_b[0] - split_a[1] * split_b[0] - split_a[0] * split_b[1])
		return [x, y]

	static func two_product_sum(a, b, c, d, D):
		var ab_product = two_product(a, b)
		var cd_product = two_product(c, d)
		var st_sum = two_two_sum(ab_product[0], ab_product[1], cd_product[0], cd_product[1])
		D[0] = st_sum[3]
		D[1] = st_sum[2]
		D[2] = st_sum[1]
		D[3] = st_sum[0]

	static func cross_product(a, b, c, d, D):
		var prod_s = two_product(a, b)
		var prod_t = two_product(c, d)
		var st_diff = two_two_diff(prod_s[0], prod_s[1], prod_t[0], prod_t[1])
		D[0] = st_diff[3]
		D[1] = st_diff[2]
		D[2] = st_diff[1]
		D[3] = st_diff[0]
	
	static func square(a):
		var x = a * a
		var split_result = split(a)
		var y = split_result[1] * split_result[1] - (x - split_result[0] * split_result[0] - (split_result[0] * split_result[0]) * split_result[1])
		return [x, y]

	static func square_sum(a, b, D):
		var s_square = square(a)
		var t_square = square(b)
		var st_sum = two_two_sum(s_square[0], s_square[1], t_square[0], t_square[1])
		D[0] = st_sum[3]
		D[1] = st_sum[2]
		D[2] = st_sum[1]
		D[3] = st_sum[0]

	static func estimate(elen, e):
		var Q = e[0]
		for i in range(1, elen):
			Q += e[i]
		return Q

	static func fast_expansion_sum_zeroelim(elen, e, flen, f, h):
		var infinite_loop_iterator = 0
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
			if eindex < elen:
				enow = e[eindex]
			else:
				enow = null
		else:
			Q = fnow
			findex += 1
			if findex < flen:
				fnow = f[findex]
			else:
				fnow = null
		var hindex = 0
		if eindex < elen and findex < flen:
			if (fnow > enow) == (fnow > -enow):
				var enow_sum = fast_two_sum(enow, Q)
				Qnew = enow_sum[0]
				hh = enow_sum[1]
				eindex += 1
				if eindex < elen:
					enow = e[eindex]
				else:
					enow = null
			else:
				var fnow_sum = fast_two_sum(fnow, Q)
				Qnew = fnow_sum[0]
				hh = fnow_sum[1]
				findex += 1
				if findex < flen:
					fnow = f[findex]
				else:
					fnow = null
			
			Q = Qnew
			if hh != 0:
				h[hindex] = hh
				hindex += 1
			infinite_loop_iterator = 0
			while eindex < elen and findex < flen and infinite_loop_iterator < WHILE_LOOP_MAX_ITERATIONS:
				infinite_loop_iterator += 1
				if infinite_loop_iterator >= WHILE_LOOP_MAX_ITERATIONS:
					print("[godot-svg] Encountered an infinite loop during delaunay triangulation (fast_expansion_sum_zeroelim loop 1)")
					return
				
				if (fnow > enow) == (fnow > -enow):
					var enow_sum = two_sum(Q, enow)
					Qnew = enow_sum[0]
					hh = enow_sum[1]
					eindex += 1
					if eindex < elen:
						enow = e[eindex]
					else:
						enow = null
				else:
					var fnow_sum = two_sum(Q, fnow)
					Qnew = fnow_sum[0]
					hh = fnow_sum[1]
					findex += 1
					if findex < flen:
						fnow = f[findex]
					else:
						fnow = null
				
				Q = Qnew
				if hh != 0:
					h[hindex] = hh
					hindex += 1
		
		infinite_loop_iterator = 0
		while eindex < elen and infinite_loop_iterator < WHILE_LOOP_MAX_ITERATIONS:
			infinite_loop_iterator += 1
			if infinite_loop_iterator >= WHILE_LOOP_MAX_ITERATIONS:
				print("[godot-svg] Encountered an infinite loop during delaunay triangulation (fast_expansion_sum_zeroelim loop 2)")
				return
			
			var enow_sum = two_sum(Q, enow)
			Qnew = enow_sum[0]
			hh = enow_sum[1]
			eindex += 1
			if eindex < elen:
				enow = e[eindex]
			else:
				enow = null
			Q = Qnew
			if hh != 0:
				h[hindex] = hh
				hindex += 1
		
		infinite_loop_iterator = 0
		while findex < flen and infinite_loop_iterator < WHILE_LOOP_MAX_ITERATIONS:
			infinite_loop_iterator += 1
			if infinite_loop_iterator >= WHILE_LOOP_MAX_ITERATIONS:
				print("[godot-svg] Encountered an infinite loop during delaunay triangulation (fast_expansion_sum_zeroelim loop 3)")
				return
			
			var fnow_sum = two_sum(Q, fnow)
			Qnew = fnow_sum[0]
			hh = fnow_sum[1]
			findex += 1
			if findex < flen:
				fnow = f[findex]
			else:
				fnow = null
			Q = Qnew
			if hh != 0:
				h[hindex] = hh
				hindex += 1
		
		if Q != 0 or hindex == 0:
			h[hindex] = Q
			hindex += 1
		return hindex
	
	static func sum_three(alen, a, blen, b, clen, c, tmp, out):
		return fast_expansion_sum_zeroelim(fast_expansion_sum_zeroelim(alen, a, blen, b, tmp), tmp, clen, c, out)
	
	static func scale_expansion_zeroelim(elen, e, b, h):
		var Q
		var sum
		var hh
		var product1
		var product0
		var bvirt
		var c
		var ahi
		var alo
		var bhi
		var blo

		var bhi_split_result = split(b)
		bhi = bhi_split_result[0]
		blo = bhi_split_result[1]
		var enow = e[0]
		var enow_two_split_result = two_product_presplit(enow, b, bhi, blo)
		Q = enow_two_split_result[0]
		hh = enow_two_split_result[1]
		var hindex = 0
		if hh != 0:
			h[hindex] = hh
			hindex += 1
		for i in range(1, elen):
			enow = e[i]
			enow_two_split_result = two_product_presplit(enow, b, bhi, blo)
			product1 = enow_two_split_result[0]
			product0 = enow_two_split_result[1]
			var q_two_sum_result = two_sum(Q, product0)
			sum = q_two_sum_result[0]
			hh = q_two_sum_result[1]
			if hh != 0:
				h[hindex] = hh
				hindex += 1
			var product1_two_sum_result = fast_two_sum(product1, sum)
			Q = product1_two_sum_result[0]
			hh = product1_two_sum_result[1]
			if hh != 0:
				h[hindex] = hh
				hindex += 1
		if Q != 0 or hindex == 0:
			h[hindex] = Q
			hindex += 1
		return hindex

	static func orient2dadapt(ax, ay, bx, by, cx, cy, detsum):
		var B = PoolRealArray()
		for i in range(0, 4):
			B.append(0)
		var C1 = PoolRealArray()
		for i in range(0, 8):
			C1.append(0)
		var C2 = PoolRealArray()
		for i in range(0, 12):
			C2.append(0)
		var D = PoolRealArray()
		for i in range(0, 16):
			D.append(0)
		var u = PoolRealArray()
		for i in range(0, 4):
			u.append(0)

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
	
	static func finadd(fin, fin2, finlen, a, alen):
		finlen = fast_expansion_sum_zeroelim(finlen, fin, a, alen, fin2)
		var tmp = fin
		fin = fin2
		fin2 = tmp
		return finlen

	static func incircleadapt(ax, ay, bx, by, cx, cy, dx, dy, permanent):
		var bc = PoolRealArray()
		for i in range(0, 4):
			bc.append(0)
		var ca = PoolRealArray()
		for i in range(0, 4):
			ca.append(0)
		var ab = PoolRealArray()
		for i in range(0, 4):
			ab.append(0)
		var aa = PoolRealArray()
		for i in range(0, 4):
			aa.append(0)
		var bb = PoolRealArray()
		for i in range(0, 4):
			bb.append(0)
		var cc = PoolRealArray()
		for i in range(0, 4):
			cc.append(0)
		var u = PoolRealArray()
		for i in range(0, 4):
			u.append(0)
		var v = PoolRealArray()
		for i in range(0, 4):
			v.append(0)
		var axtbc = PoolRealArray()
		for i in range(0, 8):
			axtbc.append(0)
		var aytbc = PoolRealArray()
		for i in range(0, 8):
			aytbc.append(0)
		var bxtca = PoolRealArray()
		for i in range(0, 8):
			bxtca.append(0)
		var bytca = PoolRealArray()
		for i in range(0, 8):
			bytca.append(0)
		var cxtab = PoolRealArray()
		for i in range(0, 8):
			cxtab.append(0)
		var cytab = PoolRealArray()
		for i in range(0, 8):
			cytab.append(0)
		var abt = PoolRealArray()
		for i in range(0, 8):
			abt.append(0)
		var bct = PoolRealArray()
		for i in range(0, 8):
			bct.append(0)
		var cat = PoolRealArray()
		for i in range(0, 8):
			cat.append(0)
		var abtt = PoolRealArray()
		for i in range(0, 4):
			abtt.append(0)
		var bctt = PoolRealArray()
		for i in range(0, 4):
			bctt.append(0)
		var catt = PoolRealArray()
		for i in range(0, 4):
			catt.append(0)
		
		var _8 = PoolRealArray()
		_8.resize(8)
		var _16 = PoolRealArray()
		_16.resize(16)
		var _16b = PoolRealArray()
		_16b.resize(16)
		var _16c = PoolRealArray()
		_16c.resize(16)
		var _32 = PoolRealArray()
		_32.resize(32)
		var _32b = PoolRealArray()
		_32b.resize(32)
		var _48 = PoolRealArray()
		_48.resize(48)
		var _64 = PoolRealArray()
		_64.resize(64)
		
		var fin = Array()
		fin.resize(1152)
		var fin2 = Array()
		fin2.resize(1152)

		var finlen
		var adxtail
		var bdxtail
		var cdxtail
		var adytail
		var bdytail
		var cdytail
		var axtbclen
		var aytbclen
		var bxtcalen
		var bytcalen
		var cxtablen
		var cytablen
		var abtlen
		var bctlen
		var catlen
		var abttlen
		var bcttlen
		var cattlen
		var n1
		var n0
	
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
	
		var adx = ax - dx;
		var bdx = bx - dx;
		var cdx = cx - dx;
		var ady = ay - dy;
		var bdy = by - dy;
		var cdy = cy - dy;
	
		cross_product(bdx, bdy, cdx, cdy, bc)
		cross_product(cdx, cdy, adx, ady, ca)
		cross_product(adx, ady, bdx, bdy, ab)
	
		finlen = fast_expansion_sum_zeroelim(
			fast_expansion_sum_zeroelim(
				fast_expansion_sum_zeroelim(
					scale_expansion_zeroelim(scale_expansion_zeroelim(4, bc, adx, _8), _8, adx, _16), _16,
					scale_expansion_zeroelim(scale_expansion_zeroelim(4, bc, ady, _8), _8, ady, _16b), _16b, _32), _32,
				fast_expansion_sum_zeroelim(
					scale_expansion_zeroelim(scale_expansion_zeroelim(4, ca, bdx, _8), _8, bdx, _16), _16,
					scale_expansion_zeroelim(scale_expansion_zeroelim(4, ca, bdy, _8), _8, bdy, _16b), _16b, _32b), _32b, _64), _64,
			fast_expansion_sum_zeroelim(
				scale_expansion_zeroelim(scale_expansion_zeroelim(4, ab, cdx, _8), _8, cdx, _16), _16,
				scale_expansion_zeroelim(scale_expansion_zeroelim(4, ab, cdy, _8), _8, cdy, _16b), _16b, _32), _32, fin)
	
		var det = estimate(finlen, fin)
		var errbound = iccerrbound_b * permanent
		if det >= errbound or -det >= errbound:
			return det
	
		adxtail = two_diff_tail(ax, dx, adx)
		adytail = two_diff_tail(ay, dy, ady)
		bdxtail = two_diff_tail(bx, dx, bdx)
		bdytail = two_diff_tail(by, dy, bdy)
		cdxtail = two_diff_tail(cx, dx, cdx)
		cdytail = two_diff_tail(cy, dy, cdy)
		if adxtail == 0 and bdxtail == 0 and cdxtail == 0 and adytail == 0 and bdytail == 0 and cdytail == 0:
			return det
	
		errbound = iccerrbound_c * permanent + resulterrbound * abs(det)
		det += (
			(adx * adx + ady * ady) * ((bdx * cdytail + cdy * bdxtail) - (bdy * cdxtail + cdx * bdytail)) +
			2 * (adx * adxtail + ady * adytail) * (bdx * cdy - bdy * cdx)
		) + (
			(bdx * bdx + bdy * bdy) * ((cdx * adytail + ady * cdxtail) - (cdy * adxtail + adx * cdytail)) +
			2 * (bdx * bdxtail + bdy * bdytail) * (cdx * ady - cdy * adx)
		) + (
			(cdx * cdx + cdy * cdy) * ((adx * bdytail + bdy * adxtail) - (ady * bdxtail + bdx * adytail)) +
			2 * (cdx * cdxtail + cdy * cdytail) * (adx * bdy - ady * bdx)
		)
	
		if det >= errbound or -det >= errbound:
			return det
	
		if bdxtail != 0 or bdytail != 0 or cdxtail != 0 or cdytail != 0:
			square_sum(adx, ady, aa)
		if cdxtail != 0 or cdytail != 0 or adxtail != 0 or adytail != 0:
			square_sum(bdx, bdy, bb)
		if adxtail != 0 or adytail != 0 or bdxtail != 0 or bdytail != 0:
			square_sum(cdx, cdy, cc)
		
		if adxtail != 0:
			axtbclen = scale_expansion_zeroelim(4, bc, adxtail, axtbc)
			finlen = finadd(fin, fin2, finlen, sum_three(
				scale_expansion_zeroelim(axtbclen, axtbc, 2 * adx, _16), _16,
				scale_expansion_zeroelim(scale_expansion_zeroelim(4, cc, adxtail, _8), _8, bdy, _16b), _16b,
				scale_expansion_zeroelim(scale_expansion_zeroelim(4, bb, adxtail, _8), _8, -cdy, _16c), _16c, _32, _48), _48)
		if adytail != 0:
			aytbclen = scale_expansion_zeroelim(4, bc, adytail, aytbc)
			finlen = finadd(fin, fin2, finlen, sum_three(
				scale_expansion_zeroelim(aytbclen, aytbc, 2 * ady, _16), _16,
				scale_expansion_zeroelim(scale_expansion_zeroelim(4, bb, adytail, _8), _8, cdx, _16b), _16b,
				scale_expansion_zeroelim(scale_expansion_zeroelim(4, cc, adytail, _8), _8, -bdx, _16c), _16c, _32, _48), _48)
		if bdxtail != 0:
			bxtcalen = scale_expansion_zeroelim(4, ca, bdxtail, bxtca)
			finlen = finadd(fin, fin2, finlen, sum_three(
				scale_expansion_zeroelim(bxtcalen, bxtca, 2 * bdx, _16), _16,
				scale_expansion_zeroelim(scale_expansion_zeroelim(4, aa, bdxtail, _8), _8, cdy, _16b), _16b,
				scale_expansion_zeroelim(scale_expansion_zeroelim(4, cc, bdxtail, _8), _8, -ady, _16c), _16c, _32, _48), _48)
		if bdytail != 0:
			bytcalen = scale_expansion_zeroelim(4, ca, bdytail, bytca)
			finlen = finadd(fin, fin2, finlen, sum_three(
				scale_expansion_zeroelim(bytcalen, bytca, 2 * bdy, _16), _16,
				scale_expansion_zeroelim(scale_expansion_zeroelim(4, cc, bdytail, _8), _8, adx, _16b), _16b,
				scale_expansion_zeroelim(scale_expansion_zeroelim(4, aa, bdytail, _8), _8, -cdx, _16c), _16c, _32, _48), _48)
		if cdxtail != 0:
			cxtablen = scale_expansion_zeroelim(4, ab, cdxtail, cxtab)
			finlen = finadd(fin, fin2, finlen, sum_three(
				scale_expansion_zeroelim(cxtablen, cxtab, 2 * cdx, _16), _16,
				scale_expansion_zeroelim(scale_expansion_zeroelim(4, bb, cdxtail, _8), _8, ady, _16b), _16b,
				scale_expansion_zeroelim(scale_expansion_zeroelim(4, aa, cdxtail, _8), _8, -bdy, _16c), _16c, _32, _48), _48)
		if cdytail != 0:
			cytablen = scale_expansion_zeroelim(4, ab, cdytail, cytab)
			finlen = finadd(fin, fin2, finlen, sum_three(
				scale_expansion_zeroelim(cytablen, cytab, 2 * cdy, _16), _16,
				scale_expansion_zeroelim(scale_expansion_zeroelim(4, aa, cdytail, _8), _8, bdx, _16b), _16b,
				scale_expansion_zeroelim(scale_expansion_zeroelim(4, bb, cdytail, _8), _8, -adx, _16c), _16c, _32, _48), _48)
	
		if adxtail != 0 or adytail != 0:
			if bdxtail != 0 or bdytail != 0 or cdxtail != 0 or cdytail != 0:
				two_product_sum(bdxtail, cdy, bdx, cdytail, u)
				two_product_sum(cdxtail, -bdy, cdx, -bdytail, v)
				bctlen = fast_expansion_sum_zeroelim(4, u, 4, v, bct)
				cross_product(bdxtail, bdytail, cdxtail, cdytail, bctt)
				bcttlen = 4;
			else:
				bct[0] = 0
				bctlen = 1
				bctt[0] = 0
				bcttlen = 1
			if adxtail != 0:
				var len1 = scale_expansion_zeroelim(bctlen, bct, adxtail, _16c)
				finlen = finadd(fin, fin2, finlen, fast_expansion_sum_zeroelim(
					scale_expansion_zeroelim(axtbclen, axtbc, adxtail, _16), _16,
					scale_expansion_zeroelim(len1, _16c, 2 * adx, _32), _32, _48), _48)
	
				var len2 = scale_expansion_zeroelim(bcttlen, bctt, adxtail, _8)
				finlen = finadd(fin, fin2, finlen, sum_three(
					scale_expansion_zeroelim(len2, _8, 2 * adx, _16), _16,
					scale_expansion_zeroelim(len2, _8, adxtail, _16b), _16b,
					scale_expansion_zeroelim(len1, _16c, adxtail, _32), _32, _32b, _64), _64)
	
				if bdytail != 0:
					finlen = finadd(fin, fin2, finlen, scale_expansion_zeroelim(scale_expansion_zeroelim(4, cc, adxtail, _8), _8, bdytail, _16), _16)
				if cdytail != 0:
					finlen = finadd(fin, fin2, finlen, scale_expansion_zeroelim(scale_expansion_zeroelim(4, bb, -adxtail, _8), _8, cdytail, _16), _16)
			
			if adytail != 0:
				var len1 = scale_expansion_zeroelim(bctlen, bct, adytail, _16c)
				finlen = finadd(fin, fin2, finlen, fast_expansion_sum_zeroelim(
					scale_expansion_zeroelim(aytbclen, aytbc, adytail, _16), _16,
					scale_expansion_zeroelim(len1, _16c, 2 * ady, _32), _32, _48), _48)
	
				var len2 = scale_expansion_zeroelim(bcttlen, bctt, adytail, _8)
				finlen = finadd(fin, fin2, finlen, sum_three(
					scale_expansion_zeroelim(len2, _8, 2 * ady, _16), _16,
					scale_expansion_zeroelim(len2, _8, adytail, _16b), _16b,
					scale_expansion_zeroelim(len1, _16c, adytail, _32), _32, _32b, _64), _64)
		
		if bdxtail != 0 or bdytail != 0:
			if cdxtail != 0 or cdytail != 0 or adxtail != 0 or adytail != 0:
				two_product_sum(cdxtail, ady, cdx, adytail, u)
				n1 = -cdy
				n0 = -cdytail
				two_product_sum(adxtail, n1, adx, n0, v)
				catlen = fast_expansion_sum_zeroelim(4, u, 4, v, cat)
				cross_product(cdxtail, cdytail, adxtail, adytail, catt)
				cattlen = 4
			else:
				cat[0] = 0
				catlen = 1
				catt[0] = 0
				cattlen = 1
			if bdxtail != 0:
				var len1 = scale_expansion_zeroelim(catlen, cat, bdxtail, _16c)
				finlen = finadd(fin, fin2, finlen, fast_expansion_sum_zeroelim(
					scale_expansion_zeroelim(bxtcalen, bxtca, bdxtail, _16), _16,
					scale_expansion_zeroelim(len1, _16c, 2 * bdx, _32), _32, _48), _48);
	
				var len2 = scale_expansion_zeroelim(cattlen, catt, bdxtail, _8);
				finlen = finadd(fin, fin2, finlen, sum_three(
					scale_expansion_zeroelim(len2, _8, 2 * bdx, _16), _16,
					scale_expansion_zeroelim(len2, _8, bdxtail, _16b), _16b,
					scale_expansion_zeroelim(len1, _16c, bdxtail, _32), _32, _32b, _64), _64);
	
				if cdytail != 0:
					finlen = finadd(fin, fin2, finlen, scale_expansion_zeroelim(scale_expansion_zeroelim(4, aa, bdxtail, _8), _8, cdytail, _16), _16)
				if adytail != 0:
					finlen = finadd(fin, fin2, finlen, scale_expansion_zeroelim(scale_expansion_zeroelim(4, cc, -bdxtail, _8), _8, adytail, _16), _16)
			if bdytail != 0:
				var len1 = scale_expansion_zeroelim(catlen, cat, bdytail, _16c)
				finlen = finadd(fin, fin2, finlen, fast_expansion_sum_zeroelim(
					scale_expansion_zeroelim(bytcalen, bytca, bdytail, _16), _16,
					scale_expansion_zeroelim(len1, _16c, 2 * bdy, _32), _32, _48), _48)
	
				var len2 = scale_expansion_zeroelim(cattlen, catt, bdytail, _8)
				finlen = finadd(fin, fin2, finlen, sum_three(
					scale_expansion_zeroelim(len2, _8, 2 * bdy, _16), _16,
					scale_expansion_zeroelim(len2, _8, bdytail, _16b), _16b,
					scale_expansion_zeroelim(len1, _16c, bdytail, _32), _32,  _32b, _64), _64)
		
		if cdxtail != 0 or cdytail != 0:
			if adxtail != 0 || adytail != 0 || bdxtail != 0 || bdytail != 0:
				two_product_sum(adxtail, bdy, adx, bdytail, u)
				n1 = -ady
				n0 = -adytail
				two_product_sum(bdxtail, n1, bdx, n0, v)
				abtlen = fast_expansion_sum_zeroelim(4, u, 4, v, abt)
				cross_product(adxtail, adytail, bdxtail, bdytail, abtt)
				abttlen = 4
			else:
				abt[0] = 0
				abtlen = 1
				abtt[0] = 0
				abttlen = 1
			if cdxtail != 0:
				var len1 = scale_expansion_zeroelim(abtlen, abt, cdxtail, _16c)
				finlen = finadd(fin, fin2, finlen, fast_expansion_sum_zeroelim(
					scale_expansion_zeroelim(cxtablen, cxtab, cdxtail, _16), _16,
					scale_expansion_zeroelim(len1, _16c, 2 * cdx, _32), _32, _48), _48)
	
				var len2 = scale_expansion_zeroelim(abttlen, abtt, cdxtail, _8)
				finlen = finadd(fin, fin2, finlen, sum_three(
					scale_expansion_zeroelim(len2, _8, 2 * cdx, _16), _16,
					scale_expansion_zeroelim(len2, _8, cdxtail, _16b), _16b,
					scale_expansion_zeroelim(len1, _16c, cdxtail, _32), _32, _32b, _64), _64)
	
				if adytail != 0:
					finlen = finadd(fin, fin2, finlen, scale_expansion_zeroelim(scale_expansion_zeroelim(4, bb, cdxtail, _8), _8, adytail, _16), _16)
				if bdytail != 0:
					finlen = finadd(fin, fin2, finlen, scale_expansion_zeroelim(scale_expansion_zeroelim(4, aa, -cdxtail, _8), _8, bdytail, _16), _16)
			if cdytail != 0:
				var len1 = scale_expansion_zeroelim(abtlen, abt, cdytail, _16c)
				finlen = finadd(fin, fin2, finlen, fast_expansion_sum_zeroelim(
					scale_expansion_zeroelim(cytablen, cytab, cdytail, _16), _16,
					scale_expansion_zeroelim(len1, _16c, 2 * cdy, _32), _32, _48), _48)
	
				var len2 = scale_expansion_zeroelim(abttlen, abtt, cdytail, _8)
				finlen = finadd(fin, fin2, finlen, sum_three(
					scale_expansion_zeroelim(len2, _8, 2 * cdy, _16), _16,
					scale_expansion_zeroelim(len2, _8, cdytail, _16b), _16b,
					scale_expansion_zeroelim(len1, _16c, cdytail, _32), _32, _32b, _64), _64)
	
		return fin[finlen - 1]
	
	static func incircle(ax, ay, bx, by, cx, cy, dx, dy):
		var adx = ax - dx
		var bdx = bx - dx
		var cdx = cx - dx
		var ady = ay - dy
		var bdy = by - dy
		var cdy = cy - dy

		var bdxcdy = bdx * cdy
		var cdxbdy = cdx * bdy
		var alift = adx * adx + ady * ady

		var cdxady = cdx * ady
		var adxcdy = adx * cdy
		var blift = bdx * bdx + bdy * bdy

		var adxbdy = adx * bdy
		var bdxady = bdx * ady
		var clift = cdx * cdx + cdy * cdy

		var det = (
			alift * (bdxcdy - cdxbdy) +
			blift * (cdxady - adxcdy) +
			clift * (adxbdy - bdxady)
		)

		var permanent = (
			(abs(bdxcdy) + abs(cdxbdy)) * alift +
			(abs(cdxady) + abs(adxcdy)) * blift +
			(abs(adxbdy) + abs(bdxady)) * clift
		)

		var errbound = iccerrbound_a * permanent

		if det > errbound or -det > errbound:
			return det
		return incircleadapt(ax, ay, bx, by, cx, cy, dx, dy, permanent)

# The subsequent code is adapted from delaunator.js
# Copyright (c) 2021, Mapbox
# License: ISC License
# https://github.com/mapbox/delaunator/blob/main/LICENSE
# 
# The original library code has been modified to fit the goals of this project.

const EDGE_STACK = PoolIntArray()
const WHILE_LOOP_MAX_ITERATIONS = 1000

class Delaunator:
	var coords
	var _triangles
	var _halfedges
	var _hash_size
	var _hull_prev
	var _hull_next
	var _hull_tri
	var _hull_hash
	var _hull_start
	var _ids
	var _dists
	var _cx
	var _cy
	var triangles
	var halfedges
	var triangles_len
	var hull
	var bounding_box

	static func from(points: Array):
		var n = points.size()
		var coords = PoolRealArray()
		coords.resize(n * 2)

		for i in range(0, n):
			var p = points[i]
			coords[2 * i] = p.x
			coords[2 * i + 1] = p.y

		return Delaunator.new(coords)

	func _init(coords: PoolRealArray):
		EDGE_STACK.resize(512)
		var n = coords.size() >> 1

		self.coords = coords
		bounding_box = Rect2()

		# arrays that will store the triangulation graph
		var max_triangles = max(2 * n - 5, 0)
		_triangles = PoolIntArray()
		_triangles.resize(max_triangles * 3)
		_halfedges = PoolIntArray()
		_halfedges.resize(max_triangles * 3)

		# temporary arrays for tracking the edges of the advancing convex hull
		_hash_size = ceil(sqrt(n))
		_hull_prev = PoolIntArray() # edge to prev edge
		for i in range(0, n):
			_hull_prev.append(0)
		_hull_next = PoolIntArray() # edge to next edge
		for i in range(0, n):
			_hull_next.append(0)
		_hull_tri = PoolIntArray() # edge to adjacent triangle
		for i in range(0, n):
			_hull_tri.append(0)
		_hull_hash = PoolIntArray() # angular edge hash
		for i in range(0, _hash_size):
			_hull_hash.append(-1)

		# temporary arrays for sorting points
		_ids = PoolIntArray()
		_ids.resize(n)
		_dists = PoolRealArray()
		_dists.resize(n)

		update()

	func update():
		var infinite_loop_iterator = 0
		var n = coords.size() >> 1

		var _ids_qs
		var _dists_qs

		# populate an array of point indices; calculate input data bbox
		var min_x = INF
		var min_y = INF
		var max_x = -INF
		var max_y = -INF

		for i in range(0, n):
			var x = coords[2 * i]
			var y = coords[2 * i + 1]
			if x < min_x:
				min_x = x
			if y < min_y:
				min_y = y
			if x > max_x:
				max_x = x
			if y > max_y:
				max_y = y
			_ids[i] = i
		
		bounding_box.position.x = min_x
		bounding_box.position.y = min_y
		bounding_box.size.x = max_x - min_x
		bounding_box.size.y = max_y - min_y

		var cx = (min_x + max_x) / 2
		var cy = (min_y + max_y) / 2

		var min_dist = INF
		var i0
		var i1
		var i2
		
		# pick a seed point close to the center
		for i in range(0, n):
			var d = dist(cx, cy, coords[2 * i], coords[2 * i + 1])
			if d < min_dist:
				i0 = i
				min_dist = d
		var i0x = coords[2 * i0]
		var i0y = coords[2 * i0 + 1]

		min_dist = INF
		
		# find the point closest to the seed
		for i in range(0, n):
			if i == i0:
				continue
			var d = dist(i0x, i0y, coords[2 * i], coords[2 * i + 1])
			if d < min_dist and d > 0:
				i1 = i
				min_dist = d
		var i1x = coords[2 * i1]
		var i1y = coords[2 * i1 + 1]

		var min_radius = INF

		# find the third point which forms the smallest circumcircle with the first two
		for i in range(0, n):
			if i == i0 or i == i1:
				continue
			var r = circumradius(i0x, i0y, i1x, i1y, coords[2 * i], coords[2 * i + 1])
			if r < min_radius:
				i2 = i
				min_radius = r
		var i2x = coords[2 * i2]
		var i2y = coords[2 * i2 + 1]

		if min_radius == INF:
			# order collinear points by dx (or dy if all x are identical)
			# and return the list as a hull
			for i in range(0, n):
				var dist_at_i = coords[2 * i] - coords[0]
				if dist_at_i == 0:
					dist_at_i = coords[2 * i + 1] - coords[1]
				_dists[i] = dist_at_i
			_ids_qs = Array(_ids)
			_dists_qs = Array(_dists)
			quicksort(_ids_qs, _dists_qs, 0, n - 1)
			_ids = PoolIntArray(_ids_qs)
			var hull = PoolIntArray()
			hull.resize(n)
			var j = 0
			var d0 = -INF
			for i in range(0, n):
				var id = _ids[i]
				if _dists[id] > d0:
					hull[j] = id
					j += 1
					d0 = _dists[id]
			hull = hull.resize(j)
			triangles = PoolIntArray()
			halfedges = PoolIntArray()
			return

		# swap the order of the seed points for counter-clockwise orientation
		if RobustPredicates.orient2d(i0x, i0y, i1x, i1y, i2x, i2y) < 0:
			var i = i1
			var x = i1x
			var y = i1y
			i1 = i2
			i1x = i2x
			i1y = i2y
			i2 = i
			i2x = x
			i2y = y

		var center = circumcenter(i0x, i0y, i1x, i1y, i2x, i2y)
		_cx = center.x
		_cy = center.y

		for i in range(0, n):
			_dists[i] = dist(coords[2 * i], coords[2 * i + 1], center.x, center.y)

		# sort the points by distance from the seed triangle circumcenter
		_ids_qs = Array(_ids)
		_dists_qs = Array(_dists)
		quicksort(_ids_qs, _dists_qs, 0, n - 1)
		_ids = PoolIntArray(_ids_qs)
		
		# set up the seed triangle as the starting hull
		_hull_start = i0
		var hull_size = 3

		_hull_prev[i2] = i1
		_hull_next[i0] = i1
		_hull_prev[i0] = i2
		_hull_next[i1] = i2
		_hull_prev[i1] = i0
		_hull_next[i2] = i0

		_hull_tri[i0] = 0
		_hull_tri[i1] = 1
		_hull_tri[i2] = 2

		for i in range(0, _hull_hash.size()):
			_hull_hash[i] = -1
		_hull_hash[_hash_key(i0x, i0y)] = i0
		_hull_hash[_hash_key(i1x, i1y)] = i1
		_hull_hash[_hash_key(i2x, i2y)] = i2

		triangles_len = 0
		_add_triangle(i0, i1, i2, -1, -1, -1)

		var xp
		var yp
		for k in range(0, _ids.size()):
			var i = _ids[k]
			var x = coords[2 * i]
			var y = coords[2 * i + 1]

			# skip near-duplicate points
			if k > 0 and abs(x - xp) <= EPSILON and abs(y - yp) <= EPSILON:
				continue
			xp = x
			yp = y

			# skip seed triangle points
			if i == i0 or i == i1 or i == i2:
				continue

			# find a visible edge on the convex hull using edge hash
			var start = 0
			var key = _hash_key(x, y)
			for j in range(0, _hash_size):
				start = _hull_hash[fmod((key + j), _hash_size)]
				if start != -1 and start != _hull_next[start]:
					break

			start = _hull_prev[start]
			var e = start
			var q = _hull_next[e]
			infinite_loop_iterator = 0
			while (
				RobustPredicates.orient2d(x, y, coords[2 * e], coords[2 * e + 1], coords[2 * q], coords[2 * q + 1]) >= 0 and
				infinite_loop_iterator < WHILE_LOOP_MAX_ITERATIONS
			):
				infinite_loop_iterator += 1
				if infinite_loop_iterator >= WHILE_LOOP_MAX_ITERATIONS:
					print("[godot-svg] Encountered an infinite loop during delaunay triangulation (find a visible edge on the convex hull)")
					return
				e = q
				if e == start:
					e = -1
					break
				q = _hull_next[e]
			
			if e == -1:
				continue # likely a near-duplicate point; skip it
			
			# add the first triangle from the point
			var t = _add_triangle(e, i, _hull_next[e], -1, -1, _hull_tri[e])

			# recursively flip triangles from the point until they satisfy the Delaunay condition
			_hull_tri[i] = _legalize(t + 2)
			_hull_tri[e] = t # keep track of boundary triangles on the hull
			hull_size += 1

			# walk forward through the hull, adding more triangles and flipping recursively
			var nn = _hull_next[e]
			q = _hull_next[nn]
			infinite_loop_iterator = 0
			while (
				RobustPredicates.orient2d(x, y, coords[2 * nn], coords[2 * nn + 1], coords[2 * q], coords[2 * q + 1]) < 0 and
				infinite_loop_iterator < WHILE_LOOP_MAX_ITERATIONS
			):
				infinite_loop_iterator += 1
				if infinite_loop_iterator >= WHILE_LOOP_MAX_ITERATIONS:
					print("[godot-svg] Encountered an infinite loop during delaunay triangulation (walk forward through the hull)")
					return
				t = _add_triangle(nn, i, q, _hull_tri[i], -1, _hull_tri[nn])
				_hull_tri[i] = _legalize(t + 2)
				_hull_next[nn] = nn # mark as removed
				hull_size -= 1
				nn = q
				q = _hull_next[nn]

			# walk backward from the other side, adding more triangles and flipping
			if e == start:
				q = _hull_prev[e]
				infinite_loop_iterator = 0
				while (
					RobustPredicates.orient2d(x, y, coords[2 * q], coords[2 * q + 1], coords[2 * e], coords[2 * e + 1]) < 0 and
					infinite_loop_iterator < WHILE_LOOP_MAX_ITERATIONS
				):
					infinite_loop_iterator += 1
					if infinite_loop_iterator >= WHILE_LOOP_MAX_ITERATIONS:
						print("[godot-svg] Encountered an infinite loop during delaunay triangulation (walk backward from the other side)")
						return
					t = _add_triangle(q, i, e, -1, _hull_tri[e], _hull_tri[q])
					_legalize(t + 2)
					_hull_tri[q] = t
					_hull_next[e] = e # mark as removed
					hull_size -= 1
					e = q
					q = _hull_prev[e]

			# update the hull indices
			_hull_prev[i] = e
			_hull_start = e
			_hull_prev[nn] = i
			_hull_next[e] = i
			_hull_next[i] = nn

			# save the two new edges in the hash table
			_hull_hash[_hash_key(x, y)] = i
			_hull_hash[_hash_key(coords[2 * e], coords[2 * e + 1])] = e
			
		hull = PoolIntArray()
		hull.resize(hull_size)
		var e = _hull_start
		for i in range(0, hull_size):
			hull[i] = e
			e = _hull_next[e]

		# trim typed triangle mesh arrays
		triangles = PoolIntArray()
		for i in range(0, triangles_len):
			triangles.append(_triangles[i])
		halfedges = PoolIntArray()
		for i in range(0, triangles_len):
			halfedges.append(_halfedges[i])
		
	func _hash_key(x, y):
		return fmod(floor(pseudo_angle(x - _cx, y - _cy) * _hash_size), _hash_size)
	
	func _legalize(a):
		var infinite_loop_iterator = 0
		var infinite_loop_iterator_inner = 0
		var i = 0
		var ar = 0

		# recursion eliminated with a fixed-size stack
		while infinite_loop_iterator < WHILE_LOOP_MAX_ITERATIONS:
			infinite_loop_iterator += 1
			if infinite_loop_iterator >= WHILE_LOOP_MAX_ITERATIONS:
				print("[godot-svg] Encountered an infinite loop during delaunay triangulation (legalize main loop)")
				return ar
			
			var b = _halfedges[a]

			# if the pair of triangles doesn't satisfy the Delaunay condition
			# (p1 is inside the circumcircle of [p0, pl, pr]), flip them,
			# then do the same check/flip recursively for the new pair of triangles
			#
			#           pl                    pl
			#          /||\                  /  \
			#       al/ || \bl            al/    \a
			#        /  ||  \              /      \
			#       /  a||b  \    flip    /___ar___\
			#     p0\   ||   /p1   =>   p0\---bl---/p1
			#        \  ||  /              \      /
			#       ar\ || /br             b\    /br
			#          \||/                  \  /
			#           pr                    pr
			#
			var a0 = a - a % 3
			ar = a0 + (a + 2) % 3

			if b == -1: # convex hull edge
				if i == 0:
					break
				i -= 1
				a = EDGE_STACK[i]
				continue

			var b0 = b - b % 3
			var al = a0 + (a + 1) % 3
			var bl = b0 + (b + 2) % 3

			var p0 = _triangles[ar]
			var pr = _triangles[a]
			var pl = _triangles[al]
			var p1 = _triangles[bl]

			var illegal = in_circle(
				coords[2 * p0], coords[2 * p0 + 1],
				coords[2 * pr], coords[2 * pr + 1],
				coords[2 * pl], coords[2 * pl + 1],
				coords[2 * p1], coords[2 * p1 + 1]
			)

			if illegal:
				_triangles[a] = p1
				_triangles[b] = p0

				var hbl = _halfedges[bl]

				# edge swapped on the other side of the hull (rare); fix the halfedge reference
				if hbl == -1:
					var e = _hull_start
					infinite_loop_iterator_inner
					while infinite_loop_iterator_inner < WHILE_LOOP_MAX_ITERATIONS:
						infinite_loop_iterator_inner += 1
						if infinite_loop_iterator_inner >= WHILE_LOOP_MAX_ITERATIONS:
							print("[godot-svg] Encountered an infinite loop during delaunay triangulation (legalize edge swapped on the other side of the hull)")
							return ar
						if _hull_tri[e] == bl:
							_hull_tri[e] = a
							break
						e = _hull_prev[e]
						if e == _hull_start:
							break
				_link(a, hbl)
				_link(b, _halfedges[ar])
				_link(ar, bl)

				var br = b0 + (b + 1) % 3

				# don't worry about hitting the cap: it can only happen on extremely degenerate input
				if i < EDGE_STACK.size():
					EDGE_STACK[i] = br
					i += 1
			
			else:
				if i == 0:
					break
				i -= 1
				a = EDGE_STACK[i]

		return ar
	
	func _link(a, b):
		_halfedges[a] = b
		if b != -1:
			_halfedges[b] = a
	
	# add a new triangle given vertex indices and adjacent half-edge ids
	func _add_triangle(i0, i1, i2, a, b, c):
		var t = triangles_len

		_triangles[t] = i0
		_triangles[t + 1] = i1
		_triangles[t + 2] = i2

		_link(t, a)
		_link(t + 1, b)
		_link(t + 2, c)

		triangles_len += 3

		return t
	
	func pseudo_angle(dx, dy):
		var denominator = (abs(dx) + abs(dy))
		if denominator == 0:
			return INF
		var p = dx / denominator
		return (3 - p if dy > 0 else 1 + p) / 4 # [0..1]
	
	func dist(ax, ay, bx, by):
		var dx = ax - bx
		var dy = ay - by
		return dx * dx + dy * dy
	
	func in_circle(ax, ay, bx, by, cx, cy, px, py):
		var dx = ax - px
		var dy = ay - py
		var ex = bx - px
		var ey = by - py
		var fx = cx - px
		var fy = cy - py

		var ap = dx * dx + dy * dy
		var bp = ex * ex + ey * ey
		var cp = fx * fx + fy * fy

		return (
			dx * (ey * cp - bp * fy) -
			dy * (ex * cp - bp * fx) +
			ap * (ex * fy - ey * fx) < 0
		)
	
	func circumradius(ax, ay, bx, by, cx, cy):
		var dx = bx - ax
		var dy = by - ay
		var ex = cx - ax
		var ey = cy - ay

		var bl = dx * dx + dy * dy
		var cl = ex * ex + ey * ey
		var denominator = (dx * ey - dy * ex)
		if denominator == 0:
			return INF
		var d = 0.5 / denominator

		var x = (ey * bl - dy * cl) * d
		var y = (dx * cl - ex * bl) * d

		return x * x + y * y
	
	func circumcenter(ax, ay, bx, by, cx, cy):
		var dx = bx - ax
		var dy = by - ay
		var ex = cx - ax
		var ey = cy - ay

		var bl = dx * dx + dy * dy
		var cl = ex * ex + ey * ey
		var denominator = (dx * ey - dy * ex)
		if denominator == 0:
			return INF
		var d = 0.5 / denominator

		var x = ax + (ey * bl - dy * cl) * d
		var y = ay + (dx * cl - ex * bl) * d

		return Vector2(x, y)
	
	func quicksort(ids: Array, dists: Array, left: int, right: int):
		if right - left <= 20:
			for i in range(left + 1, right + 1):
				var temp = ids[i]
				var temp_dist = dists[temp]
				var j = i - 1
				while j >= left && dists[ids[j]] > temp_dist:
					ids[j + 1] = ids[j]
					j -= 1
				ids[j + 1] = temp
		else:
			var median = (left + right) >> 1
			var i = left + 1
			var j = right
			swap(ids, median, i)
			if dists[ids[left]] > dists[ids[right]]:
				swap(ids, left, right)
			if dists[ids[i]] > dists[ids[right]]:
				swap(ids, i, right)
			if dists[ids[left]] > dists[ids[i]]:
				swap(ids, left, i)

			var temp = ids[i]
			var temp_dist = dists[temp]
			while true:
				while true:
					i += 1
					if not (dists[ids[i]] < temp_dist):
						break
				while true:
					j -= 1
					if not (dists[ids[j]] > temp_dist):
						break
				if j < i:
					break
				swap(ids, i, j)
			ids[left + 1] = ids[j]
			ids[j] = temp

			if right - i + 1 >= j - left:
				quicksort(ids, dists, i, right)
				quicksort(ids, dists, left, j - 1)
			else:
				quicksort(ids, dists, left, j - 1)
				quicksort(ids, dists, i, right)
	
	func swap(arr, i, j):
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp

# The subsequent code is adapted from constrainautor.js
# Copyright 2020, Marco Gunnink
# License: ISC License
# https://github.com/kninnug/Constrainautor/blob/master/LICENSE

class BitSet:
	var bs: Dictionary

	func _init(bs: Dictionary):
		self.bs = bs
	
	func add(idx: int):
		bs[idx] = true
		return self
	
	func delete(idx: int):
		bs.erase(idx)
		return self
	
	func set_bit(idx: int, val: bool):
		if val:
			bs[idx] = true
		elif bs.has(idx):
			bs.erase(idx)
		return val
	
	func has(idx: int):
		return bs.has(idx)
	
	static func from_length(length: int):
		return BitSet.new({})

# Constrain a triangulation from Delaunator, using (parts of) the algorithm
# in "A fast algorithm for generating constrained Delaunay triangulations" by
# S. W. Sloan.
class Constrainautor:
	func next_edge(e: int) -> int:
		return e - 2 if e % 3 == 2 else e + 1
	
	func prev_edge(e: int) -> int:
		return e + 2 if e % 3 == 0 else e - 1
	
	const U32NIL = pow(2, 31) - 1 # Max value of a Uint32Array: use as a sentinel for not yet defined 
	var del: Delaunator
	var vert_map: PoolIntArray
	var flips: BitSet
	var consd: BitSet

	# Make a Constrainautor.
	# @param del The triangulation output from Delaunator.
	# @param edges If provided, constrain these edges as by constrainAll.
	func _init(del, edges = null):
		if del.triangles.size() % 3 != 0 or del.halfedges.size() != del.triangles.size() or del.coords.size() % 2 != 0:
			print("[godot-svg] Delaunator output appears inconsistent.")
			return
		if del.triangles.size() < 3:
			print("[godot-svg] No edges in triangulation.")
		
		self.del = del;
		
		var num_points = del.coords.size() >> 1
		var num_edges = del.triangles.size()
		
		# Map every vertex id to the right-most edge that points to that vertex.
		vert_map = PoolIntArray()
		for i in range(0, num_points):
			vert_map.append(U32NIL)
		# Keep track of edges flipped while constraining
		flips = BitSet.from_length(num_edges)
		# Keep track of constrained edges
		consd = BitSet.from_length(num_edges)
		
		for e in range(0, num_edges):
			var v = del.triangles[e]
			if vert_map[v] == U32NIL:
				update_vert(e)
		
		if edges:
			constrain_all(edges)

	# Constrain the triangulation such that there is an edge between p1 and p2.
	# @param segP1 The index of one segment end-point in the coords array.
	# @param segP2 The index of the other segment end-point in the coords array.
	# @return The id of the edge that points from p1 to p2. If the 
	#         constrained edge lies on the hull and points in the opposite 
	#         direction (p2 to p1), the negative of its id is returned.
	func constrain_one(seg_p1: int, seg_p2: int):
		var infinite_loop_iterator = 0
		var start: int = vert_map[seg_p1]
		
		var triangles_size = del.triangles.size()
		
		# Loop over the edges touching segP1
		var edg: int = start
		while infinite_loop_iterator < WHILE_LOOP_MAX_ITERATIONS:
			infinite_loop_iterator += 1
			if infinite_loop_iterator >= WHILE_LOOP_MAX_ITERATIONS:
				print("[godot-svg] Encountered an infinite loop while constraining triangulation (edges touching segment p1)")
				return
			
			# edg points toward segP1, so its start-point is opposite it
			var p4 = del.triangles[edg] if edg < triangles_size else -1
			var nxt = next_edge(edg)
			
			# already constrained, but in reverse order
			if p4 == seg_p2:
				return protect(edg)
			
			# The edge opposite segP1
			var opp = prev_edge(edg)
			var p3 = del.triangles[opp] if opp < triangles_size else -1
			
			# already constrained
			if p3 == seg_p2:
				protect(nxt)
				return nxt
			
			# edge opposite segP1 intersects constraint
			if intersect_segments(seg_p1, seg_p2, p3, p4):
				edg = opp
				break
			
			var adj = del.halfedges[nxt] if nxt < del.halfedges.size() else -1
			# The next edge pointing to segP1
			edg = adj

			if not (edg != -1 && edg != start):
				break
		
		var con_edge = edg
		# Walk through the triangulation looking for further intersecting
		# edges and flip them. If an intersecting edge cannot be flipped,
		# assign its id to `rescan` and restart from there, until there are
		# no more intersects.
		var rescan = -1
		infinite_loop_iterator = 0
		while edg != -1 and infinite_loop_iterator < WHILE_LOOP_MAX_ITERATIONS:
			infinite_loop_iterator += 1
			if infinite_loop_iterator >= WHILE_LOOP_MAX_ITERATIONS:
				print("[godot-svg] Encountered an infinite loop while constraining triangulation (flipping intersecting edges)")
				return
			
			# edg is the intersecting half-edge in the triangle we came from
			# adj is now the opposite half-edge in the adjacent triangle, which
			# is away from segP1.
			var adj: int = del.halfedges[edg]
			# cross diagonal
			var bot: int = prev_edge(edg)
			var top: int = prev_edge(adj)
			var rgt: int = next_edge(adj)
			
			if adj == -1:
				print("[godot-svg] Adding delaunay constraint: Constraining edge exited the hull")
				return null
			
			if consd.has(edg): # assume consd is consistent
				print("[godot-svg] Adding delaunay constraint: Edge intersects already constrained edge")
				return null
			
			if (
				is_collinear(seg_p1, seg_p2, del.triangles[edg]) or
				is_collinear(seg_p1, seg_p2, del.triangles[adj])
			):
				print("[godot-svg] Adding delaunay constraint: Constraining edge intersects point")
				return null
			
			var convex = intersect_segments(
				del.triangles[edg],
				del.triangles[adj],
				del.triangles[bot],
				del.triangles[top]
			);
			
			# The quadrilateral formed by the two triangles adjoing edg is not
			# convex, so the edge can't be flipped. Continue looking for the
			# next intersecting edge and restart at this one later.
			if not convex:
				if rescan == -1:
					rescan = edg
				
				if del.triangles[top] == seg_p2:
					if edg == rescan:
						print("[godot-svg] Infinite loop: non-convex quadrilateral")
						return
					edg = rescan
					rescan = -1
					continue
				
				# Look for the next intersect
				if intersect_segments(seg_p1, seg_p2, del.triangles[top], del.triangles[adj]):
					edg = top
				elif intersect_segments(seg_p1, seg_p2, del.triangles[rgt], del.triangles[top]):
					edg = rgt
				elif rescan == edg:
					print("[godot-svg] Infinite loop: no further intersect after non-convex")
					return
				
				continue
			
			flip_diagonal(edg)
			
			# The new edge might still intersect, which will be fixed in the
			# next rescan.
			if intersect_segments(seg_p1, seg_p2, del.triangles[bot], del.triangles[top]):
				if rescan == -1:
					rescan = bot
				if rescan == bot:
					print("[godot-svg] Infinite loop: flipped diagonal still intersects")
					return
			
			# Reached the other segment end-point? Start the rescan.
			if del.triangles[top] == seg_p2:
				con_edge = top
				edg = rescan
				rescan = -1
			# Otherwise, for the next edge that intersects. Because we just
			# flipped, it's either edg again, or rgt.
			elif intersect_segments(seg_p1, seg_p2, del.triangles[rgt], del.triangles[top]):
				edg = rgt
		
		protect(con_edge)
		infinite_loop_iterator = 0
		var flipped = 0
		
		while infinite_loop_iterator < WHILE_LOOP_MAX_ITERATIONS:
			infinite_loop_iterator += 1
			if infinite_loop_iterator >= WHILE_LOOP_MAX_ITERATIONS:
				print("[godot-svg] Encountered an infinite loop while constraining triangulation (delete flips)")
				return
			
			# need to use var to scope it outside the loop, but re-initialize
			# to 0 each iteration
			var flip_keys = flips.bs.keys()
			flip_keys.sort()
			flipped = 0
			for flip_key in flip_keys:
				edg = int(flip_key)
				if flips.has(edg):
					flips.delete(edg)
					var adj = del.halfedges[edg]
					if adj == -1:
						continue
					flips.delete(adj)
				
					if not is_delaunay(edg):
						flip_diagonal(edg)
						flipped += 1
			
			if not (flipped > 0):
				break
		
		return find_edge(seg_p1, seg_p2)

	# Fix the Delaunay condition. It is no longer necessary to call this
	# method after constraining (many) edges, since constrainOne will do it 
	# after each.
	# @param deep If true, keep checking & flipping edges until all
	#        edges are Delaunay, otherwise only check the edges once.
	# @return The triangulation object.
	func delaunify(deep = false):
		var infinite_loop_iterator = 0
		var length = del.halfedges.size()
		
		while infinite_loop_iterator < WHILE_LOOP_MAX_ITERATIONS:
			infinite_loop_iterator += 1
			if infinite_loop_iterator >= WHILE_LOOP_MAX_ITERATIONS:
				print("[godot-svg] Encountered an infinite loop while constraining triangulation (delaunify main loop)")
				return self
			
			var flipped = 0
			for edg in range(0, length):
				if consd.has(edg):
					continue
				flips.delete(edg)
				
				var adj = del.halfedges[edg]
				if adj == -1:
					continue
				
				flips.delete(adj)
				if not is_delaunay(edg):
					flip_diagonal(edg)
					flipped += 1

			if not (deep && flipped > 0):
				break
		
		return self
	
	# Call constrainOne on each edge, and delaunify afterwards.
	# @param edges The edges to constrain: each element is an array with
	#        [p1, p2] which are indices into the points array originally 
	#        supplied to Delaunator.
	# @return The triangulation object.
	func constrain_all(edges: Array):
		var length = edges.size()
		for i in range(0, length):
			var e = edges[i]
			constrain_one(e[0], e[1])
		
		return self

	# Whether an edge is a constrained edge.
	# @param edg The edge id.
	# @return True if the edge is constrained.
	func is_constrained(edg: int):
		return consd.has(edg)
	
	# Find the edge that points from p1 -> p2. If there is only an edge from
	# p2 -> p1 (i.e. it is on the hull), returns the negative id of it.
	# @param p1 The index of the first point into the points array.
	# @param p2 The index of the second point into the points array.
	# @return The id of the edge that points from p1 -> p2, or the negative
	#         id of the edge that goes from p2 -> p1, or Infinity if there is
	#         no edge between p1 and p2.
	func find_edge(p1, p2):
		var infinite_loop_iterator = 0
		var start1 = vert_map[p2]
		var edg = start1
		var prv = -1
		# Walk around p2, iterating over the edges pointing to it
		while infinite_loop_iterator < WHILE_LOOP_MAX_ITERATIONS:
			infinite_loop_iterator += 1
			if infinite_loop_iterator >= WHILE_LOOP_MAX_ITERATIONS:
				print("[godot-svg] Encountered an infinite loop while constraining triangulation (find edge)")
				return
			
			var edg_value = del.triangles[edg] if edg < del.triangles.size() else -1
			if edg_value == p1:
				return edg
			prv = next_edge(edg)
			var prv_value = del.halfedges[prv] if prv < del.halfedges.size() else -1
			edg = prv_value
			if not (edg != -1 && edg != start1):
				break

		# Did not find p1 -> p2, the only option is that it is on the hull on
		# the 'left-hand' side, pointing p2 -> p1 (or there is no edge)
		var next_prv_edge = next_edge(prv)
		var next_prv_value = del.triangles[next_prv_edge] if next_prv_edge < del.triangles.size() else -1
		if next_prv_value == p1:
			return -prv

		return INF
	
	# Mark an edge as constrained, i.e. should not be touched by `delaunify`.
	# @private
	# @param edg The edge id.
	# @return If edg has an adjacent, returns that, otherwise -edg.
	func protect(edg: int):
		var adj = del.halfedges[edg]
		flips.delete(edg)
		consd.add(edg)
		
		if adj != -1:
			flips.delete(adj)
			consd.add(adj)
			return adj
		
		return -edg
	
	# Mark an edge as flipped, unless it is already marked as constrained.
	# @private
	# @param edg The edge id.
	# @return True if edg was not constrained.
	func mark_flip(edg: int):
		if consd.has(edg):
			return false
		var adj = del.halfedges[edg]
		if adj != -1:
			pass
			flips.add(edg)
			flips.add(adj)
		return true
	
	# Flip the edge shared by two triangles.
	# @private
	# @param edg The edge shared by the two triangles, must have an
	#        adjacent half-edge.
	# @return The new diagonal.
	func flip_diagonal(edg: int):
		# Flip a diagonal
		#                top                     edg
		#          o  <----- o            o <------  o 
		#         | ^ \      ^           |       ^ / ^
		#      lft|  \ \     |        lft|      / /  |
		#         |   \ \adj |           |  bot/ /   |
		#         | edg\ \   |           |    / /top |
		#         |     \ \  |rgt        |   / /     |rgt
		#         v      \ v |           v  / v      |
		#         o ----->  o            o   ------> o 
		#           bot                     adj

		var adj = del.halfedges[edg]
		var bot = prev_edge(edg)
		var lft = next_edge(edg)
		var top = prev_edge(adj)
		var rgt = next_edge(adj)
		var adj_bot = del.halfedges[bot]
		var adj_top = del.halfedges[top]
	
		if consd.has(edg): # assume consd is consistent
			print("[godot-svg] Trying to flip a constrained edge")
			return
		
		# move *edg to *top
		del.triangles[edg] = del.triangles[top]
		del.halfedges[edg] = adj_top
		if not flips.set_bit(edg, flips.has(top)):
			consd.set_bit(edg, consd.has(top))
		if adj_top != -1:
			del.halfedges[adj_top] = edg
		del.halfedges[bot] = top
		
		# move *adj to *bot
		del.triangles[adj] = del.triangles[bot]
		del.halfedges[adj] = adj_bot
		if not flips.set_bit(adj, flips.has(bot)):
			consd.set_bit(adj, consd.has(bot))
		if adj_bot != -1:
			del.halfedges[adj_bot] = adj
		del.halfedges[top] = bot
		
		mark_flip(edg)
		mark_flip(lft)
		mark_flip(adj)
		mark_flip(rgt)
		
		# mark flips unconditionally
		flips.add(bot)
		consd.delete(bot)
		flips.add(top)
		consd.delete(top)

		update_vert(edg)
		update_vert(lft)
		update_vert(adj)
		update_vert(rgt)

		return bot
	
	# Whether the two triangles sharing edg conform to the Delaunay condition.
	# As a shortcut, if the given edge has no adjacent (is on the hull), it is
	# certainly Delaunay.
	# @private
	# @param edg The edge shared by the triangles to test.
	# @return True if they are Delaunay.
	func is_delaunay(edg: int):
		var adj = del.halfedges[edg]
		if adj == -1:
			return true
		
		var p1 = del.triangles[prev_edge(edg)]
		var p2 = del.triangles[edg]
		var p3 = del.triangles[next_edge(edg)]
		var px = del.triangles[prev_edge(adj)]
		
		return not in_circle(p1, p2, p3, px)
	
	# Update the vertex -> incoming edge map.
	# @private
	# @param start The id of an *outgoing* edge.
	# @return The id of the right-most incoming edge.
	func update_vert(start: int):
		var v = del.triangles[start]
		
		# When iterating over incoming edges around a vertex, we do so in
		# clockwise order ('going left'). If the vertex lies on the hull, two
		# of the edges will have no opposite, leaving a gap. If the starting
		# incoming edge is not the right-most, we will miss edges between it
		# and the gap. So walk counter-clockwise until we find an edge on the
		# hull, or get back to where we started.
		
		var inc = prev_edge(start)
		var adj = del.halfedges[inc]
		var encountered_adj = {}
		while adj != -1 and adj != start:
			if encountered_adj.has(adj):
				print("[godot-svg] Encountered an infinite loop while constraining triangulation (update vert)")
				return inc
			encountered_adj[adj] = true
			
			inc = prev_edge(adj)
			adj = del.halfedges[inc]
		
		vert_map[v] = inc
		return inc
	
	# Whether the segment between [p1, p2] intersects with [p3, p4]. When the
	# segments share an end-point (e.g. p1 == p3 etc.), they are not considered
	# intersecting.
	# @private
	# @param p1 The index of point 1 into this.del.coords.
	# @param p2 The index of point 2 into this.del.coords.
	# @param p3 The index of point 3 into this.del.coords.
	# @param p4 The index of point 4 into this.del.coords.
	# @return True if the segments intersect.
	func intersect_segments(p1, p2, p3, p4):
		# If the segments share one of the end-points, they cannot intersect
		# (provided the input is properly segmented, and the triangulation is
		# correct), but intersectSegments will say that they do. We can catch
		# it here already.
		if p1 == null or p2 == null or p3 == null or p4 == null:
			return false
		if p1 == p3 or p1 == p4 or p2 == p3 or p2 == p4:
			return false
		var intersection = Geometry.segment_intersects_segment_2d(
			Vector2(del.coords[p1 * 2], del.coords[p1 * 2 + 1]),
			Vector2(del.coords[p2 * 2], del.coords[p2 * 2 + 1]),
			Vector2(del.coords[p3 * 2], del.coords[p3 * 2 + 1]),
			Vector2(del.coords[p4 * 2], del.coords[p4 * 2 + 1])
		)
		return intersection != null
	
	# Whether point px is in the circumcircle of the triangle formed by p1, p2,
	# and p3 (which are in counter-clockwise order).
	# @param p1 The index of point 1 into this.del.coords.
	# @param p2 The index of point 2 into this.del.coords.
	# @param p3 The index of point 3 into this.del.coords.
	# @param px The index of point x into this.del.coords.
	# @return True if (px, py) is in the circumcircle.
	func in_circle(p1: int, p2: int, p3: int, px: int):
		return RobustPredicates.incircle(
			del.coords[p1 * 2], del.coords[p1 * 2 + 1],
			del.coords[p2 * 2], del.coords[p2 * 2 + 1],
			del.coords[p3 * 2], del.coords[p3 * 2 + 1],
			del.coords[px * 2], del.coords[px * 2 + 1]
		) < 0.0
	
	# Whether point p1, p2, and p are collinear.
	# @private
	# @param p1 The index of segment point 1 into this.del.coords.
	# @param p2 The index of segment point 2 into this.del.coords.
	# @param p The index of the point p into this.del.coords.
	# @return True if the points are collinear.
	func is_collinear(p1: int, p2: int, p: int):
		return RobustPredicates.orient2d(
			del.coords[p1 * 2], del.coords[p1 * 2 + 1],
			del.coords[p2 * 2], del.coords[p2 * 2 + 1],
			del.coords[p * 2], del.coords[p * 2 + 1]
		) == 0.0

# The subsequent code is licensed under this project.

class DelaunaySorting:
	static func sort_x(a, b):
		return a[2].y > b[2].y # compare max x position

# Solve for polygon with holes
static func delaunay_polygon_2d(points: Array, hole_indices = []):
	# 1. Remove duplicate points from points array, Constrainautor can see this as an error.
	# 2. Add hole polygon vertex pairs as constrained edges
	var points_original_length = points.size()
	var points_deduped = Array()
	var dedupe_count = 0
	var edges = Array()
	var first_hole_index = -1 # hole_indices[0] if hole_indices.size() > 0 else points.size()
	for i in range(0, points_original_length - 1):
		if (
			points[i].is_equal_approx(points[i + 1])
		):
			dedupe_count += 1
		else:
			points_deduped.push_back(points[i])
			var edge_i = i - dedupe_count
			if (
				i > first_hole_index - dedupe_count and
				not hole_indices.has(edge_i)
			):
				edges.push_back([edge_i, edge_i + 1])
		if i == points_original_length - 2:
			points_deduped.push_back(points[i + 1])
	
	# Create a delaunay triangulation of points
	var delaunay = Delaunator.from(points_deduped)
	
	# Constrain edges that belong to the shape we're trying to triangulate
	var constrainautor = Constrainautor.new(delaunay)
	for edge in edges:
		constrainautor.constrain_one(edge[0], edge[1])
	
	# Calculate fill rule per triangle
	var triangles = PoolIntArray()
	var coords = delaunay.coords
	var _triangles = delaunay.triangles
	var n = coords.size() >> 1
	
	var all_collision_segments = []
	for i in range(0, n - 1):
		if hole_indices.find(i + 1) == -1:
			var pos_a = Vector2(coords[i * 2], coords[i * 2 + 1])
			var pos_b = Vector2(coords[(i + 1) * 2], coords[(i + 1) * 2 + 1])
			var segment = PoolVector2Array([
				pos_a,
				pos_b,
				Vector2(min(pos_a.x, pos_b.x), max(pos_a.x, pos_b.x))
			])
			all_collision_segments.push_back(segment)
	all_collision_segments.sort_custom(DelaunaySorting, "sort_x")
	
	for i in range(0, _triangles.size(), 3):
		var is_fill = true
		var insideness = 0
		var check_point = Vector2()
		var c1 = Vector2(coords[_triangles[i] * 2], coords[_triangles[i] * 2 + 1])
		var c2 = Vector2(coords[_triangles[i + 1] * 2], coords[_triangles[i + 1] * 2 + 1])
		var c3 = Vector2(coords[_triangles[i + 2] * 2], coords[_triangles[i + 2] * 2 + 1])
		check_point += c1 + c2 + c3
		check_point /= Vector2(3.0, 3.0)

		for segment in all_collision_segments:
			if segment[2].x > check_point.x:
				continue
			
			var segment_start: Vector2 = segment[0]
			var segment_end: Vector2 = segment[1]
			var check_end_point = Vector2(
				check_point.x,
				min(segment_start.y, segment_end.y) - 1
			)
			if Geometry.segment_intersects_segment_2d(check_point, check_end_point, segment_start, segment_end):
				if segment_start.x < segment_end.x:
					insideness += 1
				else:
					insideness -= 1
					
			# We can short circuit due to x-sorting of all_collision_segments
			if segment_start.x < check_point.x and segment_end.x < check_point.x:
				break
		
		is_fill = int(abs(insideness)) % 2 == 1
		if is_fill:
			var triangles_size = triangles.size()
			triangles.resize(triangles_size + 3)
			triangles[triangles_size] = _triangles[i]
			triangles[triangles_size + 1] = _triangles[i + 1]
			triangles[triangles_size + 2] = _triangles[i + 2]
			
	return triangles
