extends "svg_render_element.gd"

var attr_points = [] setget _set_attr_points
var attr_path_length = SVGValueConstant.NONE setget _set_attr_path_length

# Lifecycle

func _init():
	node_name = "polyline"

func _draw():
	._draw()
	if attr_points.size() < 2:
		hide()
		return
	else:
		show()
	
	var scale_factor = get_scale_factor()
	
	var fill_paint = resolve_paint(attr_fill)
	var fill_color = fill_paint.color
	var fill_texture = fill_paint.texture
	
	var stroke_paint = resolve_paint(attr_stroke)
	var stroke_color = stroke_paint.color
	var stroke_texture = stroke_paint.texture
	
	var stroke_width = attr_stroke_width.get_length(inherited_view_box.size.x)
	
	var fill_points = PoolVector2Array()
	var stroke_points = PoolVector2Array()
	
	var current_stroke_start_point = Vector2()
	
	for current_point in attr_points:
		fill_points.push_back(current_point)
		stroke_points.push_back(current_point)
	
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
	update()

func _set_attr_path_length(path_length):
	if typeof(path_length) != TYPE_STRING:
		attr_path_length = path_length
	else:
		attr_path_length = path_length.to_float()
	update()
