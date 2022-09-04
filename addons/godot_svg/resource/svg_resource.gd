extends Resource
class_name SVGResource

export(Resource) var viewport = null setget _set_viewport
export(String, MULTILINE) var xml = null setget _set_xml

var node_name = "root"

func get_class():
	return "SVGResource"

func is_class(value):
	return value == "SVGResource"

func _set_viewport(new_viewport):
	viewport = new_viewport
	emit_changed()

func _set_xml(new_xml):
	xml = new_xml
	emit_changed()
