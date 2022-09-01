extends "svg_render_element.gd"

const PathCommand = SVGValueConstant.PathCommand
const PathCoordinate = SVGValueConstant.PathCoordinate

var attr_d = [] setget _set_attr_d
var attr_path_length = SVGValueConstant.NONE setget _set_attr_path_length

# Lifecycle

func _init():
	node_name = "path"

func _draw():
	var scale_factor = get_scale_factor()
	
	var fill_paint = resolve_paint(attr_fill)
	var fill_color = fill_paint.color
	var fill_texture = fill_paint.texture
	
	var stroke_paint = resolve_paint(attr_stroke)
	var stroke_color = stroke_paint.color
	var stroke_texture = stroke_paint.texture
	
	var stroke_width = attr_stroke_width.get_length(inherited_view_box.size.x)
	
	var fill_point_lists = []
	var fill_points = PoolVector2Array()
	var stroke_point_lists = []
	var stroke_points = PoolVector2Array()
	var strokes_closed = []
	
	var current_stroke_start_point = Vector2()
	var current_point = Vector2()
	for i in range(0, attr_d.size()):
		var instruction = attr_d[i]
		var next_instruction = attr_d[i + 1] if i < attr_d.size() - 1 else instruction
		var is_relative = instruction.coordinate_type == PathCoordinate.RELATIVE
		var values = instruction.values
		match instruction.command:
			PathCommand.MOVE_TO:
				current_point = (current_point if is_relative else Vector2()) + Vector2(values[0], values[1])
				current_stroke_start_point = current_point
				if not [PathCommand.MOVE_TO, PathCommand.CLOSE_PATH].has(next_instruction.command):
					if fill_points.size() > 0:
						if not current_stroke_start_point.is_equal_approx(current_point):
							fill_points.push_back(current_stroke_start_point)
						fill_point_lists.push_back(fill_points)
						fill_points = PoolVector2Array()
					if stroke_points.size() > 0:
						stroke_point_lists.push_back(stroke_points)
						strokes_closed.push_back(false)
						stroke_points = PoolVector2Array()
					fill_points.push_back(current_point)
					stroke_points.push_back(current_point)
			PathCommand.LINE_TO:
				current_point = (current_point if is_relative else Vector2()) + Vector2(values[0], values[1])
				fill_points.push_back(current_point)
				stroke_points.push_back(current_point)
			PathCommand.CLOSE_PATH:
				if not current_stroke_start_point.is_equal_approx(current_point):
					fill_points.push_back(current_stroke_start_point)
					stroke_points.push_back(current_stroke_start_point)
				if fill_points.size() > 0:
					fill_point_lists.push_back(fill_points)
					fill_points = PoolVector2Array()
				if stroke_points.size() > 0:
					stroke_point_lists.push_back(stroke_points)
					strokes_closed.push_back(true)
					stroke_points = PoolVector2Array()
				
	if stroke_points.size() > 0:
		stroke_point_lists.push_back(stroke_points)
	
	draw_shape({
		"scale_factor": scale_factor,
		"fill_color": fill_color,
		"fill_texture": fill_texture,
		"fill_polygon": fill_points,
		"fill_uv": [], # TODO
		"stroke_color": stroke_color,
		"stroke_texture": stroke_texture,
		"stroke_points": stroke_point_lists,
		"stroke_width": stroke_width,
		"stroke_closed": strokes_closed,
	})


# Public Methods

func get_bounding_box():
	# TODO
	return Rect2(0, 0, 0, 0)

# Getters / Setters

func _set_attr_d(d):
	d = get_style("d", d)
	if typeof(d) != TYPE_STRING:
		attr_d = d
	else:
		d = d + "$"
		attr_d = []
		var current_command = -1
		var current_coordinate = -1
		var current_values = ""
		var letter_regex = RegEx.new()
		letter_regex.compile("[a-zA-Z$]")
		for c in d:
			if letter_regex.search(c) != null:
				var values = []
				var space_split = current_values.split(" ", false)
				for space_token in space_split:
					var comma_split = space_token.split(",", false)
					for comma_token in comma_split:
						values.push_back(comma_token.to_float())
				
				# Split out implicit commands
				var implicit_commands = []
				var use_implicit_command = -1
				var use_implicit_point_count = 0
				if [PathCommand.MOVE_TO, PathCommand.LINE_TO].has(current_command):
					use_implicit_command = PathCommand.LINE_TO
					use_implicit_point_count = 2
				elif current_command == PathCommand.HORIZONTAL_LINE_TO:
					use_implicit_command = PathCommand.HORIZONTAL_LINE_TO
					use_implicit_point_count = 1
				elif current_command == PathCommand.VERTICAL_LINE_TO:
					use_implicit_command = PathCommand.VERTICAL_LINE_TO
					use_implicit_point_count = 1
				elif current_command == PathCommand.CUBIC_BEZIER_CURVE:
					use_implicit_command = PathCommand.CUBIC_BEZIER_CURVE
					use_implicit_point_count = 6
				elif current_command == PathCommand.SMOOTH_CUBIC_BEZIER_CURVE:
					use_implicit_command = PathCommand.SMOOTH_CUBIC_BEZIER_CURVE
					use_implicit_point_count = 4
				elif current_command == PathCommand.QUADRATIC_BEZIER_CURVE:
					use_implicit_command = PathCommand.QUADRATIC_BEZIER_CURVE
					use_implicit_point_count = 4
				elif current_command == PathCommand.SMOOTH_QUADRATIC_BEZIER_CURVE:
					use_implicit_command = PathCommand.SMOOTH_QUADRATIC_BEZIER_CURVE
					use_implicit_point_count = 2
				elif current_command == PathCommand.ELLIPTICAL_ARC_CURVE:
					use_implicit_command = PathCommand.ELLIPTICAL_ARC_CURVE
					use_implicit_point_count = 7
				if use_implicit_command > -1:
					var implicit_values = SVGHelper.array_slice(values, use_implicit_point_count)
					for point_group_index in range(0, implicit_values.size(), use_implicit_point_count):
						if point_group_index + use_implicit_point_count - 1 < implicit_values.size():
							implicit_commands.push_back({
								"command": use_implicit_command,
								"coordinate_type": current_coordinate,
								"values": SVGHelper.array_slice(implicit_values, point_group_index, point_group_index + use_implicit_point_count)
							})
				attr_d.push_back({
					"command": current_command,
					"coordinate_type": current_coordinate,
					"values": values,
				})
				if implicit_commands.size() > 0:
					for implicit_command in implicit_commands:
						attr_d.push_back(implicit_command)
				current_command = -1
				current_coordinate = -1
				current_values = ""
			if c == "M":
				current_command = PathCommand.MOVE_TO
				current_coordinate = PathCoordinate.ABSOLUTE
			elif c == "m":
				current_command = PathCommand.MOVE_TO
				current_coordinate = PathCoordinate.RELATIVE
			elif c == "L":
				current_command = PathCommand.LINE_TO
				current_coordinate = PathCoordinate.ABSOLUTE
			elif c == "l":
				current_command = PathCommand.LINE_TO
				current_coordinate = PathCoordinate.RELATIVE
			elif c == "H":
				current_command = PathCommand.HORIZONTAL_LINE_TO
				current_coordinate = PathCoordinate.ABSOLUTE
			elif c == "h":
				current_command = PathCommand.HORIZONTAL_LINE_TO
				current_coordinate = PathCoordinate.RELATIVE
			elif c == "V":
				current_command = PathCommand.VERTICAL_LINE_TO
				current_coordinate = PathCoordinate.ABSOLUTE
			elif c == "v":
				current_command = PathCommand.VERTICAL_LINE_TO
				current_coordinate = PathCoordinate.RELATIVE
			elif c == "C":
				current_command = PathCommand.CUBIC_BEZIER_CURVE
				current_coordinate = PathCoordinate.ABSOLUTE
			elif c == "c":
				current_command = PathCommand.CUBIC_BEZIER_CURVE
				current_coordinate = PathCoordinate.RELATIVE
			elif c == "S":
				current_command = PathCommand.SMOOTH_CUBIC_BEZIER_CURVE
				current_coordinate = PathCoordinate.ABSOLUTE
			elif c == "s":
				current_command = PathCommand.SMOOTH_CUBIC_BEZIER_CURVE
				current_coordinate = PathCoordinate.RELATIVE
			elif c == "Q":
				current_command = PathCommand.QUADRATIC_BEZIER_CURVE
				current_coordinate = PathCoordinate.ABSOLUTE
			elif c == "q":
				current_command = PathCommand.QUADRATIC_BEZIER_CURVE
				current_coordinate = PathCoordinate.RELATIVE
			elif c == "T":
				current_command = PathCommand.SMOOTH_QUADRATIC_BEZIER_CURVE
				current_coordinate = PathCoordinate.ABSOLUTE
			elif c == "t":
				current_command = PathCommand.SMOOTH_QUADRATIC_BEZIER_CURVE
				current_coordinate = PathCoordinate.RELATIVE
			elif c == "A":
				current_command = PathCommand.ELLIPTICAL_ARC_CURVE
				current_coordinate = PathCoordinate.ABSOLUTE
			elif c == "a":
				current_command = PathCommand.ELLIPTICAL_ARC_CURVE
				current_coordinate = PathCoordinate.RELATIVE
			elif c == "Z":
				current_command = PathCommand.CLOSE_PATH
				current_coordinate = PathCoordinate.ABSOLUTE
			elif c == "z":
				current_command = PathCommand.CLOSE_PATH
				current_coordinate = PathCoordinate.RELATIVE
			else:
				current_values += c
	update()

func _set_attr_path_length(path_length):
	if typeof(path_length) != TYPE_STRING:
		attr_path_length = path_length
	else:
		attr_path_length = path_length.to_float()
	update()