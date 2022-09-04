extends "svg_render_element.gd"

var attr_x1 = SVGLengthPercentage.new("0") setget _set_attr_x1
var attr_x2 = SVGLengthPercentage.new("0") setget _set_attr_x2
var attr_y1 = SVGLengthPercentage.new("0") setget _set_attr_y1
var attr_y2 = SVGLengthPercentage.new("0") setget _set_attr_y2
var attr_path_length = SVGValueConstant.NONE setget _set_attr_path_length

# Lifecycle

func _init():
	node_name = "line"

func _draw():
	var scale_factor = get_scale_factor()
	
	var fill_paint = resolve_paint(attr_fill)
	var fill_color = fill_paint.color
	var fill_texture = fill_paint.texture
	
	var stroke_paint = resolve_paint(attr_stroke)
	var stroke_color = stroke_paint.color
	var stroke_texture = stroke_paint.texture
	
	var stroke_width = attr_stroke_width.get_length(inherited_view_box.size.x)
	
	var fill_points = PoolVector2Array([
		Vector2(
			attr_x1.get_length(inherited_view_box.size.x),
			attr_y1.get_length(inherited_view_box.size.y)
		),
		Vector2(
			attr_x2.get_length(inherited_view_box.size.x),
			attr_y2.get_length(inherited_view_box.size.y)
		)
	])
	var stroke_points = PoolVector2Array([
		Vector2(
			attr_x1.get_length(inherited_view_box.size.x),
			attr_y1.get_length(inherited_view_box.size.y)
		),
		Vector2(
			attr_x2.get_length(inherited_view_box.size.x),
			attr_y2.get_length(inherited_view_box.size.y)
		)
	])
	
	draw_shape({
		"scale_factor": scale_factor,
		"fill_color": fill_color,
		"fill_texture": fill_texture,
		"fill_polygon": fill_points,
		"fill_uv": [], # TODO
		"stroke_color": stroke_color,
		"stroke_texture": stroke_texture,
		"stroke_points": stroke_points,
		"stroke_width": stroke_width,
		"stroke_closed": false,
	})


# Public Methods

func get_bounding_box():
	# TODO
	return Rect2(0, 0, 0, 0)

# Getters / Setters

func _set_attr_x1(x1):
	if typeof(x1) != TYPE_STRING:
		attr_x1 = x1
	else:
		attr_x1 = SVGLengthPercentage.new(x1)
	update()

func _set_attr_x2(x2):
	if typeof(x2) != TYPE_STRING:
		attr_x2 = x2
	else:
		attr_x2 = SVGLengthPercentage.new(x2)
	update()

func _set_attr_y1(y1):
	if typeof(y1) != TYPE_STRING:
		attr_y1 = y1
	else:
		attr_y1 = SVGLengthPercentage.new(y1)
	update()

func _set_attr_y2(y2):
	if typeof(y2) != TYPE_STRING:
		attr_y2 = y2
	else:
		attr_y2 = SVGLengthPercentage.new(y2)
	update()

func _set_attr_path_length(path_length):
	if typeof(path_length) != TYPE_STRING:
		attr_path_length = path_length
	else:
		attr_path_length = path_length.to_float()
	update()
