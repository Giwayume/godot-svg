extends Resource
class_name SVGSourceElement

export(String) var node_name = ""
export(String) var text = ""
export(Dictionary) var attributes = {}
export(Array, Resource) var children = []

func get_class():
	return "SVGSourceElement"

func is_class(value):
	return value == "SVGSourceElement"

# Public Methods
func add_child(new_child: SVGSourceElement):
	children.push_back(new_child)
	emit_changed()
