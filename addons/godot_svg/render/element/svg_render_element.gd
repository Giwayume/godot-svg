extends Node2D

const SVGLine2D = preload("../polygon/svg_line_2d.gd")
const SVGPolygonLine2D = preload("../polygon/svg_polygon_line_2d.gd")
const SVGPolygonLines2D = preload("../polygon/svg_polygon_lines_2d.gd")

export(Resource) var element_resource = null setget _set_element_resource
export(Rect2) var inherited_view_box = Rect2()

# Reference to SVG2D Node

var is_root = false
var svg_node = null
var node_name = "element"
var node_text = ""

# Core Attributes
var attr_id = null
var attr_lang = null
var attr_tabindex = 0

# Styling Attributes
var attr_class = ""
var attr_style = {} setget _set_attr_style
var applied_stylesheet_style = {} setget _set_applied_stylesheet_style

# Conditional Processing Attributes
var attr_required_extensions = null
var attr_required_features = null
var attr_system_language = null

# Presentation Attributes
var attr_clip_path = null
var attr_clip_rule = null
var attr_color = null
var attr_color_interpolation = null
var attr_color_rendering = null
var attr_cursor = null
var attr_display = "inline" setget _set_attr_display
var attr_fill = SVGPaint.new("#000000") setget _set_attr_fill
var attr_fill_opacity = null
var attr_fill_rule = null
var attr_filter = null
var attr_mask = null
var attr_opacity = null
var attr_pointer_events = null
var attr_shape_rendering = null
var attr_stroke = SVGPaint.new("#00000000") setget _set_attr_stroke
var attr_stroke_dasharray = [] setget _set_attr_stroke_dasharray
var attr_stroke_dashoffset = SVGLengthPercentage.new("0") setget _set_attr_stroke_dashoffset
var attr_stroke_linecap = null
var attr_stroke_linejoin = SVGValueConstant.MITER setget _set_attr_stroke_linejoin
var attr_stroke_miterlimit = 4.0 setget _set_attr_stroke_miterlimit
var attr_stroke_opacity = SVGLengthPercentage.new("100%") setget _set_attr_stroke_opacity
var attr_stroke_width = SVGLengthPercentage.new("1px") setget _set_attr_stroke_width
var attr_transform = Transform2D() setget _set_attr_transform
var attr_vector_effect = SVGValueConstant.NONE
var attr_visibility = SVGValueConstant.VISIBLE

# Internal Variables

var _previous_canvas_transform_scale = Vector2()
var _shape_fills = []
var _shape_strokes = []

# Lifecycle

func _init():
	apply_attributes()

func _ready():
	connect("visibility_changed", self, "_on_visibility_changed")

func _process(_delta):
	var canvas_transform_scale = get_viewport().canvas_transform.get_scale()
	if (
		canvas_transform_scale.x != _previous_canvas_transform_scale.x or
		canvas_transform_scale.y != _previous_canvas_transform_scale.y
	):
		update()
	_previous_canvas_transform_scale = canvas_transform_scale

# Public Methods

func apply_attributes():
	if element_resource != null:
		for attribute_name in element_resource.attributes:
			if "attr_" + attribute_name in self:
				set("attr_" + attribute_name, element_resource.attributes[attribute_name])
	update()

func get_bounding_box():
	return Rect2(0, 0, 0, 0)

func get_scale_factor():
	return global_scale * _previous_canvas_transform_scale

func get_style(attribute_name, default_value):
	var value = default_value
	if attr_style.has(attribute_name):
		value = attr_style[attribute_name]
	elif applied_stylesheet_style.has(attribute_name):
		value = applied_stylesheet_style[attribute_name]
	return value

func draw_shape(updates):
	if not visible:
		return
	
	if attr_display == SVGValueConstant.NONE or attr_visibility == SVGValueConstant.HIDDEN:
		for shape_fill in _shape_fills:
			shape_fill.get_parent().remove_child(shape_fill)
			shape_fill.queue_free()
		_shape_fills = []
		for shape_stroke in _shape_strokes:
			shape_stroke.get_parent().remove_child(shape_stroke)
			shape_stroke.queue_free()
		_shape_strokes = []
		return
	
	if updates.has("fill_color") and updates.fill_color.a > 0:
		var polygon_lists = []
		if updates.has("fill_polygon"):
			if updates.fill_polygon.size() > 0:
				if updates.fill_polygon[0] is PoolVector2Array:
					polygon_lists = updates.fill_polygon
				else:
					polygon_lists = [updates.fill_polygon]
			# Remove unused
			for shape_stroke_index in range(polygon_lists.size(), _shape_fills.size()):
				var shape = _shape_fills[shape_stroke_index]
				shape.get_parent().remove_child(shape)
				shape.queue_free()
			_shape_fills = SVGHelper.array_slice(_shape_fills, 0, polygon_lists.size())
			# Create new
			for point_list_index in range(_shape_fills.size(), polygon_lists.size()):
				var shape = Polygon2D.new()
				add_child(shape)
				_shape_fills.push_back(shape)
		
		var fill_index = 0
		for _shape_fill in _shape_fills:
			if fill_index < polygon_lists.size():
				_shape_fill.polygon = polygon_lists[fill_index]
			_shape_fill.color = updates.fill_color
			if updates.has("stroke_color"):
				_shape_fill.antialiased = updates.stroke_color.a == 0
			if updates.has("fill_texture") and updates.fill_texture != null:
				if updates.has("fill_uv"):
					_shape_fill.uv = updates.fill_uv
				_shape_fill.texture = updates.fill_texture
			_shape_fill.show()
			fill_index += 1
	else:
		for shape in _shape_fills:
			shape.hide()
	
	if updates.has("stroke_color") and updates.stroke_color.a > 0:
		var point_lists = []
		if updates.has("stroke_points"):
			if updates.stroke_points.size() > 0:
				if updates.stroke_points[0] is PoolVector2Array:
					point_lists = updates.stroke_points
				else:
					point_lists = [updates.stroke_points]
			# Remove unused
			for shape_stroke_index in range(point_lists.size(), _shape_strokes.size()):
				var shape = _shape_strokes[shape_stroke_index]
				shape.get_parent().remove_child(shape)
				shape.queue_free()
			_shape_strokes = SVGHelper.array_slice(_shape_strokes, 0, point_lists.size())
			# Create new
			for point_list_index in range(_shape_strokes.size(), point_lists.size()):
				var shape = SVGPolygonLines2D.new()
				add_child(shape)
				_shape_strokes.push_back(shape)
		
		var stroke_index = 0
		for _shape_stroke in _shape_strokes:
			var _stroke_attrs = {}
			if stroke_index < point_lists.size():
				_shape_stroke.points = point_lists[stroke_index]
			else:
				_shape_stroke.points = []
			if attr_stroke_dasharray.size() > 0:
				var full_percentage_size = sqrt((pow(inherited_view_box.size.x, 2) + pow(inherited_view_box.size.y, 2)) / 2)
				var dash_array = []
				for size in attr_stroke_dasharray:
					dash_array.push_back(size.get_length(full_percentage_size))
				_shape_stroke.dash_offset = attr_stroke_dashoffset.get_length(full_percentage_size)
				_shape_stroke.dash_array = dash_array
			_stroke_attrs.color = updates.stroke_color
			_stroke_attrs.cap_mode = attr_stroke_linecap
			_stroke_attrs.joint_mode = attr_stroke_linejoin
			_stroke_attrs.antialiased = true
			_stroke_attrs.sharp_limit = attr_stroke_miterlimit
			_stroke_attrs.opacity = attr_stroke_opacity.get_length(1)
			if updates.has("stroke_width") and updates.has("scale_factor"):
	#			var applied_stroke_width = updates.stroke_width * updates.scale_factor.x
	#			if applied_stroke_width >= 2:
	#				applied_stroke_width += 2
	#			elif applied_stroke_width > 1:
	#				applied_stroke_width = applied_stroke_width + ((applied_stroke_width - 1) * 2)
	#			_stroke_attrs.width = applied_stroke_width / max(0.0001, updates.scale_factor.x)
				_stroke_attrs.width = updates.stroke_width
				var applied_stroke_width = updates.stroke_width * updates.scale_factor.x
				if applied_stroke_width < 1:
					_shape_stroke.modulate = Color(1, 1, 1, applied_stroke_width)
				else:
					_shape_stroke.modulate = Color(1, 1, 1, 1)
				
			if updates.has("stroke_closed"):
				if typeof(updates.stroke_closed) == TYPE_ARRAY and stroke_index < updates.stroke_closed.size():
					_stroke_attrs.closed = updates.stroke_closed[stroke_index]
				else:
					_stroke_attrs.closed = updates.stroke_closed
			
			_shape_stroke.line_attributes = _stroke_attrs
			_shape_stroke.show()
			stroke_index += 1
	else:
		for stroke in _shape_strokes:
			stroke.hide()

func resolve_paint(attr_paint):
	var paint = {
		"color": Color(1, 1, 1, 1),
		"texture": null,
	}
	if attr_paint is SVGPaint:
		if attr_paint.url != null:
			var result = svg_node._resolve_resource_locator(attr_fill.url)
			var renderer = result.renderer
			if renderer.node_name == "linearGradient":
				var stops = svg_node._find_elements_by_name("stop", result.resource)
				var gradient = Gradient.new()
				gradient.colors = []
				gradient.offsets = []
				for stop in stops:
					var offset = stop.renderer.attr_offset.get_length(1)
					var color = stop.renderer.attr_stop_color
					var opacity = stop.renderer.attr_stop_opacity
					if opacity < 1:
						color.a = opacity
					gradient.add_point(offset, color)
				var gradient_texture = GradientTexture2D.new()
				var transform = renderer.attr_gradient_transform
				gradient_texture.gradient = gradient
				gradient_texture.fill_from = transform.xform(Vector2(
					renderer.attr_x1.get_length(1),
					renderer.attr_y1.get_length(1)
				))
				gradient_texture.fill_to = transform.xform(Vector2(
					renderer.attr_x2.get_length(1),
					renderer.attr_y2.get_length(1)
				))
				gradient_texture.repeat = {
					SVGValueConstant.PAD: GradientTexture2D.REPEAT_NONE,
					SVGValueConstant.REPEAT: GradientTexture2D.REPEAT,
					SVGValueConstant.REFLECT: GradientTexture2D.REPEAT_MIRROR,
				}[renderer.attr_spread_method]
				paint.texture = gradient_texture
#				paint.texture = preload("res://icon.png")
		else:
			paint.color = attr_paint.color
	return paint

# Getters / Setters

func _set_element_resource(new_element_resource):
	element_resource = new_element_resource
	if element_resource != null:
		set_name(element_resource.node_name)
	update()

func _set_attr_display(display):
	display = get_style("display", display)
	attr_display = display
	update()

func _set_attr_fill(fill):
	fill = get_style("fill", fill)
	if typeof(fill) != TYPE_STRING:
		attr_fill = fill
	else:
		if [SVGValueConstant.NONE, SVGValueConstant.CONTEXT_FILL, SVGValueConstant.CONTEXT_STROKE].has(fill):
			attr_fill = SVGPaint.new("#00000000")
		else:
			attr_fill = SVGPaint.new(fill)
	update()

func _set_attr_stroke_opacity(stroke_opacity):
	stroke_opacity = get_style("stroke_opacity", stroke_opacity)
	if typeof(stroke_opacity) != TYPE_STRING:
		attr_stroke_opacity = stroke_opacity
	else:
		attr_stroke_opacity = SVGLengthPercentage.new(stroke_opacity)

func _set_attr_stroke(stroke):
	stroke = get_style("stroke", stroke)
	if typeof(stroke) != TYPE_STRING:
		attr_stroke = stroke
	else:
		if [SVGValueConstant.NONE, SVGValueConstant.CONTEXT_FILL, SVGValueConstant.CONTEXT_STROKE].has(stroke):
			attr_stroke = SVGPaint.new("#00000000")
		else:
			attr_stroke = SVGPaint.new(stroke)
	update()

func _set_attr_stroke_dasharray(stroke_dasharray):
	stroke_dasharray = get_style("stroke_dasharray", stroke_dasharray)
	if typeof(stroke_dasharray) != TYPE_STRING:
		attr_stroke_dasharray = stroke_dasharray
	else:
		if stroke_dasharray == SVGValueConstant.NONE:
			attr_stroke_dasharray = []
		else:
			var values = []
			var space_split = stroke_dasharray.split(" ", false)
			for space_split_string in space_split:
				var comma_split = space_split_string.split(",", false)
				for number_string in comma_split:
					values.push_back(SVGLengthPercentage.new(number_string))
			if values.size() % 2 == 1:
				values.append_array(values.duplicate())
			attr_stroke_dasharray = values
	update()

func _set_attr_stroke_dashoffset(stroke_dashoffset):
	stroke_dashoffset = get_style("stroke_dashoffset", stroke_dashoffset)
	if typeof(stroke_dashoffset) != TYPE_STRING:
		attr_stroke_dashoffset = stroke_dashoffset
	else:
		attr_stroke_dashoffset = SVGLengthPercentage.new(stroke_dashoffset)
	update()

func _set_attr_stroke_linejoin(stroke_linejoin):
	stroke_linejoin = get_style("stroke_linejoin", stroke_linejoin)
	attr_stroke_linejoin = stroke_linejoin
	update()

func _set_attr_stroke_miterlimit(stroke_miterlimit):
	stroke_miterlimit = get_style("stroke_miterlimit", stroke_miterlimit)
	if typeof(stroke_miterlimit) != TYPE_STRING:
		attr_stroke_miterlimit = stroke_miterlimit
	else:
		attr_stroke_miterlimit = stroke_miterlimit.to_float()
	update()

func _set_attr_stroke_width(stroke_width):
	stroke_width = get_style("stroke_width", stroke_width)
	if typeof(stroke_width) != TYPE_STRING:
		attr_stroke_width = stroke_width
	else:
		attr_stroke_width = SVGLengthPercentage.new(stroke_width)
	update()

func _set_attr_style(style):
	if typeof(style) != TYPE_STRING:
		attr_style = style
	else:
		if style == SVGValueConstant.NONE:
			attr_style = {}
		else:
			attr_style = SVGAttributeParser.parse_css_style(style)
	for attr_name in attr_style:
		if "attr_" + attr_name in self:
			self["attr_" + attr_name] = self["attr_" + attr_name]
	update()

func _set_applied_stylesheet_style(style):
	if typeof(style) == TYPE_DICTIONARY:
		applied_stylesheet_style = style
		for attr_name in applied_stylesheet_style:
			if "attr_" + attr_name in self:
				self["attr_" + attr_name] = self["attr_" + attr_name]
	update()

func _set_attr_transform(new_transform):
	new_transform = get_style("transform", new_transform)
	attr_transform = SVGAttributeParser.parse_transform_list(new_transform)
	self.transform = attr_transform
	update()

# Signal Callbacks

func _on_visibility_changed():
	if visible:
		update()

