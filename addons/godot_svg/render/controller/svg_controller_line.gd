extends "svg_controller_element.gd"

#------------#
# Attributes #
#------------#

var attr_x1 = SVGLengthPercentage.new("0"): set = _set_attr_x1
var attr_x2 = SVGLengthPercentage.new("0"): set = _set_attr_x2
var attr_y1 = SVGLengthPercentage.new("0"): set = _set_attr_y1
var attr_y2 = SVGLengthPercentage.new("0"): set = _set_attr_y2
var attr_path_length = SVGValueConstant.NONE: set = _set_attr_path_length

#-----------#
# Lifecycle #
#-----------#

func _init():
	node_name = "line"

func _process_polygon():
	var stroke = [
		{
			"command": PathCommand.MOVE_TO,
			"points": [Vector2(
				attr_x1.get_length(inherited_view_box.size.x),
				attr_y1.get_length(inherited_view_box.size.y)
			)]
		},
		{
			"command": PathCommand.LINE_TO,
			"points": [Vector2(
				attr_x2.get_length(inherited_view_box.size.x),
				attr_y2.get_length(inherited_view_box.size.y)
			)]
		}
	]
	return {
		"is_simple_shape": true,
		"fill": [],
		"stroke": stroke,
	}

#------------------#
# Internal Methods #
#------------------#

func _calculate_bounding_box():
	var x1 = attr_x1.get_length(inherited_view_box.size.x)
	var y1 = attr_y1.get_length(inherited_view_box.size.y)
	var x2 = attr_x2.get_length(inherited_view_box.size.x)
	var y2 = attr_y2.get_length(inherited_view_box.size.y)
	var xl = min(x1, x2)
	var xr = max(x1, x2)
	var yt = min(y1, y2)
	var yb = max(y1, y2)
	_bounding_box = Rect2(
		xl,
		yt,
		(xr - xl),
		(yb - yt)
	)
	emit_signal("bounding_box_calculated", _bounding_box)
	if parent_controller != null and parent_controller.node_name == "g":
		parent_controller._calculate_bounding_box()

#-------------------#
# Getters / Setters #
#-------------------#

func _set_attr_x1(x1):
	if typeof(x1) != TYPE_STRING:
		attr_x1 = x1
	else:
		attr_x1 = SVGLengthPercentage.new(x1)
	apply_props("x1")

func _set_attr_x2(x2):
	if typeof(x2) != TYPE_STRING:
		attr_x2 = x2
	else:
		attr_x2 = SVGLengthPercentage.new(x2)
	apply_props("x2")

func _set_attr_y1(y1):
	if typeof(y1) != TYPE_STRING:
		attr_y1 = y1
	else:
		attr_y1 = SVGLengthPercentage.new(y1)
	apply_props("y1")

func _set_attr_y2(y2):
	if typeof(y2) != TYPE_STRING:
		attr_y2 = y2
	else:
		attr_y2 = SVGLengthPercentage.new(y2)
	apply_props("y2")

func _set_attr_path_length(path_length):
	if typeof(path_length) != TYPE_STRING:
		attr_path_length = path_length
	else:
		attr_path_length = path_length.to_float()
	apply_props("path_length")
