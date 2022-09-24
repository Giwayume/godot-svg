tool
extends Polygon2D

const cubic_curve_shader = preload("cubic_curve_shader.tres")
const draw_notify_script = preload("draw_notify.gd")

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
					if not other_is_matrix or j < other_matrix.rows.size():
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
					if not other_is_matrix or j < other_matrix.rows.size():
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

var init_conds = {
	CurveClass.SERPENTINE: Matrix.new([
		Vector3(0.0, 0.0, 1.0),
		Vector3(1.0, 0.3, 1.0),
		Vector3(-0.3, 0.7, 1.0),
		Vector3(1.0, 1.0, 1.0),
	]),
	CurveClass.LOOP: Matrix.new([
		Vector3(0.0, 0.0, 1.0),
		Vector3(1.0, 0.0, 1.0),
		Vector3(1.0, 1.0, 1.0),
		Vector3(0.0, 1.0, 1.0),
	]),
	CurveClass.CUSP_WITH_INFLECTION_AT_INFINITY: Matrix.new([
		Vector3(0.0, 0.0, 1.0),
		Vector3(1.0, 1.0, 1.0),
		Vector3(1.0, 0.0, 1.0),
		Vector3(0.0, 1.0, 1.0),
	]),
	CurveClass.CUSP_WITH_CUSP_AT_INFINITY: Matrix.new([
		Vector3(0.0, 0.0, 1.0),
		Vector3(1.0, 0.0, 1.0),
		Vector3(0.0, 1.0, 1.0),
		Vector3(1.0, 1.0, 1.0),
	]),
	CurveClass.QUADRATIC: Matrix.new([
		Vector3(0.0, 0.0, 1.0),
		Vector3(0.0, 0.0, 1.0) + (Vector3(1.0, 0.0, 1.0) - Vector3(0.0, 0.0, 1.0)) * (2.0 / 3.0),
		Vector3(1.0, 1.0, 1.0) + (Vector3(1.0, 0.0, 1.0) - Vector3(1.0, 1.0, 1.0)) * (2.0 / 3.0),
		Vector3(1.0, 1.0, 1.0)
	]),
	CurveClass.LINE_OR_POINT: Matrix.new([
		Vector3(0.0, 0.0, 1.0),
		Vector3(0.0, 0.0, 1.0),
		Vector3(1.0, 1.0, 1.0),
		Vector3(1.0, 1.0, 1.0)
	]),
#	CurveClass.POINT: Matrix.new([
#		Vector3(0.0, 0.0, 1.0),
#		Vector3(0.0, 0.0, 1.0),
#		Vector3(0.0, 0.0, 1.0),
#		Vector3(0.0, 0.0, 1.0),
#	])
}

var B = init_conds[CurveClass.SERPENTINE]

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

# defined in the equations the end of section 2.2 .... would be nice of the paper to label their equations.
func bezier_cubic_curve(t: float):
	var s: float = 1.0 - t
	return (
		B.get_row(0).multiply(s * s * s).add(
			B.get_row(1).multiply(s * s * t * 3.0).add(
				B.get_row(2).multiply(s * t * t * 3.0).add(
					B.get_row(3).multiply(t * t * t)
				)
			)
		)
	)

func bezier_curve_by_c_matrix(C, t):
	var T = Matrix.new([[1.0, t, t * t, t * t * t]])
	var x = T * C
	return x.get_row(0)

var _control_polygon
var _mesh
var _poly1
var _poly2

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if _mesh != null:
			_mesh.queue_free()
			_mesh = null
		if _poly1 != null:
			_poly1.queue_free()
			_poly1 = null
		if _poly2 != null:
			_poly2.queue_free()
			_poly2 = null

func _init():
	pass
#	if _poly1 == null:
#		_poly1 = Polygon2D.new()
#		_poly1.material = ShaderMaterial.new()
#		material.shader = cubic_curve_shader
#		.add_child(_poly1)
#	if _poly2 == null:
#		_poly2 = Polygon2D.new()
#		_poly2.material = ShaderMaterial.new()
#		material.shader = cubic_curve_shader
#		.add_child(_poly2)
	if _mesh == null:
		_mesh = MeshInstance2D.new()
		var mesh_material = ShaderMaterial.new()
		mesh_material.shader = cubic_curve_shader
		_mesh.material = mesh_material
		.add_child(_mesh)

func _ready():
	_control_polygon = self # find_node("Polygon2D")
#	_control_polygon.connect("drawn", self, "_update")
	for i in range(0, 4):
		_control_polygon.polygon[i].x = init_conds[CurveClass.LOOP].rows[i][0]
		_control_polygon.polygon[i].y = init_conds[CurveClass.LOOP].rows[i][1]
	_update()

func _draw():
	_update()

func H(d: Array, t: float, s: float):
	return 36.0 * (
		(d[3] * d[1] - d[2] * d[2]) * s * s +
		d[1] * d[2] * s * t -
		d[1] * d[1] * t * t
	)

func _update():
	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF
	for i in range(0, 4):
		if _control_polygon.polygon[i].x < min_x:
			min_x = _control_polygon.polygon[i].x
		if _control_polygon.polygon[i].x > max_x:
			max_x = _control_polygon.polygon[i].x
		if _control_polygon.polygon[i].y < min_y:
			min_y = _control_polygon.polygon[i].y
		if _control_polygon.polygon[i].y > max_y:
			max_y = _control_polygon.polygon[i].y
	for i in range(0, 4):
		B.rows[i] = [
			(_control_polygon.polygon[i].x - min_x) / (max_x - min_x),
			(_control_polygon.polygon[i].y - min_y) / (max_y - min_y),
			1.0
		]
#	for i in range(0, 4):
#		B.rows[i] = [
#			_control_polygon.polygon[i].x,
#			_control_polygon.polygon[i].y,
#			1.0
#		]
	
	var C = M3.multiply(B)

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
	
	var needs_subdivision = false
	var epsilon = 0.000001
	
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
					1.0
				],
				[
					-sm * tl - sl * tm,
					-3.0 * sl * tl * tl,
					-3.0 * sm * tm * tm,
					0.0
				],
				[
					sl * sm,
					3.0 * sl * sl * tl,
					3.0 * sm * sm * tm,
					0.0
				],
				[
					0.0,
					-sl * sl * sl,
					-sm * sm * sm,
					0.0
				]
			])
			
			tex_coords = M3_inv.multiply(F)
			
			if d[1] < 0.0:
				tex_coords = tex_coords.multiply(Matrix.from_diagonal([-1.0, -1.0, 1.0, 1.0]))
		
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
					1.0
				],
				[
					-se * td - sd * te,
					-se * td * td - 2.0 * sd * te * td,
					-sd * te * te - 2.0 * se * td * te,
					0.0
				],
				[
					sd * se,
					te * sd * sd + 2.0 * se * td * sd,
					td * se * se + 2.0 * sd * te * se,
					0.0
				],
				[
					0.0,
					-sd * sd * se,
					-sd * se * se,
					0.0
				]
			])
			
			tex_coords = M3_inv.multiply(F)
			
			var Td = td / sd
			var Te = te / se
			if (Td >= 0.0 and Td <= 1.0) or (Te >= 0.0 and Te <= 1.0):
				needs_subdivision = true
			
			if d[1] * H(d, 0.5, 1.0) > 0.0:
				tex_coords = tex_coords.multiply(Matrix.from_diagonal([-1.0, -1.0, 1.0, 1.0]))
			
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
					1.0
				],
				[
					-sl,
					-3.0 * sl * tl * tl,
					0.0,
					0.0
				],
				[
					0.0,
					3.0 * sl * sl * tl,
					0.0,
					0.0
				],
				[
					0.0,
					-sl * sl * sl,
					0.0,
					0.0
				]
			])
			
			tex_coords = M3_inv.multiply(F)
			
		else:
			if abs(d[3]) > epsilon:
				classification = CurveClass.QUADRATIC
				
				tex_coords = Matrix.new([
					[0.0, 0.0, 1.0, 1.0],
					[0.5, 0.0, 1.0, 1.0],
					[1.0, 1.0, 1.0, 1.0],
					[0.0, 0.0, 0.0, 0.0],
				])
				
				for i in range(0, 4):
					tex_coords.rows[i][2] = tex_coords.rows[i][0]
		
			else:
				classification = CurveClass.LINE_OR_POINT

	var vertices = PoolVector2Array()
	var colors = PoolColorArray()
	
	_control_polygon.vertex_colors = PoolColorArray([
		Color(1.0, 1.0, 1.0, 0.0),
		Color(1.0, 1.0, 1.0, 0.0),
		Color(1.0, 1.0, 1.0, 0.0),
		Color(1.0, 1.0, 1.0, 0.0),
	])
	
	var order = [1, 0, 2, 3]
	if (
		classification == CurveClass.SERPENTINE or
		classification == CurveClass.CUSP_WITH_CUSP_AT_INFINITY
	):
		order = [0, 1, 3, 2]
	elif classification == CurveClass.CUSP_WITH_INFLECTION_AT_INFINITY:
		order = [0, 2, 1, 3]
	
	for i in order:
		vertices.push_back(_control_polygon.polygon[i])
		colors.push_back(Color(
			tex_coords.rows[i][0],
			tex_coords.rows[i][1],
			tex_coords.rows[i][2],
			1.0
		))

#	_poly1.polygon = PoolVector2Array([vertices[0], vertices[1], vertices[2]])
#	_poly2.polygon = PoolVector2Array([vertices[1], vertices[2], vertices[3]])
#	_poly1.vertex_colors = PoolColorArray([colors[0], colors[1], colors[2]])
#	_poly2.vertex_colors = PoolColorArray([colors[1], colors[2], colors[3]])

	var array_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(ArrayMesh.ARRAY_MAX)
	arrays[ArrayMesh.ARRAY_VERTEX] = vertices
	arrays[ArrayMesh.ARRAY_COLOR] = colors
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLE_STRIP, arrays, [], Mesh.ARRAY_COMPRESS_VERTEX)
	_mesh.mesh = array_mesh
	_mesh.update()
	
#	for i in range(0, 4):
#		_control_polygon.vertex_colors[i] = colors[i]
