extends "svg_render_element.gd"

var attr_x1 = SVGLengthPercentage.new("0") setget _set_attr_x1
var attr_x2 = SVGLengthPercentage.new("0") setget _set_attr_x2
var attr_y1 = SVGLengthPercentage.new("0") setget _set_attr_y1
var attr_y2 = SVGLengthPercentage.new("0") setget _set_attr_y2
var attr_path_length = SVGValueConstant.NONE setget _set_attr_path_length

# Lifecycle

func _init():
	node_name = "line"

func _process_polygon():
	var stroke = [
		{
			"command": PathCommand.MOVE_TO,
			"points": [Vector2(
				attr_x1.get_length(inherited_view_box.size.x, inherited_view_box.position.x),
				attr_y1.get_length(inherited_view_box.size.y, inherited_view_box.position.y)
			)]
		},
		{
			"command": PathCommand.LINE_TO,
			"points": [Vector2(
				attr_x2.get_length(inherited_view_box.size.x, inherited_view_box.position.x),
				attr_y2.get_length(inherited_view_box.size.y, inherited_view_box.position.y)
			)]
		}
	]
	return {
		"is_simple_shape": true,
		"fill": [],
		"stroke": stroke,
	}

func _props_applied():
	._props_applied()
	var scale_factor = get_scale_factor()
	
	var fill_paint = resolve_fill_paint()
	var fill_color = fill_paint.color
	var fill_texture = fill_paint.texture
	var fill_texture_units = fill_paint.texture_units
	var fill_texture_uv_transform = fill_paint.texture_uv_transform
	
	var stroke_paint = resolve_stroke_paint()
	var stroke_color = stroke_paint.color
	var stroke_texture = stroke_paint.texture
	var stroke_texture_units = stroke_paint.texture_units
	var stroke_texture_uv_transform = stroke_paint.texture_uv_transform
	
	var stroke_width = attr_stroke_width.get_length(inherited_view_box.size.x)
	
	draw_shape({
		"is_simple_shape": true,
		"scale_factor": scale_factor,
		"fill_color": fill_color,
		"fill_texture": fill_texture,
		"fill_texture_units": fill_texture_units,
		"fill_texture_uv_transform": fill_texture_uv_transform,
		"fill_uv": [], # TODO
		"stroke_color": stroke_color,
		"stroke_texture": stroke_texture,
		"stroke_texture_units": stroke_texture_units,
		"stroke_texture_uv_transform": stroke_texture_uv_transform,
		"stroke_width": stroke_width,
		"stroke_closed": false,
	})


# Public Methods

func _calculate_bounding_box():
	var x1 = attr_x1.get_length(inherited_view_box.size.x, inherited_view_box.position.x)
	var y1 = attr_y1.get_length(inherited_view_box.size.y, inherited_view_box.position.y)
	var x2 = attr_x2.get_length(inherited_view_box.size.x, inherited_view_box.position.x)
	var y2 = attr_y2.get_length(inherited_view_box.size.y, inherited_view_box.position.y)
	var xl = min(x1, x2)
	var xr = max(x1, x2)
	var yt = min(y1, y2)
	var yb = max(y1, y2)
	_bounding_box = Rect2(
		xl,
		yt,
		(xr - xl),
		(yb - yt)
	)
	emit_signal("bounding_box_calculated", _bounding_box)

# Getters / Setters

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

func _set_attr_path_length(path_length):
	if typeof(path_length) != TYPE_STRING:
		attr_path_length = path_length
	else:
		attr_path_length = path_length.to_float()
	apply_props()
