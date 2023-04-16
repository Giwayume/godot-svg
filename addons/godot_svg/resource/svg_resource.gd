extends Resource
class_name SVGResource

@export var viewport: Resource: set = _set_viewport
@export var xml: String: set = _set_xml
@export var render_cache: Dictionary: set = _set_render_cache
@export var imported_path: String: set = _set_imported_path

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

func _set_render_cache(new_render_cache):
	render_cache = new_render_cache
	emit_changed()

func _set_imported_path(new_imported_path):
	imported_path = new_imported_path
	emit_changed()
