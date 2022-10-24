extends "svg_render_element.gd"

const ARC_POINTS_MAX = 256

var attr_cx = SVGLengthPercentage.new("0") setget _set_attr_cx
var attr_cy = SVGLengthPercentage.new("0") setget _set_attr_cy
var attr_r = SVGLengthPercentage.new("0") setget _set_attr_r
var attr_path_length = SVGValueConstant.NONE setget _set_attr_path_length

var svg_fill = null
var svg_stroke = null

# Lifecycle

func _init():
	node_name = "circle"

func _process_polygon():
	var scale_factor = get_scale_factor()
	var center = Vector2(
		attr_cx.get_length(inherited_view_box.size.x, inherited_view_box.position.x),
		attr_cy.get_length(inherited_view_box.size.y, inherited_view_box.position.y)
	)
	var radius = attr_r.get_length(inherited_view_box.size.x)
	var circumference = 2 * PI * radius
	var arc_points = max(20.0, round(circumference * _current_arc_resolution.x))
	
	var arc_angle = PI / 2
	var bezier_segments = (2.0 * PI) / arc_angle
	var handle_offset_unit = (4.0/3.0) * tan(PI / (2 * bezier_segments))
	var handle_offset = handle_offset_unit * radius
	var fill = [
		{
			"command": PathCommand.MOVE_TO,
			"points": [center + Vector2(0.0, -radius)],
		},
		{
			"command": PathCommand.CUBIC_BEZIER_CURVE,
			"points": [
				center + Vector2(handle_offset, -radius),
				center + Vector2(radius, -handle_offset),
				center + Vector2(radius, 0.0),
			],
		},
		{
			"command": PathCommand.CUBIC_BEZIER_CURVE,
			"points": [
				center + Vector2(radius, handle_offset),
				center + Vector2(handle_offset, radius),
				center + Vector2(0.0, radius),
			],
		},
		{
			"command": PathCommand.CUBIC_BEZIER_CURVE,
			"points": [
				center + Vector2(-handle_offset, radius),
				center + Vector2(-radius, handle_offset),
				center + Vector2(-radius, 0.0),
			],
		},
		{
			"command": PathCommand.CUBIC_BEZIER_CURVE,
			"points": [
				center + Vector2(-radius, -handle_offset),
				center + Vector2(-handle_offset, -radius),
				center + Vector2(0.0, -radius),
			],
		},
		{
			"command": PathCommand.CLOSE_PATH,
		},
	]
	var stroke = [
		{
			"command": PathCommand.MOVE_TO,
			"points": [center + Vector2(0.0, -radius)],
		},
		{
			"command": PathCommand.CUBIC_BEZIER_CURVE,
			"points": [
				center + Vector2(handle_offset, -radius),
				center + Vector2(radius, -handle_offset),
				center + Vector2(radius, 0.0),
			],
		},
		{
			"command": PathCommand.CUBIC_BEZIER_CURVE,
			"points": [
				center + Vector2(radius, handle_offset),
				center + Vector2(handle_offset, radius),
				center + Vector2(0.0, radius),
			],
		},
		{
			"command": PathCommand.CUBIC_BEZIER_CURVE,
			"points": [
				center + Vector2(-handle_offset, radius),
				center + Vector2(-radius, handle_offset),
				center + Vector2(-radius, 0.0),
			],
		},
		{
			"command": PathCommand.CUBIC_BEZIER_CURVE,
			"points": [
				center + Vector2(-radius, -handle_offset),
				center + Vector2(-handle_offset, -radius),
				center + Vector2(0.0, -radius),
			],
		},
		{
			"command": PathCommand.CLOSE_PATH,
		},
	]
	
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

#func _calculate_arc_resolution(scale_factor): # Override to limit max points used.
#	var arc_resolution = ._calculate_arc_resolution(scale_factor)
#	var radius = attr_r.get_length(inherited_view_box.size.x)
#	var circumference = 2 * PI * radius
#	if round(circumference * arc_resolution.x) > ARC_POINTS_MAX:
#		arc_resolution = Vector2(
#			circumference / ARC_POINTS_MAX,
#			circumference / ARC_POINTS_MAX
#		)
#	return arc_resolution

func _calculate_bounding_box():
	var center = Vector2(
		attr_cx.get_length(inherited_view_box.size.x, inherited_view_box.position.x),
		attr_cy.get_length(inherited_view_box.size.y, inherited_view_box.position.y)
	)
	var radius = attr_r.get_length(inherited_view_box.size.x)
	_bounding_box = Rect2(
		center.x - radius,
		center.y - radius,
		(radius * 2),
		(radius * 2)
	)
	emit_signal("bounding_box_calculated", _bounding_box)

# Getters / Setters

func _set_attr_cx(cx):
	cx = get_style("cx", cx)
	if typeof(cx) != TYPE_STRING:
		attr_cx = cx
	else:
		attr_cx = SVGLengthPercentage.new(cx)
	_rerender_prop_cache.erase("processed_polygon")
	apply_props()

func _set_attr_cy(cy):
	cy = get_style("cy", cy)
	if typeof(cy) != TYPE_STRING:
		attr_cy = cy
	else:
		attr_cy = SVGLengthPercentage.new(cy)
	_rerender_prop_cache.erase("processed_polygon")
	apply_props()

func _set_attr_r(r):
	r = get_style("r", r)
	if typeof(r) != TYPE_STRING:
		attr_r = r
	else:
		attr_r = SVGLengthPercentage.new(r)
	_rerender_prop_cache.erase("processed_polygon")
	apply_props()

func _set_attr_path_length(path_length):
	if typeof(path_length) != TYPE_STRING:
		attr_path_length = path_length
	else:
		attr_path_length = path_length.to_float()
	apply_props()
