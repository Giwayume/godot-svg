extends "svg_controller_element.gd"

#-----------#
# Constants #
#-----------#

const PathCoordinate = SVGValueConstant.PathCoordinate

#------------#
# Attributes #
#------------#

var attr_d = []: set = _set_attr_d
var attr_path_length = SVGValueConstant.NONE: set = _set_attr_path_length

#-----------#
# Lifecycle #
#-----------#

func _init():
	node_name = "path"

func _process_polygon():
	var scale_factor = get_scale_factor()
	
	if typeof(attr_d) == TYPE_STRING:
		attr_d = SVGAttributeParser.parse_d(attr_d)
	
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

#------------------#
# Internal Methods #
#------------------#

func _calculate_bounding_box():
	# TODO - currently only calculated during render.
	emit_signal("bounding_box_calculated", _bounding_box)
	if parent_controller != null and parent_controller.node_name == "g":
		parent_controller._calculate_bounding_box()

#-------------------#
# Getters / Setters #
#-------------------#

func _set_attr_d(d):
	_bounding_box = Rect2()
	d = get_style("d", d)
	if typeof(d) != TYPE_STRING:
		attr_d = d
	else:
		attr_d = d # Logic moved to _process_polygon() to speed up cached initialization
	apply_props("d")

func _set_attr_path_length(path_length):
	if typeof(path_length) != TYPE_STRING:
		attr_path_length = path_length
	else:
		attr_path_length = path_length.to_float()
	apply_props("path_length")
