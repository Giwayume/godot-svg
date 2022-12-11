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


func _process_polygon():
	var position = Vector2(
		attr_x.get_length(inherited_view_box.size.x, inherited_view_box.position.x),
		attr_y.get_length(inherited_view_box.size.y, inherited_view_box.position.y)
	)
	
	var width = 0
	if attr_width is SVGLengthPercentage:
		width = attr_width.get_length(inherited_view_box.size.x)
	
	var height = 0
	if attr_height is SVGLengthPercentage:
		height = attr_height.get_length(inherited_view_box.size.y)
	
	var rx = 0
	if attr_rx is SVGLengthPercentage:
		rx = attr_rx.get_length(inherited_view_box.size.x)
	
	var ry = rx
	if attr_ry is SVGLengthPercentage:
		ry = attr_ry.get_length(inherited_view_box.size.y)
	
	var half_width = width / 2.0
	var half_height = height / 2.0
	
	rx = min(rx, half_width)
	ry = min(ry, half_height)
	
	if rx == 0 or ry == 0:
		rx = 0
		ry = 0
	
	var arc_angle = PI / 2
	var bezier_segments = (2.0 * PI) / arc_angle
	var handle_offset_unit = (4.0/3.0) * tan(PI / (2 * bezier_segments))
	var handle_offset_x = handle_offset_unit * rx
	var handle_offset_y = handle_offset_unit * ry
	
	var fill = [
		{
			"command": PathCommand.MOVE_TO,
			"points": [position + Vector2(rx, 0.0)],
		},
	]
	# Top edge
	if rx < half_width or ry == 0:
		fill.push_back({
			"command": PathCommand.LINE_TO,
			"points": [position + Vector2(width - rx, 0.0)],
		})
	# Top right corner
	if rx > 0 and ry > 0:
		fill.push_back({
			"command": PathCommand.CUBIC_BEZIER_CURVE,
			"points": [
				position + Vector2(width - rx + handle_offset_x, 0.0),
				position + Vector2(width, ry - handle_offset_y),
				position + Vector2(width, ry),
			]
		})
	# Right edge
	if ry < half_height or rx == 0:
		fill.push_back({
			"command": PathCommand.LINE_TO,
			"points": [position + Vector2(width, height - ry)],
		})
	# Bottom right corner
	if rx > 0 and ry > 0:
		fill.push_back({
			"command": PathCommand.CUBIC_BEZIER_CURVE,
			"points": [
				position + Vector2(width, height - ry + handle_offset_y),
				position + Vector2(width - rx + handle_offset_x, height),
				position + Vector2(width - rx, height),
			]
		})
	# Bottom edge
	if rx < half_width or ry == 0:
		fill.push_back({
			"command": PathCommand.LINE_TO,
			"points": [position + Vector2(rx, height)],
		})
	# Bottom left corner
	if rx > 0 and ry > 0:
		fill.push_back({
			"command": PathCommand.CUBIC_BEZIER_CURVE,
			"points": [
				position + Vector2(rx - handle_offset_x, height),
				position + Vector2(0.0, height - ry + handle_offset_y),
				position + Vector2(0.0, height - ry),
			]
		})
	# Left edge
	if ry < half_height or rx == 0:
		fill.push_back({
			"command": PathCommand.LINE_TO,
			"points": [position + Vector2(0.0, ry)],
		})
	# Top left corner
	if rx > 0 and ry > 0:
		fill.push_back({
			"command": PathCommand.CUBIC_BEZIER_CURVE,
			"points": [
				position + Vector2(0.0, ry - handle_offset_y),
				position + Vector2(rx - handle_offset_x, 0.0),
				position + Vector2(rx, 0.0),
			]
		})
	fill.push_back({
		"command": PathCommand.CLOSE_PATH,
	})
	var stroke = fill.duplicate(true)
	
	return {
		"is_simple_shape": true,
		"fill": fill,
		"stroke": stroke,
		"stroke_closed": true,
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
		"stroke_color": stroke_color,
		"stroke_texture": stroke_texture,
		"stroke_texture_units": stroke_texture_units,
		"stroke_texture_uv_transform": stroke_texture_uv_transform,
		"stroke_width": stroke_width,
	})


# Internal Methods

func _calculate_arc_resolution(_scale_factor): # Override to disable.
	return Vector2(1.0, 1.0)

func _calculate_bounding_box():
	var position = Vector2(
		attr_x.get_length(inherited_view_box.size.x, inherited_view_box.position.x),
		attr_y.get_length(inherited_view_box.size.y, inherited_view_box.position.y)
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
