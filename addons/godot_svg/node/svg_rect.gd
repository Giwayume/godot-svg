tool
extends Control

const TriangulationMethod = SVGValueConstant.TriangulationMethod
const SVG2D = preload("svg_2d.gd")

# Exported properties
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

# Internal Properties

var is_gles2 = OS.get_current_video_driver() == OS.VIDEO_DRIVER_GLES2

var _svg_2d = null
var _is_size_svg_queued = false

# Lifecycle

func _init():
	rect_clip_content = true
	_svg_2d = SVG2D.new()
	_svg_2d.connect("renderers_created", self, "_size_svg")
	.add_child(_svg_2d)
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

# Internal Methods

func _queue_size_svg():
	if not _is_size_svg_queued:
		_is_size_svg_queued = true
		call_deferred("_size_svg")

func _size_svg():
	_is_size_svg_queued = false
	if _svg_2d and _svg_2d._root_viewport_renderer != null:
		var viewport_renderer = _svg_2d._root_viewport_renderer
		if viewport_renderer != null:
			var view_box = viewport_renderer.calculate_view_box()
			if typeof(viewport_renderer.attr_preserve_aspect_ratio) == TYPE_STRING:
				if viewport_renderer.attr_preserve_aspect_ratio == SVGValueConstant.NONE:
					_svg_2d.scale = Vector2(
						rect_size.x / view_box.size.x,
						rect_size.y / view_box.size.y
					)
			else:
				var x_align_ratio = 0.0
				if viewport_renderer.attr_preserve_aspect_ratio.align.x == SVGValueConstant.MID:
					x_align_ratio = 0.5
				elif viewport_renderer.attr_preserve_aspect_ratio.align.x == SVGValueConstant.MAX:
					x_align_ratio = 1.0
				var y_align_ratio = 0.0
				if viewport_renderer.attr_preserve_aspect_ratio.align.y == SVGValueConstant.MID:
					y_align_ratio = 0.5
				elif viewport_renderer.attr_preserve_aspect_ratio.align.y == SVGValueConstant.MAX:
					y_align_ratio = 1.0
				if viewport_renderer.attr_preserve_aspect_ratio.meet_or_slice == SVGValueConstant.SLICE:
					if (view_box.size.x / view_box.size.y) > (rect_size.x / rect_size.y):
						var scale_y = rect_size.y / view_box.size.y
						_svg_2d.scale = Vector2(
							scale_y,
							scale_y
						)
						var leftover_space = rect_size.x - (view_box.size.x * _svg_2d.scale.x)
						_svg_2d.position = Vector2(x_align_ratio * leftover_space, 0.0)
					else:
						var scale_x = rect_size.x / view_box.size.x
						_svg_2d.scale = Vector2(
							scale_x,
							scale_x
						)
						var leftover_space = rect_size.y - (view_box.size.y * _svg_2d.scale.y)
						_svg_2d.position = Vector2(0.0, y_align_ratio * leftover_space)
				else: # MEET
					if (view_box.size.x / view_box.size.y) > (rect_size.x / rect_size.y):
						var scale_x = rect_size.x / view_box.size.x
						_svg_2d.scale = Vector2(
							scale_x,
							scale_x
						)
						var leftover_space = rect_size.y - (view_box.size.y * _svg_2d.scale.y)
						_svg_2d.position = Vector2(0.0, y_align_ratio * leftover_space)
					else:
						var scale_y = rect_size.y / view_box.size.y
						_svg_2d.scale = Vector2(
							scale_y,
							scale_y
						)
						var leftover_space = rect_size.x - (view_box.size.x * _svg_2d.scale.x)
						_svg_2d.position = Vector2(x_align_ratio * leftover_space, 0.0)
						

# Editor

func _get_configuration_warning():
	if _svg is Texture:
		return "You added an SVG file that is imported as \"Texture\". In the Import tab, choose \"Import As: SVG\" instead!"
	elif _svg != null and not _svg is SVGResource:
		return "You must import your SVG file as \"GodotSVG\" in the import settings!"
	elif is_gles2 and _antialiased:
		return "\"antialiased\" is enabled, but GLES2 does not support the antialiasing technique used by this plugin. Use GLES3 instead."
	return ""

# Getters / Setters

func _set_svg(svg):
	_svg = svg
	if _svg_2d != null:
		_svg_2d.svg = svg
	_queue_size_svg()

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
