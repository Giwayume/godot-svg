tool
extends Node2D

#---------#
# Signals #
#---------#

signal viewport_scale_changed(new_scale)
signal controllers_created()

#-----------#
# Constants #
#-----------#

const TriangulationMethod = SVGValueConstant.TriangulationMethod

#-----------------#
# User properties #
#-----------------#

var svg = null setget _set_svg, _get_svg
var fixed_scaling_ratio = 0 setget _set_fixed_scaling_ratio, _get_fixed_scaling_ratio
var antialiased = true setget _set_antialiased, _get_antialiased
var triangulation_method = TriangulationMethod.DELAUNAY setget _set_triangulation_method, _get_triangulation_method
var assume_no_self_intersections = false setget _set_assume_no_self_intersections, _get_assume_no_self_intersections
var assume_no_holes = false setget _set_assume_no_holes, _get_assume_no_holes
var disable_render_cache = false setget _set_disable_render_cache, _get_disable_render_cache

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
			"type": TYPE_REAL,
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
	update_configuration_warning()

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

func _get_antialiased():
	return _antialiased

func _set_triangulation_method(triangulation_method):
	if _triangulation_method != triangulation_method:
		_triangulation_method = triangulation_method
		controller.triangulation_method = triangulation_method
		if _svg != null and _is_ready:
			_svg.render_cache = null
		controller.generate_from_scratch()

func _get_triangulation_method():
	return _triangulation_method

func _set_assume_no_self_intersections(assume_no_self_intersections):
	if _assume_no_self_intersections != assume_no_self_intersections:
		_assume_no_self_intersections = assume_no_self_intersections
		controller.assume_no_self_intersections = assume_no_self_intersections
		if _svg != null and _is_ready:
			_svg.render_cache = null
		controller.generate_from_scratch()

func _get_assume_no_self_intersections():
	return _assume_no_self_intersections

func _set_assume_no_holes(assume_no_holes):
	if _assume_no_holes != assume_no_holes:
		_assume_no_holes = assume_no_holes
		controller.assume_no_holes = assume_no_holes
		if _svg != null and _is_ready:
			_svg.render_cache = null
		controller.generate_from_scratch()

func _get_assume_no_holes():
	return _assume_no_holes

func _set_disable_render_cache(disable_render_cache):
	if _disable_render_cache != disable_render_cache:
		_disable_render_cache = disable_render_cache
		controller.disable_render_cache = disable_render_cache
		if _svg != null and _is_ready:
			_svg.render_cache = null
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

var _is_ready: bool = false

#-----------#
# Lifecycle #
#-----------#

func _init():
	controller = SVGControllerRoot.new(self)

func _ready():
	_is_ready = true

func _enter_tree():
	if controller.is_editor_hint:
		controller.editor_plugin = get_node("/root/EditorNode/GodotSVGEditorPlugin")
	controller._enter_tree()

func _exit_tree():
	controller._exit_tree()

#func _process(delta):
#	if controller != null and controller.has_method("_process"):
#		controller._process(delta)

#----------------#
# Editor Methods #
#----------------#

func _get_configuration_warning():
	if controller != null:
		if controller.svg is Texture:
			return "You added an SVG file that is imported as \"Texture\". In the Import tab, choose \"Import As: SVG\" instead!"
		elif controller.svg != null and not controller.svg is SVGResource:
			return "You must import your SVG file as \"SVG\" in the import settings!"
		elif controller.is_gles2 and controller.antialiased:
			return "\"antialiased\" is enabled, but GLES2 does not support the antialiasing technique used by this plugin. Use the GLES3 renderer instead."
	return ""

func _get_item_rect():
	var edit_rect = Rect2()
	if controller.svg is SVGResource and controller.svg.viewport != null:
		var viewport_controller = controller._element_resource_to_controller_map[controller.svg.viewport]
		if viewport_controller != null:
			edit_rect = viewport_controller.calculate_view_box()
	return edit_rect
