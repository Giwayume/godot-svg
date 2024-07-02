extends "svg_controller_element.gd"

#------------#
# Attributes #
#------------#

var attr_cx = SVGLengthPercentage.new("0"): set = _set_attr_cx
var attr_cy = SVGLengthPercentage.new("0"): set = _set_attr_cy
var attr_r = SVGLengthPercentage.new("0"): set = _set_attr_r
var attr_path_length = SVGValueConstant.NONE: set = _set_attr_path_length

#-----------#
# Lifecycle #
#-----------#

func _init():
	node_name = "circle"

func _process_polygon():
	var scale_factor = get_scale_factor()
	var center = Vector2(
		attr_cx.get_length(inherited_view_box.size.x),
		attr_cy.get_length(inherited_view_box.size.y)
	)
	var radius = attr_r.get_length(inherited_view_box.size.x)
	var circumference = 2 * PI * radius
	
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

#------------------#
# Internal Methods #
#------------------#

func _calculate_bounding_box():
	var center = Vector2(
		attr_cx.get_length(inherited_view_box.size.x),
		attr_cy.get_length(inherited_view_box.size.y)
	)
	var radius = attr_r.get_length(inherited_view_box.size.x)
	_bounding_box = Rect2(
		center.x - radius,
		center.y - radius,
		(radius * 2),
		(radius * 2)
	)
	emit_signal("bounding_box_calculated", _bounding_box)
	if parent_controller != null and parent_controller.node_name == "g":
		parent_controller._calculate_bounding_box()

#-------------------#
# Getters / Setters #
#-------------------#

func _set_attr_cx(cx):
	cx = get_style("cx", cx)
	if typeof(cx) != TYPE_STRING:
		attr_cx = cx
	else:
		attr_cx = SVGLengthPercentage.new(cx)
	_rerender_prop_cache.erase("processed_polygon")
	apply_props("cx")

func _set_attr_cy(cy):
	cy = get_style("cy", cy)
	if typeof(cy) != TYPE_STRING:
		attr_cy = cy
	else:
		attr_cy = SVGLengthPercentage.new(cy)
	_rerender_prop_cache.erase("processed_polygon")
	apply_props("cy")

func _set_attr_r(r):
	r = get_style("r", r)
	if typeof(r) != TYPE_STRING:
		attr_r = r
	else:
		attr_r = SVGLengthPercentage.new(r)
	_rerender_prop_cache.erase("processed_polygon")
	apply_props("r")

func _set_attr_path_length(path_length):
	if typeof(path_length) != TYPE_STRING:
		attr_path_length = path_length
	else:
		attr_path_length = path_length.to_float()
	apply_props("path_length")
