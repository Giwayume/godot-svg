extends "svg_controller_element.gd"

#-----------#
# Lifecycle #
#-----------#

func _init():
	node_name = "g"
	is_canvas_group = true

#------------------#
# Internal Methods #
#------------------#

func _calculate_bounding_box():
	var left = INF
	var right = -INF
	var top = INF
	var bottom = -INF
	for child in _child_list:
		if is_instance_valid(child) and child.controller.has_method("get_bounding_box"):
			var child_bounds = child.controller.get_bounding_box()
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
	if parent_controller != null and parent_controller.node_name == "g":
		parent_controller._calculate_bounding_box()

func _on_child_bounds_changed(_child_bounding_box):
	_calculate_bounding_box()

#----------------#
# Public Methods #
#----------------#

func add_child(new_child, legible_unique_name = false):
	controlled_node.add_child_to_root(new_child, legible_unique_name)
	if not new_child.is_connected("bounding_box_calculated", Callable(self, "_on_child_bounds_changed")):
		new_child.connect("bounding_box_calculated", Callable(self, "_on_child_bounds_changed"))

func remove_child(child_to_remove):
	if child_to_remove.is_connected("bounding_box_calculated", Callable(self, "_on_child_bounds_changed")):
		child_to_remove.disconnect("bounding_box_calculated", Callable(self, "_on_child_bounds_changed"))
	controlled_node.remove_child_from_root(child_to_remove)
