extends "svg_controller_element.gd"

#------------#
# Attributes #
#------------#

var attr_cx = SVGLengthPercentage.new("0"): set = _set_attr_cx
var attr_cy = SVGLengthPercentage.new("0"): set = _set_attr_cy
var attr_rx = SVGValueConstant.AUTO: set = _set_attr_rx
var attr_ry = SVGValueConstant.AUTO: set = _set_attr_ry
var attr_path_length = SVGValueConstant.NONE: set = _set_attr_path_length

#-----------#
# Lifecycle #
#-----------#

func _init():
	node_name = "ellipse"

func _process_polygon():
	var scale_factor = get_scale_factor()
	var center = Vector2(
		attr_cx.get_length(inherited_view_box.size.x),
		attr_cy.get_length(inherited_view_box.size.y)
	)
	var radius_x = attr_rx.get_length(inherited_view_box.size.x)
	var radius_y = attr_ry.get_length(inherited_view_box.size.y)
	var circumference = PI * (radius_x + radius_y)
	
	var arc_angle = PI / 2
	var bezier_segments = (2.0 * PI) / arc_angle
	var handle_offset_unit = (4.0/3.0) * tan(PI / (2 * bezier_segments))
	var handle_offset_x = handle_offset_unit * radius_x
	var handle_offset_y = handle_offset_unit * radius_y
	var fill = [
		{
			"command": PathCommand.MOVE_TO,
			"points": [center + Vector2(0.0, -radius_y)],
		},
		{
			"command": PathCommand.CUBIC_BEZIER_CURVE,
			"points": [
				center + Vector2(handle_offset_x, -radius_y),
				center + Vector2(radius_x, -handle_offset_y),
				center + Vector2(radius_x, 0.0),
			],
		},
		{
			"command": PathCommand.CUBIC_BEZIER_CURVE,
			"points": [
				center + Vector2(radius_x, handle_offset_y),
				center + Vector2(handle_offset_x, radius_y),
				center + Vector2(0.0, radius_y),
			],
		},
		{
			"command": PathCommand.CUBIC_BEZIER_CURVE,
			"points": [
				center + Vector2(-handle_offset_x, radius_y),
				center + Vector2(-radius_x, handle_offset_y),
				center + Vector2(-radius_x, 0.0),
			],
		},
		{
			"command": PathCommand.CUBIC_BEZIER_CURVE,
			"points": [
				center + Vector2(-radius_x, -handle_offset_y),
				center + Vector2(-handle_offset_x, -radius_y),
				center + Vector2(0.0, -radius_y),
			],
		},
		{
			"command": PathCommand.CLOSE_PATH,
		},
	]
	var stroke = [
		{
			"command": PathCommand.MOVE_TO,
			"points": [center + Vector2(0.0, -radius_y)],
		},
		{
			"command": PathCommand.CUBIC_BEZIER_CURVE,
			"points": [
				center + Vector2(handle_offset_x, -radius_y),
				center + Vector2(radius_x, -handle_offset_y),
				center + Vector2(radius_x, 0.0),
			],
		},
		{
			"command": PathCommand.CUBIC_BEZIER_CURVE,
			"points": [
				center + Vector2(radius_x, handle_offset_y),
				center + Vector2(handle_offset_x, radius_y),
				center + Vector2(0.0, radius_y),
			],
		},
		{
			"command": PathCommand.CUBIC_BEZIER_CURVE,
			"points": [
				center + Vector2(-handle_offset_x, radius_y),
				center + Vector2(-radius_x, handle_offset_y),
				center + Vector2(-radius_x, 0.0),
			],
		},
		{
			"command": PathCommand.CUBIC_BEZIER_CURVE,
			"points": [
				center + Vector2(-radius_x, -handle_offset_y),
				center + Vector2(-handle_offset_x, -radius_y),
				center + Vector2(0.0, -radius_y),
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
	var radius_x = attr_rx.get_length(inherited_view_box.size.x)
	var radius_y = attr_ry.get_length(inherited_view_box.size.y)
	_bounding_box = Rect2(
		center.x - radius_x,
		center.y - radius_y,
		(radius_x * 2),
		(radius_y * 2)
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
	apply_props("cx")

func _set_attr_cy(cy):
	cy = get_style("cy", cy)
	if typeof(cy) != TYPE_STRING:
		attr_cy = cy
	else:
		attr_cy = SVGLengthPercentage.new(cy)
	apply_props("cy")

func _set_attr_rx(rx):
	rx = get_style("rx", rx)
	if typeof(rx) != TYPE_STRING:
		attr_rx = rx
	else:
		if rx == SVGValueConstant.AUTO:
			attr_rx = rx
		else:
			attr_rx = SVGLengthPercentage.new(rx)
	apply_props("rx")

func _set_attr_ry(ry):
	ry = get_style("ry", ry)
	if typeof(ry) != TYPE_STRING:
		attr_ry = ry
	else:
		if ry == SVGValueConstant.AUTO:
			attr_ry = ry
		else:
			attr_ry = SVGLengthPercentage.new(ry)
	apply_props("ry")

func _set_attr_path_length(path_length):
	if typeof(path_length) != TYPE_STRING:
		attr_path_length = path_length
	else:
		attr_path_length = path_length.to_float()
	apply_props("path_length")
