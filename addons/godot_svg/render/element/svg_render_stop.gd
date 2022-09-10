extends "svg_render_element.gd"

var attr_offset = SVGLengthPercentage.new("0") setget _set_attr_offset
var attr_stop_color = Color(0, 0, 0, 1) setget _set_attr_stop_color
var attr_stop_opacity = 1 setget _set_attr_stop_opacity

# Lifecycle

func _init():
	node_name = "stop"

# Getters / Setters

func _set_attr_offset(offset):
	if typeof(offset) != TYPE_STRING:
		attr_offset = offset
	else:
		attr_offset = SVGLengthPercentage.new(offset)
	apply_props()

func _set_attr_stop_color(stop_color):
	stop_color = get_style("stop_color", stop_color)
	attr_stop_color = SVGAttributeParser.parse_css_color(stop_color)
	apply_props()

func _set_attr_stop_opacity(stop_opacity):
	stop_opacity = get_style("stop_opacity", stop_opacity)
	if typeof(stop_opacity) != TYPE_STRING:
		attr_stop_opacity = stop_opacity
	else:
		attr_stop_opacity = stop_opacity.to_float()
	apply_props()
