extends SVGRenderElement
class_name SVGRenderViewport

var attr_height = SVGValueConstant.AUTO setget _set_attr_height
var attr_preserve_aspect_ratio = {
	"align": {
		"x": SVGValueConstant.MID,
		"y": SVGValueConstant.MID,
	},
	"meetOrSlice": SVGValueConstant.MEET,
} setget _set_attr_preserve_aspect_ratio
var attr_view_box = Rect2()
var attr_width = SVGValueConstant.AUTO setget _set_attr_width
var attr_x = SVGLengthPercentage.new("0") setget _set_attr_x
var attr_xmlns = "http://www.w3.org/2000/svg"
var attr_y = SVGLengthPercentage.new("0") setget _set_attr_y

func _set_attr_height(height):
	if typeof(height) != TYPE_STRING:
		attr_height = height
	else:
		if height == SVGValueConstant.AUTO:
			attr_height = height
		else:
			attr_height = SVGLengthPercentage.new(height)

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

func _set_attr_view_box(view_box):
	if typeof(view_box) != TYPE_STRING:
		attr_view_box = view_box
	else:
		if view_box == SVGValueConstant.NONE:
			attr_view_box = Rect2()
		else:
			var split = attr_view_box.split(" ", false)
			attr_view_box = Rect2(
				split[0] if split.size() > 0 else 0,
				split[1] if split.size() > 1 else 0,
				split[2] if split.size() > 2 else 0,
				split[3] if split.size() > 3 else 0
			)

func _set_attr_width(width):
	if typeof(width) != TYPE_STRING:
		attr_width = width
	else:
		if width == SVGValueConstant.AUTO:
			attr_width = width
		else:
			attr_width = SVGLengthPercentage.new(width)

func _set_attr_x(x):
	if typeof(x) != TYPE_STRING:
		attr_x = x
	else:
		if x == SVGValueConstant.AUTO:
			attr_x = x
		else:
			attr_x = SVGLengthPercentage.new(x)

func _set_attr_y(y):
	if typeof(y) != TYPE_STRING:
		attr_y = y
	else:
		if y == SVGValueConstant.AUTO:
			attr_y = y
		else:
			attr_y = SVGLengthPercentage.new(y)
