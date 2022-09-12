extends "svg_render_element.gd"

var attr_cx = SVGLengthPercentage.new("0") setget _set_attr_cx
var attr_cy = SVGLengthPercentage.new("0") setget _set_attr_cy
var attr_r = SVGLengthPercentage.new("0") setget _set_attr_r
var attr_path_length = SVGValueConstant.NONE setget _set_attr_path_length

var svg_fill = null
var svg_stroke = null

# Lifecycle

func _init():
	node_name = "circle"

func _draw():
	._draw()
	var scale_factor = get_scale_factor()
	
	var center = Vector2(
		attr_cx.get_length(inherited_view_box.size.x),
		attr_cy.get_length(inherited_view_box.size.y)
	)
	var radius = attr_r.get_length(inherited_view_box.size.x)
	
	var fill_paint = resolve_paint(attr_fill)
	var fill_color = fill_paint.color
	var fill_texture = fill_paint.texture
	
	var stroke_paint = resolve_paint(attr_stroke)
	var stroke_color = stroke_paint.color
	var stroke_texture = stroke_paint.texture
	
	var stroke_width = attr_stroke_width.get_length(inherited_view_box.size.x)

	var circumference = 2 * PI * radius
	var arc_points = min(1024, max(24, 32 * floor((circumference * scale_factor.x / 4) / 32)))
	var arc_stretch = PI / 32
	
	draw_shape({
		"is_simple_shape": true,
		"scale_factor": scale_factor,
		"fill_color": fill_color,
		"fill_texture": fill_texture,
		"fill_polygon": SVGDrawing.generate_fill_circle_arc_points(center, radius, 0, 2*PI, arc_points),
		"fill_uv": SVGDrawing.generate_fill_circle_arc_uv(0, 2*PI, Vector2(), fill_texture.get_width(), arc_points) if fill_texture != null else null,
		"stroke_color": stroke_color,
		"stroke_texture": stroke_texture,
		"stroke_width": stroke_width,
		"stroke_points": SVGDrawing.generate_stroke_circle_arc_points(center, radius, 0, 2*PI, arc_points),
		"stroke_closed": true,
	})

# Internal Methods

func _calculate_bounding_box():
	var center = Vector2(
		attr_cx.get_length(inherited_view_box.size.x, inherited_view_box.position.x),
		attr_cy.get_length(inherited_view_box.size.y, inherited_view_box.position.y)
	)
	var radius = attr_r.get_length(inherited_view_box.size.x)
	var stroke_width = get_visible_stroke_width()
	var half_stroke_width = stroke_width / 2.0
	_bounding_box = Rect2(
		center.x - radius - half_stroke_width,
		center.y - radius - half_stroke_width,
		(radius * 2) + stroke_width,
		(radius * 2) + stroke_width
	)
	emit_signal("bounding_box_calculated", _bounding_box)

# Getters / Setters

func _set_attr_cx(cx):
	cx = get_style("cx", cx)
	if typeof(cx) != TYPE_STRING:
		attr_cx = cx
	else:
		attr_cx = SVGLengthPercentage.new(cx)
	apply_props()

func _set_attr_cy(cy):
	cy = get_style("cy", cy)
	if typeof(cy) != TYPE_STRING:
		attr_cy = cy
	else:
		attr_cy = SVGLengthPercentage.new(cy)
	apply_props()

func _set_attr_r(r):
	r = get_style("r", r)
	if typeof(r) != TYPE_STRING:
		attr_r = r
	else:
		attr_r = SVGLengthPercentage.new(r)
	apply_props()

func _set_attr_path_length(path_length):
	if typeof(path_length) != TYPE_STRING:
		attr_path_length = path_length
	else:
		attr_path_length = path_length.to_float()
	apply_props()
