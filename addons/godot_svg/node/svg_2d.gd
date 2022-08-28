tool
extends Node2D

export(Resource) var svg = null setget _set_svg, _get_svg
export(bool) var toggle_render setget _set_toggle_render

var _svg = null
var _renderer_map = {}

# Lifecycle

func _draw():
	if _svg != null:
		_draw_recursive(_svg.viewport.children, _renderer_map[_svg.viewport].attr_view_box)

# Internal Methods

func _get_svg_element_renderer(node_name):
	match node_name:
		"circle": return SVGRenderCircle
		"svg": return SVGRenderViewport
	return SVGRenderElement

func _create_renderers_recursive(children):
	for child in children:
		var renderer = _get_svg_element_renderer(child.node_name).new()
		renderer.element_resource = child
		renderer.apply_attributes()
		_renderer_map[child] = renderer
		if child.children.size() > 0:
			_create_renderers_recursive(child.children)

func _draw_recursive(children, view_box):
	for child in children:
		var renderer = _renderer_map[child]
		renderer.draw(self, view_box)
		if child.children.size() > 0:
			var new_view_box = view_box
			if renderer is SVGRenderViewport:
				new_view_box = renderer.attr_view_box
			_draw_recursive(child.children, new_view_box)

# Getters / Setters

func _set_svg(svg):
	_renderer_map = {}
	_svg = svg
	if _svg != null and _svg.viewport != null:
		_create_renderers_recursive([_svg.viewport])
	update()

func _get_svg():
	return _svg

func _set_toggle_render(new_toggle_render):
	update()
