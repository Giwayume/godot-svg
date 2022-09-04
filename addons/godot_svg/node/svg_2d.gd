tool
extends Node2D

const SVGResource = preload("../resource/svg_resource.gd")
const SVGRenderCircle = preload("../render/element/svg_render_circle.gd")
const SVGRenderDefs = preload("../render/element/svg_render_defs.gd")
const SVGRenderElement = preload("../render/element/svg_render_element.gd")
const SVGRenderEllipse = preload("../render/element/svg_render_ellipse.gd")
const SVGRenderG = preload("../render/element/svg_render_g.gd")
const SVGRenderLine = preload("../render/element/svg_render_line.gd")
const SVGRenderLinearGradient = preload("../render/element/svg_render_linear_gradient.gd")
const SVGRenderPath = preload("../render/element/svg_render_path.gd")
const SVGRenderPolyline = preload("../render/element/svg_render_polyline.gd")
const SVGRenderRect = preload("../render/element/svg_render_rect.gd")
const SVGRenderStop = preload("../render/element/svg_render_stop.gd")
const SVGRenderStyle = preload("../render/element/svg_render_style.gd")
const SVGRenderViewport = preload("../render/element/svg_render_viewport.gd")

export(Resource) var svg = null setget _set_svg, _get_svg
export(float) var fixed_scaling_ratio = 0 setget _set_fixed_scaling_ratio, _get_fixed_scaling_ratio

var _editor_plugin = null
var _fixed_scaling_ratio = 0
var _svg = null
var _renderer_map = {}
var _global_stylesheet = []

# Lifecycle

func _enter_tree():
	if Engine.is_editor_hint():
		_editor_plugin = get_node("/root/EditorNode/GodotSVGEditorPlugin")
		if _editor_plugin != null:
			_editor_plugin.connect("svg_resources_reimported", self, "_on_svg_resources_reimported")

func _exit_tree():
	if Engine.is_editor_hint():
		if _editor_plugin != null:
			_editor_plugin.disconnect("svg_resources_reimported", self, "_on_svg_resources_reimported")

# Internal Methods

func _get_svg_element_renderer(node_name):
	match node_name:
		"circle": return SVGRenderCircle
		"defs": return SVGRenderDefs
		"ellipse": return SVGRenderEllipse
		"g": return SVGRenderG
		"line": return SVGRenderLine
		"linearGradient": return SVGRenderLinearGradient
		"path": return SVGRenderPath
		"polyline": return SVGRenderPolyline
		"rect": return SVGRenderRect
		"stop": return SVGRenderStop
		"style": return SVGRenderStyle
		"svg": return SVGRenderViewport
	return SVGRenderElement

func _create_renderers_recursive(parent, children, view_box):
	for child in children:
		var renderer = _get_svg_element_renderer(child.node_name).new()
		renderer.svg_node = self
		renderer.element_resource = child
		renderer.node_text = child.text
		if view_box == null:
			renderer.is_root = true
		renderer.apply_attributes()
		parent.add_child(renderer)
		_renderer_map[child] = renderer
		if view_box == null and renderer is SVGRenderViewport:
			renderer.inherited_view_box = renderer.calc_view_box()
		else:
			renderer.inherited_view_box = view_box if view_box is Rect2 else renderer.inherited_view_box
		if renderer is SVGRenderViewport and renderer.attr_view_box is Rect2:
			view_box = renderer.attr_view_box
		if renderer is SVGRenderStyle:
			_global_stylesheet.append_array(renderer.get_stylesheet())
		if child.children.size() > 0:
			_create_renderers_recursive(renderer, child.children, view_box)

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
								continue
						if element_selector.id != null:
							if element_selector.id != renderer.attr_id:
								continue
						if element_selector.class != null:
							var renderer_classes = renderer.attr_class.split(" ", false)
							for classname in element_selector.class:
								if not renderer_classes.has(classname):
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

# Editor

func _get_configuration_warning():
	if _svg is Texture:
		return "You added an SVG file that is imported as \"Texture\". In the Import tab, choose \"Import As: SVG\" instead!"
	elif _svg != null and not _svg is SVGResource:
		return "You must import your SVG file as \"GodotSVG\" in the import settings!"
	return ""

func _get_item_rect():
	var edit_rect = Rect2()
	if _svg is SVGResource and _svg.viewport != null:
			var viewport_renderer = _renderer_map[_svg.viewport]
			if viewport_renderer != null:
				edit_rect = viewport_renderer.calc_view_box()
	return edit_rect

func _on_svg_resources_reimported(resource_names):
	if _svg != null:
		if _svg.resource_path in resource_names:
			_set_svg(_svg)

# Getters / Setters

func _set_svg(svg):
	# Cleanup
	for renderer_name in _renderer_map:
		_renderer_map[renderer_name].queue_free()
	_renderer_map = {}
	
	# Assign
	_svg = svg
	
	# Create renderers
	if svg is SVGResource and svg.viewport != null:
		_create_renderers_recursive(self, [svg.viewport], null)
		if _global_stylesheet.size() > 0:
			_apply_stylesheet_recursive([svg.viewport])
	update()
	update_configuration_warning()

func _get_svg():
	return _svg

func _set_fixed_scaling_ratio(fixed_scaling_ratio):
	_fixed_scaling_ratio = fixed_scaling_ratio
	update()

func _get_fixed_scaling_ratio():
	return _fixed_scaling_ratio
