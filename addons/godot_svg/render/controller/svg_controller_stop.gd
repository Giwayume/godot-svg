extends "svg_controller_element.gd"

#------------#
# Attributes #
#------------#

var attr_offset = SVGLengthPercentage.new("0"): set = _set_attr_offset
var attr_stop_color = Color(0, 0, 0, 1): set = _set_attr_stop_color
var attr_stop_opacity = 1: set = _set_attr_stop_opacity

#-----------#
# Lifecycle #
#-----------#

func _init():
	node_name = "stop"
	is_renderable = false

#-------------------#
# Getters / Setters #
#-------------------#

func _set_attr_offset(offset):
	if typeof(offset) != TYPE_STRING:
		attr_offset = offset
	else:
		attr_offset = SVGLengthPercentage.new(offset)
	apply_props("offset")

func _set_attr_stop_color(stop_color):
	stop_color = get_style("stop_color", stop_color)
	attr_stop_color = SVGAttributeParser.parse_css_color(stop_color)
	apply_props("stop_color")

func _set_attr_stop_opacity(stop_opacity):
	stop_opacity = get_style("stop_opacity", stop_opacity)
	if typeof(stop_opacity) != TYPE_STRING:
		attr_stop_opacity = stop_opacity
	else:
		attr_stop_opacity = stop_opacity.to_float()
	apply_props("stop_opacity")
