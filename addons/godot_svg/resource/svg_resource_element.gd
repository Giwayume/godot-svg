extends Resource
class_name SVGResourceElement

export(String) var node_name = ""
export(String) var text = ""
export(Dictionary) var attributes = {}
export(Array, Resource) var children = []

func get_class():
	return "SVGResourceElement"

func is_class(value):
	return value == "SVGResourceElement"

# Public Methods
func add_child(new_child: SVGResourceElement):
	children.push_back(new_child)
	emit_changed()
