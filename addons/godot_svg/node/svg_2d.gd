tool
extends Node2D

signal viewport_scale_changed(new_scale)
signal renderers_created()

const TriangulationMethod = SVGValueConstant.TriangulationMethod
const SVGResource = preload("../resource/svg_resource.gd")
const SVGRenderCircle = preload("../render/element/svg_render_circle.gd")
const SVGRenderClipPath = preload("../render/element/svg_render_clip_path.gd")
const SVGRenderDefs = preload("../render/element/svg_render_defs.gd")
const SVGRenderElement = preload("../render/element/svg_render_element.gd")
const SVGRenderEllipse = preload("../render/element/svg_render_ellipse.gd")
const SVGRenderG = preload("../render/element/svg_render_g.gd")
const SVGRenderImage = preload("../render/element/svg_render_image.gd")
const SVGRenderLine = preload("../render/element/svg_render_line.gd")
const SVGRenderLinearGradient = preload("../render/element/svg_render_linear_gradient.gd")
const SVGRenderMask = preload("../render/element/svg_render_mask.gd")
const SVGRenderPath = preload("../render/element/svg_render_path.gd")
const SVGRenderPattern = preload("../render/element/svg_render_pattern.gd")
const SVGRenderPolygon = preload("../render/element/svg_render_polygon.gd")
const SVGRenderPolyline = preload("../render/element/svg_render_polyline.gd")
const SVGRenderRadialGradient = preload("../render/element/svg_render_radial_gradient.gd")
const SVGRenderRect = preload("../render/element/svg_render_rect.gd")
const SVGRenderStop = preload("../render/element/svg_render_stop.gd")
const SVGRenderStyle = preload("../render/element/svg_render_style.gd")
const SVGRenderText = preload("../render/element/svg_render_text.gd")
const SVGRenderViewport = preload("../render/element/svg_render_viewport.gd")

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

# Internal Properties

var is_gles2 = OS.get_current_video_driver() == OS.VIDEO_DRIVER_GLES2

var _root_viewport_renderer = null

var _is_render_cache_computed = false
var _is_editor_hint = false
var _is_queued_render_from_scratch = false
var _editor_plugin = null
var _last_known_viewport_scale = Vector2(0.0, 0.0)
var _renderer_map = {}
var _global_stylesheet = []
var _resource_locator_cache = {}
var _process_polygon_thread = null
var _polygons_to_process = []
var _polygons_to_process_mutex = null

# Lifecycle

func _init():
	_is_editor_hint = Engine.is_editor_hint()

func _enter_tree():
	if _is_editor_hint:
		_editor_plugin = get_node("/root/EditorNode/GodotSVGEditorPlugin")
		if _editor_plugin != null:
			_editor_plugin.connect("svg_resources_reimported", self, "_on_svg_resources_reimported")
			_editor_plugin.connect("editor_viewport_scale_changed", self, "_on_editor_viewport_scale_changed")
	
	if _last_known_viewport_scale.is_equal_approx(Vector2(0.0, 0.0)):
		_last_known_viewport_scale = get_viewport().canvas_transform.get_scale()
	emit_signal("viewport_scale_changed", _last_known_viewport_scale)

func _exit_tree():
	if _is_editor_hint:
		if _editor_plugin != null:
			_editor_plugin.disconnect("svg_resources_reimported", self, "_on_svg_resources_reimported")
			_editor_plugin.disconnect("editor_viewport_scale_changed", self, "_on_editor_viewport_scale_changed")

func _process(_delta):
	if not _is_editor_hint and _fixed_scaling_ratio == 0:
		var new_viewport_scale = get_viewport().canvas_transform.get_scale()
		if not new_viewport_scale.is_equal_approx(_last_known_viewport_scale):
			emit_signal("viewport_scale_changed", new_viewport_scale)
		_last_known_viewport_scale = new_viewport_scale

# Internal Methods

func _get_svg_element_renderer(node_name):
	match node_name:
		"circle": return SVGRenderCircle
		"clipPath": return SVGRenderClipPath
		"defs": return SVGRenderDefs
		"ellipse": return SVGRenderEllipse
		"g": return SVGRenderG
		"image": return SVGRenderImage
		"line": return SVGRenderLine
		"linearGradient": return SVGRenderLinearGradient
		"mask": return SVGRenderMask
		"path": return SVGRenderPath
		"pattern": return SVGRenderPattern
		"polygon": return SVGRenderPolygon
		"polyline": return SVGRenderPolyline
		"radialGradient": return SVGRenderRadialGradient
		"rect": return SVGRenderRect
		"stop": return SVGRenderStop
		"style": return SVGRenderStyle
		"svg": return SVGRenderViewport
		"text": return SVGRenderText
	return SVGRenderElement

func _create_renderers_recursive(parent, children, render_props = {}):
	var view_box = null
	if not render_props.has("cache_id"):
		render_props.cache_id = "0"
	if render_props.has("view_box"):
		view_box = render_props.view_box
	var is_in_root_viewport = false
	if render_props.has("is_in_root_viewport"):
		is_in_root_viewport = render_props.is_in_root_viewport
	var is_in_clip_path = false
	if render_props.has("is_in_clip_path"):
		is_in_clip_path = render_props.is_in_clip_path
	var child_index = 0
	for child in children:
		var renderer = _get_svg_element_renderer(child.node_name).new()
		if parent == self:
			_root_viewport_renderer = renderer
		renderer.svg_node = self
		renderer.element_resource = child
		renderer.node_text = child.text
		renderer.assume_no_self_intersections = _assume_no_self_intersections
		renderer.assume_no_holes = _assume_no_holes
		renderer.is_in_root_viewport = is_in_root_viewport
		renderer.is_in_clip_path = is_in_clip_path
		renderer.render_cache_id = render_props.cache_id + "." + str(child_index)
		if view_box == null:
			renderer.is_root = true
		renderer.apply_resource_attributes()
		parent.add_child(renderer)
		_renderer_map[child] = renderer
		if renderer is SVGRenderViewport:
			renderer.inherited_view_box = renderer.calculate_view_box()
		else:
			renderer.inherited_view_box = view_box if view_box is Rect2 else renderer.inherited_view_box
		if renderer is SVGRenderViewport and renderer.attr_view_box is Rect2:
			view_box = renderer.attr_view_box
		if renderer is SVGRenderStyle:
			_global_stylesheet.append_array(renderer.get_stylesheet())
		if child.children.size() > 0:
			var new_options = {
				"view_box": view_box,
				"is_in_root_viewport": is_in_root_viewport,
				"is_in_clip_path": is_in_clip_path,
				"cache_id": renderer.render_cache_id
			}
			if renderer is SVGRenderViewport or renderer.attr_mask != SVGValueConstant.NONE or renderer.attr_clip_path != SVGValueConstant.NONE:
				new_options.is_in_root_viewport = false
			if renderer is SVGRenderClipPath:
				new_options.is_in_clip_path = true
			_create_renderers_recursive(renderer, child.children, new_options)
		child_index += 1

func _apply_stylesheet_recursive(children, rule_state = null):
	var rules = _global_stylesheet
	if rule_state == null:
		rule_state = []
		for rule in rules:
			var state = []
			for selector_path in rule.selector_paths:
				state.push_back(0)
			rule_state.push_back(state)
	for child in children:
		var renderer = _renderer_map[child]
		var applied_styles_with_weights = {}
		var rule_index = 0
		for rule in rules:
			var is_selector_path_match = false
			var selector_weight = 0
			var selector_path_index = 0
			for selector_path in rule.selector_paths:
				var current_match_index = rule_state[rule_index][selector_path_index]
				if current_match_index > -1:
					var element_selector = selector_path[current_match_index]
					var is_all_matching = true
					if not element_selector.any:
						if element_selector.node_name != null:
							if element_selector.node_name != renderer.node_name:
								is_all_matching = false
								continue
						if element_selector.id != null:
							if element_selector.id != renderer.attr_id:
								is_all_matching = false
								continue
						if element_selector.class != null:
							var renderer_classes = renderer.attr_class.split(" ", false)
							for classname in element_selector.class:
								if not renderer_classes.has(classname):
									is_all_matching = false
									continue
					if is_all_matching:
						if current_match_index < selector_path.size() - 1:
							rule_state[rule_index][selector_path_index] += 1
						else:
							is_selector_path_match = true
				selector_path_index += 1
			if is_selector_path_match:
				for prop_name in rule.declarations:
					if not applied_styles_with_weights.has(prop_name) or applied_styles_with_weights[prop_name].weight < selector_weight:
						applied_styles_with_weights[prop_name] = {
							"weight": selector_weight,
							"value": rule.declarations[prop_name]
						}
			rule_index += 1
		var applied_stylesheet_style = {}
		for prop_name in applied_styles_with_weights:
			applied_stylesheet_style[prop_name] = applied_styles_with_weights[prop_name].value
		renderer.applied_stylesheet_style = applied_stylesheet_style
		if child.children.size() > 0:
			_apply_stylesheet_recursive(child.children, rule_state.duplicate(true))

func _resolve_resource_locator(url: String, parent_resource = null):
	if parent_resource == null and _svg is SVGResource and _svg.viewport != null:
		parent_resource = _svg.viewport
		if _resource_locator_cache.has(url):
			return _resource_locator_cache[url]
	var located_resource = {
		"resource": null,
		"renderer": null,
	}
	if url.begins_with("#"):
		if parent_resource.attributes.has("id") and parent_resource.attributes.id == url.substr(1):
			located_resource.resource = parent_resource
			located_resource.renderer = _renderer_map[parent_resource]
	if located_resource.resource == null and parent_resource.children.size() > 0:
		for child_resource in parent_resource.children:
			if child_resource != null:
				located_resource = _resolve_resource_locator(url, child_resource)
				if located_resource.resource != null:
					break
	if located_resource.resource != null:
		_resource_locator_cache[url] = located_resource
	return located_resource

func _find_elements_by_name(name: String, parent_resource = null):
	if parent_resource == null and _svg is SVGResource and _svg.viewport != null:
		parent_resource = _svg.viewport
	var found_resources = []
	for child_resource in parent_resource.children:
		if child_resource != null:
			if child_resource.node_name == name:
				found_resources.push_back({
					"resource": child_resource,
					"renderer": _renderer_map[child_resource],
				})
				found_resources.append_array(_find_elements_by_name(name, child_resource))
	return found_resources

func _queue_render_from_scratch():
	if not _is_queued_render_from_scratch:
		_is_queued_render_from_scratch = true
		call_deferred("_render_from_scratch")

func _render_from_scratch():
	_is_queued_render_from_scratch = false
	
	# Cleanup
	for element_resource in _renderer_map:
		_renderer_map[element_resource].queue_free()
	_root_viewport_renderer = null
	_renderer_map = {}
	_global_stylesheet = []
	_resource_locator_cache = {}
	
	# Create renderers
	if _svg is SVGResource and _svg.viewport != null:
		_is_render_cache_computed = _svg.render_cache != null
		if not _disable_render_cache and not _is_render_cache_computed:
			_svg.render_cache = {
				"process_polygon": {},
			}
		_create_renderers_recursive(self, [_svg.viewport])
		if _global_stylesheet.size() > 0:
			_apply_stylesheet_recursive([_svg.viewport])
		emit_signal("renderers_created")
	update()


func _queue_process_polygon(polygon_definition: Dictionary):
	if _polygons_to_process_mutex == null:
		_polygons_to_process_mutex = Mutex.new()
	var need_to_create_thread = false
	if _process_polygon_thread == null:
		need_to_create_thread = true
	
	# Add process to process list for thread to read
	_polygons_to_process_mutex.lock()
	var process_already_exists = false
	for process_item in _polygons_to_process:
		if process_item.renderer == polygon_definition.renderer:
			process_already_exists = true
			break
	if not process_already_exists:
		_polygons_to_process.push_back(polygon_definition)
	_polygons_to_process_mutex.unlock()

	# Start thread
	if need_to_create_thread:
		_process_polygon_thread = Thread.new()
		_process_polygon_thread.start(self, "_process_polygon_thread", null, Thread.PRIORITY_LOW)

func _process_polygon_thread(_userdata):
	var has_polygons_to_process = false
	_polygons_to_process_mutex.lock()
	has_polygons_to_process = _polygons_to_process.size() > 0
	_polygons_to_process_mutex.unlock()
	
	while has_polygons_to_process:
		_polygons_to_process_mutex.lock()
		var _polygon_to_process = _polygons_to_process.pop_front()
		_polygons_to_process_mutex.unlock()
		if is_instance_valid(_polygon_to_process.renderer):
			var polygon = _polygon_to_process.renderer.call("_process_simplified_polygon")
			if is_instance_valid(_polygon_to_process.renderer):
				_polygon_to_process.renderer.call_deferred("_process_simplified_polygon_complete", polygon)
				if not _disable_render_cache and not _is_render_cache_computed:
					_svg.render_cache.process_polygon[_polygon_to_process.renderer.render_cache_id] = polygon
		_polygons_to_process_mutex.lock()
		has_polygons_to_process = _polygons_to_process.size() > 0
		_polygons_to_process_mutex.unlock()

	call_deferred("_process_polygon_thread_end")

func _process_polygon_thread_end():
	if _process_polygon_thread != null:
		_process_polygon_thread.wait_to_finish()
		_process_polygon_thread = null
	call_deferred("_process_polygon_end_notify")

func _process_polygon_end_notify():
	if (
		_is_editor_hint and
		not _disable_render_cache and
		not _is_render_cache_computed and
		_polygons_to_process.size() == 0 and
		_svg != null and
		_editor_plugin != null
	):
		var error = _editor_plugin.overwrite_svg_resource(_svg)
		if error != OK:
			print("[godot-svg] Editor error occurred when saving render cache back to SVG resource. Code: ", error)
		_is_render_cache_computed = true

# Editor

func _get_configuration_warning():
	if _svg is Texture:
		return "You added an SVG file that is imported as \"Texture\". In the Import tab, choose \"Import As: SVG\" instead!"
	elif _svg != null and not _svg is SVGResource:
		return "You must import your SVG file as \"SVG\" in the import settings!"
	elif is_gles2 and _antialiased:
		return "\"antialiased\" is enabled, but GLES2 does not support the antialiasing technique used by this plugin. Use the GLES3 renderer instead."
	return ""

func _get_item_rect():
	var edit_rect = Rect2()
	if _svg is SVGResource and _svg.viewport != null:
			var viewport_renderer = _renderer_map[_svg.viewport]
			if viewport_renderer != null:
				edit_rect = viewport_renderer.calculate_view_box()
	return edit_rect

func _on_svg_resources_reimported(resource_names):
	if _svg != null:
		if _svg.resource_path in resource_names:
			_set_svg(_svg)

func _on_editor_viewport_scale_changed(new_scale):
	_last_known_viewport_scale = new_scale
#	emit_signal("viewport_scale_changed", new_scale)

# Getters / Setters

func _set_svg(svg):
	_svg = svg
	update_configuration_warning()
	_queue_render_from_scratch()

func _get_svg():
	return _svg

func _set_fixed_scaling_ratio(fixed_scaling_ratio):
	_fixed_scaling_ratio = fixed_scaling_ratio
	_queue_render_from_scratch()

func _get_fixed_scaling_ratio():
	return _fixed_scaling_ratio

func _set_antialiased(antialiased):
	if _antialiased != antialiased:
		_antialiased = antialiased
		_queue_render_from_scratch()

func _get_antialiased():
	return _antialiased

func _set_triangulation_method(triangulation_method):
	if _triangulation_method != triangulation_method:
		_triangulation_method = triangulation_method
		if _svg != null:
			_svg.render_cache = null
		_queue_render_from_scratch()

func _get_triangulation_method():
	return _triangulation_method

func _set_assume_no_self_intersections(assume_no_self_intersections):
	if _assume_no_self_intersections != assume_no_self_intersections:
		_assume_no_self_intersections = assume_no_self_intersections
		if _svg != null:
			_svg.render_cache = null
		_queue_render_from_scratch()

func _get_assume_no_self_intersections():
	return _assume_no_self_intersections

func _set_assume_no_holes(assume_no_holes):
	if _assume_no_holes != assume_no_holes:
		_assume_no_holes = assume_no_holes
		if _svg != null:
			_svg.render_cache = null
		_queue_render_from_scratch()

func _get_assume_no_holes():
	return _assume_no_holes

func _set_disable_render_cache(disable_render_cache):
	if _disable_render_cache != disable_render_cache:
		_disable_render_cache = disable_render_cache
		if _svg != null:
			_svg.render_cache = null
		_queue_render_from_scratch()
	
func _get_disable_render_cache():
	return _disable_render_cache
