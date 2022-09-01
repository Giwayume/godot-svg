extends "svg_render_element.gd"

var attr_height = SVGValueConstant.AUTO setget _set_attr_height
var attr_preserve_aspect_ratio = {
	"align": {
		"x": SVGValueConstant.MID,
		"y": SVGValueConstant.MID,
	},
	"meetOrSlice": SVGValueConstant.MEET,
} setget _set_attr_preserve_aspect_ratio
var attr_view_box = SVGValueConstant.NONE setget _set_attr_view_box
var attr_width = SVGValueConstant.AUTO setget _set_attr_width
var attr_x = SVGLengthPercentage.new("0") setget _set_attr_x
var attr_xmlns = "http://www.w3.org/2000/svg"
var attr_y = SVGLengthPercentage.new("0") setget _set_attr_y

# Lifecycle

func _init():
	node_name = "viewport"

func _draw():
	var view_box = inherited_view_box
	if attr_view_box is Rect2:
		view_box = attr_view_box
	
	if view_box.size.x == 0 or view_box.size.y == 0:
		hide()
		return
	show()
	
	var height = 0
	if attr_height is SVGLengthPercentage:
		if attr_height.percentage == null or not is_root:
			height = attr_height.get_length(500)
		else:
			height = inherited_view_box.size.y
	elif attr_height == SVGValueConstant.AUTO:
		height = inherited_view_box.size.y
	
	var width = 0
	if attr_width is SVGLengthPercentage:
		if attr_width.percentage == null or not is_root:
			width = attr_width.get_length(500)
		else:
			width = inherited_view_box.size.x
	elif attr_width == SVGValueConstant.AUTO:
		width = inherited_view_box.size.x
	
	var x = 0
	if attr_x is SVGLengthPercentage:
		x = attr_x.get_length(inherited_view_box.size.x)
	
	var y = 0
	if attr_y is SVGLengthPercentage:
		y = attr_y.get_length(inherited_view_box.size.y)
	
	position = Vector2(x, y)
	scale = Vector2(
		width / view_box.size.x,
		height / view_box.size.y
	)

# Getters / Setters

func _set_attr_height(height):
	if typeof(height) != TYPE_STRING:
		attr_height = height
	else:
		if height == SVGValueConstant.AUTO:
			attr_height = height
		else:
			attr_height = SVGLengthPercentage.new(height)
	update()

func _set_attr_preserve_aspect_ratio(preserve_aspect_ratio):
	if typeof(preserve_aspect_ratio) != TYPE_STRING:
		attr_preserve_aspect_ratio = preserve_aspect_ratio
	else:
		if preserve_aspect_ratio == SVGValueConstant.NONE:
			attr_preserve_aspect_ratio = preserve_aspect_ratio
		else:
			var split = preserve_aspect_ratio.split(" ", false)
			var align_string = split[0]
			var align_x = align_string.substr(1, 3).to_lower()
			var align_y = align_string.substr(5, 3).to_lower()
			attr_preserve_aspect_ratio = {
				"align": {
					"x": align_x,
					"y": align_y,
				},
				"meetOrSlice": split[1] if split.length() > 1 else SVGValueConstant.MEET,
			}
	update()

func _set_attr_view_box(view_box):
	if typeof(view_box) != TYPE_STRING:
		attr_view_box = view_box
	else:
		if view_box == SVGValueConstant.NONE:
			attr_view_box = view_box
		else:
			var split = view_box.split(" ", false)
			attr_view_box = Rect2(
				split[0] if split.size() > 0 else 0,
				split[1] if split.size() > 1 else 0,
				split[2] if split.size() > 2 else 0,
				split[3] if split.size() > 3 else 0
			)
	update()

func _set_attr_width(width):
	if typeof(width) != TYPE_STRING:
		attr_width = width
	else:
		if width == SVGValueConstant.AUTO:
			attr_width = width
		else:
			attr_width = SVGLengthPercentage.new(width)
	update()

func _set_attr_x(x):
	if typeof(x) != TYPE_STRING:
		attr_x = x
	else:
		attr_x = SVGLengthPercentage.new(x)
	update()

func _set_attr_y(y):
	if typeof(y) != TYPE_STRING:
		attr_y = y
	else:
		attr_y = SVGLengthPercentage.new(y)
	update()

# Public Methods

func calc_view_box():
	if attr_view_box is Rect2:
		return attr_view_box
	elif attr_view_box == SVGValueConstant.NONE:
		return Rect2(0, 0, attr_width.get_length(1), attr_height.get_length(1))