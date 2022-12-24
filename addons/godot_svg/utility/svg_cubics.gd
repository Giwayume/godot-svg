class_name SVGCubics

class Matrix:
	var rows = []
	
	func _init(new_rows, column_count = null):
		if new_rows is Array:
			for row in new_rows:
				if row is Matrix:
					rows.push_back(row.rows[0])
				elif row is Vector3:
					rows.push_back([row.x, row.y, row.z])
				else:
					rows.push_back(row)
		else:
			var zeroed_rows = []
			for i in range(new_rows):
				var new_row = []
				for j in range(column_count):
					new_row.push_back(0.0)
				zeroed_rows.push_back(new_row)
			rows = zeroed_rows
	
	static func from_diagonal(values):
		var new_matrix = Matrix.new(values.size(), values.size())
		for i in range(0, values.size()):
			new_matrix.rows[i][i] = values[i]
		return new_matrix
	
	func set_row(index, values):
		if values is Matrix:
			values = Matrix.rows[0]
		if index < rows.size():
			for i in values.size():
				if i < rows[i].size():
					rows[index][i] = values[i]
				else:
					break
		return self
	
	func get_row(index):
		var new_values = []
		for value in rows[index]:
			new_values.push_back(value)
		return Matrix.new([new_values])
	
	func add_row(index):
		var sum = 0.0
		for value in rows[index]:
			sum += value
		return sum
	
	func get_row_count():
		return rows.size()
	
	func set_column(index, values):
		if values is Matrix:
			values = Matrix.rows[0]
		for i in values.size():
			if i < rows.size() and index < rows[i].size():
				rows[i][index] = values[i]
		return self
	
	func get_column(index):
		var new_values = []
		for row in rows:
			new_values.push_back([row[index]])
		return Matrix.new(new_values)
	
	func add_column(index):
		var sum = 0.0
		for row in rows:
			sum += row[index]
		return sum
	
	func get_column_count():
		return rows[0].size()
	
	func set_diagonal(values):
		for i in range(0, rows.count()):
			rows[i][i] = values[i]
		return self
	
	func add(other_matrix):
		var new_rows = []
		var other_is_matrix = other_matrix is Matrix
		for i in range(0, rows.size()):
			if not other_is_matrix or i < other_matrix.rows.size():
				var new_row = []
				for j in range(0, rows[i].size()):
					if not other_is_matrix or j < other_matrix.rows[i].size():
						if other_is_matrix:
							new_row.push_back(rows[i][j] + other_matrix.rows[i][j])
						else:
							new_row.push_back(rows[i][j] + other_matrix)
				new_rows.push_back(new_row)
		return Matrix.new(new_rows)
	
	func subtract(other_matrix):
		var new_rows = []
		var other_is_matrix = other_matrix is Matrix
		for i in range(0, rows.size()):
			if not other_is_matrix or i < other_matrix.rows.size():
				var new_row = []
				for j in range(0, rows[i].size()):
					if not other_is_matrix or j < other_matrix.rows[i].size():
						if other_is_matrix:
							new_row.push_back(rows[i][j] - other_matrix.rows[i][j])
						else:
							new_row.push_back(rows[i][j] - other_matrix)
				new_rows.push_back(new_row)
		return Matrix.new(new_rows)

	func multiply(other_matrix):
		var m1 = rows.size()
		var m2 = rows[0].size()
		var res = []
		if other_matrix is Matrix:
			var n1 = other_matrix.rows.size()
			var n2 = other_matrix.rows[0].size()
			for i in range(0, m1):
				var row_array = []
				for j in range(0, n2):
					row_array.push_back(0.0)
				res.push_back(row_array)
			for i in range(0, m1):
				for j in range(0, n2):
					res[i][j] = 0.0
					for x in range(0, m2):
						res[i][j] += rows[i][x] * other_matrix.rows[x][j]
		else:
			for i in range(0, m1):
				var new_row = []
				for j in range(0, m2):
					new_row.push_back(rows[i][j] * other_matrix)
				res.push_back(new_row)
		return Matrix.new(res)

	func determinant():
		var m1 = rows.size()
		var m2 = rows[0].size()
		if m1 == 3 and m2 == 3:
			return (
				rows[0][0] * rows[1][1] * rows[2][2] +
				rows[1][0] * rows[2][1] * rows[0][2] +
				rows[2][0] * rows[0][1] * rows[1][2] -
				rows[0][2] * rows[1][1] * rows[2][0] -
				rows[1][2] * rows[2][1] * rows[0][0] -
				rows[2][2] * rows[0][1] * rows[1][0]
			)
		elif m1 == 4 and m2 == 4:
			var tmp1 = rows[2][2] * rows[3][3]
			var tmp2 = rows[2][3] * rows[3][2]
			var tmp3 = rows[2][1] * rows[3][3]
			var tmp4 = rows[2][3] * rows[3][1]
			var tmp5 = rows[2][1] * rows[3][2]
			var tmp6 = rows[2][2] * rows[3][1]
			var tmp7 = rows[2][0] * rows[3][3]
			var tmp8 = rows[2][3] * rows[3][0]
			var tmp9 = rows[2][0] * rows[3][2]
			var tmp10 = rows[2][2] * rows[3][0]
			var tmp11 = rows[2][0] * rows[3][1]
			var tmp12 = rows[2][1] * rows[3][0]
			return (
				rows[0][0] * rows[1][1] * tmp1 -
				rows[0][0] * rows[1][1] * tmp2 -
				rows[0][0] * rows[1][2] * tmp3 +
				rows[0][0] * rows[1][2] * tmp4 +
				rows[0][0] * rows[1][3] * tmp5 -
				rows[0][0] * rows[1][3] * tmp6 -
				rows[0][1] * rows[1][0] * tmp1 +
				rows[0][1] * rows[1][0] * tmp2 +
				rows[0][1] * rows[1][2] * tmp7 -
				rows[0][1] * rows[1][2] * tmp8 -
				rows[0][1] * rows[1][3] * tmp9 +
				rows[0][1] * rows[1][3] * tmp10 +
				rows[0][2] * rows[1][0] * tmp3 -
				rows[0][2] * rows[1][0] * tmp4 -
				rows[0][2] * rows[1][1] * tmp7 +
				rows[0][2] * rows[1][1] * tmp8 +
				rows[0][2] * rows[1][3] * tmp11 -
				rows[0][2] * rows[1][3] * tmp12 -
				rows[0][3] * rows[1][0] * tmp5 +
				rows[0][3] * rows[1][0] * tmp6 +
				rows[0][3] * rows[1][1] * tmp9 -
				rows[0][3] * rows[1][1] * tmp10 +
				rows[0][3] * rows[1][2] * tmp12 -
				rows[0][3] * rows[1][2] * tmp11
			)
		else:
			return 0.0

enum CurveClass {
	UNKNOWN,
	SERPENTINE,
	LOOP,
	CUSP_WITH_INFLECTION_AT_INFINITY,
	CUSP_WITH_CUSP_AT_INFINITY,
	QUADRATIC,
	LINE_OR_POINT,
	COUNT
}

static func H(d: Array, t: float, s: float):
	return 36.0 * (
		(d[3] * d[1] - d[2] * d[2]) * s * s +
		d[1] * d[2] * s * t -
		d[1] * d[1] * t * t
	)

static func evaluate_control_points(control_points: Array):
	var vertices = PoolVector2Array()
	var implicit_coordinates = PoolVector3Array()
	
	var B = Matrix.new([
		[0.0, 0.0, 1.0],
		[0.0, 0.0, 1.0],
		[1.0, 1.0, 1.0],
		[1.0, 1.0, 1.0]
	])
	
	var M2 = Matrix.new([
		[1.0, 0.0, 0.0],
		[-2.0, 2.0, 0.0],
		[1.0, -2.0, 1.0],
	])
	
	var M2_inv = Matrix.new([
		[1.0, 0.0, 0.0],
		[1.0, 1.0 / 2.0, 0.0],
		[1.0, 1.0, 1.0],
	])
	
	var M3 = Matrix.new([
		[1.0, 0.0, 0.0, 0.0],
		[-3.0, 3.0, 0.0, 0.0],
		[3.0, -6.0, 3.0, 0.0],
		[-1.0, 3.0, -3.0, 1.0],
	])

	var M3_inv = Matrix.new([
		[1.0, 0.0, 0.0, 0.0],
		[1.0, 1.0 / 3.0, 0.0, 0.0],
		[1.0, 2.0 / 3.0, 1.0 / 3.0, 0.0],
		[1.0, 1.0, 1.0, 1.0]
	])
	
	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF
	for i in range(0, control_points.size()):
		if control_points[i].x < min_x:
			min_x = control_points[i].x
		if control_points[i].x > max_x:
			max_x = control_points[i].x
		if control_points[i].y < min_y:
			min_y = control_points[i].y
		if control_points[i].y > max_y:
			max_y = control_points[i].y
	
	if max_x - min_x == 0.0 or max_y - min_y == 0.0:
		for i in range(0, 4):
			vertices.push_back(Vector2.ZERO)
			implicit_coordinates.push_back(Vector3.ZERO)
		return {
			"vertices": vertices,
			"implicit_coordinates": implicit_coordinates,
			"needs_subdivision_at": [],
		}
	
	for i in range(0, 4):
		B.rows[i] = [
			(control_points[i].x - min_x) / (max_x - min_x),
			(control_points[i].y - min_y) / (max_y - min_y),
			1.0
		]
	
	var C = M3.multiply(B)
	
	var Q = Matrix.new([
		B.rows[0],
		(
			Matrix.new([B.rows[1]]).add(Matrix.new([B.rows[2]])).multiply(3.0).subtract(
				Matrix.new([B.rows[0]]).add(Matrix.new([B.rows[3]])).multiply(0.25)
			).rows[0]
		),
		B.rows[3]
	])
	
	var C2 = M2.multiply(Q)
	
	var d = [
		Matrix.new([C.get_row(3), C.get_row(2), C.get_row(1)]).determinant(),
		-Matrix.new([C.get_row(3), C.get_row(2), C.get_row(0)]).determinant(),
		Matrix.new([C.get_row(3), C.get_row(1), C.get_row(0)]).determinant(),
		-Matrix.new([C.get_row(2), C.get_row(1), C.get_row(0)]).determinant(),
	]
	
	var delta_array = [
		0.0,
		d[0] * d[2] - d[1] * d[1],
		d[1] * d[2] - d[0] * d[3],
		d[1] * d[3] - d[2] * d[2],
	]
	
	var delta: float = 3.0 * d[2] * d[2] - 4.0 * d[3] * d[1]
	var classification = CurveClass.UNKNOWN
	
	var F = Matrix.new(4, 4)
	var tex_coords = Matrix.new(4, 4)
	
	var needs_subdivision_at = []
	var epsilon = 0.0001
	
	if abs(d[1]) > epsilon:
		if delta >= 0.0:
			if delta == 0:
				classification = CurveClass.CUSP_WITH_INFLECTION_AT_INFINITY
				
				var td = d[2]
				var sd = 2.0 * d[1]
			else:
				classification = CurveClass.SERPENTINE
		
			var tmp = sqrt(delta / 3.0)
			var tl = d[2] + tmp
			var sl = 2.0 * d[1]
			var tm = d[2] - tmp
			var sm = sl
			var tn = 1.0
			var sn = 0.0
			
			F = Matrix.new([
				[
					tl * tm,
					tl * tl * tl,
					tm * tm * tm,
				],
				[
					-sm * tl - sl * tm,
					-3.0 * sl * tl * tl,
					-3.0 * sm * tm * tm,
				],
				[
					sl * sm,
					3.0 * sl * sl * tl,
					3.0 * sm * sm * tm,
				],
				[
					0.0,
					-sl * sl * sl,
					-sm * sm * sm,
				]
			])
			
			tex_coords = M3_inv.multiply(F)
			
			if d[1] < 0.0:
				tex_coords = tex_coords.multiply(Matrix.from_diagonal([-1.0, -1.0, 1.0]))
		
		elif delta < 0.0:
			classification = CurveClass.LOOP
			
			var tmp = sqrt(-delta)
			var td = d[2] + tmp
			var sd = 2.0 * d[1]
			var te = d[2] - tmp
			var se = sd
			
			F = Matrix.new([
				[
					td * te,
					td * td * te,
					td * te * te,
				],
				[
					-se * td - sd * te,
					-se * td * td - 2.0 * sd * te * td,
					-sd * te * te - 2.0 * se * td * te,
				],
				[
					sd * se,
					te * sd * sd + 2.0 * se * td * sd,
					td * se * se + 2.0 * sd * te * se,
				],
				[
					0.0,
					-sd * sd * se,
					-sd * se * se,
				]
			])
			
			tex_coords = M3_inv.multiply(F)
			
			var Td = td / sd
			var Te = te / se
			if (Td >= 0.0 and Td <= 1.0):
				needs_subdivision_at.push_back(Td)
			if (Te >= 0.0 and Te <= 1.0):
				needs_subdivision_at.push_back(Te)
			
			if d[1] * H(d, 0.5, 1.0) > 0.0:
				tex_coords = tex_coords.multiply(Matrix.from_diagonal([-1.0, -1.0, 1.0]))
			
	else:
		if abs(d[2]) > epsilon:
			classification = CurveClass.CUSP_WITH_CUSP_AT_INFINITY
			
			var tl = d[3]
			var sl = 3.0 * d[2]
			var tm = 1.0
			var sm = 0.0
			var tn = 1.0
			var sn = 0.0
			
			F = Matrix.new([
				[
					tl,
					tl * tl * tl,
					1.0,
				],
				[
					-sl,
					-3.0 * sl * tl * tl,
					0.0,
				],
				[
					0.0,
					3.0 * sl * sl * tl,
					0.0,
				],
				[
					0.0,
					-sl * sl * sl,
					0.0,
				]
			])
			
			tex_coords = M3_inv.multiply(F)
			
		else:
			if abs(d[3]) > epsilon:
				classification = CurveClass.QUADRATIC
				
				tex_coords = Matrix.new([
					[0.0, 0.0, 1.0],
					[0.5, 0.0, 1.0],
					[1.0, 1.0, 1.0],
					[0.0, 0.0, 0.0],
				])
				
				for i in range(0, 4):
					tex_coords.rows[i][2] = tex_coords.rows[i][0]
		
			else:
				classification = CurveClass.LINE_OR_POINT
	
	var order = [1, 0, 2, 3]
	if (
		classification == CurveClass.SERPENTINE or
		classification == CurveClass.CUSP_WITH_CUSP_AT_INFINITY
	):
		order = [0, 1, 3, 2]
	elif classification == CurveClass.CUSP_WITH_INFLECTION_AT_INFINITY:
		order = [0, 2, 1, 3]
	
	for i in [order[0], order[1], order[2], order[1], order[2], order[3]]:
		vertices.push_back(control_points[i])
		implicit_coordinates.push_back(Vector3(
			tex_coords.rows[i][0],
			tex_coords.rows[i][1],
			tex_coords.rows[i][2]
		))
	
	needs_subdivision_at.sort()
	return {
		"classification": classification,
		"vertices": vertices,
		"implicit_coordinates": implicit_coordinates,
		"needs_subdivision_at": needs_subdivision_at,
	}
