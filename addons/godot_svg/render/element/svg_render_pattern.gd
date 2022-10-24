extends "svg_render_element.gd"

var attr_x = SVGLengthPercentage.new("0") setget _set_attr_x
var attr_y = SVGLengthPercentage.new("0") setget _set_attr_y
var attr_width = SVGLengthPercentage.new("0") setget _set_attr_width
var attr_height = SVGLengthPercentage.new("0") setget _set_attr_height
var attr_href = SVGValueConstant.NONE setget _set_attr_href
var attr_xlink_href = SVGValueConstant.NONE setget _set_attr_xlink_href
var attr_pattern_units = SVGValueConstant.OBJECT_BOUNDING_BOX setget _set_attr_pattern_units
var attr_pattern_content_units = SVGValueConstant.USER_SPACE_ON_USE setget _set_attr_pattern_content_units
var attr_pattern_transform = Transform2D() setget _set_attr_pattern_transform
var attr_preserve_aspect_ratio = {
	"align": {
		"x": SVGValueConstant.MID,
		"y": SVGValueConstant.MID,
	},
	"meet_or_slice": SVGValueConstant.MEET,
} setget _set_attr_preserve_aspect_ratio
var attr_view_box = SVGValueConstant.NONE setget _set_attr_view_box

# Lifecycle

func _init():
	node_name = "pattern"
	_baking_viewport = Viewport.new()
	_baking_viewport.usage = Viewport.USAGE_2D_NO_SAMPLING
	_baking_viewport.transparent_bg = true
	_baking_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	_baking_viewport.render_target_v_flip = true
	_baking_viewport.name = "baking_viewport"
	.add_child(_baking_viewport)
	hide()

# Public Methods

func resolve_href():
	var resolved = self
	var result = null
	if attr_href == SVGValueConstant.NONE:
		result = { "renderer": self }
	else:
		result = svg_node._resolve_resource_locator(attr_href)
	var renderer = result.renderer
	if renderer != null and renderer.node_name == "pattern":
		var renderer_to_copy = renderer.resolve_href() if renderer != self else self
		resolved = load(renderer_to_copy.get_script().resource_path).new()
		resolved.svg_node = svg_node
		resolved._is_href_duplicate = true
		resolved.element_resource = renderer_to_copy.element_resource
		resolved.apply_resource_attributes()
		var override_attributes = {}
		var overridable_attributes = ["view_box", "pattern_units", "pattern_transform", "pattern_content_units", "preserve_aspect_ratio", "x", "y", "width", "height"]
		for attribute_name in element_resource.attributes:
			if overridable_attributes.has(attribute_name):
				override_attributes[attribute_name] = self.get("attr_" + attribute_name)
		if override_attributes.size() > 0:
			resolved.set_attributes(override_attributes)
		resolved.svg_node._create_renderers_recursive(resolved._baking_viewport, resolved.element_resource.children)
	return resolved

func update_as_user(user_view_box):
	var content_view_box = user_view_box
	if attr_view_box is Rect2:
		content_view_box = attr_view_box
	var reference_width = 1.0
	var reference_height = 1.0
	var reference_x = 0.0
	var reference_y = 0.0
	var content_reference_width = 1.0
	var content_reference_height = 1.0
	var content_reference_x = 0.0
	var content_reference_y = 0.0
	if attr_pattern_units == SVGValueConstant.USER_SPACE_ON_USE:
		reference_width = user_view_box.size.x
		reference_height = user_view_box.size.y
		reference_x = user_view_box.position.x
		reference_y = user_view_box.position.y
	var x = attr_x.get_length(reference_width, reference_x)
	var y = attr_y.get_length(reference_height, reference_y)
	var width = attr_width.get_length(reference_width)
	var height = attr_height.get_length(reference_height)
	if attr_pattern_content_units == SVGValueConstant.USER_SPACE_ON_USE:
		content_reference_width = width
		content_reference_height = height
		content_reference_x = x
		content_reference_y = y
	var scale_factor = Vector2(
		width / content_reference_width,
		height / content_reference_height
	)
	_baking_viewport.size = Vector2(width, height)
	_baking_viewport.canvas_transform = Transform2D().scaled(scale_factor)
	_baking_viewport.canvas_transform.origin += (-Vector2(content_reference_x, content_reference_y)) * scale_factor
	_baking_viewport.update_worlds()
	_baking_viewport.render_target_update_mode = Viewport.UPDATE_ONCE

# Getters / Setters

func _set_attr_x(x):
	if typeof(x) != TYPE_STRING:
		attr_x = x
	else:
		attr_x = SVGLengthPercentage.new(x)
	apply_props()

func _set_attr_y(y):
	if typeof(y) != TYPE_STRING:
		attr_y = y
	else:
		attr_y = SVGLengthPercentage.new(y)
	apply_props()

func _set_attr_width(width):
	if typeof(width) != TYPE_STRING:
		attr_width = width
	else:
		attr_width = SVGLengthPercentage.new(width)
	apply_props()

func _set_attr_height(height):
	if typeof(height) != TYPE_STRING:
		attr_height = height
	else:
		attr_height = SVGLengthPercentage.new(height)
	apply_props()

func _set_attr_href(href):
	attr_href = href
	apply_props()

func _set_attr_xlink_href(xlink_href):
	_set_attr_href(xlink_href)

func _set_attr_pattern_units(pattern_units):
	attr_pattern_units = pattern_units

func _set_attr_pattern_content_units(pattern_content_units):
	attr_pattern_content_units = pattern_content_units

func _set_attr_pattern_transform(pattern_transform):
	pattern_transform = get_style("transform", pattern_transform)
	attr_pattern_transform = SVGAttributeParser.parse_transform_list(pattern_transform)
	apply_props()

func _set_attr_preserve_aspect_ratio(preserve_aspect_ratio):
	if typeof(preserve_aspect_ratio) != TYPE_STRING:
		attr_preserve_aspect_ratio = preserve_aspect_ratio
	else:
		if preserve_aspect_ratio == SVGValueConstant.NONE:
			attr_preserve_aspect_ratio = preserve_aspect_ratio
		else:
			var split = preserve_aspect_ratio.split(" ", false)
			var align_string = split[0]
			var align_x = align_string.substr(1, 3).to_lower()
			var align_y = align_string.substr(5, 3).to_lower()
			attr_preserve_aspect_ratio = {
				"align": {
					"x": align_x,
					"y": align_y,
				},
				"meet_or_slice": split[1] if split.length() > 1 else SVGValueConstant.MEET,
			}
	apply_props()

func _set_attr_view_box(view_box):
	if typeof(view_box) != TYPE_STRING:
		attr_view_box = view_box
	else:
		if view_box == SVGValueConstant.NONE:
			attr_view_box = view_box
		else:
			var split = view_box.split(" ", false)
			attr_view_box = Rect2(
				split[0] if split.size() > 0 else 0,
				split[1] if split.size() > 1 else 0,
				split[2] if split.size() > 2 else 0,
				split[3] if split.size() > 3 else 0
			)
	apply_props()
