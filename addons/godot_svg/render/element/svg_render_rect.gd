extends "svg_render_element.gd"

var attr_x = SVGLengthPercentage.new("0") setget _set_attr_x
var attr_y = SVGLengthPercentage.new("0") setget _set_attr_y
var attr_width = SVGValueConstant.AUTO setget _set_attr_width
var attr_height = SVGValueConstant.AUTO setget _set_attr_height
var attr_rx = SVGValueConstant.AUTO setget _set_attr_rx
var attr_ry = SVGValueConstant.AUTO setget _set_attr_ry
var attr_path_length = SVGValueConstant.NONE setget _set_attr_path_length

# Lifecycle

func _init():
	node_name = "rect"

func _draw():
	._draw()
	var scale_factor = get_scale_factor()
	
	var position = Vector2(
		attr_x.get_length(inherited_view_box.size.x),
		attr_y.get_length(inherited_view_box.size.y)
	)
	
	var width = 0
	if attr_width is SVGLengthPercentage:
		width = attr_width.get_length(inherited_view_box.size.x)
	
	var height = 0
	if attr_height is SVGLengthPercentage:
		height = attr_height.get_length(inherited_view_box.size.y)

	var fill_paint = resolve_fill_paint()
	var fill_color = fill_paint.color
	var fill_texture = fill_paint.texture
	
	var stroke_paint = resolve_stroke_paint()
	var stroke_color = stroke_paint.color
	var stroke_texture = stroke_paint.texture
	
	var stroke_width = attr_stroke_width.get_length(inherited_view_box.size.x)

	draw_shape({
		"is_simple_shape": true,
		"scale_factor": scale_factor,
		"fill_color": fill_color,
		"fill_texture": fill_texture,
		"fill_polygon": SVGDrawing.generate_fill_rect_points(position.x, position.y, width, height),
		"fill_uv": SVGDrawing.generate_fill_rect_uv(position.x, position.y, width, height, fill_texture.get_width()) if fill_texture != null else null,
		"stroke_color": stroke_color,
		"stroke_texture": stroke_texture,
		"stroke_points": SVGDrawing.generate_stroke_rect_points(position.x, position.y, width, height),
		"stroke_width": stroke_width,
		"stroke_closed": true,
	})


# Internal Methods

func _calculate_bounding_box():
	var position = Vector2(
		attr_x.get_length(inherited_view_box.size.x),
		attr_y.get_length(inherited_view_box.size.y)
	)
	
	var width = 0
	if attr_width is SVGLengthPercentage:
		width = attr_width.get_length(inherited_view_box.size.x)
		
	var height = 0
	if attr_height is SVGLengthPercentage:
		height = attr_height.get_length(inherited_view_box.size.y)

	_bounding_box = Rect2(
		position.x,
		position.y,
		width,
		height
	)
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

func _set_attr_width(width):
	width = get_style("width", width)
	if typeof(width) != TYPE_STRING:
		attr_width = width
	else:
		if width == SVGValueConstant.AUTO:
			attr_width = width
		else:
			attr_width = SVGLengthPercentage.new(width)
	apply_props()

func _set_attr_height(height):
	height = get_style("height", height)
	if typeof(height) != TYPE_STRING:
		attr_height = height
	else:
		if height == SVGValueConstant.AUTO:
			attr_height = height
		else:
			attr_height = SVGLengthPercentage.new(height)
	apply_props()

func _set_attr_rx(rx):
	rx = get_style("rx", rx)
	if typeof(rx) != TYPE_STRING:
		attr_rx = rx
	else:
		attr_rx = SVGLengthPercentage.new(rx)
	apply_props()

func _set_attr_ry(ry):
	ry = get_style("ry", ry)
	if typeof(ry) != TYPE_STRING:
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
