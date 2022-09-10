extends "svg_render_element.gd"

# Lifecycle

func _init():
	node_name = "g"
	is_render_group = true

func _draw():
	draw_shape({})

# Internal Methods

func _calculate_bounding_box():
	var left = INF
	var right = -INF
	var top = INF
	var bottom = -INF
	for child in _child_list:
		if is_instance_valid(child) and child.has_method("get_bounding_box"):
			var child_bounds = child.get_bounding_box()
			if child_bounds.position.x < left:
				left = child_bounds.position.x
			if child_bounds.position.y < top:
				top = child_bounds.position.y
			if child_bounds.position.x + child_bounds.size.x > right:
				right = child_bounds.position.x + child_bounds.size.x
			if child_bounds.position.y + child_bounds.size.y > bottom:
				bottom = child_bounds.position.y + child_bounds.size.y
	_bounding_box = Rect2(left, top, right - left, bottom - top)
	emit_signal("bounding_box_calculated", _bounding_box)

func _on_child_bounds_changed(_child_bounding_box):
	_calculate_bounding_box()

# Public Methods

func add_child(new_child, legible_unique_name = false):
	.add_child(new_child, legible_unique_name)
	if not new_child.is_connected("bounding_box_calculated", self, "_on_child_bounds_changed"):
		new_child.connect("bounding_box_calculated", self, "_on_child_bounds_changed")

func remove_child(child_to_remove):
	if child_to_remove.is_connected("bounding_box_calculated", self, "_on_child_bounds_changed"):
		child_to_remove.disconnect("bounding_box_calculated", self, "_on_child_bounds_changed")
	.remove_child(child_to_remove)
