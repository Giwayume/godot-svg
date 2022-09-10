extends "svg_render_element.gd"

var attr_cx = SVGLengthPercentage.new("0") setget _set_attr_cx
var attr_cy = SVGLengthPercentage.new("0") setget _set_attr_cy
var attr_rx = SVGValueConstant.AUTO setget _set_attr_rx
var attr_ry = SVGValueConstant.AUTO setget _set_attr_ry
var attr_path_length = SVGValueConstant.NONE setget _set_attr_path_length

var svg_fill = null
var svg_stroke = null

# Lifecycle

func _init():
	node_name = "ellipse"

func _draw():
	._draw()
	var scale_factor = get_scale_factor()
	
	var center = Vector2(
		attr_cx.get_length(inherited_view_box.size.x),
		attr_cy.get_length(inherited_view_box.size.y)
	)
	var radius_x = attr_rx.get_length(inherited_view_box.size.x)
	var radius_y = attr_ry.get_length(inherited_view_box.size.y)
	
	var fill_paint = resolve_paint(attr_fill)
	var fill_color = fill_paint.color
	var fill_texture = fill_paint.texture
	
	var stroke_paint = resolve_paint(attr_stroke)
	var stroke_color = stroke_paint.color
	var stroke_texture = stroke_paint.texture
	
	var stroke_width = attr_stroke_width.get_length(inherited_view_box.size.x)
	
	if not svg_fill:
		svg_fill = Polygon2D.new()
		add_child(svg_fill)
	if not svg_stroke:
		svg_stroke = SVGLine2D.new()
		svg_stroke.joint_mode = Line2D.LINE_JOINT_BEVEL
		add_child(svg_stroke)
	
	var circumference = PI * (radius_x + radius_y)
	var arc_points = min(1024, max(24, 32 * floor((circumference * scale_factor.x / 4) / 32)))
	var arc_stretch = PI / 32
	
	draw_shape({
		"scale_factor": scale_factor,
		"fill_color": fill_color,
		"fill_texture": fill_texture,
		"fill_polygon": SVGDrawing.generate_fill_ellipse_arc_points(center, radius_x, radius_y, 0, 2*PI, arc_points),
		"fill_uv": SVGDrawing.generate_fill_circle_arc_uv(0, 2*PI, Vector2(), fill_texture.get_width(), arc_points) if fill_texture != null else null,
		"stroke_color": stroke_color,
		"stroke_texture": stroke_texture,
		"stroke_width": stroke_width,
		"stroke_points": SVGDrawing.generate_stroke_ellipse_arc_points(center, radius_x, radius_y, -arc_stretch, 2*PI + arc_stretch, arc_points),
	})

# Internal Methods

func _calculate_bounding_box():
	var center = Vector2(
		attr_cx.get_length(inherited_view_box.size.x),
		attr_cy.get_length(inherited_view_box.size.y)
	)
	var radius_x = attr_rx.get_length(inherited_view_box.size.x)
	var radius_y = attr_ry.get_length(inherited_view_box.size.y)
	_bounding_box = Rect2(center.x - radius_x, center.y - radius_y, radius_x * 2, radius_y * 2)
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

func _set_attr_rx(rx):
	rx = get_style("rx", rx)
	if typeof(rx) != TYPE_STRING:
		attr_rx = rx
	else:
		if rx == SVGValueConstant.AUTO:
			attr_rx = rx
		else:
			attr_rx = SVGLengthPercentage.new(rx)
	apply_props()

func _set_attr_ry(ry):
	ry = get_style("ry", ry)
	if typeof(ry) != TYPE_STRING:
		attr_ry = ry
	else:
		if ry == SVGValueConstant.AUTO:
			attr_ry = ry
		else:
			attr_ry = SVGLengthPercentage.new(ry)
	apply_props()

func _set_attr_path_length(path_length):
	if typeof(path_length) != TYPE_STRING:
		attr_path_length = path_length
	else:
		attr_path_length = path_length.to_float()
	apply_props()
