#---------#
# Signals #
#---------#

signal node_structure_generated
signal controlled_node_process(delta)
signal viewport_scale_changed(new_scale)

#-----------#
# Constants #
#-----------#

const TriangulationMethod = SVGValueConstant.TriangulationMethod
const SVGElement2D = preload("../element/2d/svg_element_2d.gd")
const SVGElement3D = preload("../element/3d/svg_element_3d.gd")
const SVGControllerCircle = preload("svg_controller_circle.gd")
const SVGControllerClipPath = preload("svg_controller_clip_path.gd")
const SVGControllerDefs = preload("svg_controller_defs.gd")
const SVGControllerEllipse = preload("svg_controller_ellipse.gd")
const SVGControllerElement = preload("svg_controller_element.gd")
const SVGControllerG = preload("svg_controller_g.gd")
const SVGControllerImage = preload("svg_controller_image.gd")
const SVGControllerLine = preload("svg_controller_line.gd")
const SVGControllerLinearGradient = preload("svg_controller_linear_gradient.gd")
const SVGControllerMask = preload("svg_controller_mask.gd")
const SVGControllerPath = preload("svg_controller_path.gd")
const SVGControllerPattern = preload("svg_controller_pattern.gd")
const SVGControllerPolygon = preload("svg_controller_polygon.gd")
const SVGControllerPolyline = preload("svg_controller_polyline.gd")
const SVGControllerRadialGradient = preload("svg_controller_radial_gradient.gd")
const SVGControllerRect = preload("svg_controller_rect.gd")
const SVGControllerStop = preload("svg_controller_stop.gd")
const SVGControllerStyle = preload("svg_controller_style.gd")
const SVGControllerViewport = preload("svg_controller_viewport.gd")
const SVGControllerText = preload("svg_controller_text.gd")
const SVGControllerUse = preload("svg_controller_use.gd")

#-----------------#
# User properties #
#-----------------#

var svg = null: set = _set_svg
var fixed_scaling_ratio = 0: set = _set_fixed_scaling_ratio
var antialiased = true: set = _set_antialiased
var triangulation_method = TriangulationMethod.DELAUNAY: set = _set_triangulation_method
var assume_no_self_intersections = false: set = _set_assume_no_self_intersections
var assume_no_holes = false: set = _set_assume_no_holes
var disable_render_cache = false: set = _set_disable_render_cache

func _set_svg(new_svg):
	svg = new_svg

func _set_fixed_scaling_ratio(new_fixed_scaling_ratio):
	fixed_scaling_ratio = new_fixed_scaling_ratio

func _set_antialiased(new_antialiased):
	antialiased = new_antialiased

func _set_triangulation_method(new_triangulation_method):
	triangulation_method = new_triangulation_method

func _set_assume_no_self_intersections(new_assume_no_self_intersections):
	assume_no_self_intersections = new_assume_no_self_intersections

func _set_assume_no_holes(new_assume_no_holes):
	assume_no_holes = new_assume_no_holes

func _set_disable_render_cache(new_disable_render_cache):
	disable_render_cache = new_disable_render_cache

#-------------------#
# Public properties #
#-------------------#

var editor_plugin = null # plugin.gd instance
var is_editor_hint = false
var is_gles2 = false # OS.get_current_video_driver() == OS.VIDEO_DRIVER_GLES2
var is_2d = true
var last_known_viewport_scale = Vector2(0.0, 0.0)
var root_node = null # SVG2D, SVG3D, or SVGRect node
var root_element_controller = null # SVGControllerElement for <svg> tag.

#---------------------#
# Internal properties #
#---------------------#

var _element_resource_to_controller_map = {}
var _global_stylesheet = []
var _is_queued_generate_from_scratch = false
var _is_render_cache_computed = false
var _polygons_to_process = []
var _polygons_to_process_mutex = null
var _process_polygon_thread = null
var _url_cache = {}

#-----------#
# Lifecycle #
#-----------#

func _init(root_node: Node):
	self.root_node = root_node
	is_2d = root_node is Node2D
	is_editor_hint = Engine.is_editor_hint()

func _enter_tree():
	if is_editor_hint and editor_plugin != null:
		editor_plugin.connect("svg_resources_reimported", Callable(self, "_on_svg_resources_reimported"))
		editor_plugin.connect("editor_viewport_scale_changed", Callable(self, "_on_editor_viewport_scale_changed"))
	
	if last_known_viewport_scale.is_equal_approx(Vector2(0.0, 0.0)):
		last_known_viewport_scale = root_node.get_viewport().canvas_transform.get_scale()
	emit_signal("viewport_scale_changed", last_known_viewport_scale)

func _exit_tree():
	if is_editor_hint and editor_plugin != null:
		editor_plugin.disconnect("svg_resources_reimported", Callable(self, "_on_svg_resources_reimported"))
		editor_plugin.disconnect("editor_viewport_scale_changed", Callable(self, "_on_editor_viewport_scale_changed"))

func _process(_delta):
	if not is_editor_hint and fixed_scaling_ratio == 0:
		var new_viewport_scale = root_node.get_viewport().canvas_transform.get_scale()
		if not new_viewport_scale.is_equal_approx(last_known_viewport_scale):
			emit_signal("viewport_scale_changed", new_viewport_scale)
		last_known_viewport_scale = new_viewport_scale

func _predelete():
	if is_instance_valid(editor_plugin):
		if editor_plugin.is_connected("svg_resources_reimported", Callable(self, "_on_svg_resources_reimported")):
			editor_plugin.disconnect("svg_resources_reimported", Callable(self, "_on_svg_resources_reimported"))
		if editor_plugin.is_connected("editor_viewport_scale_changed", Callable(self, "_on_editor_viewport_scale_changed")):
			editor_plugin.disconnect("editor_viewport_scale_changed", Callable(self, "_on_editor_viewport_scale_changed"))

#------------------#
# Internal Methods #
#------------------#

# For a given SVG element name, returns the controller class that implements it.
func _get_controller_class_by_element_name(element_name: String):
	match element_name:
		"circle": return SVGControllerCircle
		"clipPath": return SVGControllerClipPath
		"defs": return SVGControllerDefs
		"ellipse": return SVGControllerEllipse
		"g": return SVGControllerG
		"image": return SVGControllerImage
		"line": return SVGControllerLine
		"linearGradient": return SVGControllerLinearGradient
		"mask": return SVGControllerMask
		"path": return SVGControllerPath
		"pattern": return SVGControllerPattern
		"polygon": return SVGControllerPolygon
		"polyline": return SVGControllerPolyline
		"radialGradient": return SVGControllerRadialGradient
		"rect": return SVGControllerRect
		"stop": return SVGControllerStop
		"style": return SVGControllerStyle
		"svg": return SVGControllerViewport
		"text": return SVGControllerText
		"use": return SVGControllerUse
	return SVGControllerElement

# Trashes everything and re-generates the node/controller structure.
func _generate_from_scratch_deferred():
	_is_queued_generate_from_scratch = false
	
	# Cleanup
	for element_resource in _element_resource_to_controller_map:
		_element_resource_to_controller_map[element_resource].controlled_node.queue_free()
	_element_resource_to_controller_map = {}
	_global_stylesheet = []
	_url_cache = {}
	
	# Create controllers
	if svg is SVGResource and svg.viewport != null:
		_is_render_cache_computed = not svg.render_cache.is_empty()
		if not disable_render_cache and not _is_render_cache_computed:
			svg.render_cache = {
				"process_polygon": {},
			}
		_generate_node_controller_structure(root_node, [svg.viewport])
		if _global_stylesheet.size() > 0:
			_apply_stylesheet_recursive([svg.viewport])
		emit_signal("node_structure_generated")
	
	if is_2d:
		root_node.queue_redraw()

# Recursively generate the node/controller structure.
func _generate_node_controller_structure(s_parent_node, s_children, s_render_props = {}):
	var render_order = 0.0
	var renderable_nodes = ["circle", "ellipse", "image", "line", "path", "polygon", "polyline", "rect", "text"]
	var generation_stack = [
		{
			"children": s_children,
			"child_evaluate_index": 0,
			"parent_node": s_parent_node,
			"parent_viewport_controller": null,
			"render_props": s_render_props,
		}
	]
	var generation_result = {
		"top_level_controllers": [],
	}
	while generation_stack.size() > 0:
		var stack_frame = generation_stack.back()
		var children = stack_frame.children
		var render_props = stack_frame.render_props
		
		var view_box = null
		var is_in_root_viewport = false
		var is_in_clip_path = false
		var inherited_props = {}
		var is_cacheable = true
		if not render_props.has("cache_id"):
			render_props.cache_id = "0"
		if render_props.has("view_box"):
			view_box = render_props.view_box
		if render_props.has("is_in_root_viewport"):
			is_in_root_viewport = render_props.is_in_root_viewport
		if render_props.has("is_in_clip_path"):
			is_in_clip_path = render_props.is_in_clip_path
		if render_props.has("inherited_props"):
			inherited_props = render_props.inherited_props
		if render_props.has("is_cacheable"):
			is_cacheable = render_props.is_cacheable
	
		var parent_controller = stack_frame.parent_node.controller if "controller" in stack_frame.parent_node and stack_frame.parent_node.controller is SVGControllerElement else null
		
		var node_name_counter = {}
		
		var is_child_stack_completed = true
		for child_index in range(stack_frame.child_evaluate_index, children.size()):
			var child = children[child_index]
			var controlled_node = SVGElement2D.new() if is_2d else SVGElement3D.new()
			var controller = _get_controller_class_by_element_name(child.node_name).new()
			if stack_frame.parent_node == root_node:
				root_element_controller = controller
			if stack_frame.parent_node == s_parent_node:
				generation_result.top_level_controllers.push_back(controller)
			if not node_name_counter.has(child.node_name):
				node_name_counter[child.node_name] = 0
			node_name_counter[child.node_name] += 1
			controlled_node.node_name = child.node_name
			controlled_node.controller = controller
			controller.node_name = child.node_name
			controller.controlled_node = controlled_node
			controller.root_controller = self
			controller.parent_controller = parent_controller
			controller.parent_viewport_controller = stack_frame.parent_viewport_controller
			controller.element_resource = child
			controller.node_text = child.text
			controller.is_in_root_viewport = is_in_root_viewport
			controller.is_in_clip_path = is_in_clip_path
			controller.render_cache_id = render_props.cache_id + "." + str(child_index)
			if renderable_nodes.has(controller.node_name):
				controller.render_order = render_order
				render_order += 1.0
			if not is_cacheable:
				controller.is_cacheable = false
			if view_box == null:
				controller.is_root_element = true
			var assigned_attribute_names = controller.read_attributes_from_element_resource()
			if inherited_props.size() > 0:
				controller._on_inherited_properties_updated(inherited_props)
			stack_frame.parent_node.add_child(controlled_node)
			controlled_node.name = child.node_name + "#" + str(node_name_counter[child.node_name])
			if parent_controller != null:
				parent_controller._child_list.push_back(controlled_node)
			_element_resource_to_controller_map[child] = controller
			
			if controller is SVGControllerViewport:
				controller.inherited_view_box = controller.calculate_view_box()
			else:
				controller.inherited_view_box = view_box if view_box is Rect2 else controller.inherited_view_box
			if controller is SVGControllerViewport and controller.attr_view_box is Rect2:
				view_box = controller.attr_view_box
			if controller is SVGControllerStyle:
				_global_stylesheet.append_array(controller.get_stylesheet())
			
			var child_inherited_props = inherited_props.duplicate()
			for attribute_name in assigned_attribute_names:
				if SVGValueConstant.GLOBAL_INHERITED_ATTRIBUTE_NAMES.has(attribute_name):
					child_inherited_props[attribute_name] = controller.get("attr_" + attribute_name)
			
			if child.children.size() > 0:
				var new_render_props = {
					"view_box": view_box,
					"is_in_root_viewport": is_in_root_viewport,
					"is_in_clip_path": is_in_clip_path,
					"cache_id": controller.render_cache_id,
					"inherited_props": child_inherited_props,
					"is_cacheable": is_cacheable,
				}
				var new_parent_viewport_controller = stack_frame.parent_viewport_controller
				if controller is SVGControllerViewport:
					new_parent_viewport_controller = controller
				if controller is SVGControllerViewport or controller.attr_mask != SVGValueConstant.NONE or controller.attr_clip_path != SVGValueConstant.NONE:
					new_render_props.is_in_root_viewport = false
				if controller is SVGControllerClipPath:
					new_render_props.is_in_clip_path = true
				stack_frame.child_evaluate_index = child_index + 1
				generation_stack.push_back({
					"children": child.children,
					"child_evaluate_index": 0,
					"parent_node": controlled_node,
					"parent_viewport_controller": new_parent_viewport_controller,
					"render_props": new_render_props,
				})
				is_child_stack_completed = false
				break
		
		if is_child_stack_completed:
			generation_stack.pop_back()
	return generation_result

# Walks back through the element resource tree and assigns properties to controllers
# matching the CSS selectors from _global_stylesheet
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
		var controller = _element_resource_to_controller_map[child]
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
							if element_selector.node_name != controller.node_name:
								is_all_matching = false
								continue
						if element_selector.id != null:
							if element_selector.id != controller.attr_id:
								is_all_matching = false
								continue
						if element_selector["class"] != null:
							var controller_classes = controller.attr_class.split(" ", false)
							for classname in element_selector["class"]:
								if not controller_classes.has(classname):
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
		controller.set_applied_stylesheet_style(applied_stylesheet_style)
		if child.children.size() > 0:
			_apply_stylesheet_recursive(child.children, rule_state.duplicate(true))

# Editor plugin notifies that the viewport scale has changed.
func _on_editor_viewport_scale_changed(new_scale):
	last_known_viewport_scale = new_scale
#	emit_signal("viewport_scale_changed", new_scale)

# Editor plugin notifies that the svg resource has changed.
func _on_svg_resources_reimported(resource_names):
	if svg != null:
		if svg.resource_path in resource_names:
			_set_svg(svg)
			generate_from_scratch()

# Path solve and triangulate in a thread (start the process)
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
		if process_item.controller == polygon_definition.controller:
			process_already_exists = true
			break
	if not process_already_exists:
		_polygons_to_process.push_back(polygon_definition)
	_polygons_to_process_mutex.unlock()

	# Start thread
	if need_to_create_thread:
		_process_polygon_thread = Thread.new()
		_process_polygon_thread.start(Callable(self, "_process_polygon_thread_method"), Thread.PRIORITY_LOW)

# Path solve and triangulate in a thread (thread main logic)
func _process_polygon_thread_method():
	var has_polygons_to_process = false
	_polygons_to_process_mutex.lock()
	has_polygons_to_process = _polygons_to_process.size() > 0
	_polygons_to_process_mutex.unlock()
	
	while has_polygons_to_process:
		_polygons_to_process_mutex.lock()
		var _polygon_to_process = _polygons_to_process.pop_front()
		_polygons_to_process_mutex.unlock()
		if is_instance_valid(_polygon_to_process.controller):
			var polygon = _polygon_to_process.controller.call("_process_simplified_polygon")
			if is_instance_valid(_polygon_to_process.controller):
				_polygon_to_process.controller.call_deferred("_process_simplified_polygon_complete", polygon)
				if not disable_render_cache and not _is_render_cache_computed:
					svg.render_cache.process_polygon[_polygon_to_process.controller.render_cache_id] = polygon
		_polygons_to_process_mutex.lock()
		has_polygons_to_process = _polygons_to_process.size() > 0
		_polygons_to_process_mutex.unlock()

	call_deferred("_process_polygon_thread_end")

# Path solve and triangulate in a thread (end)
func _process_polygon_thread_end():
	if _process_polygon_thread != null:
		_process_polygon_thread.wait_to_finish()
		_process_polygon_thread = null
	if _polygons_to_process.size() > 0:
		_process_polygon_thread = Thread.new()
		_process_polygon_thread.start(Callable(self, "_process_polygon_thread_method"), Thread.PRIORITY_LOW)
	else:
		call_deferred("_process_polygon_end_notify")

# Path solve and triangulate in a thread (write the solution back to disk in editor)
func _process_polygon_end_notify():
	if (
		is_editor_hint and
		not disable_render_cache and
		not _is_render_cache_computed and
		_polygons_to_process.size() == 0 and
		svg != null and
		editor_plugin != null
	):
		var error = editor_plugin.overwrite_svg_resource(svg)
		if error != OK:
			print("[godot-svg] Editor error occurred when saving render cache back to SVG resource. Code: ", error)
		_is_render_cache_computed = true

#----------------#
# Public methods #
#----------------#

# Finds all SVG elements with the given element name, and returns an Array of Dictionary objects
# containing information about them: SVGElementResource, SVGControllerElement, and Node instances.
func get_elements_by_name(name: String, parent_resource = null) -> Array:
	if parent_resource == null and svg is SVGResource and svg.viewport != null:
		parent_resource = svg.viewport
	var found_resources = []
	for child_resource in parent_resource.children:
		if child_resource != null:
			var controller = _element_resource_to_controller_map[child_resource] if _element_resource_to_controller_map.has(child_resource) else null
			if controller:
				if child_resource.node_name == name:
					found_resources.push_back({
						"resource": child_resource,
						"controller": controller,
						"node": controller.controlled_node,
					})
				elif child_resource.node_name == "g":
					found_resources.append_array(
						get_elements_by_name(name, child_resource)
					)
	return found_resources

# Resolves an IRI reference, returning a dictionary containing the
# SVGElementResource, SVGControllerElement, and Node instances that match the reference.
# Spec: https://www.w3.org/TR/SVG/linking.html#IRIReference
func resolve_url(url: String, parent_resource = null) -> Dictionary:
	if parent_resource == null and svg is SVGResource and svg.viewport != null:
		parent_resource = svg.viewport
		if _url_cache.has(url):
			return _url_cache[url]
	var located_resource = {
		"resource": null,
		"controller": null,
		"node": null,
	}
	if url.begins_with("#"):
		if parent_resource.attributes.has("id") and parent_resource.attributes.id == url.substr(1):
			located_resource.resource = parent_resource
			located_resource.controller = _element_resource_to_controller_map[parent_resource]
			located_resource.node = located_resource.controller.controlled_node
	if located_resource.resource == null and parent_resource.children.size() > 0:
		for child_resource in parent_resource.children:
			if child_resource != null:
				located_resource = resolve_url(url, child_resource)
				if located_resource.resource != null:
					break
	if located_resource.resource != null:
		_url_cache[url] = located_resource
	return located_resource

# Destroys all nodes associated with the SVG and re-creates it all again based on the SVGResource.
# Used when the SVG node structure changes.
func generate_from_scratch():
	if not _is_queued_generate_from_scratch:
		_is_queued_generate_from_scratch = true
		call_deferred("_generate_from_scratch_deferred")

# Loads a SVG from a UTF8-encoded string buffer that contains the contents of the SVG document.
func load_svg_from_buffer(buffer: PackedByteArray):
	var svg_resource = SVGResource.new()
	svg_resource = SVGResourceFormatLoader.new().load_svg_resource_from_buffer(svg_resource, buffer)
	svg = svg_resource
	generate_from_scratch()
