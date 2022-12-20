# Adapted from earcut.js
# License: ISC License
# https://github.com/mapbox/earcut/blob/master/LICENSE

class_name SVGEarcut

class PolygonNode:
	var i = 0
	var x = 0.0
	var y = 0.0
	var prev = null
	var next = null
	var steiner = false
	var z = 0.0;
	var prev_z = null
	var next_z = null
	
	func _init(i, position):
		self.i = i
		self.x = position.x
		self.y = position.y

class Sorting:
	static func compare_x(a, b):
		return true if a.x < b.x else false

static func signed_area(data, start, end):
	var sum = 0
	var i = start
	var j = end - 1
	while i < end:
		sum += (data[j].x - data[i].x) * (data[i].y + data[j].y)
		j = i
		i += 1
	return sum

static func insert_node(i, position, last):
	var p = PolygonNode.new(i, position)
	if not last:
		p.prev = p
		p.next = p
	else:
		p.next = last.next
		p.prev = last
		last.next.prev = p
		last.next = p
	return p

static func remove_node(p):
	p.next.prev = p.prev
	p.prev.next = p.next

static func equals(p1, p2):
	return p1.x == p2.x and p1.y == p2.y

static func linked_list(data, start, end, clockwise):
	var last = null
	if clockwise == (signed_area(data, start, end) > 0):
		for i in range(start, end):
			last = insert_node(i, data[i], last)
	else:
		for i in range(end - 1, start - 1, -1):
			last = insert_node(i, data[i], last)
	if last and equals(last, last.next):
		remove_node(last)
		last = last.next
	return last

static func get_leftmost(start):
	var p = start
	var leftmost = start
	while true:
		if p.x < leftmost.x or (p.x == leftmost.x and p.y < leftmost.y):
			leftmost = p
		p = p.next
		if not (p != start):
			break
	return leftmost

static func area(p, q, r):
	return (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y)

static func point_in_triangle(ax, ay, bx, by, cx, cy, px, py):
	return (
		(cx - px) * (ay - py) >= (ax - px) * (cy - py) and
		(ax - px) * (by - py) >= (bx - px) * (ay - py) and
		(bx - px) * (cy - py) >= (cx - px) * (by - py)
	)

static func locally_inside(a, b):
	return (
		area(a, b, a.next) >= 0.0 and area(a, a.prev, b) >= 0.0
		if area(a.prev, a, a.next) < 0.0 else
		area(a, b, a.prev) < 0.0 or area(a, a.next, b) < 0.0
	)

static func sector_contains_sector(m, p):
	return area(m.prev, m, p.prev) < 0.0 and area(p.next, m, m.next) < 0.0

static func find_hole_bridge(hole, outer_node):
	var p = outer_node
	var hx = hole.x
	var hy = hole.y
	var qx = -INF
	var m = null
	while true:
		if hy <= p.y and p.next.y and p.next.y != p.y:
			var x = p.x + (hy - p.y) * (p.next.x - p.x) / (p.next.y - p.y)
			if x <= hx and x > qx:
				qx = x
				m = p if p.x < p.next.x else p.next
				if x == hx:
					return m
		p = p.next
		if not (p != outer_node):
			break
	if not m:
		return null
	
	var stop = m
	var mx = m.x
	var my = m.y
	var tangential_min = INF
	var tangential
	p = m
	while true:
		if (
			hx >= p.x and p.x > mx and hx != p.x and 
			point_in_triangle(hx if hy < my else qx, hy, mx, my, qx if hy < my else hx, hy, p.x, p.y)
		):
			tangential = abs(hy - p.y) / (hx - p.x)
			if (
				locally_inside(p, hole) and
				(tangential < tangential_min or (tangential == tangential_min and (p.x > m.x or (p.x == m.x and sector_contains_sector(m, p)))))
			):
				m = p
				tangential_min = tangential
		p = p.next
		if not (p != stop):
			break
	return m

static func split_polygon(a, b):
	var a2 = PolygonNode.new(a.i, Vector2(a.x, a.y))
	var b2 = PolygonNode.new(b.i, Vector2(b.x, b.y))
	var an = a.next
	var bp = b.prev
	a.next = b
	b.prev = a
	a2.next = an
	an.prev = a2
	b2.next = a2
	a2.prev = b2
	bp.next = b2
	b2.prev = bp
	return b2

static func filter_points(start, end = null):
	if not start:
		return start
	if not end:
		end = start
	var p = start
	var again
	while true:
		again = false
		if not p.steiner and (equals(p, p.next) or area(p.prev, p, p.next) == 0):
			remove_node(p)
			p = p.prev
			end = p.prev
			if p == p.next:
				break
			again = true
		else:
			p = p.next
		if not (again or p != end):
			break
	return end

static func eliminate_hole(hole, outer_node):
	var bridge = find_hole_bridge(hole, outer_node)
	if not bridge:
		return outer_node
	var bridge_reverse = split_polygon(bridge, hole)
	filter_points(bridge_reverse, bridge_reverse.next)
	return filter_points(bridge, bridge.next)

static func eliminate_holes(data, hole_indices, outer_node, is_outer_clockwise):
	var queue = []
	var hole_count = hole_indices.size()
	var start = null
	var end = null
	var list = null
	
	for i in range(0, hole_count):
		start = hole_indices[i]
		end = hole_indices[i + 1] if i < hole_count - 1 else data.size()
		list = linked_list(data, start, end, !is_outer_clockwise)
		if list == list.next:
			list.steiner = true
		queue.push_back(get_leftmost(list))
	
	queue.sort_custom(Sorting, "compare_x")
	
	for i in range(0, queue.size()):
		outer_node = eliminate_hole(queue[i], outer_node)
	
	return outer_node

static func sort_linked(list):
	var p = null
	var q = null
	var e = null
	var tail = null
	var num_merges = 0
	var p_size = 0
	var q_size = 0
	var in_size = 1
	while true:
		p = list
		list = null
		tail = null
		num_merges = 0
		while p:
			num_merges += 1
			q = p
			p_size = 0
			for i in range(0, in_size):
				p_size += 1
				q = q.next_z
				if not q:
					break
			q_size = in_size
			while p_size > 0 or (q_size > 0 and q):
				if p_size != 0 and (q_size == 0 or not q or p.z <= q.z):
					e = p
					p = p.next_z
					p_size -= 1
				else:
					e = q
					q = q.next_z
					q_size -= 1
				if tail:
					tail.next_z = e
				else:
					list = e
				e.prev_z = tail
				tail = e
			p = q
		tail.next_z = null
		in_size *= 2
		if not (num_merges > 1):
			break
	return list

static func z_order(x, y, min_x, min_y, inv_size):
	x = int(x - min_x) * int(inv_size) | int(0);
	y = int(y - min_y) * int(inv_size) | int(0);

	x = (x | (x << 8)) & 0x00FF00FF;
	x = (x | (x << 4)) & 0x0F0F0F0F;
	x = (x | (x << 2)) & 0x33333333;
	x = (x | (x << 1)) & 0x55555555;

	y = (y | (y << 8)) & 0x00FF00FF;
	y = (y | (y << 4)) & 0x0F0F0F0F;
	y = (y | (y << 2)) & 0x33333333;
	y = (y | (y << 1)) & 0x55555555;

	return x | (y << 1);

static func index_curve(start, min_x, min_y, inv_size):
	var p = start
	while true:
		if p.z == 0.0:
			p.z = z_order(p.x, p.y, min_x, min_y, inv_size)
		p.prev_z = p.prev
		p.next_z = p.next
		p = p.next
		if not (p != start):
			break
	p.prev_z.next_z = null
	p.prev_z = null
	sort_linked(p)

static func is_ear(ear):
	var a = ear.prev
	var b = ear
	var c = ear.next
	if area(a, b, c) >= 0.0:
		return false
	var ax = a.x
	var bx = b.x
	var cx = c.x
	var ay = a.y
	var by = b.y
	var cy = c.y
	var x0 = (ax if ax < cx else cx) if ax < bx else (bx if bx < cx else cx)
	var y0 = (ay if ay < cy else cy) if ay < by else (by if by < cy else cy)
	var x1 = (ax if ax > cx else cx) if ax > bx else (bx if bx > cx else cx)
	var y1 = (ay if ay > cy else cy) if ay > by else (by if by > cy else cy)
	var p = c.next
	while p != a:
		if (
			p.x >= x0 and p.x <= x1 and p.y >= y0 and p.y <= y1 and
			point_in_triangle(ax, ay, bx, by, cx, cy, p.x, p.y) and
			area(p.prev, p, p.next) >= 0
		):
			return false
		p = p.next
	return true
	
static func is_ear_hashed(ear, min_x, min_y, inv_size):
	var a = ear.prev
	var b = ear
	var c = ear.next
	if area(a, b, c) >= 0.0:
		return false
	var ax = a.x
	var bx = b.x
	var cx = c.x
	var ay = a.y
	var by = b.y
	var cy = c.y
	var x0 = (ax if ax < cx else cx) if ax < bx else (bx if bx < cx else cx)
	var y0 = (ay if ay < cy else cy) if ay < by else (by if by < cy else cy)
	var x1 = (ax if ax > cx else cx) if ax > bx else (bx if bx > cx else cx)
	var y1 = (ay if ay > cy else cy) if ay > by else (by if by > cy else cy)
	
	var min_z = z_order(x0, y0, min_x, min_y, inv_size)
	var max_z = z_order(x1, y1, min_x, min_y, inv_size)

	var p = ear.prev_z
	var n = ear.next_z

	while p && p.z >= min_z && n && n.z <= max_z:
		if (
			p.x >= x0 and p.x <= x1 and p.y >= y0 and p.y <= y1 and p != a and p != c and
			point_in_triangle(ax, ay, bx, by, cx, cy, p.x, p.y) and area(p.prev, p, p.next) >= 0
		):
			return false
		p = p.prev_z
		if (
			n.x >= x0 and n.x <= x1 and n.y >= y0 and n.y <= y1 and n != a and n != c and
			point_in_triangle(ax, ay, bx, by, cx, cy, n.x, n.y) and area(n.prev, n, n.next) >= 0
		):
			return false
		n = n.next_z
	while p && p.z >= min_z:
		if (
			p.x >= x0 and p.x <= x1 and p.y >= y0 and p.y <= y1 and p != a and p != c and
			point_in_triangle(ax, ay, bx, by, cx, cy, p.x, p.y) and area(p.prev, p, p.next) >= 0
		):
			return false
		p = p.prev_z
	while n && n.z <= max_z:
		if (
			n.x >= x0 and n.x <= x1 and n.y >= y0 and n.y <= y1 and n != a and n != c and
			point_in_triangle(ax, ay, bx, by, cx, cy, n.x, n.y) and area(n.prev, n, n.next) >= 0
		):
			return false
		n = n.next_z
	return true

static func intersects(p1, q1, p2, q2):
	if p1 and q1 and p2 and q2:
		return Geometry.segment_intersects_segment_2d(
			Vector2(p1.x, p1.y),
			Vector2(p2.x, p2.y),
			Vector2(q1.x, q1.y),
			Vector2(q2.x, q2.y)
		) != null
	return false

static func cure_local_intersections(start, triangles):
	var p = start
	while true:
		var a = p.prev
		var b = p.next.next
		if not equals(a, b) and intersects(a, p, p.next, b) and locally_inside(a, b) and locally_inside(b, a):
			triangles.push_back(a.i)
			triangles.push_back(p.i)
			triangles.push_back(b.i)
			remove_node(p)
			remove_node(p.next)
			p = b
			start = b
		p  = p.next
		if not (p != start):
			break
	return filter_points(p)

static func intersects_polygon(a, b):
	var p = a
	while true:
		if p.i != a.i and p.next.i != a.i and p.i != b.i and p.next.i != b.i and intersects(p, p.next, a, b):
			return true
		p = p.next
		if not (p != a):
			break
	return false

static func middle_inside(a, b):
	var p = a
	var inside = false
	var px = (a.x + b.x) / 2.0
	var py = (a.y + b.y) / 2.0
	while true:
		if (
			(
				(p.y > py) != (p.next.y > py)
			) and
			p.next.y != p.y and
			(
				px < (p.next.x - p.x) * (py - p.y) / (p.next.y - p.y) + p.x
			)
		):
			inside = !inside;
		if not (p != a):
			break
	return inside

static func is_valid_diagonal(a, b):
	return (
		a.next.i != b.i and a.prev.i != b.i and !intersects_polygon(a, b) and
		(
			locally_inside(a, b) and locally_inside(b, a) and middle_inside(a, b) and
			(
				area(a.prev, a, b.prev) or area(a, b.prev, b)
			) or
			equals(a, b) and area(a.prev, a, a.next) > 0 and area(b.prev, b, b.next) > 0
		)
	)

static func split_earcut(start, triangles, min_x, min_y, inv_size):
	var a = start
	while true:
		var b = a.next.next
		while b != a.prev:
			if a.i != b.i and is_valid_diagonal(a, b):
				var c = split_polygon(a, b)
				a = filter_points(a, a.next)
				c = filter_points(c, c.next)
				earcut_linked(a, triangles, min_x, min_y, inv_size, 0)
				earcut_linked(c, triangles, min_x, min_y, inv_size, 0)
				return
			b = b.next
		a = a.next
		if not (a != start):
			break

static func earcut_linked(ear, triangles, min_x, min_y, inv_size, process_pass):
	if not ear:
		return
	if not process_pass and inv_size:
		index_curve(ear, min_x, min_y, inv_size)
	var stop = ear
	var prev = null
	var next = null
	while ear.prev != ear.next:
		prev = ear.prev
		next = ear.next
		if is_ear_hashed(ear, min_x, min_y, inv_size) if inv_size else is_ear(ear):
			triangles.push_back(prev.i)
			triangles.push_back(ear.i)
			triangles.push_back(next.i)
			remove_node(ear)
			ear = next.next
			stop = next.next
			continue
		ear = next
		if ear == stop:
			if not process_pass:
				earcut_linked(filter_points(ear), triangles, min_x, min_y, inv_size, 1)
			elif process_pass == 1:
				ear = cure_local_intersections(filter_points(ear), triangles)
				earcut_linked(ear, triangles, min_x, min_y, inv_size, 2)
			elif process_pass == 2:
				split_earcut(ear, triangles, min_x, min_y, inv_size) 
			break

static func earcut_polygon_2d(data, hole_indices = [], is_outer_clockwise = true):
	
	var has_holes = hole_indices.size() > 0
	var outer_length = hole_indices[0] if has_holes else data.size()
	var outer_node = linked_list(data, 0, outer_length, is_outer_clockwise)
	var triangles = []
	
	if not outer_node or outer_node.next == outer_node.prev:
		return triangles
	
	var min_x = 0.0
	var min_y = 0.0
	var max_x = 0.0
	var max_y = 0.0
	var x = 0.0
	var y = 0.0
	var inv_size = 0.0
	
	if has_holes:
		outer_node = eliminate_holes(data, hole_indices, outer_node, is_outer_clockwise)
	
	if data.size() > 80:
		min_x = INF
		max_x = -INF
		min_y = INF
		max_y = -INF
		
		for i in range(0, outer_length):
			x = data[i].x
			y = data[i].y
			if x < min_x:
				min_x = x
			if y < min_y:
				min_y = y
			if x > max_x:
				max_x = x
			if y > max_y:
				max_y = y
		
		inv_size = max(max_x - min_x, max_y - min_y)
		inv_size = 32767.0 / inv_size if inv_size != 0.0 else 0.0
	
	earcut_linked(outer_node, triangles, min_x, min_y, inv_size, 0)
	
	return triangles
