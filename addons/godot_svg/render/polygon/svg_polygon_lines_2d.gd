extends Node2D

const SVGPolygonLine2D = preload("svg_polygon_line_2d.gd")

var dash_array = [] setget _set_dash_array
var dash_offset = 0 setget _set_dash_offset
var inherited_view_box = Rect2(0, 0, 1, 1) setget _set_inherited_view_box
var line_attributes = {} setget _set_line_attributes
var points = [] setget _set_points

var _lines = []

# Internal methods

func _create_lines():
	call_deferred("_create_lines_deferred")

func _create_lines_deferred():
	for existing_line in _lines:
		existing_line.get_parent().remove_child(existing_line)
		existing_line.queue_free()
	_lines = []
	
	if points.size() == 0:
		return
	
	var full_percentage_size = sqrt((pow(inherited_view_box.size.x, 2) + pow(inherited_view_box.size.y, 2)) / 2)
	
	if dash_array.size() == 0:
		var new_line = SVGPolygonLine2D.new()
		new_line.points = points
		for line_attribute in line_attributes:
			new_line[line_attribute] = line_attributes[line_attribute]
		_lines.push_back(new_line)
		add_child(new_line)
		new_line.draw_now()
	else:
		# Figure out starting offset for dash
		var current_dash_size_index = 0
		var current_dash_size = 0.0
		var current_distance_traversed = 0.0
		var is_dash_render = true
		if dash_offset != 0:
			var repeat_size = 0
			for size in dash_array:
				repeat_size += size
			var repeat_count = floor(abs(dash_offset / repeat_size))
			var cumulative_offset = repeat_count * dash_offset
			if int(repeat_count) % 2 == 1:
				is_dash_render = false
			if dash_offset > 0:
				for current_index in range(0, dash_array.size()):
					var size = float(dash_array[current_index])
					cumulative_offset += size
					if cumulative_offset > dash_offset:
						current_dash_size_index = current_index
						current_distance_traversed = cumulative_offset - dash_offset
			else:
				cumulative_offset *= -1
				for current_index in range(dash_array.size() - 1, -1, -1):
					var size = float(dash_array[current_index])
					cumulative_offset -= size
					if cumulative_offset < dash_offset:
						current_dash_size_index = current_index
						current_distance_traversed = cumulative_offset - dash_offset
		current_dash_size = float(dash_array[current_dash_size_index])
		
		var points_reference = Array(points)
		var point_lists = []
		var previous_point = Vector2()
		var current_point_list = PoolVector2Array([points_reference[0]])
		var current_point = points_reference[0]
		var point_index = 1
		while point_index < points_reference.size():
			previous_point = current_point
			current_point = points_reference[point_index]
			var direction = previous_point.direction_to(current_point)
			var distance = previous_point.distance_to(current_point)
			if current_distance_traversed + distance > current_dash_size:
				var current_line_travel = current_dash_size - current_distance_traversed
				var point_end = previous_point + (direction * current_line_travel)
				current_point_list.push_back(point_end)
				current_point = point_end
				if current_dash_size_index < dash_array.size() - 1:
					current_dash_size_index += 1
				else:
					current_dash_size_index = 0
				current_distance_traversed = 0.0
				current_dash_size = float(dash_array[current_dash_size_index])
				if is_dash_render:
					point_lists.push_back(current_point_list)
				is_dash_render = not is_dash_render
				current_point_list = PoolVector2Array([point_end])
			elif point_index == points_reference.size() - 1:
				current_point_list.push_back(current_point)
				if is_dash_render:
					point_lists.push_back(current_point_list)
				break
			else:
				current_distance_traversed += distance
				current_point_list.push_back(current_point)
				point_index += 1
		
			if point_index > 65536: # Prevent infinite loop
				break
		
		for new_points in point_lists:
			var new_line = SVGPolygonLine2D.new()
			new_line.points = new_points
			for line_attribute in line_attributes:
				new_line[line_attribute] = line_attributes[line_attribute]
			_lines.push_back(new_line)
			add_child(new_line)
			new_line.draw_now()

# Getters / Setters

func _set_dash_array(new_dash_array):
	dash_array = new_dash_array
	_create_lines()

func _set_dash_offset(new_dash_offset):
	dash_offset = float(new_dash_offset)
	_create_lines()

func _set_inherited_view_box(new_inherited_view_box):
	inherited_view_box = new_inherited_view_box
	_create_lines()

func _set_line_attributes(new_line_attributes):
	line_attributes = new_line_attributes
	_create_lines()

func _set_points(new_points):
	points = new_points
	_create_lines()
