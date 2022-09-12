class_name SVGClipper

enum VertexFlag {
	NONE = 0,
	OPEN_START = 1,
	OPEN_END = 2,
	LOCAL_MAX = 4,
	LOCAL_MIN = 8
}

enum OutRecFlag {
	INNER,
	OUTER,
	OPEN
}

enum ClipType {
	NONE,
	INTERSECTION,
	UNION,
	DIFFERENCE,
	XOR
}

enum PathType {
	SUBJECT,
	CLIP
}

enum FillRule {
	EVEN_ODD,
	NON_ZERO,
	POSITIVE,
	NEGATIVE
}

const CLIPPER_HORIZONTAL = -INF

class Vertex:
	var pt = Vector2()
	var next
	var prev
	var flags = 0
	
	func _init():
		next = self
		prev = self

class LocalMinima:
	var vertex = Vertex.new()
	var polytype = PathType.SUBJECT
	var is_open = false

class Scanline:
	var y = 0
	var next
	
	func _init():
		next = self

class IntersectNode:
	var pt = Vector2()
	var edge1 = Active.new()
	var edge2 = Active.new()

class OutPt:
	var pt = Vector2()
	var next
	var prev
	
	func _init():
		next = self
		prev = self

class OutRec:
	var idx = 0
	var owner
	var start_e = Active.new()
	var end_e = Active.new()
	var pts = OutPt.new()
	var polypath = []
	var flag = 0
	
	func _init():
		owner = self

class Active:
	var bot = Vector2()
	var curr = Vector2()
	var top = Vector2()
	var dx = 0.0
	var wind_dx = 1
	var wind_cnt = 0
	var wind_cnt2 = 0
	var outrec = null
	var next_in_ael
	var prev_in_ael
	var next_in_sel
	var prev_in_sel
	var merge_jump
	var vertex_top = Vertex.new()
	var local_min = LocalMinima.new()
	
	func _init():
		next_in_ael = self
		prev_in_ael = self
		next_in_sel = self
		prev_in_sel = self
		merge_jump = self

func loc_min_sorter(loc_min_1, loc_min_2):
	return loc_min_2.vertex.pt.y < loc_min_1.vertex.pt.y

# PolyPath methods ...

class PolyPath:
	var _childs = []
	var _parent = null
	var _path = null
	
	func _init(parent = null, path = null):
		_parent = parent
		_path = path
	
	func clear():
		for i in range(0, _childs.size()):
			_childs[i].clear()
		_childs.clear()
	
	func child_count():
		return _childs.size()
	
	func add_child(path):
		var child = PolyPath.new(self, path)
		_childs.push_back(child)
		return child
	
	func get_child(index):
		return _childs[index]
	
	func get_parent():
		return _parent
	
	func get_path():
		return _path
	
	func is_hole() -> bool:
		var result = true
		var pp = _parent
		while pp:
			result = !result
			pp = pp._parent
		return result

# miscellaneous functions ...

class ClipperUtil:
	static func is_odd(val):
		return val % 2 == 1

	static func is_hot_edge(e):
		return e.outrec

	static func is_open(e):
		return e.local_min.is_open

	static func is_start_side(e):
		return e == e.outrec.start_e

	static func swap_sides(outrec):
		var e2 = outrec.start_e
		outrec.start_e = outrec.end_e
		outrec.end_e = e2
		outrec.pts = outrec.pts.next

	static func fix_orientation(e):
		var result = true
		var e2 = e
		while e2.prev_in_ael:
			e2 = e2.prev_in_ael
			if e2.outrec and not is_open(e2):
				result = !result
		if result != is_start_side(e):
			if result:
				e.outrec.flag = OutRecFlag.OUTER
			else:
				e.outrec.flag = OutRecFlag.INNER
			swap_sides(e.outrec)
			return true
		else:
			return false

	static func is_horizontal(e) -> bool:
		return e.dx == CLIPPER_HORIZONTAL

	static func top_x(edge, current_y):
		return edge.top.x if current_y == edge.top.y else edge.bot.x + round(edge.dx * (current_y - edge.bot.y))

	static func get_top_delta_x(e1, e2):
		return top_x(e2, e1.top.y) - e1.top.x if e1.top.y > e2.top.y else e2.top.x - top_x(e1, e2.top.y)

	static func move_edge_to_follow_left_in_ael(e, e_left):
		var ael_prev = Active.new()
		var ael_next = Active.new()
		ael_prev = e.prev_in_ael
		ael_next = e.next_in_ael
		ael_prev.next_in_ael = ael_next
		if ael_next:
			ael_next.prev_in_ael = ael_prev
		e.next_in_ael = e_left.next_in_ael
		e_left.next_in_ael.prev_in_ael = e
		e.prev_in_ael = e_left
		e_left.next_in_ael = e

	static func e2_inserts_before_e1(e1, e2, prefer_left):
		if prefer_left:
			return get_top_delta_x(e1, e2) < 0 if e2.curr.x == e1.curr.x else e2.curr.x < e1.curr.x
		else:
			return get_top_delta_x(e1, e2) <= 0 if e2.curr.x == e1.curr.x else e2.curr.x <= e1.curr.x

	static func get_poly_type(e):
		return e.local_min.polytype

	static func is_same_poly_type(e1, e2):
		return e1.local_min.polytype == e2.local_min.polytype

	static func get_intersect_point(e1, e2):
		var b1 = 0.0
		var b2 = 0.0
		if e1.dx == e2.dx:
			return Vector2(top_x(e1, e1.curr.y), e1.curr.y)
		
		if e1.dx == 0:
			if is_horizontal(e2):
				return Vector2(e1.bot.x, e2.bot.y)
			b2 = e2.bot.y - (e2.bot.x / e2.dx)
			return Vector2(e1.bot.x, round(e1.bot.x / e2.dx + b2))
		elif e2.dx == 0:
			if is_horizontal(e1):
				return Vector2(e2.bot.x, e1.bot.y)
			b1 = e1.bot.y - (e1.bot.x / e1.dx)
			return Vector2(e2.bot.x, round(e2.bot.x / e1.dx + b1))
		else:
			b1 = e1.bot.x - e1.bot.y * e1.dx
			b2 = e2.bot.x - e2.bot.y * e2.dx
			var q = (b2 - b1) / (e1.dx - e2.dx)
			return (
				Vector2(round(e1.dx * q + b1), round(q))
				if (abs(e1.dx) < abs(e2.dx))
				else Vector2(round(e2.dx * q + b2), round(1))
			)

	static func set_dx(e):
		var dy = e.top.y - e.bot.y
		e.dx = CLIPPER_HORIZONTAL if (dy == 0) else float(e.top.x - e.bot.x) / dy

	static func next_vertex(e):
		return e.vertex_top.next if (e.wind_dx > 0) else e.vertex_top.prev

	static func is_maxima(e):
		return e.vertex_top.flags & VertexFlag.LOCAL_MAX

	static func terminate_hot_open(e):
		if e.outrec.start_e == e:
			e.outrec.start_e = null
		else:
			e.outrec.end_e = null
		e.outrec = null

	static func get_maxima_pair(e):
		var e2 = Active.new()
		if is_horizontal(e):
			e2 = e.prev_in_ael
			while e2 and e2.curr.x >- e.top.x:
				if e2.vertex_top == e.vertex_top:
					return e2
				e2 = e2.prev_in_ael
			e2 = e.next_in_ael
			while e2 and (top_x(e2, e.top.x) <= e.top.x):
				if e2.vertex_top == e.vertex_top:
					return e2
				e2 = e2.next_in_ael
			return null
		else:
			e2 = e.next_in_ael
			while e2:
				if e2.vertex_top == e.vertex_top:
					return e2
				e2 = e2.next_in_ael
			return null

	static func point_count(op):
		if !op:
			return 0
		var p = op
		var cnt = 0
		p = p.next
		cnt += 1
		while p != op:
			p = p.next
			cnt += 1
		return cnt

	static func dispose_out_pts(op):
		if !op:
			return
		op.prev.next = null
		while op:
			var tmp_pp = op
			op = op.next

	static func intersect_list_sort(node1, node2):
		return node2.pt.y < node1.pt.y

	static func set_orientation(outrec, e1, e2):
		outrec.start_e = e1
		outrec.end_e = e2
		e1.outrec = outrec
		e2.outrec = outrec

	static func swap_outrecs(e1, e2):
		var or1 = e1.outrec
		var or2 = e2.outrec
		if or1 == or2:
			var e = or1.start_e
			or1.start_e = or1.end_e
			or1.end_e = e
			return
		if or1:
			if e1 == or1.start_e:
				or1.start_e = e2
			else:
				or1.end_e = e2
		if or2:
			if e2 == or2.start_e:
				or2.start_e = e1
			else:
				or2.end_e = e1
		e1.outrec = or2
		e2.outrec = or1

	static func edges_adjacent_in_sel(inode):
		return (inode.edge1.next_in_sel == inode.edge2) || (inode.edge1.prev_in_sel == inode.edge2)

# Clipper class methods ...

class Clipper:
	var _actives = null
	var _sel = null
	var _scanline_list = []
	var _curr_loc_min = null
	var _outrec_list = []
	var _minima_list = []
	var _minima_list_sorted = false
	var _has_open_paths = false
	var _vertex_list = []
	var _fillrule = null
	var _cliptype = null
	var _intersect_list = []
	
	func _init():
		clear()
	
	func clean_up():
		while _actives:
			delete_from_ael(_actives)
		_scanline_list = []
		dispose_all_out_recs()
	
	func clear():
		dispose_vertices_and_local_minima()
		if _minima_list.size() > 0:
			_curr_loc_min = _minima_list.front()
		else:
			_curr_loc_min = null
		_minima_list_sorted = false
		_has_open_paths = false
	
	func reset():
		if not _minima_list_sorted:
			_minima_list.sort_custom(self, "loc_min_sorter")
			_minima_list_sorted = true
		for i in _minima_list:
			insert_scanline(i.vertex.pt.y)
		if _minima_list.size() > 0:
			_curr_loc_min = _minima_list.front()
		else:
			_curr_loc_min = null
		
		_actives = null
		_sel = null
	
	func insert_scanline(y):
		_scanline_list.push_back(y)
	
	func pop_scanline(y_container):
		if _scanline_list.size() == 0:
			return false
		y_container.y = _scanline_list.front()
		_scanline_list.pop_front()
		while _scanline_list.size() > 0 and y_container.y == _scanline_list.front():
			_scanline_list.pop_front()
		return true
	
	func pop_local_minima(y, local_minima_container):
		if _curr_loc_min == _minima_list.back() or _curr_loc_min.vertex.pt.y != y:
			return false
		local_minima_container.local_minima = _curr_loc_min
		var curr_loc_min_index = _minima_list.find(_curr_loc_min)
		if curr_loc_min_index != -1:
			if curr_loc_min_index < _minima_list.size() - 1:
				_curr_loc_min = _minima_list[curr_loc_min_index + 1]
			else:
				_curr_loc_min = null
		return true
	
	func dispose_all_out_recs():
		for i in _outrec_list:
			if i.pts:
				ClipperUtil.dispose_out_pts(i.pts)
			# delete
		_outrec_list.clear()
	
	func dispose_vertices_and_local_minima():
		for ml_iter in _minima_list:
			pass # delete
		_minima_list.clear()
		for vl_iter in _vertex_list:
			pass # delete
		_vertex_list.clear()
	
	func add_loc_min(vert, polytype, is_open):
		if VertexFlag.LOCAL_MIN & vert.flags:
			return
		vert.flags |= VertexFlag.LOCAL_MIN
		
		var lm = LocalMinima.new()
		lm.vertex = vert
		lm.polytype = polytype
		lm.is_open = is_open
		_minima_list.push_back(lm)
	
	func add_path_to_vertex_list(path, polytype, is_open):
		var path_len = path.size()
		while path_len > 1 and path[path_len - 1] == path[0]:
			path_len -= 1
		if path_len < 2:
			return
		
		var i = 1
		var p0_is_minima = false
		var p0_is_maxima = false
		var going_up = false
		while i < path_len and path[i].y == path[0].y:
			i += 1
		var is_flat = i == path_len
		if is_flat:
			if not is_open:
				return
			going_up = false
		else:
			going_up = path[i].y < path[0].y
			if going_up:
				i = path_len - 1
				while path[i].y == path[0].y:
					i -= 1
				p0_is_minima = path[i].y < path[0].y
			else:
				i = path_len - 1
				while path[i].y == path[0].y:
					i -= 1
				p0_is_maxima = path[i].y > path[0].y
		
		var vertices = []
		for vert_idx in range(0, path_len):
			vertices.push_back(Vertex.new())
		
		vertices[0].pt = path[0]
		vertices[0].flags = VertexFlag.NONE
		
		if is_open:
			vertices[0].flags |= VertexFlag.OPEN_START
			if going_up:
				add_loc_min(vertices[0], polytype, is_open)
			else:
				vertices[0].flags |= VertexFlag.LOCAL_MAX
		
		i = 0
		for j in range(1, path_len):
			if path[j] == vertices[i].pt:
				continue
			vertices[j].pt = path[j]
			vertices[j].flags = VertexFlag.NONE
			vertices[i].next = vertices[j]
			vertices[j].prev = vertices[i]
			if path[j].y > path[i].y and going_up:
				vertices[i].flags |= VertexFlag.LOCAL_MAX
				going_up = false
			elif path[j].y < path[i].y and not going_up:
				going_up = true
				add_loc_min(vertices[i], polytype, is_open)
			i = j
		
		vertices[i].next = vertices[0]
		vertices[0].prev = vertices[i]
		
		if is_open:
			vertices[i].flags |= VertexFlag.OPEN_END
			if going_up:
				vertices[i].flags |= VertexFlag.LOCAL_MAX
			else:
				add_loc_min(vertices[i], polytype, is_open)
		elif going_up:
			var v = vertices[i]
			while v.next.pt.y <= v.pt.y:
				v = v.next
			v.flags |= VertexFlag.LOCAL_MAX
			if p0_is_minima:
				add_loc_min(vertices[0], polytype, is_open)
		else:
			var v = vertices[i]
			while v.next.pt.y >= v.pt.y:
				v = v.next
			add_loc_min(v, polytype, is_open)
			if p0_is_maxima:
				vertices[0].flags |= VertexFlag.LOCAL_MAX
	
		_vertex_list.push_back(vertices)
	
	func add_path(path, polytype, is_open):
		if is_open:
			if polytype == PathType.CLIP:
				print("AddPath: Only subject paths may be open.")
				return
			_has_open_paths = true
		_minima_list_sorted = false
		add_path_to_vertex_list(path, polytype, is_open)
	
	func add_paths(paths, polytype, is_open):
		for i in range(0, paths.size()):
			add_path(paths[i], polytype, is_open)
	
	func is_contributing_closed(e):
		match _fillrule:
			FillRule.NON_ZERO:
				if abs(e.wind_cnt != 1):
					return false
			FillRule.POSITIVE:
				if e.wind_cnt != 1:
					return false
			FillRule.NEGATIVE:
				if e.wind_cnt != -1:
					return false
		
		match _cliptype:
			ClipType.INTERSECTION:
				match _fillrule:
					FillRule.EVEN_ODD:
						return e.wind_cnt2 != 0
					FillRule.NON_ZERO:
						return e.wind_cnt2 != 0
					FillRule.POSITIVE:
						return e.wind_cnt2 > 0
					FillRule.NEGATIVE:
						return e.wind_cnt2 < 0
			ClipType.UNION:
				match _fillrule:
					FillRule.EVEN_ODD:
						return e.wind_cnt2 == 0
					FillRule.NON_ZERO:
						return e.wind_cnt2 == 0
					FillRule.POSITIVE:
						return e.wind_cnt2 <= 0
					FillRule.NEGATIVE:
						return e.wind_cnt2 >= 0
			ClipType.DIFFERENCE:
				if ClipperUtil.get_poly_type(e) == PathType.SUBJECT:
					match _fillrule:
						FillRule.EVEN_ODD:
							return e.wind_cnt2 == 0
						FillRule.NON_ZERO:
							return e.wind_cnt2 == 0
						FillRule.POSITIVE:
							return e.wind_cnt2 <= 0
						FillRule.NEGATIVE:
							return e.wind_cnt2 >= 0
				else:
					match _fillrule:
						FillRule.EVEN_ODD:
							return e.wind_cnt2 != 0
						FillRule.NON_ZERO:
							return e.wind_cnt2 != 0
						FillRule.POSITIVE:
							return e.wind_cnt2 > 0
						FillRule.NEGATIVE:
							return e.wind_cnt2 < 0
			ClipType.XOR:
				return true
		return false
	
	func is_contributing_open(e):
		match _cliptype:
			ClipType.INTERSECTION:
				return e.wind_cnt != 0
			ClipType.UNION:
				return e.wind_cnt == 0 and e.wind_cnt2 == 0
			ClipType.DIFFERENCE:
				return e.wind_cnt2 == 0
			ClipType.XOR:
				return (e.wind_cnt != 0) != (e.wind_cnt2 != 0)
		return false
	
	func set_winding_left_edge_closed(e):
		var e2 = e.prev_in_ael
		var pt = ClipperUtil.get_poly_type(e)
		while e2 and (ClipperUtil.get_poly_type(e2) != pt or ClipperUtil.is_open(e2)):
			e2 = e2.prev_in_ael
		
		if not e2:
			e.wind_cnt = e.wind_dx
			e2 = _actives
		elif _fillrule == FillRule.EVEN_ODD:
			e.wind_cnt = e.wind_dx
			e.wind_cnt2 = e2.wind_cnt2
			e2 = e2.next_in_ael
		else:
			if e2.wind_cnt * e2.wind_dx < 0:
				if abs(e2.wind_cnt) > 1:
					if e2.wind_dx * e.wind_dx < 0:
						e.wind_cnt = e2.wind_cnt
					else:
						e.wind_cnt = e2.wind_cnt + e.wind_dx
				else:
					e.wind_cnt = 1 if ClipperUtil.is_open(e) else e.wind_dx
			else:
				if e2.wind_dx * e.wind_dx < 0:
					e.wind_cnt = e2.wind_cnt
				else:
					e.wind_cnt = e2.wind_cnt + e.wind_dx
			e.wind_cnt2 = e2.wind_cnt2
			e2 = e2.next_in_ael
		
		if _fillrule == FillRule.EVEN_ODD:
			while e2 != e:
				if ClipperUtil.get_poly_type(e2) != pt and ClipperUtil.is_open(e2):
					e.wind_cnt2 = 1 if (e.wind_cnt2 == 0) else 0
				e2 = e2.next_in_ael
		else:
			while e2 != e:
				if ClipperUtil.get_poly_type(e2) != pt and not ClipperUtil.is_open(e2):
					e.wind_cnt2 += e2.wind_dx
				e2 = e2.next_in_ael
	
	func set_winding_left_edge_open(e):
		var e2 = _actives
		if _fillrule == FillRule.EVEN_ODD:
			var cnt1 = 0
			var cnt2 = 0
			while e2 != e:
				if ClipperUtil.get_poly_type(e2) == PathType.CLIP:
					cnt2 += 1
				elif ClipperUtil.is_open(e2):
					cnt1 += 1
				e2 = e2.next_in_ael
			e.wind_cnt = 1 if ClipperUtil.is_odd(cnt1) else 0
			e.wind_cnt2 = 1 if ClipperUtil.is_odd(cnt2) else 0
		else:
			while e2 != e:
				if ClipperUtil.get_poly_type(e2) == PathType.CLIP:
					e.wind_cnt2 += e2.wind_dx
				elif ClipperUtil.is_open(e2):
					e.wind_cnt += e2.wind_dx
				e2 = e2.next_in_ael
	
	func insert_edge_into_ael(e1, e2):
		if not _actives:
			e1.prev_in_ael = null
			e1.next_in_ael = null
			_actives = e1
			return
		if not e2:
			if ClipperUtil.e2_inserts_before_e1(_actives, e1, false):
				e1.prev_in_ael = null
				e1.next_in_ael = _actives
				_actives.prev_in_ael = e1
				_actives = e1
				return
			e2 = _actives
			while (
				e2.next_in_ael and
				ClipperUtil.e2_inserts_before_e1(e1, e2.next_in_ael, false)
			):
				e2 = e2.next_in_ael
		else:
			while (
				e2.next_in_ael and
				ClipperUtil.e2_inserts_before_e1(e1, e2.next_in_ael, true)
			):
				e2 = e2.next_in_ael
		e1.next_in_ael = e2.next_in_ael
		if e2.next_in_ael:
			e2.next_in_ael.prev_in_ael = e1
		e1.prev_in_ael = e2
		e2.next_in_ael = e1
	
	func insert_local_minima_into_ael(bot_y):
		var local_minima_container = {
			"local_minima": null
		}
		var left_bound = Active.new()
		var right_bound = Active.new()
		while pop_local_minima(bot_y, local_minima_container):
			var local_minima = local_minima_container.local_minima
			if local_minima.vertex.flags & VertexFlag.OPEN_START > 0:
				left_bound = null
			else:
				left_bound = Active.new()
				left_bound.bot = local_minima.vertex.pt
				left_bound.curr = left_bound.bot
				left_bound.vertex_top = local_minima.vertex.prev
				left_bound.top = left_bound.vertex_top.pt
				left_bound.wind_dx = -1
				left_bound.local_min = local_minima
				ClipperUtil.set_dx(left_bound)
			
			if local_minima.vertex.flags & VertexFlag.OPEN_END > 0:
				right_bound = null
			else:
				right_bound = Active.new()
				right_bound.bot = local_minima.vertex.pt
				right_bound.curr = right_bound.bot
				right_bound.vertex_top = local_minima.vertex.next
				right_bound.top = right_bound.vertex_top.pt
				right_bound.wind_dx = 1
				right_bound.local_min = local_minima
				ClipperUtil.set_dx(right_bound)
			
			if left_bound and right_bound:
				if ClipperUtil.is_horizontal(left_bound):
					if left_bound.top.x > left_bound.bot.x:
						var tmp = left_bound
						left_bound = right_bound
						right_bound = tmp
				elif ClipperUtil.is_horizontal(right_bound):
					if right_bound.top.x < right_bound.bot.x:
						var tmp = left_bound
						left_bound = right_bound
						right_bound = tmp
				elif left_bound.dx < right_bound.dx:
					var tmp = left_bound
					left_bound = right_bound
					right_bound = tmp
			elif not left_bound:
				left_bound = right_bound
				right_bound = null
			
			var contributing = false
			insert_edge_into_ael(left_bound, null)
			if ClipperUtil.is_open(left_bound):
				set_winding_left_edge_open(left_bound)
				contributing = is_contributing_open(left_bound)
			else:
				set_winding_left_edge_closed(left_bound)
				contributing = is_contributing_closed(left_bound)
			
			if right_bound != null:
				right_bound.wind_cnt = left_bound.wind_cnt
				right_bound.wind_cnt2 = left_bound.wind_cnt2
				insert_edge_into_ael(right_bound, left_bound)
				if contributing:
					add_local_min_poly(left_bound, right_bound, left_bound.bot)
				if ClipperUtil.is_horizontal(right_bound):
					push_horz(right_bound)
				else:
					insert_scanline(right_bound.top.y)
			elif contributing:
				start_open_path(left_bound, left_bound.bot)
			
			if ClipperUtil.is_horizontal(left_bound):
				push_horz(left_bound)
			else:
				insert_scanline(left_bound.top.y)
			
			if right_bound and left_bound.next_in_ael != right_bound:
				var e = right_bound.next_in_ael
				ClipperUtil.move_edge_to_follow_left_in_ael(right_bound, left_bound)
				while right_bound.next_in_ael != e:
					intersect_edges(right_bound, right_bound.next_in_ael, right_bound.bot)
					swap_positions_in_ael(right_bound, right_bound.next_in_ael)
	
	func push_horz(e):
		e.next_in_sel = _sel if _sel else null
		_sel = e
	
	func pop_horz(e_container):
		e_container.e = _sel
		if !e_container.e:
			return false
		_sel = _sel.next_in_sel
		return true
	
	func get_owner(e):
		if ClipperUtil.is_horizontal(e) and e.top.x < e.bot.x:
			e = e.next_in_ael
			while e and (!ClipperUtil.is_hot_edge(e) or ClipperUtil.is_open(e)):
				e = e.next_in_ael
			if not e:
				return null
			return e.outrec.owner if (e.outrec.flag == OutRecFlag.OUTER) == (e.outrec.start_e == e) else e.outrec
		else:
			e = e.prev_in_ael
			while e and (!ClipperUtil.is_hot_edge(e) or ClipperUtil.is_open(e)):
				e = e.prev_in_ael
			if not e:
				return null
			return e.outrec.owner if (e.outrec.flag == OutRecFlag.OUTER) == (e.outrec.end_e == e) else e.outrec
	
	func add_local_min_poly(e1, e2, pt):
		var outrec = create_out_rec()
		outrec.idx = _outrec_list.size()
		_outrec_list.push_back(outrec)
		outrec.owner = get_owner(e1)
		outrec.polypath = null
		
		if ClipperUtil.is_open(e1):
			outrec.flag = OutRecFlag.OPEN
		elif !outrec.owner or outrec.owner.flag == OutRecFlag.INNER:
			outrec.flag = OutRecFlag.OUTER
		else:
			outrec.flag = OutRecFlag.INNER
		
		var swap_sides_needed = false
		if ClipperUtil.is_horizontal(e1):
			if e1.top.x > e1.bot.x:
				swap_sides_needed = true
		elif ClipperUtil.is_horizontal(e2):
			if e2.top.x < e2.bot.x:
				swap_sides_needed = true
		elif e1.dx < e2.dx:
			swap_sides_needed = true
		if (outrec.flag == OutRecFlag.OUTER) != swap_sides_needed:
			ClipperUtil.set_orientation(outrec, e1, e2)
		else:
			ClipperUtil.set_orientation(outrec, e2, e1)
		
		var op = create_out_pt()
		op.pt = pt
		op.next = op
		op.prev = op
		outrec.pts = op
	
	func add_local_max_poly(e1, e2, pt):
		if not ClipperUtil.is_hot_edge(e2):
			print("Error in AddLocalMaxPoly().")
			return
		
		add_out_pt(e1, pt)
		if e1.outrec == e2.outrec:
			e1.outrec.start_e = null
			e1.outrec.end_e = null
			e1.outrec = null
			e2.outrec = null
		elif e1.outrec.idx < e2.outrec.idx:
			join_outrec_paths(e1, e2)
		else:
			join_outrec_paths(e2, e1)
	
	func join_outrec_paths(e1, e2):
		if ClipperUtil.is_start_side(e1) == ClipperUtil.is_start_side(e2):
			if ClipperUtil.is_open(e1):
				ClipperUtil.swap_sides(e2.outrec)
			elif !ClipperUtil.fix_orientation(e1) and !ClipperUtil.fix_orientation(e2):
				print("Error in JoinOutrecPaths()")
				return
			
			if e1.outrec.owner == e2.outrec:
				e1.outrec.owner = e2.outrec.owner
		
		var p1_st = e1.outrec.pts
		var p2_st = e2.outrec.pts
		var p1_end = p1_st.next
		var p2_end = p2_st.next
		if ClipperUtil.is_start_side(e2):
			p2_end.prev = p1_st
			p1_st.next = p2_end
			p2_st.next = p1_end
			p1_end.prev = p2_st
			e1.outrec.pts = p2_st
			e1.outrec.start_e = e2.outrec.start_e
			if e1.outrec.start_e:
				e1.outrec.start_e.outrec = e1.outrec
		else:
			p1_end.prev = p2_st
			p2_st.next = p1_end
			p1_st.next = p2_end
			p2_end.prev = p1_st
			e1.outrec.end_e = e2.outrec.end_e
			if e1.outrec.end_e:
				e1.outrec.end_e.outrec = e1.outrec
		
		e2.outrec.start_e = null
		e2.outrec.end_e = null
		e2.outrec.pts = null
		e2.outrec.owner = e1.outrec
		
		e1.outrec = null
		e2.outrec = null
	
	func terminate_hot_open(e):
		if e.outrec.start_e == e:
			e.outrec.start_e = null
		else:
			e.outrec.end_e = null
		e.outrec = null
	
	func create_out_pt():
		return OutPt.new()
	
	func create_out_rec():
		return OutRec.new()
	
	func add_out_pt(e, pt):
		var to_start = ClipperUtil.is_start_side(e)
		var start_op = e.outrec.pts
		if not start_op:
			return null
		var end_op = start_op.next
		if to_start:
			if pt == start_op.pt:
				return start_op
		elif pt == end_op.pt:
			return end_op
		
		var new_op = create_out_pt()
		new_op.pt = pt
		end_op.prev = new_op
		new_op.prev = start_op
		new_op.next = end_op
		start_op.next = new_op
		if to_start:
			e.outrec.pts = new_op
		return new_op
	
	func start_open_path(e, pt):
		var outrec = create_out_rec()
		outrec.idx = _outrec_list.size()
		_outrec_list.push_back(outrec)
		outrec.flag = OutRecFlag.OPEN
		outrec.owner = null
		outrec.polypath = null
		outrec.end_e = null
		outrec.start_e = null
		e.outrec = outrec
		
		var op = create_out_pt()
		op.pt = pt
		op.next = op
		op.prev = op
		outrec.pts = op
	
	func update_edge_into_ael(e):
		e.bot = e.top
		e.vertex_top = ClipperUtil.next_vertex(e)
		e.top = e.vertex_top.pt
		e.curr = e.bot
		ClipperUtil.set_dx(e)
		if not ClipperUtil.is_horizontal(e):
			insert_scanline(e.top.y)
	
	func intersect_edges(e1, e2, pt):
		e1.curr = pt
		e2.curr = pt
		
		if _has_open_paths and (ClipperUtil.is_open(e1) || ClipperUtil.is_open(e2)):
			if ClipperUtil.is_open(e1) and ClipperUtil.is_open(e2):
				return
			var edge_o = Active.new()
			var edge_c = Active.new()
			if ClipperUtil.is_open(e1):
				edge_o = e1
				edge_c = e2
			else:
				edge_o = e2
				edge_c = e1
			
			match _cliptype:
				ClipType.INTERSECTION:
					if ClipperUtil.is_same_poly_type(edge_o, edge_c) or abs(edge_c.wind_cnt) != 1:
						return
				ClipType.DIFFERENCE:
					if ClipperUtil.is_same_poly_type(edge_o, edge_c) or abs(edge_c.wind_cnt) != 1:
						return
				ClipType.UNION:
					if (
						ClipperUtil.is_hot_edge(edge_o) != (
							(abs(edge_c.wind_cnt) != 1) or (
								ClipperUtil.is_hot_edge(edge_o) != (edge_c.wind_cnt != 0)
							)
						)
					):
						return
				ClipType.XOR:
					if abs(edge_c.wind_cnt) != 1:
						return
			if ClipperUtil.is_hot_edge(edge_o):
				add_out_pt(edge_o, pt)
				terminate_hot_open(edge_o)
			else:
				start_open_path(edge_o, pt)
			return
		
		var old_e1_windcnt = 0
		var old_e2_windcnt = 0
		if e1.local_min.polytype == e2.local_min.polytype:
			if _fillrule == FillRule.EVEN_ODD:
				old_e1_windcnt = e1.wind_cnt
				e1.wind_cnt = e2.wind_cnt
				e2.wind_cnt = old_e1_windcnt
			else:
				if e1.wind_cnt + e2.wind_dx == 0:
					e1.wind_cnt = -e1.wind_cnt
				else:
					e1.wind_cnt += e2.wind_dx
				if e2.wind_cnt - e1.wind_dx == 0:
					e2.wind_cnt = -e2.wind_cnt
				else:
					e2.wind_cnt -= e1.wind_dx
		else:
			if _fillrule != FillRule.EVEN_ODD:
				e1.wind_cnt2 += e2.wind_dx
			else:
				e1.wind_cnt2 = 1 if e1.wind_cnt2 == 0 else 0
			if _fillrule != FillRule.EVEN_ODD:
				e2.wind_cnt2 -= e1.wind_dx
			else:
				e2.wind_cnt2 = 1 if e2.wind_cnt2 == 0 else 0
		
		match _fillrule:
			FillRule.POSITIVE:
				old_e1_windcnt = e1.wind_cnt
				old_e2_windcnt = e2.wind_cnt
			FillRule.NEGATIVE:
				old_e1_windcnt = -e1.wind_cnt
				old_e2_windcnt = -e2.wind_cnt
			_:
				old_e1_windcnt = abs(e1.wind_cnt)
				old_e2_windcnt = abs(e2.wind_cnt)
		
		if ClipperUtil.is_hot_edge(e1) and ClipperUtil.is_hot_edge(e2):
			if (
				(old_e1_windcnt != 0 and old_e1_windcnt != 1) or
				(old_e2_windcnt != 0 and old_e2_windcnt != 1) or
				(e1.local_min.polytype != e2.local_min.polytype and _cliptype != ClipType.XOR)
			):
				add_local_max_poly(e1, e2, pt)
			elif ClipperUtil.is_start_side(e1):
				add_local_max_poly(e1, e2, pt)
				add_local_min_poly(e1, e2, pt)
			else:
				add_out_pt(e1, pt)
				add_out_pt(e2, pt)
				ClipperUtil.swap_outrecs(e1, e2)
		elif ClipperUtil.is_hot_edge(e1):
			if old_e2_windcnt == 0 or old_e2_windcnt == 1:
				add_out_pt(e1, pt)
				ClipperUtil.swap_outrecs(e1, e2)
		elif ClipperUtil.is_hot_edge(e2):
			if old_e1_windcnt == 0 or old_e1_windcnt == 1:
				add_out_pt(e2, pt)
				ClipperUtil.swap_outrecs(e1, e2)
		elif (old_e1_windcnt == 0 or old_e1_windcnt == 1) and (old_e2_windcnt == 0 or old_e2_windcnt == 1):
			var e1_wc2 = 0
			var e2_wc2 = 0
			match _fillrule:
				FillRule.POSITIVE:
					e1_wc2 = e1.wind_cnt2
					e2_wc2 = e2.wind_cnt2
				FillRule.NEGATIVE:
					e1_wc2 = -e1.wind_cnt2
					e2_wc2 = -e2.wind_cnt2
				_:
					e1_wc2 = abs(e1.wind_cnt2)
					e2_wc2 = abs(e2.wind_cnt2)
		
			if not ClipperUtil.is_same_poly_type(e1, e2):
				add_local_min_poly(e1, e2, pt)
			elif old_e1_windcnt == 1 and old_e2_windcnt == 1:
				match _cliptype:
					ClipType.INTERSECTION:
						if e1_wc2 > 0 and e2_wc2 > 0:
							add_local_min_poly(e1, e2, pt)
					ClipType.UNION:
						if e1_wc2 <= 0 and e2_wc2 <= 0:
							add_local_min_poly(e1, e2, pt)
					ClipType.DIFFERENCE:
						if (
							(ClipperUtil.get_poly_type(e1) == PathType.CLIP and e1_wc2 > 0 and e2_wc2 > 0) or
							(ClipperUtil.get_poly_type(e1) == PathType.SUBJECT and e1_wc2 <= 0 and e2_wc2 <= 0)
						):
							add_local_min_poly(e1, e2, pt)
					ClipType.XOR:
						add_local_min_poly(e1, e2, pt)
	
	func delete_from_ael(e):
		var prev = e.prev_in_ael
		var next = e.next_in_ael
		if not prev and not next and e != _actives:
			return
		if prev:
			prev.next_in_ael = next
		else:
			_actives = next
		if next:
			next.prev_in_ael = prev
		# delete e
	
	func copy_ael_to_sel():
		var e = _actives
		_sel = e
		while e:
			e.prev_in_sel = e.prev_in_ael
			e.next_in_sel = e.next_in_ael
			e = e.next_in_ael
	
	func copy_actives_to_sel_adjust_curr_x(top_y):
		var e = _actives
		_sel = e
		while e:
			e.prev_in_sel = e.prev_in_ael
			e.next_in_sel = e.next_in_ael
			e.curr.x = ClipperUtil.top_x(e, top_y)
			e = e.next_in_ael
		
	func execute_internal(ct, ft):
		if ct == ClipType.NONE:
			return true
		_fillrule = ft
		_cliptype = ct
		reset()
		
		var y_container = {
			"y": 0
		}
		if not pop_scanline(y_container):
			return false
		while true:
			insert_local_minima_into_ael(y_container.y)
			var e_container = {
				"e": Active.new()
			}
			while pop_horz(e_container):
				process_horizontal(e_container.e)
			if not pop_scanline(y_container):
				break
			process_intersections(y_container.y)
			do_top_of_scanbeam(y_container.y)
		return true
	
	func execute(is_polypath = false, clip_type = ClipType.NONE, solution_closed = [], solution_open = null, ft = FillRule.EVEN_ODD):
		solution_closed.clear()
		if not execute_internal(clip_type, ft):
			return false
		if is_polypath:
			build_result_2(solution_closed, null)
		else:
			build_result(solution_closed, solution_open)
		clean_up()
		return true
	
	func process_intersections(top_y):
		build_intersect_list(top_y)
		if _intersect_list.size() == 0:
			return
		fixup_intersection_order()
		process_intersect_list()
	
	func dispose_intersect_nodes():
		for node_iter in _intersect_list:
			pass # delete
		_intersect_list.clear()
	
	func insert_new_intersect_node(e1, e2, top_y):
		var pt = ClipperUtil.get_intersect_point(e1, e2)
		
		if pt.y > e1.curr.y:
			pt.y = e1.curr.y
			
			if abs(e1.dx) < abs(e2.dx):
				pt.x = ClipperUtil.top_x(e1, pt.y)
			else:
				pt.x = ClipperUtil.top_x(e2, pt.y)
		elif pt.y < top_y:
			pt.y = top_y
			
			if e1.top.y == top_y:
				pt.x = e1.top.x
			elif e2.top.y == top_y:
				pt.x = e2.top.x
			elif abs(e1.dx) < abs(e2.dx):
				pt.x = e1.curr.x
			else:
				pt.x = e2.curr.x
		
		var node = IntersectNode.new()
		node.edge1 = e1
		node.edge2 = e2
		node.pt = pt
		_intersect_list.push_back(node)
	
	func build_intersect_list(top_y):
		if not _actives or not _actives.next_in_ael:
			return
		copy_actives_to_sel_adjust_curr_x(top_y)
		
		var mul = 1
		while true:
			
			var first = _sel
			var second = null
			var base_e = Active.new()
			var prev_base = null
			var tmp = Active.new()
			
			while first:
				if mul == 1:
					second = first.next_in_sel
					if not second:
						first.merge_jump = null
						break
					first.merge_jump = second.next_in_sel
				else:
					second = first.merge_jump
					if not second:
						first.merge_jump = null
						break
					first.merge_jump = second.merge_jump
				
				base_e = first
				var l_cnt = mul
				var r_cnt = mul
				while l_cnt > 0 and r_cnt > 0:
					if second.curr.x < first.curr.x:
						tmp = second.prev_in_sel
						for i in range(0, l_cnt):
							insert_new_intersect_node(tmp, second, top_y)
							tmp = tmp.prev_in_sel
						
						if first == base_e:
							if prev_base:
								prev_base.merge_jump = second
							base_e = second
							base_e.merge_jump = first.merge_jump
							if not first.prev_in_sel:
								_sel = second
						tmp = second.next_in_sel
						insert_2_before_1_in_sel(first, second)
						second = tmp
						if not second:
							break
						r_cnt -= 1
					else:
						first = first.next_in_sel
						l_cnt -= 1
				first = base_e.merge_jump
				prev_base = base_e
			if not _sel.merge_jump:
				break
			else:
				mul <<= 1
	
	func process_intersect_list():
		for node_iter in _intersect_list:
			var i_node = node_iter
			intersect_edges(i_node.edge1, i_node.edge2, i_node.pt)
			swap_positions_in_ael(i_node.edge1, i_node.edge2)
		dispose_intersect_nodes()
		return true
	
	func fixup_intersection_order():
		var cnt = _intersect_list.size()
		if cnt < 2:
			return
		_intersect_list.sort_custom(self, "intersect_list_sort")
		
		copy_ael_to_sel()
		for i in range(0, cnt):
			if not ClipperUtil.edges_adjacent_in_sel(_intersect_list[i]):
				var j = i + 1
				while not ClipperUtil.edges_adjacent_in_sel(_intersect_list[j]):
					j += 1
				var tmp = _intersect_list[i]
				_intersect_list[i] = _intersect_list[j]
				_intersect_list[j] = tmp
			swap_positions_in_sel(_intersect_list[i].edge1, _intersect_list[i].edge2)
	
	func swap_positions_in_ael(e1, e2):
		if e1.next_in_ael == e1.prev_in_ael or e2.next_in_ael == e2.prev_in_ael:
			return
		
		var next = Active.new()
		var prev = Active.new()
		if e1.next_in_ael == e2:
			next = e2.next_in_ael
			if next:
				next.prev_in_ael = e1
			prev = e1.prev_in_ael
			if prev:
				prev.next_in_ael = e2
			e2.prev_in_ael = prev
			e2.next_in_ael = e1
			e1.prev_in_ael = e2
			e1.next_in_ael = next
		elif e2.next_in_ael == e1:
			next = e1.next_in_ael
			if next:
				next.prev_in_ael = e2
			prev = e2.prev_in_ael
			if prev:
				prev.next_in_ael = e1
			e1.prev_in_ael = prev
			e1.next_in_ael = e2
			e2.prev_in_ael = e1
			e2.next_in_ael = next
		else:
			next = e1.next_in_ael
			prev = e1.prev_in_ael
			e1.next_in_ael = e2.next_in_ael
			if e1.next_in_ael:
				e1.next_in_ael.prev_in_ael = e1
			e1.prev_in_ael = e2.prev_in_ael
			if e1.prev_in_ael:
				e1.prev_in_ael.next_in_ael = e1
			e2.next_in_ael = next
			if e2.next_in_ael:
				e2.next_in_ael.prev_in_ael = e2
			e2.prev_in_ael = prev
			if e2.prev_in_ael:
				e2.prev_in_ael.next_in_ael = e2
		
		if not e1.prev_in_ael:
			_actives = e1
		elif not e2.prev_in_ael:
			_actives = e2
	
	func swap_positions_in_sel(e1, e2):
		if not e1.next_in_sel and not e1.prev_in_sel:
			return
		if not e2.next_in_sel and not e2.prev_in_sel:
			return
		
		if e1.next_in_sel == e2:
			var next = e2.next_in_sel
			if next:
				next.prev_in_sel = e1
			var prev = e1.prev_in_sel
			if prev:
				prev.next_in_sel = e2
			e2.prev_in_sel = prev
			e2.next_in_sel = e1
			e1.prev_in_sel = e2
			e1.next_in_sel = next
		elif e2.next_in_sel == e1:
			var next = e1.next_in_sel
			if next:
				next.prev_in_sel = e2
			var prev = e2.prev_in_sel
			if prev:
				prev.next_in_sel = e1
			e1.prev_in_sel = prev
			e1.next_in_sel = e2
			e2.prev_in_sel = e1
			e2.next_in_sel = next
		else:
			var next = e1.next_in_sel
			var prev = e1.prev_in_sel
			e1.next_in_sel = e2.next_in_sel
			if e1.next_in_sel:
				e1.next_in_sel.prev_in_sel = e1
			e1.prev_in_sel = e2.prev_in_sel
			if e1.prev_in_sel:
				e1.prev_in_sel.next_in_sel = e1
			e2.next_in_sel = next
			if e2.next_in_sel:
				e2.next_in_sel.prev_in_sel = e2
			e2.prev_in_sel = prev
			if e2.prev_in_sel:
				e2.prev_in_sel.next_in_sel = e2
		
		if not e1.prev_in_sel:
			_sel = e1
		elif not e2.prev_in_sel:
			_sel = e2
	
	func insert_2_before_1_in_sel(first, second):
		var prev = second.prev_in_sel
		var next = second.next_in_sel
		prev.next_in_sel = next
		if next:
			next.prev_in_sel = prev
		prev = first.prev_in_sel
		if prev:
			prev.next_in_sel = second
		first.prev_in_sel = second
		second.prev_in_sel = prev
		second.next_in_sel = first
	
	func reset_horz_direction(horz, max_pair, horz_container):
		if horz.bot.x == horz.top.x:
			horz_container.horz_left = horz.curr.x
			horz_container.horz_right = horz.curr.x
			var e = horz.next_in_ael
			while e and e != max_pair:
				e = e.next_in_ael
			return e != null
		elif horz.curr.x < horz.top.x:
			horz_container.horz_left = horz.curr.x
			horz_container.horz_right = horz.top.x
			return true
		else:
			horz_container.horz_left = horz.top.x
			horz_container.horz_right = horz.curr.x
			return false
	
	func process_horizontal(horz):
		var pt = Vector2()
		if not ClipperUtil.is_open(horz):
			pt = horz.bot
			while not ClipperUtil.is_maxima(horz) and ClipperUtil.next_vertex(horz).pt.y == pt.y:
				update_edge_into_ael(horz)
			horz.bot = pt
			horz.curr = pt
		
		var max_pair = null
		if ClipperUtil.is_maxima(horz) and (not ClipperUtil.is_open(horz) or (horz.vertex_top.flags & (VertexFlag.OPEN_START | VertexFlag.OPEN_END) == 0)):
			max_pair = ClipperUtil.get_maxima_pair(horz)
		
		var horz_container = {
			"horz_left": null,
			"horz_right": null,
		}
		var is_left_to_right = reset_horz_direction(horz, max_pair, horz_container)
		if ClipperUtil.is_hot_edge(horz):
			add_out_pt(horz, horz.curr)
		
		while true:
			var e = Active.new()
			var is_max = ClipperUtil.is_maxima(horz)
			if is_left_to_right:
				e = horz.next_in_ael
			else:
				e = horz.prev_in_ael
			while e:
				if (is_left_to_right and e.curr.x > horz_container.horz_right) or (not is_left_to_right and e.curr.x < horz_container.horz_left):
					break
				if e.curr.x == horz.top.x and not is_max and not ClipperUtil.is_horizontal(e):
					pt = ClipperUtil.next_vertex(horz).pt
					if (is_left_to_right and ClipperUtil.top_x(e, pt.y) >= pt.x) or (not is_left_to_right and ClipperUtil.top_x(e, pt.y) <= pt.x):
						break
				
				if e == max_pair:
					if ClipperUtil.is_hot_edge(horz):
						if is_left_to_right:
							add_local_max_poly(horz, e, horz.top)
						else:
							add_local_max_poly(e, horz, horz.top)
					delete_from_ael(e)
					delete_from_ael(horz)
					return
				
				if is_left_to_right:
					pt = Vector2(e.curr.x, horz.curr.y)
					intersect_edges(horz, e, pt)
				else:
					pt = Vector2(e.curr.x, horz.curr.y)
					intersect_edges(e, horz, pt)
				
				var next_e = Active.new()
				if is_left_to_right:
					next_e = e.next_in_ael
				else:
					next_e = e.prev_in_ael
				swap_positions_in_ael(horz, e)
				e = next_e
			
			if is_max or ClipperUtil.next_vertex(horz).pt.y != horz.top.y:
				break
			
			update_edge_into_ael(horz)
			is_left_to_right = reset_horz_direction(horz, max_pair, horz_container)
			
			if ClipperUtil.is_open(horz):
				if ClipperUtil.is_maxima(horz):
					max_pair = ClipperUtil.get_maxima_pair(horz)
				if ClipperUtil.is_hot_edge(horz):
					add_out_pt(horz, horz.bot)
		
		if ClipperUtil.is_hot_edge(horz):
			add_out_pt(horz, horz.top)
		if not ClipperUtil.is_open(horz):
			update_edge_into_ael(horz)
		elif not ClipperUtil.is_maxima(horz):
			update_edge_into_ael(horz)
		elif not max_pair:
			delete_from_ael(horz)
		elif ClipperUtil.is_hot_edge(horz):
			add_local_max_poly(horz, max_pair, horz.top)
		else:
			delete_from_ael(max_pair)
			delete_from_ael(horz)
	
	func do_top_of_scanbeam(y):
		_sel = null
		var e = _actives
		while e:
			if e.top.y == y:
				e.curr = e.top
				if ClipperUtil.is_maxima(e):
					e = do_maxima(e)
					continue
				else:
					update_edge_into_ael(e)
					if ClipperUtil.is_hot_edge(e):
						add_out_pt(e, e.bot)
					if ClipperUtil.is_horizontal(e):
						push_horz(e)
			else:
				e.curr.y = y
				e.curr.x = ClipperUtil.top_x(e, y)
			e = e.next_in_ael
	
	func do_maxima(e):
		var next_e = e.next_in_ael
		var prev_e = e.prev_in_ael
		var max_pair = Active.new()
		if ClipperUtil.is_open(e) and (e.vertex_top.flags & (VertexFlag.OPEN_START | VertexFlag.OPEN_END)) != 0:
			if ClipperUtil.is_hot_edge(e):
				add_out_pt(e, e.top)
			if not ClipperUtil.is_horizontal(e):
				if ClipperUtil.is_hot_edge(e):
					terminate_hot_open(e)
				delete_from_ael(e)
			return next_e
		else:
			max_pair = ClipperUtil.get_maxima_pair(e)
			if not max_pair:
				return next_e
		
		while next_e != max_pair:
			intersect_edges(e, next_e, e.top)
			swap_positions_in_ael(e, next_e)
			next_e = e.next_in_ael
		
		if ClipperUtil.is_open(e):
			if ClipperUtil.is_hot_edge(e):
				if max_pair:
					add_local_max_poly(e, max_pair, e.top)
				else:
					add_out_pt(e, e.top)
			if max_pair:
				delete_from_ael(max_pair)
			delete_from_ael(e)
			return prev_e.next_in_ael if prev_e else _actives
		if ClipperUtil.is_hot_edge(e):
			add_local_max_poly(e, max_pair, e.top)
		
		delete_from_ael(e)
		delete_from_ael(max_pair)
		return prev_e.next_in_ael if prev_e else _actives
	
	func build_result(solution_closed, solution_open):
		solution_closed.clear()
		if solution_open:
			solution_open.clear()
		
		for ol_iter in _outrec_list:
			var outrec = ol_iter
			if not outrec.pts:
				continue
			var op = outrec.pts.next
			var cnt = ClipperUtil.point_count(op)
			if op.pt == outrec.pts.pt:
				cnt -= 1
			
			var is_open = outrec.flag == OutRecFlag.OPEN
			if cnt < 2 or (not is_open and cnt == 2) or (is_open and not solution_open):
				continue
			var p = []
			for i in range(0, cnt):
				p.push_back(op.pt)
				op = op.next
			if is_open:
				solution_open.push_back(p)
			else:
				solution_closed.push_back(p)
	
	func build_result_2(pt, solution_open):
		pt.clear()
		if solution_open:
			solution_open.clear()
		
		for ol_iter in _outrec_list:
			var outrec = ol_iter
			if not outrec.pts:
				continue
			var op = outrec.pts.next
			var cnt = ClipperUtil.point_count(op)
			if op.pt == outrec.pts.pt:
				cnt -= 1
			
			var is_open = outrec.flag == OutRecFlag.OPEN
			if cnt < 2 or (not is_open and cnt == 2) or (is_open and not solution_open):
				continue
			
			var p = []
			for i in range(0, cnt):
				p.push_back(op.pt)
				op = op.next
			if is_open:
				solution_open.push_back(p)
			elif outrec.owner and outrec.owner.polypath:
				outrec.polypath = outrec.owner.polypath.add_child(p)
			else:
				outrec.polypath = pt.add_child(p)
	
	func get_bounds():
		if _vertex_list.size() == 0:
			return Rect2(0, 0, 0, 0)
		var left = INF
		var top = INF
		var right = -INF
		var bottom = -INF
		var result = Rect2(INF, INF, -INF, -INF)
		if _vertex_list.size() > 0:
			var it = _vertex_list.front()
			while it != _vertex_list.back():
				var v = it
				var v2 = v
				if v2.pt.x < left:
					left = v2.pt.x
				if v2.pt.x > right:
					right = v2.pt.x
				if v2.pt.y < top:
					top = v2.pt.y
				if v2.pt.y > bottom:
					bottom = v2.pt.y
				v2 = v2.next
				while v2 != v:
					if v2.pt.x < left:
						left = v2.pt.x
					if v2.pt.x > right:
						right = v2.pt.x
					if v2.pt.y < top:
						top = v2.pt.y
					if v2.pt.y > bottom:
						bottom = v2.pt.y
					v2 = v2.next
				var it_idx = _vertex_list.find(it)
				if it_idx != -1:
					if it_idx < _vertex_list.size() - 1:
						it = _vertex_list[it_idx + 1]
					else:
						break
				else:
					break
				
		return Rect2(left, top, right - left, bottom - top)
	
	
