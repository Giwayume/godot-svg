extends "svg_render_element.gd"

var attr_points = [] setget _set_attr_points
var attr_path_length = SVGValueConstant.NONE setget _set_attr_path_length

# Lifecycle

func _init():
	node_name = "polygon"

func _process_polygon():
	var current_stroke_start_point = Vector2()
	
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
		"stroke_closed": true,
	}

func _props_applied():
	._props_applied()
	if attr_points.size() < 2:
		hide()
		return
	else:
		show()
	
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

func _calculate_bounding_box():
	# TODO
	_bounding_box = Rect2(0, 0, 0, 0)
	emit_signal("bounding_box_calculated", _bounding_box)

# Getters / Setters

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
	apply_props()

func _set_attr_path_length(path_length):
	if typeof(path_length) != TYPE_STRING:
		attr_path_length = path_length
	else:
		attr_path_length = path_length.to_float()
	apply_props()
