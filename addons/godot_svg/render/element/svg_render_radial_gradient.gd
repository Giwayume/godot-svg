extends "svg_render_element.gd"

var attr_cx = SVGLengthPercentage.new("50%") setget _set_attr_cx
var attr_cy = SVGLengthPercentage.new("50%") setget _set_attr_cy
var attr_fr = SVGLengthPercentage.new("0%") setget _set_attr_fr
var attr_fx = SVGValueConstant.AUTO setget _set_attr_fx
var attr_fy = SVGValueConstant.AUTO setget _set_attr_fy
var attr_gradient_units = SVGValueConstant.OBJECT_BOUNDING_BOX setget _set_attr_gradient_units
var attr_gradient_transform = Transform2D() setget _set_attr_gradient_transform
var attr_href = SVGValueConstant.NONE setget _set_attr_href
var attr_xlink_href = SVGValueConstant.NONE setget _set_attr_xlink_href
var attr_r = SVGLengthPercentage.new("50%") setget _set_attr_r
var attr_spread_method = SVGValueConstant.PAD setget _set_attr_spread_method

# Lifecycle

func _init():
	node_name = "radialGradient"

# Public Methods

func resolve_href():
	var resolved = self
	if attr_href != SVGValueConstant.NONE:
		var result = svg_node._resolve_resource_locator(attr_href)
		var renderer = result.renderer
		if renderer != null and renderer.node_name == "radialGradient":
			var renderer_to_copy = renderer.resolve_href()
			resolved = load(renderer_to_copy.get_script().resource_path).new()
			resolved._is_href_duplicate = true
			resolved.element_resource = renderer_to_copy.element_resource
			resolved.apply_resource_attributes()
			var override_attributes = {}
			var overridable_attributes = ["gradient_units", "gradient_transform", "spread_method", "cx", "cy", "fr", "fx", "fy", "r"]
			for attribute_name in element_resource.attributes:
				if overridable_attributes.has(attribute_name):
					override_attributes[attribute_name] = self.get("attr_" + attribute_name)
			if override_attributes.size() > 0:
				resolved.set_attributes(override_attributes)
	return resolved

# Getters / Setters

func _set_attr_cx(cx):
	if typeof(cx) != TYPE_STRING:
		attr_cx = cx
	else:
		attr_cx = SVGLengthPercentage.new(cx)
	apply_props()

func _set_attr_cy(cy):
	if typeof(cy) != TYPE_STRING:
		attr_cy = cy
	else:
		attr_cy = SVGLengthPercentage.new(cy)
	apply_props()

func _set_attr_fr(fr):
	if typeof(fr) != TYPE_STRING:
		attr_fr = fr
	else:
		attr_fr = SVGLengthPercentage.new(fr)
	apply_props()

func _set_attr_fx(fx):
	if typeof(fx) != TYPE_STRING:
		attr_fx = fx
	else:
		if fx == SVGValueConstant.AUTO:
			attr_fx = fx
		else:
			attr_fx = SVGLengthPercentage.new(fx)
	apply_props()

func _set_attr_fy(fy):
	if typeof(fy) != TYPE_STRING:
		attr_fy = fy
	else:
		if fy == SVGValueConstant.AUTO:
			attr_fy = fy
		else:
			attr_fy = SVGLengthPercentage.new(fy)
	apply_props()

func _set_attr_gradient_units(gradient_units):
	attr_gradient_units = gradient_units
	apply_props()

func _set_attr_gradient_transform(gradient_transform):
	gradient_transform = get_style("transform", gradient_transform)
	attr_gradient_transform = SVGAttributeParser.parse_transform_list(gradient_transform)
	apply_props()

func _set_attr_href(href):
	attr_href = href
	apply_props()

func _set_attr_xlink_href(xlink_href):
	_set_attr_href(xlink_href)

func _set_attr_r(r):
	if typeof(r) != TYPE_STRING:
		attr_r = r
	else:
		attr_r = SVGLengthPercentage.new(r)
	apply_props()

func _set_attr_spread_method(spread_method):
	attr_spread_method = spread_method
	apply_props()
