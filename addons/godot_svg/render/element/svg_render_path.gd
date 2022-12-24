extends "svg_render_element.gd"

const PathCoordinate = SVGValueConstant.PathCoordinate

var attr_d = [] setget _set_attr_d
var attr_path_length = SVGValueConstant.NONE setget _set_attr_path_length

# Lifecycle

func _init():
	node_name = "path"

func _process_polygon():
	var scale_factor = get_scale_factor()
	
	var fill_commands = []
	var stroke_commands = []
	
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
					fill_commands.push_back({
						"command": PathCommand.MOVE_TO,
						"points": [current_point],
					})
					stroke_commands.push_back({
						"command": PathCommand.MOVE_TO,
						"points": [current_point],
					})
			PathCommand.LINE_TO:
				current_point = (current_point if is_relative else Vector2()) + Vector2(values[0], values[1])
				fill_commands.push_back({
					"command": PathCommand.LINE_TO,
					"points": [current_point],
				})
				stroke_commands.push_back({
					"command": PathCommand.LINE_TO,
					"points": [current_point],
				})
			PathCommand.HORIZONTAL_LINE_TO:
				current_point = Vector2((current_point.x if is_relative else 0.0) + values[0], current_point.y)
				fill_commands.push_back({
					"command": PathCommand.LINE_TO,
					"points": [current_point],
				})
				stroke_commands.push_back({
					"command": PathCommand.LINE_TO,
					"points": [current_point],
				})
			PathCommand.VERTICAL_LINE_TO:
				current_point = Vector2(current_point.x, (current_point.y if is_relative else 0.0) + values[0])
				fill_commands.push_back({
					"command": PathCommand.LINE_TO,
					"points": [current_point],
				})
				stroke_commands.push_back({
					"command": PathCommand.LINE_TO,
					"points": [current_point],
				})
			PathCommand.CUBIC_BEZIER_CURVE:
				var relative_offset = (current_point if is_relative else Vector2())
				var p0 = current_point
				var p1 = relative_offset + Vector2(values[0], values[1])
				var p2 = relative_offset + Vector2(values[2], values[3])
				var p3 = relative_offset + Vector2(values[4], values[5])
				fill_commands.push_back({
					"command": PathCommand.CUBIC_BEZIER_CURVE,
					"points": [p1, p2, p3],
				})
				stroke_commands.push_back({
					"command": PathCommand.CUBIC_BEZIER_CURVE,
					"points": [p1, p2, p3],
				})
				current_point = p3
			PathCommand.SMOOTH_CUBIC_BEZIER_CURVE:
				var relative_offset = (current_point if is_relative else Vector2())
				var p0 = current_point
				var p1 = Vector2()
				var p2 = relative_offset + Vector2(values[0], values[1])
				var p3 = relative_offset + Vector2(values[2], values[3])
				var last_fill_command = fill_commands.back()
				if last_fill_command.command == PathCommand.CUBIC_BEZIER_CURVE:
					p1 = last_fill_command.points[2] + (last_fill_command.points[2] - last_fill_command.points[1])
				elif last_fill_command.command == PathCommand.QUADRATIC_BEZIER_CURVE:
					p1 = last_fill_command.points[1] + (last_fill_command.points[1] - last_fill_command.points[0])
				else:
					p1 = last_fill_command.points[0]
				fill_commands.push_back({
					"command": PathCommand.CUBIC_BEZIER_CURVE,
					"points": [p1, p2, p3],
				})
				stroke_commands.push_back({
					"command": PathCommand.CUBIC_BEZIER_CURVE,
					"points": [p1, p2, p3],
				})
				current_point = p3
			PathCommand.QUADRATIC_BEZIER_CURVE:
				var relative_offset = (current_point if is_relative else Vector2())
				var p0 = current_point
				var p1 = relative_offset + Vector2(values[0], values[1])
				var p2 = relative_offset + Vector2(values[2], values[3])
				fill_commands.push_back({
					"command": PathCommand.QUADRATIC_BEZIER_CURVE,
					"points": [p1, p2],
				})
				stroke_commands.push_back({
					"command": PathCommand.QUADRATIC_BEZIER_CURVE,
					"points": [p1, p2],
				})
				current_point = p2
			PathCommand.SMOOTH_QUADRATIC_BEZIER_CURVE:
				var relative_offset = (current_point if is_relative else Vector2())
				var p0 = current_point
				var p1 = Vector2()
				var p2 = relative_offset + Vector2(values[0], values[1])
				var last_fill_command = fill_commands.back()
				if last_fill_command.command == PathCommand.CUBIC_BEZIER_CURVE:
					p1 = last_fill_command.points[2] + (last_fill_command.points[2] - last_fill_command.points[1])
				elif last_fill_command.command == PathCommand.QUADRATIC_BEZIER_CURVE:
					p1 = last_fill_command.points[1] + (last_fill_command.points[1] - last_fill_command.points[0])
				else:
					p1 = last_fill_command.points[0]
				fill_commands.push_back({
					"command": PathCommand.QUADRATIC_BEZIER_CURVE,
					"points": [p1, p2],
				})
				stroke_commands.push_back({
					"command": PathCommand.QUADRATIC_BEZIER_CURVE,
					"points": [p1, p2],
				})
				current_point = p2
			PathCommand.ELLIPTICAL_ARC_CURVE:
				var relative_offset = (current_point if is_relative else Vector2())
				var translated_bezier_commands = SVGArcs.arc_to_cubic_bezier(
					current_point,
					relative_offset + Vector2(values[5], values[6]),
					Vector2(values[0], values[1]),
					values[2],
					values[3],
					values[4]
				)
				if translated_bezier_commands.size() > 0:
					fill_commands.append_array(translated_bezier_commands)
					stroke_commands.append_array(translated_bezier_commands)
					for translated_command in translated_bezier_commands:
						current_point = translated_command.points[2]
			PathCommand.CLOSE_PATH:
				if not current_stroke_start_point.is_equal_approx(current_point):
					fill_commands.push_back({
						"command": PathCommand.LINE_TO,
						"points": [current_stroke_start_point],
					})
					stroke_commands.push_back({
						"command": PathCommand.LINE_TO,
						"points": [current_stroke_start_point],
					})
				fill_commands.push_back({
					"command": PathCommand.CLOSE_PATH,
				})
				stroke_commands.push_back({
					"command": PathCommand.CLOSE_PATH,
				})
	
	return {
		"is_simple_shape": false,
		"fill": fill_commands,
		"stroke": stroke_commands,
	}

var draw_cached = false

func _props_applied():
	._props_applied()
	var scale_factor = get_scale_factor()
	
	var fill_paint = resolve_fill_paint()
	var fill_color = fill_paint.color
	var fill_texture = fill_paint.texture
	var fill_texture_units = fill_paint.texture_units
	var fill_texture_uv_transform = fill_paint.texture_uv_transform
	
	var stroke_paint = resolve_stroke_paint()
	var stroke_color = stroke_paint.color
	var stroke_texture = stroke_paint.texture
	var stroke_texture_units = stroke_paint.texture_units
	var stroke_texture_uv_transform = stroke_paint.texture_uv_transform
	
	var stroke_width = attr_stroke_width.get_length(inherited_view_box.size.x)
	
	draw_shape({
		"scale_factor": scale_factor,
		"fill_color": fill_color,
		"fill_texture": fill_texture,
		"fill_texture_units": fill_texture_units,
		"fill_texture_uv_transform": fill_texture_uv_transform,
		"stroke_color": stroke_color,
		"stroke_texture": stroke_texture,
		"stroke_texture_units": stroke_texture_units,
		"stroke_texture_uv_transform": stroke_texture_uv_transform,
		"stroke_width": stroke_width,
	})


# Internal Methods

func _calculate_arc_resolution(_scale_factor): # Override to disable.
	return Vector2(1.0, 1.0)

func _calculate_bounding_box():
	# TODO
	_bounding_box = Rect2(0, 0, 0, 0)
	emit_signal("bounding_box_calculated", _bounding_box)

# Getters / Setters

func _set_attr_d(d):
	_bounding_box = Rect2()
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
		var negative_split_regex = RegEx.new()
		negative_split_regex.compile("(?=-)")
		for c in d:
			if letter_regex.search(c) != null && c != "e":
				var values = []
				var space_split = current_values.split(" ", false)
				for space_token in space_split:
					var comma_split = space_token.split(",", false)
					for comma_token in comma_split:
#						var negative_split = comma_token.split("-")
						var negative_split = SVGHelper.regex_string_split("(?<!e)-", comma_token)
						var negative_multiplier = 1.0
						for negative_token in negative_split:
							if negative_token != "":
								var decimal_split = negative_token.split(".")
								values.push_back(negative_multiplier * ".".join(SVGHelper.array_slice(decimal_split, 0, 2)).to_float())
								if decimal_split.size() > 2:
									for decimal_index in range(2, decimal_split.size()):
										values.push_back(("." + str(decimal_split[decimal_index])).to_float())
							negative_multiplier = -1.0
				
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
	apply_props()

func _set_attr_path_length(path_length):
	if typeof(path_length) != TYPE_STRING:
		attr_path_length = path_length
	else:
		attr_path_length = path_length.to_float()
	apply_props()
