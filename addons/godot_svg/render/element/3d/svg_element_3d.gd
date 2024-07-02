extends Node3D

#---------#
# Signals #
#---------#

signal bounding_box_calculated(new_bounding_box)

#-------------------#
# Public properties #
#-------------------#

var node_name: String = ""
var controller = null

#-----------#
# Lifecycle #
#-----------#

func _notification(what):
	if controller != null and controller.has_method("_notification"):
		controller._notification(what)
	if what == NOTIFICATION_PREDELETE:
		controller = null

func _ready():
	controller._ready()

func _draw():
	controller._draw()

#----------------#
# Public methods #
#----------------#

func add_child(new_child, force_readable_name = false, internal = 0):
	controller.add_child(new_child, force_readable_name)

func add_child_to_root(new_child, force_readable_name = false, internal = 0):
	super.add_child(new_child, force_readable_name)

func get_attribute(name: String):
	var value = null
	var attr_name = "attr_" + name
	if attr_name in controller:
		value = controller[attr_name]
	return value

func remove_attribute(name: String):
	var attr_name = "attr_" + name
	if attr_name in controller:
		controller[attr_name] = null

func remove_child(child_to_remove):
	controller.remove_child(child_to_remove)

func remove_child_from_root(child_to_remove):
	super.remove_child(child_to_remove)

func set_attribute(name: String, value):
	var attr_name = "attr_" + name
	if attr_name in controller:
		controller[attr_name] = value

func set_attibutes(attributes_definition: Dictionary):
	for name in attributes_definition:
		var attr_name = "attr_" + name
		if attr_name in controller:
			controller[attr_name] = attributes_definition[name]
