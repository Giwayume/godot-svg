extends Resource
class_name SVGSource

export(Resource) var viewport = null setget _set_viewport
export(String, MULTILINE) var xml = null setget _set_xml

var node_name = "root"

func get_class():
	return "SVGSource"

func is_class(value):
	return value == "SVGSource"

func _set_viewport(new_viewport):
	viewport = new_viewport
	emit_changed()

func _set_xml(new_xml):
	xml = new_xml
	emit_changed()
