@tool
extends Node2D
class_name SVG2D

#---------#
# Signals #
#---------#

signal viewport_scale_changed(new_scale)
signal controllers_created()

#-----------#
# Constants #
#-----------#

const SVGControllerRoot = preload("../render/controller/svg_controller_root.gd")
const TriangulationMethod = SVGValueConstant.TriangulationMethod

#-----------------#
# User properties #
#-----------------#

var svg = null: get = _get_svg, set = _set_svg
var fixed_scaling_ratio = 0: get = _get_fixed_scaling_ratio, set = _set_fixed_scaling_ratio
var antialiased = true: get = _get_antialiased, set = _set_antialiased
var triangulation_method = TriangulationMethod.DELAUNAY: get = _get_triangulation_method, set = _set_triangulation_method
var assume_no_self_intersections = false: get = _get_assume_no_self_intersections, set = _set_assume_no_self_intersections
var assume_no_holes = false: get = _get_assume_no_holes, set = _set_assume_no_holes
var disable_render_cache = false: get = _get_disable_render_cache, set = _set_disable_render_cache

var _svg = null
var _fixed_scaling_ratio = 0
var _antialiased = true
var _triangulation_method = TriangulationMethod.DELAUNAY
var _assume_no_self_intersections = false
var _assume_no_holes = false
var _disable_render_cache = false

func _get_property_list():
	return [
		{
			"name": "SVG2D",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_CATEGORY,
		},
		{
			"name": "svg",
			"type": TYPE_OBJECT,
			"hint": PROPERTY_HINT_RESOURCE_TYPE,
#			"hint_string": "SVGResource", # Disabling - Godot bug?
		},
		{
			"name": "fixed_scaling_ratio",
			"type": TYPE_FLOAT,
		},
		{
			"name": "antialiased",
			"type": TYPE_BOOL,
		},
		{
			"name": "triangulation_method",
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": "Delaunay,Earcut",
		},
		{
			"name": "assume_no_self_intersections",
			"type": TYPE_BOOL,
		},
		{
			"name": "assume_no_holes",
			"type": TYPE_BOOL,
		},
		{
			"name": "disable_render_cache",
			"type": TYPE_BOOL,
		}
	]

#-------------------#
# Getters / Setters #
#-------------------#

func _set_svg(svg):
	_svg = svg
	controller.svg = svg
	controller.generate_from_scratch()
	update_configuration_warnings()

func _get_svg():
	return _svg

func _set_fixed_scaling_ratio(fixed_scaling_ratio):
	if _fixed_scaling_ratio != fixed_scaling_ratio:
		_fixed_scaling_ratio = fixed_scaling_ratio
		controller.fixed_scaling_ratio = fixed_scaling_ratio
		controller.generate_from_scratch()

func _get_fixed_scaling_ratio():
	return _fixed_scaling_ratio

func _set_antialiased(antialiased):
	if _antialiased != antialiased:
		_antialiased = antialiased
		controller.antialiased = antialiased
		update_configuration_warnings()

func _get_antialiased():
	return _antialiased

func _set_triangulation_method(triangulation_method):
	if _triangulation_method != triangulation_method:
		_triangulation_method = triangulation_method
		controller.triangulation_method = triangulation_method
		if _svg != null and _is_ready:
			_svg.render_cache = {}
		controller.generate_from_scratch()

func _get_triangulation_method():
	return _triangulation_method

func _set_assume_no_self_intersections(assume_no_self_intersections):
	if _assume_no_self_intersections != assume_no_self_intersections:
		_assume_no_self_intersections = assume_no_self_intersections
		controller.assume_no_self_intersections = assume_no_self_intersections
		if _svg != null and _is_ready:
			_svg.render_cache = {}
		controller.generate_from_scratch()

func _get_assume_no_self_intersections():
	return _assume_no_self_intersections

func _set_assume_no_holes(assume_no_holes):
	if _assume_no_holes != assume_no_holes:
		_assume_no_holes = assume_no_holes
		controller.assume_no_holes = assume_no_holes
		if _svg != null and _is_ready:
			_svg.render_cache = {}
		controller.generate_from_scratch()

func _get_assume_no_holes():
	return _assume_no_holes

func _set_disable_render_cache(disable_render_cache):
	if _disable_render_cache != disable_render_cache:
		_disable_render_cache = disable_render_cache
		controller.disable_render_cache = disable_render_cache
		if _svg != null and _is_ready:
			_svg.render_cache = {}
		controller.generate_from_scratch()
	
func _get_disable_render_cache():
	return _disable_render_cache

#-------------------#
# Public Properties #
#-------------------#

var controller = null # SVGControllerRoot instance

#--------------------#
# Private Properties #
#--------------------#

var _editor_plugin = null
var _is_ready: bool = false

#-----------#
# Lifecycle #
#-----------#

func _init():
	_initialize_controller()

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if is_instance_valid(controller):
			controller._predelete()

func _ready():
	_is_ready = true

func _enter_tree():
	if controller.is_editor_hint:
		_editor_plugin = get_tree().get_root().find_child("GodotSVGEditorPlugin", true, false)
		controller.editor_plugin = _editor_plugin
		_editor_plugin.connect("svg_plugin_scripts_changed", Callable(self, "_on_svg_plugin_scripts_changed"))
	controller._enter_tree()

func _exit_tree():
	controller._exit_tree()
	
	if _editor_plugin != null:
		_editor_plugin.disconnect("svg_plugin_scripts_changed", Callable(self, "_on_svg_plugin_scripts_changed"))

#func _process(delta):
#	if controller != null and controller.has_method("_process"):
#		controller._process(delta)

#------------------#
# Internal Methods #
#------------------#

func _initialize_controller():
	var old_controller = controller
	
	controller = SVGControllerRoot.new(self)
	controller.svg = _svg
	controller.fixed_scaling_ratio = _fixed_scaling_ratio
	controller.antialiased = _antialiased
	controller.triangulation_method = _triangulation_method
	controller.assume_no_self_intersections = _assume_no_self_intersections
	controller.assume_no_holes = _assume_no_holes
	controller.disable_render_cache = _disable_render_cache
	
	if old_controller != null:
		old_controller._exit_tree()
		old_controller._predelete()

#----------------#
# Editor Methods #
#----------------#

func _get_configuration_warning():
	if controller != null:
		if controller.svg is Texture2D:
			return "You added an SVG file that is imported as \"Texture2D\". In the Import tab, choose \"Import As: SVG\" instead!"
		elif controller.svg != null and not controller.svg is SVGResource:
			return "You must import your SVG file as \"SVG\" in the import settings!"
		elif controller.is_gles2 and controller.antialiased:
			return "\"antialiased\" is enabled, but GLES2 does not support the antialiasing technique used by this plugin. Use the GLES3 renderer instead."
	return ""

func _edit_get_rect():
	var edit_rect = Rect2()
	if controller.svg is SVGResource and controller.svg.viewport != null:
		if controller._element_resource_to_controller_map.has(controller.svg.viewport):
			var viewport_controller = controller._element_resource_to_controller_map[controller.svg.viewport]
			if viewport_controller != null:
				edit_rect = viewport_controller.calculate_view_box()
	return edit_rect

func _on_svg_plugin_scripts_changed():
	var children = get_children()
	for child in children:
		remove_child(child)
	_initialize_controller()

#----------------#
# Public Methods #
#----------------#

func get_element_by_id(id: String):
	return controller.resolve_url("#" + id)

func get_elements_by_name(name: String):
	return controller.get_elements_by_name(name)

func load_svg_from_buffer(buffer: PackedByteArray):
	return controller.load_svg_from_buffer(buffer)
