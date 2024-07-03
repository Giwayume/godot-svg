@tool
extends Control
class_name SVGRect

#-----------#
# Constants #
#-----------#

const TriangulationMethod = SVGValueConstant.TriangulationMethod
const SVG2D = preload("svg_2d.gd")

#-----------------#
# User Properties #
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
			"name": "SVGRect",
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
	if _svg_2d != null:
		_svg_2d.svg = svg
	_queue_size_svg()
	update_configuration_warnings()

func _get_svg():
	return _svg

func _set_fixed_scaling_ratio(fixed_scaling_ratio):
	_fixed_scaling_ratio = fixed_scaling_ratio
	if _svg_2d != null:
		_svg_2d.fixed_scaling_ratio = fixed_scaling_ratio

func _get_fixed_scaling_ratio():
	return _fixed_scaling_ratio

func _set_antialiased(antialiased):
	_antialiased = antialiased
	if _svg_2d != null:
		_svg_2d.antialiased = antialiased
		update_configuration_warnings()

func _get_antialiased():
	return _antialiased

func _set_triangulation_method(triangulation_method):
	_triangulation_method = triangulation_method
	if _svg_2d != null:
		_svg_2d.triangulation_method = triangulation_method

func _get_triangulation_method():
	return _triangulation_method

func _set_assume_no_self_intersections(assume_no_self_intersections):
	_assume_no_self_intersections = assume_no_self_intersections
	if _svg_2d != null:
		_svg_2d.assume_no_self_intersections = assume_no_self_intersections

func _get_assume_no_self_intersections():
	return _assume_no_self_intersections

func _set_assume_no_holes(assume_no_holes):
	_assume_no_holes = assume_no_holes
	if _svg_2d != null:
		_svg_2d.assume_no_holes = assume_no_holes

func _get_assume_no_holes():
	return _assume_no_holes

func _set_disable_render_cache(disable_render_cache):
	_disable_render_cache = disable_render_cache
	if _svg_2d != null:
		_svg_2d.disable_render_cache = disable_render_cache

func _get_disable_render_cache():
	return _disable_render_cache

#---------------------#
# Internal Properties #
#---------------------#

var is_gles2 = false # OS.get_current_video_driver() == OS.VIDEO_DRIVER_GLES2

var _svg_2d = null
var _is_size_svg_queued = false

#-----------#
# Lifecycle #
#-----------#

func _init():
	clip_contents = true
	_svg_2d = SVG2D.new()
	_svg_2d.connect("controllers_created", Callable(self, "_size_svg"))
	super.add_child(_svg_2d)
	_svg_2d.svg = _svg
	_svg_2d.fixed_scaling_ratio = _fixed_scaling_ratio
	_svg_2d.antialiased = _antialiased
	_queue_size_svg()

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		_size_svg()
	elif what == NOTIFICATION_PREDELETE:
		if _svg_2d != null:
			if is_instance_valid(_svg_2d):
				_svg_2d.queue_free()

#------------------#
# Internal Methods #
#------------------#

func _queue_size_svg():
	if not _is_size_svg_queued:
		_is_size_svg_queued = true
		call_deferred("_size_svg")

func _size_svg():
	_is_size_svg_queued = false
	if _svg_2d and _svg_2d.controller.root_element_controller != null:
		var viewport_controller = _svg_2d.controller.root_element_controller
		if viewport_controller != null:
			var view_box = viewport_controller.calculate_view_box()
			if typeof(viewport_controller.attr_preserve_aspect_ratio) == TYPE_STRING:
				if viewport_controller.attr_preserve_aspect_ratio == SVGValueConstant.NONE:
					_svg_2d.scale = Vector2(
						size.x / view_box.size.x,
						size.y / view_box.size.y
					)
			else:
				var x_align_ratio = 0.0
				if viewport_controller.attr_preserve_aspect_ratio.align.x == SVGValueConstant.MID:
					x_align_ratio = 0.5
				elif viewport_controller.attr_preserve_aspect_ratio.align.x == SVGValueConstant.MAX:
					x_align_ratio = 1.0
				var y_align_ratio = 0.0
				if viewport_controller.attr_preserve_aspect_ratio.align.y == SVGValueConstant.MID:
					y_align_ratio = 0.5
				elif viewport_controller.attr_preserve_aspect_ratio.align.y == SVGValueConstant.MAX:
					y_align_ratio = 1.0
				if viewport_controller.attr_preserve_aspect_ratio.meet_or_slice == SVGValueConstant.SLICE:
					if (view_box.size.x / view_box.size.y) > (size.x / size.y):
						var scale_y = size.y / view_box.size.y
						_svg_2d.scale = Vector2(
							scale_y,
							scale_y
						)
						var leftover_space = size.x - (view_box.size.x * _svg_2d.scale.x)
						_svg_2d.position = Vector2(x_align_ratio * leftover_space, 0.0)
					else:
						var scale_x = size.x / view_box.size.x
						_svg_2d.scale = Vector2(
							scale_x,
							scale_x
						)
						var leftover_space = size.y - (view_box.size.y * _svg_2d.scale.y)
						_svg_2d.position = Vector2(0.0, y_align_ratio * leftover_space)
				else: # MEET
					if (view_box.size.x / view_box.size.y) > (size.x / size.y):
						var scale_x = size.x / view_box.size.x
						_svg_2d.scale = Vector2(
							scale_x,
							scale_x
						)
						var leftover_space = size.y - (view_box.size.y * _svg_2d.scale.y)
						_svg_2d.position = Vector2(0.0, y_align_ratio * leftover_space)
					else:
						var scale_y = size.y / view_box.size.y
						_svg_2d.scale = Vector2(
							scale_y,
							scale_y
						)
						var leftover_space = size.x - (view_box.size.x * _svg_2d.scale.x)
						_svg_2d.position = Vector2(x_align_ratio * leftover_space, 0.0)
						

#--------#
# Editor #
#--------#

func _get_configuration_warning():
	if _svg is Texture2D:
		return "You added an SVG file that is imported as \"Texture2D\". In the Import tab, choose \"Import As: SVG\" instead!"
	elif _svg != null and not _svg is SVGResource:
		return "You must import your SVG file as \"GodotSVG\" in the import settings!"
	elif is_gles2 and _antialiased:
		return "\"antialiased\" is enabled, but GLES2 does not support the antialiasing technique used by this plugin. Use GLES3 instead."
	return ""

#----------------#
# Public Methods #
#----------------#

func get_element_by_id(id: String):
	return _svg_2d.resolve_url("#" + id)

func get_elements_by_name(name: String):
	return _svg_2d.get_elements_by_name(name)

func load_svg_from_buffer(buffer: PackedByteArray):
	return _svg_2d.load_svg_from_buffer(buffer)
