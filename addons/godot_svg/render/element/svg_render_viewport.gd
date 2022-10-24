extends "svg_render_element.gd"

var attr_x = SVGLengthPercentage.new("0") setget _set_attr_x
var attr_y = SVGLengthPercentage.new("0") setget _set_attr_y
var attr_width = SVGValueConstant.AUTO setget _set_attr_width
var attr_height = SVGValueConstant.AUTO setget _set_attr_height
var attr_preserve_aspect_ratio = {
	"align": {
		"x": SVGValueConstant.MID,
		"y": SVGValueConstant.MID,
	},
	"meet_or_slice": SVGValueConstant.MEET,
} setget _set_attr_preserve_aspect_ratio
var attr_view_box = SVGValueConstant.NONE setget _set_attr_view_box
var attr_xmlns = "http://www.w3.org/2000/svg"

# Lifecycle

func _init():
	node_name = "viewport"
	_is_view_box_clip = true

func _props_applied():
	._props_applied()
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
		x = attr_x.get_length(inherited_view_box.size.x, inherited_view_box.position.x)
	
	var y = 0
	if attr_y is SVGLengthPercentage:
		y = attr_y.get_length(inherited_view_box.size.y, inherited_view_box.position.y)
	
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
	apply_props()

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
				"meet_or_slice": split[1] if split[1].length() > 1 else SVGValueConstant.MEET,
			}
	apply_props()

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
	apply_props()

func _set_attr_width(width):
	if typeof(width) != TYPE_STRING:
		attr_width = width
	else:
		if width == SVGValueConstant.AUTO:
			attr_width = width
		else:
			attr_width = SVGLengthPercentage.new(width)
	apply_props()

func _set_attr_x(x):
	if typeof(x) != TYPE_STRING:
		attr_x = x
	else:
		attr_x = SVGLengthPercentage.new(x)
	apply_props()

func _set_attr_y(y):
	if typeof(y) != TYPE_STRING:
		attr_y = y
	else:
		attr_y = SVGLengthPercentage.new(y)
	apply_props()

# Public Methods

func calculate_view_box(inherited_view_box = Rect2(0, 0, 0, 0)):
	if attr_view_box is Rect2:
		return attr_view_box
	elif attr_view_box == SVGValueConstant.NONE:
		var is_width_auto = false
		var is_height_auto = false
		var width = 0.0
		var height = 0.0
		if typeof(attr_width) == TYPE_STRING:
			is_width_auto = attr_width == SVGValueConstant.AUTO
		else:
			width = attr_width.get_length(1)
		if typeof(attr_height) == TYPE_STRING:
			is_height_auto = attr_height == SVGValueConstant.AUTO
		else:
			height = attr_height.get_length(1)
		if width == 0.0 and not is_height_auto:
			width = height
		elif height == 0.0 and not is_width_auto:
			height = width
		return Rect2(0, 0, width, height)
