extends "svg_controller_element.gd"

#------------#
# Attributes #
#------------#

var attr_points = []: set = _set_attr_points
var attr_path_length = SVGValueConstant.NONE: set = _set_attr_path_length

#-----------#
# Lifecycle #
#-----------#

func _init():
	node_name = "polyline"

func _process_polygon():
	var fill = []
	var stroke = []
	
	var point_index = 0
	for current_point in attr_points:
		fill.push_back({
			"command": PathCommand.MOVE_TO if point_index == 0 else PathCommand.LINE_TO,
			"points": [current_point],
		})
		stroke.push_back({
			"command": PathCommand.MOVE_TO if point_index == 0 else PathCommand.LINE_TO,
			"points": [current_point],
		})
		point_index += 1
	fill.push_back({
		"command": PathCommand.CLOSE_PATH,
	})
	stroke.push_back({
		"command": PathCommand.CLOSE_PATH,
	})
	
	return {
		"is_simple_shape": false,
		"fill": fill,
		"stroke": stroke,
		"stroke_closed": false,
	}

func _props_applied(changed_props = []):
	super._props_applied(changed_props)
	if attr_points.size() < 2:
		controlled_node.hide()
		return
	else:
		controlled_node.show()

#------------------#
# Internal Methods #
#------------------#

func _calculate_bounding_box():
	# TODO - currently only calculated during render.
	emit_signal("bounding_box_calculated", _bounding_box)
	if parent_controller != null and parent_controller.node_name == "g":
		parent_controller._calculate_bounding_box()

#-------------------#
# Getters / Setters #
#-------------------#

func _set_attr_points(points):
	points = get_style("points", points)
	if typeof(points) != TYPE_STRING:
		attr_points = points
	else:
		attr_points = []
		var current_point = Vector2()
		var value_index = 0
		var space_split = points.split(" ", false)
		for space_token in space_split:
			var comma_split = space_token.split(",", false)
			for comma_token in comma_split:
				if value_index % 2 == 0:
					current_point.x = comma_token.to_float()
				else:
					current_point.y = comma_token.to_float()
					attr_points.push_back(current_point)
					current_point = Vector2()
				value_index += 1
	apply_props("points")

func _set_attr_path_length(path_length):
	if typeof(path_length) != TYPE_STRING:
		attr_path_length = path_length
	else:
		attr_path_length = path_length.to_float()
	apply_props("path_length")
