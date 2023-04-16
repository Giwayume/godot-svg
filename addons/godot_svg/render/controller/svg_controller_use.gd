extends "svg_controller_element.gd"

#-----------#
# Constants #
#-----------#

const SVGElement2D = preload("../element/2d/svg_element_2d.gd")
const SVGElement3D = preload("../element/3d/svg_element_3d.gd")

#------------#
# Attributes #
#------------#

var attr_href = SVGValueConstant.NONE: set = _set_attr_href
var attr_xlink_href = SVGValueConstant.NONE: set = _set_attr_xlink_href
var attr_x = SVGLengthPercentage.new("0"): set = _set_attr_x
var attr_y = SVGLengthPercentage.new("0"): set = _set_attr_y
var attr_width = SVGLengthPercentage.new("0"): set = _set_attr_width
var attr_height = SVGLengthPercentage.new("0"): set = _set_attr_height

#---------------------#
# Internal Properties #
#---------------------#

var _used_element_controller = null # RefCounted to the controller of the currently used element

#-----------#
# Lifecycle #
#-----------#

func _init():
	node_name = "use"

func _notification(what):
	super._notification(what)
	if what == NOTIFICATION_PREDELETE:
		if _used_element_controller != null:
			if is_instance_valid(_used_element_controller.controlled_node):
				_used_element_controller.controlled_node.queue_free()

func _props_applied(changed_props = []):
	if changed_props.has("x") or changed_props.has("y"):
		var x = attr_x.get_length(inherited_view_box.size.x)
		var y = attr_y.get_length(inherited_view_box.size.y)
		controlled_node.transform.origin = Vector2(x, y)
	if changed_props.has("href"):
		if _used_element_controller != null:
			if is_instance_valid(_used_element_controller.controlled_node):
				_used_element_controller.controlled_node.queue_free()
		_used_element_controller = resolve_href()
		if _used_element_controller != null:
			root_controller._generate_node_controller_structure(controlled_node, _used_element_controller.element_resource.children)
	super._props_applied(changed_props)

#------------------#
# Internal Methods #
#------------------#

func _calculate_bounding_box():
	var x = attr_x.get_length(inherited_view_box.size.x)
	var y = attr_x.get_length(inherited_view_box.size.y)
	if _used_element_controller != null:
		_used_element_controller._calculate_bounding_box()
		var used_bounding_box = _used_element_controller.get_bounding_box()
		_bounding_box = Rect2(x + used_bounding_box.position.x, y + used_bounding_box.position.y, used_bounding_box.size.x, used_bounding_box.size.y)
	emit_signal("bounding_box_calculated", _bounding_box)

#----------------#
# Public Methods #
#----------------#

func resolve_href():
	var resolved = null
	if attr_href != SVGValueConstant.NONE:
		var result = root_controller.resolve_url(attr_href)
		var controller = result.controller
		if controller != null:
			var controller_to_copy = controller
			if controller.has_method("resolve_href"):
				controller_to_copy = controller.resolve_href()
				if controller_to_copy == null:
					controller_to_copy = controller
			
			var generation_result = root_controller._generate_node_controller_structure(
				controlled_node,
				[controller_to_copy.element_resource],
				{
					"view_box": inherited_view_box,
					"cache_id": render_cache_id,
					"is_in_root_viewport": is_in_root_viewport,
					"is_in_clip_path": is_in_clip_path,
				}
			)
			resolved = generation_result.top_level_controllers[0]
			
			var override_attributes = {}
			var overridable_attributes = ["width", "height"]
			for attribute_name in element_resource.attributes:
				if overridable_attributes.has(attribute_name):
					override_attributes[attribute_name] = self.get("attr_" + attribute_name)
			if override_attributes.size() > 0:
				resolved.set_attributes(override_attributes)
			
	return resolved

#-------------------#
# Getters / Setters #
#-------------------#

func _set_attr_href(href):
	attr_href = href
	apply_props("href")

func _set_attr_xlink_href(xlink_href):
	_set_attr_href(xlink_href)

func _set_attr_x(x):
	x = get_style("x", x)
	if typeof(x) != TYPE_STRING:
		attr_x = x
	else:
		attr_x = SVGLengthPercentage.new(x)
	apply_props("x")

func _set_attr_y(y):
	y = get_style("y", y)
	if typeof(y) != TYPE_STRING:
		attr_y = y
	else:
		attr_y = SVGLengthPercentage.new(y)
	apply_props("y")

func _set_attr_width(width):
	width = get_style("width", width)
	if typeof(width) != TYPE_STRING:
		attr_width = width
	else:
		attr_width = SVGLengthPercentage.new(width)
	apply_props("width")

func _set_attr_height(height):
	height = get_style("height", height)
	if typeof(height) != TYPE_STRING:
		attr_height = height
	else:
		attr_height = SVGLengthPercentage.new(height)
	apply_props("height")
