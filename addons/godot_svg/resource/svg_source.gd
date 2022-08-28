extends Resource
class_name SVGSource

export(Resource) var viewport = null setget _set_viewport

var node_name = "root"

func _set_viewport(new_viewport):
	viewport = new_viewport
	emit_changed()
