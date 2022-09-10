extends "svg_render_element.gd"

var attr_gradient_units = SVGValueConstant.OBJECT_BOUNDING_BOX setget _set_attr_gradient_units
var attr_gradient_transform = Transform2D() setget _set_attr_gradient_transform
var attr_href = SVGValueConstant.NONE setget _set_attr_href
var attr_spread_method = SVGValueConstant.PAD setget _set_attr_spread_method
var attr_x1 = SVGLengthPercentage.new("0%") setget _set_attr_x1
var attr_x2 = SVGLengthPercentage.new("100%") setget _set_attr_x2
var attr_y1 = SVGLengthPercentage.new("0%") setget _set_attr_y1
var attr_y2 = SVGLengthPercentage.new("0%") setget _set_attr_y2

# Lifecycle

func _init():
	node_name = "linearGradient"

# Getters / Setters

func _set_attr_gradient_units(gradient_units):
	attr_gradient_units = gradient_units
	apply_props()

func _set_attr_gradient_transform(gradient_transform):
	gradient_transform = get_style("transform", gradient_transform)
	attr_gradient_transform = SVGAttributeParser.parse_transform_list(gradient_transform)
	apply_props()

func _set_attr_href(href):
	attr_href = href
	apply_props()

func _set_attr_spread_method(spread_method):
	attr_spread_method = spread_method
	apply_props()

func _set_attr_x1(x1):
	if typeof(x1) != TYPE_STRING:
		attr_x1 = x1
	else:
		attr_x1 = SVGLengthPercentage.new(x1)
	apply_props()

func _set_attr_x2(x2):
	if typeof(x2) != TYPE_STRING:
		attr_x2 = x2
	else:
		attr_x2 = SVGLengthPercentage.new(x2)
	apply_props()

func _set_attr_y1(y1):
	if typeof(y1) != TYPE_STRING:
		attr_y1 = y1
	else:
		attr_y1 = SVGLengthPercentage.new(y1)
	apply_props()

func _set_attr_y2(y2):
	if typeof(y2) != TYPE_STRING:
		attr_y2 = y2
	else:
		attr_y2 = SVGLengthPercentage.new(y2)
	apply_props()
