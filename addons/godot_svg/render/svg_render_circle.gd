extends SVGRenderElement
class_name SVGRenderCircle

var attr_cx = SVGLengthPercentage.new("0") setget _set_attr_cx
var attr_cy = SVGLengthPercentage.new("0") setget _set_attr_cy
var attr_r = SVGLengthPercentage.new("0") setget _set_attr_r
var attr_path_length = SVGValueConstant.NONE setget _set_attr_path_length

# Drawing

func draw(canvas_item: CanvasItem, view_box: Rect2):
	var center = Vector2(
		attr_cx.get_length(view_box.size.x),
		attr_cy.get_length(view_box.size.y)
	)
	var radius = attr_r.get_length(view_box.size.x)
	
	var fill_color = Color(1, 1, 1, 1)
	if attr_fill is SVGPaint:
		if attr_fill.url != null:
			pass
		else:
			fill_color = attr_fill.color
	
	var stroke_color = Color(1, 1, 1, 1)
	if attr_stroke is SVGPaint:
		if attr_stroke.url != null:
			pass
		else:
			stroke_color = attr_stroke.color
	
	var stroke_width = attr_stroke_width.get_length(view_box.size.x)
	print_debug(stroke_width)
	
	if fill_color.a > 0:
		SVGDrawing.fill_circle_arc(canvas_item, center, radius, 0, 2*PI, fill_color, null, 32)
	if stroke_color.a > 0:
		SVGDrawing.stroke_circle_arc(canvas_item, center, radius, 0, 2*PI, stroke_color, null, stroke_width, 32)

# Getters / Setters

func _set_attr_cx(cx):
	if typeof(cx) != TYPE_STRING:
		attr_cx = cx
	else:
		attr_cx = SVGLengthPercentage.new(cx)

func _set_attr_cy(cy):
	if typeof(cy) != TYPE_STRING:
		attr_cy = cy
	else:
		attr_cy = SVGLengthPercentage.new(cy)

func _set_attr_r(r):
	if typeof(r) != TYPE_STRING:
		attr_r = r
	else:
		attr_r = SVGLengthPercentage.new(r)

func _set_attr_path_length(path_length):
	if typeof(path_length) != TYPE_STRING:
		attr_path_length = path_length
	else:
		attr_path_length = path_length.to_float()
