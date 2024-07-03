extends "svg_controller_element.gd"

const SVGElement2D = preload("../element/2d/svg_element_2d.gd")
const SVGElement3D = preload("../element/3d/svg_element_3d.gd")

#------------#
# Attributes #
#------------#

var attr_x = SVGLengthPercentage.new("0"): set = _set_attr_x
var attr_y = SVGLengthPercentage.new("0"): set = _set_attr_y
var attr_width = SVGLengthPercentage.new("0"): set = _set_attr_width
var attr_height = SVGLengthPercentage.new("0"): set = _set_attr_height
var attr_href = SVGValueConstant.NONE: set = _set_attr_href
var attr_xlink_href = SVGValueConstant.NONE: set = _set_attr_xlink_href
var attr_pattern_units = SVGValueConstant.OBJECT_BOUNDING_BOX: set = _set_attr_pattern_units
var attr_pattern_content_units = SVGValueConstant.USER_SPACE_ON_USE: set = _set_attr_pattern_content_units
var attr_pattern_transform = Transform2D(): set = _set_attr_pattern_transform
var attr_preserve_aspect_ratio = {
	"align": {
		"x": SVGValueConstant.MID,
		"y": SVGValueConstant.MID,
	},
	"meet_or_slice": SVGValueConstant.MEET,
}: set = _set_attr_preserve_aspect_ratio
var attr_view_box = SVGValueConstant.NONE: set = _set_attr_view_box

#-----------#
# Lifecycle #
#-----------#

func _init():
	node_name = "pattern"
	is_renderable = false
	_baking_viewport = SubViewport.new()
	_baking_viewport.transparent_bg = true
	_baking_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	_baking_viewport.name = "baking_viewport"

func _ready():
	if controlled_node != null:
		controlled_node.add_child(_baking_viewport)
		controlled_node.hide()

#----------------#
# Public Methods #
#----------------#

func resolve_href():
	var resolved = self
	var result = null
	if attr_href == SVGValueConstant.NONE:
		result = { "controller": self }
	else:
		result = root_controller.resolve_url(attr_href)
	var controller = result.controller
	if controller != null and controller.node_name == "pattern":
		var controller_to_copy = controller.resolve_href() if controller != self else self
		resolved = load(controller_to_copy.get_script().resource_path).new()
		resolved.root_controller = root_controller
		resolved._is_href_duplicate = true
		resolved.root_controller = controller_to_copy.root_controller
		resolved.controlled_node = SVGElement2D.new() if resolved.root_controller.is_2d else SVGElement3D.new()
		resolved.controlled_node.controller = resolved
		resolved.element_resource = controller_to_copy.element_resource
		resolved.read_attributes_from_element_resource() # TODO - read controller attributes instead?
		var override_attributes = {}
		var overridable_attributes = ["view_box", "pattern_units", "pattern_transform", "pattern_content_units", "preserve_aspect_ratio", "x", "y", "width", "height"]
		for attribute_name in element_resource.attributes:
			if overridable_attributes.has(attribute_name):
				override_attributes[attribute_name] = self.get("attr_" + attribute_name)
		if override_attributes.size() > 0:
			resolved.set_attributes(override_attributes)
		resolved.root_controller._generate_node_controller_structure(
			resolved._baking_viewport,
			resolved.element_resource.children,
			{
				"view_box": inherited_view_box,
				"cache_id": render_cache_id,
				"is_in_root_viewport": is_in_root_viewport,
				"is_in_clip_path": is_in_clip_path,
			}
		)
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
		width / max(0.000000001, content_reference_width),
		height / max(0.000000001, content_reference_height)
	)
	_baking_viewport.size = Vector2(width, height)
	_baking_viewport.canvas_transform = Transform2D().scaled(scale_factor)
	_baking_viewport.canvas_transform.origin += (-Vector2(content_reference_x, content_reference_y)) * scale_factor
	# TODO - is this needed? Removed in 4.
	# _baking_viewport.update_worlds()
	_baking_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

#-------------------#
# Getters / Setters #
#-------------------#

func _set_attr_x(x):
	if typeof(x) != TYPE_STRING:
		attr_x = x
	else:
		attr_x = SVGLengthPercentage.new(x)
	apply_props("x")

func _set_attr_y(y):
	if typeof(y) != TYPE_STRING:
		attr_y = y
	else:
		attr_y = SVGLengthPercentage.new(y)
	apply_props("y")

func _set_attr_width(width):
	if typeof(width) != TYPE_STRING:
		attr_width = width
	else:
		attr_width = SVGLengthPercentage.new(width)
	apply_props("width")

func _set_attr_height(height):
	if typeof(height) != TYPE_STRING:
		attr_height = height
	else:
		attr_height = SVGLengthPercentage.new(height)
	apply_props("height")

func _set_attr_href(href):
	attr_href = href
	apply_props("href")

func _set_attr_xlink_href(xlink_href):
	_set_attr_href(xlink_href)

func _set_attr_pattern_units(pattern_units):
	attr_pattern_units = pattern_units
	apply_props("pattern_units")

func _set_attr_pattern_content_units(pattern_content_units):
	attr_pattern_content_units = pattern_content_units
	apply_props("pattern_content_units")

func _set_attr_pattern_transform(pattern_transform):
	pattern_transform = get_style("transform", pattern_transform)
	attr_pattern_transform = SVGAttributeParser.parse_transform_list(pattern_transform, root_controller.is_2d)
	apply_props("pattern_transform")

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
	apply_props("preserve_aspect_ratio")

func _set_attr_view_box(view_box):
	if typeof(view_box) != TYPE_STRING:
		attr_view_box = view_box
	else:
		if view_box == SVGValueConstant.NONE:
			attr_view_box = view_box
		else:
			var split = view_box.split(" ", false)
			attr_view_box = Rect2(
				float(split[0]) if split.size() > 0 else 0.0,
				float(split[1]) if split.size() > 1 else 0.0,
				float(split[2]) if split.size() > 2 else 0.0,
				float(split[3]) if split.size() > 3 else 0.0
			)
	apply_props("view_box")
