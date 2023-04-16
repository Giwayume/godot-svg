extends Resource
class_name SVGResourceElement

@export var node_name: String = ""
@export var text: String = ""
@export var attributes: Dictionary = {}
@export var children: Array = [] # (Array, Resource)

func get_class():
	return "SVGResourceElement"

func is_class(value):
	return value == "SVGResourceElement"

# Public Methods
func add_child(new_child: SVGResourceElement):
	children.push_back(new_child)
	emit_changed()
