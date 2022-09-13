extends "svg_render_element.gd"

var attr_x = SVGLengthPercentage.new("0") setget _set_attr_x
var attr_y = SVGLengthPercentage.new("0") setget _set_attr_y
var attr_dx = SVGValueConstant.NONE setget _set_attr_dx
var attr_dy = SVGValueConstant.NONE setget _set_attr_dy
var attr_rotate = SVGValueConstant.NONE setget _set_attr_rotate
var attr_length_adjust = SVGValueConstant.SPACING setget _set_attr_length_adjust
var attr_text_length = SVGValueConstant.NONE setget _set_attr_text_length

# Internal Methods

func _calculate_bounding_box():
	var x = attr_x.get_length(inherited_view_box.size.x, inherited_view_box.position.x)
	var y = attr_x.get_length(inherited_view_box.size.y, inherited_view_box.position.y)
	# TODO 
	_bounding_box = Rect2(x, y, 0, 0)
	emit_signal("bounding_box_calculated", _bounding_box)

# Getters / Setters

func _set_attr_x(x):
	x = get_style("x", x)
	if typeof(x) != TYPE_STRING:
		attr_x = x
	else:
		attr_x = SVGLengthPercentage.new(x)
	apply_props()

func _set_attr_y(y):
	y = get_style("y", y)
	if typeof(y) != TYPE_STRING:
		attr_y = y
	else:
		attr_y = SVGLengthPercentage.new(y)
	apply_props()

func _set_attr_dx(dx):
	dx = get_style("dx", dx)
	if typeof(dx) != TYPE_STRING:
		attr_dx = dx
	else:
		if dx == SVGValueConstant.NONE:
			attr_dx = dx
		else:
			attr_dx = SVGLengthPercentage.new(dx)
	apply_props()

func _set_attr_dy(dy):
	dy = get_style("dy", dy)
	if typeof(dy) != TYPE_STRING:
		attr_dy = dy
	else:
		if dy == SVGValueConstant.NONE:
			attr_dy = dy
		else:
			attr_dy = SVGLengthPercentage.new(dy)
	apply_props()

func _set_attr_rotate(rotate):
	rotate = get_style("rotate", rotate)
	if typeof(rotate) != TYPE_STRING:
		attr_rotate = rotate
	else:
		if rotate == SVGValueConstant.NONE:
			attr_rotate = []
		else:
			attr_rotate = [] # TODO
	apply_props()

func _set_attr_length_adjust(length_adjust):
	length_adjust = get_style("length_adjust", length_adjust)
	attr_length_adjust = length_adjust
	apply_props()

func _set_attr_text_length(text_length):
	text_length = get_style("text_length", text_length)
	if typeof(text_length) != TYPE_STRING:
		attr_text_length = text_length
	else:
		if text_length == SVGValueConstant.NONE:
			attr_text_length = text_length
		else:
			attr_text_length = SVGLengthPercentage.new(text_length)
	apply_props()
