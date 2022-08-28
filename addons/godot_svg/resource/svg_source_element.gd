extends Resource
class_name SVGSourceElement

export(Resource) var renderer = null
export(String) var node_name = ""
export(Dictionary) var attributes = {}
export(Array, Resource) var children = []

# Public Methods
func add_child(new_child: SVGSourceElement):
	children.push_back(new_child)
	emit_changed()
