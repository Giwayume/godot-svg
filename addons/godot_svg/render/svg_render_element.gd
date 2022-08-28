extends Resource
class_name SVGRenderElement

export(Resource) var element_resource = null

# Core Attributes
var attr_id = null
var attr_lang = null
var attr_tabindex = 0

# Styling Attributes
var attr_class = null
var attr_style = null

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
var attr_display = null
var attr_fill = SVGPaint.new("#00000000") setget _set_attr_fill
var attr_fill_opacity = null
var attr_fill_rule = null
var attr_filter = null
var attr_mask = null
var attr_opacity = null
var attr_pointer_events = null
var attr_shape_rendering = null
var attr_stroke = SVGPaint.new("#00000000") setget _set_attr_stroke
var attr_stroke_dasharray = null
var attr_stroke_dashoffset = null
var attr_stroke_linecap = null
var attr_stroke_linejoin = null
var attr_stroke_miterlimit = null
var attr_stroke_opacity = null
var attr_stroke_width = SVGLengthPercentage.new("1px") setget _set_attr_stroke_width
var attr_transform = Transform2D() setget _set_attr_transform
var attr_vector_effect = SVGValueConstant.NONE
var attr_visibility = SVGValueConstant.VISIBLE

# Lifecycle

func _init():
	apply_attributes()

# Drawing

func draw(canvas_item: CanvasItem, view_box: Rect2):
	pass

# Public Methods

func apply_attributes():
	if element_resource != null:
		for attribute_name in element_resource.attributes:
			if "attr_" + attribute_name in self:
				set("attr_" + attribute_name, element_resource.attributes[attribute_name])

# Getters / Setters

func _set_attr_fill(fill):
	if typeof(fill) != TYPE_STRING:
		attr_fill = fill
	else:
		if [SVGValueConstant.NONE, SVGValueConstant.CONTEXT_FILL, SVGValueConstant.CONTEXT_STROKE].has(fill):
			attr_fill = SVGPaint.new("#00000000")
		else:
			attr_fill = SVGPaint.new(fill)
	emit_changed()

func _set_attr_stroke(stroke):
	if typeof(stroke) != TYPE_STRING:
		attr_stroke = stroke
	else:
		if [SVGValueConstant.NONE, SVGValueConstant.CONTEXT_FILL, SVGValueConstant.CONTEXT_STROKE].has(stroke):
			attr_fill = SVGPaint.new("#00000000")
		else:
			attr_stroke = SVGPaint.new(stroke)
	emit_changed()

func _set_attr_stroke_width(stroke_width):
	if typeof(stroke_width) != TYPE_STRING:
		attr_stroke_width = stroke_width
	else:
		attr_stroke_width = SVGLengthPercentage.new(stroke_width)

func _set_attr_transform(transform):
	if typeof(transform) != TYPE_STRING:
		attr_transform = transform
	else:
		if SVGValueConstant.NONE == transform:
			attr_transform = Transform2D()
		else:
			var split = transform.split(" ", false)
			var transform_matrix = Transform()
			for transform_command in split:
				transform_command = transform_command.strip_edges()
				if transform_command.begins_with("rotate("):
					var values = transform_command.replace("rotate(", "").rstrip(")").strip_edges().split(" ", false)
					if values.size() >= 2:
						transform_matrix = transform_matrix.rotated(Vector3(1, 0, 0), deg2rad(values[0].to_float()))
						transform_matrix = transform_matrix.rotated(Vector3(0, 1, 0), deg2rad(values[1].to_float()))
					if values.size() == 3:
						transform_matrix = transform_matrix.rotated(Vector3(0, 0, -1), deg2rad(values[2].to_float()))
				elif transform_command.begins_with("translate("):
					var values = transform_command.replace("translate(", "").rstrip(")").strip_edges().split(" ", false)
					if values.size() >= 2:
						transform_matrix = transform_matrix.translated(
							values[0].to_float(),
							values[1].to_float(),
							-values[2].to_float() if values.size() == 3 else 0.0
						)
				elif transform_command.begins_with("scale("):
					var values = transform_command.replace("scale(", "").rstrip(")").strip_edges().split(" ", false)
					if values.size() >= 2:
						transform_matrix = transform_matrix.scaled(
							values[0].to_float(),
							values[1].to_float(),
							values[2].to_float() if values.size() == 3 else 0.0
						)
			attr_transform = transform_matrix
