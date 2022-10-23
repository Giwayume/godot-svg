extends "svg_render_element.gd"

var attr_x = SVGLengthPercentage.new("0") setget _set_attr_x
var attr_y = SVGLengthPercentage.new("0") setget _set_attr_y
var attr_width = SVGValueConstant.AUTO setget _set_attr_width
var attr_height = SVGValueConstant.AUTO setget _set_attr_height
var attr_href = SVGValueConstant.NONE setget _set_attr_href
var attr_xlink_href = SVGValueConstant.NONE setget _set_attr_xlink_href
var attr_preserve_aspect_ratio = {
	"align": {
		"x": SVGValueConstant.MID,
		"y": SVGValueConstant.MID,
	},
	"meet_or_slice": SVGValueConstant.MEET,
} setget _set_attr_preserve_aspect_ratio
var attr_crossorigin = ""

# Internal Variables

var _control_frame = null
var _image_sprite = null

# Lifecycle

func _init():
	node_name = "image"

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if _control_frame != null:
			if is_instance_valid(_control_frame):
				_control_frame.queue_free()
			_control_frame = null
		if _image_sprite != null:
			if is_instance_valid(_image_sprite):
				_image_sprite.queue_free()
			_image_sprite = null

func _props_applied():
	._props_applied()
	
	if attr_visibility == SVGValueConstant.VISIBLE and attr_href != SVGValueConstant.NONE:
		show()
	else:
		hide()
		return
	
	if _control_frame == null:
		_control_frame = Control.new()
		_control_frame.rect_clip_content = true
		_control_frame.name = "ImageClipFrame"
		add_child(_control_frame)
	if _image_sprite == null:
		_image_sprite = Sprite.new()
		_image_sprite.centered = false
		_image_sprite.name = "Image"
		_control_frame.add_child(_image_sprite)
	
	var image_resource_path = SVGAttributeParser.relative_to_absolute_resource_url(
		attr_href,
		svg_node._svg.resource_path
	)
	var image_texture = null
	if ResourceLoader.exists(image_resource_path):
		image_texture = load(image_resource_path)
	
	if image_texture == null:
		hide()
		return
	
	_image_sprite.texture = image_texture
	
	var x = attr_x.get_length(inherited_view_box.size.x, inherited_view_box.position.x)
	var y = attr_y.get_length(inherited_view_box.size.y, inherited_view_box.position.y)

	transform.origin = Vector2(x, y)
	
	var texture_width = image_texture.get_width()
	var texture_height = image_texture.get_height()
	
	var width = 0
	if attr_width is SVGLengthPercentage:
		width = attr_width.get_length(inherited_view_box.size.x)
	elif attr_width == SVGValueConstant.AUTO:
		width = texture_width
	
	var height = 0
	if attr_height is SVGLengthPercentage:
		height = attr_height.get_length(inherited_view_box.size.y)
	elif attr_height == SVGValueConstant.AUTO:
		height = texture_height
	
	if texture_width == 0 or texture_height == 0 or width == 0 or height == 0:
		hide()
		return
	
	_control_frame.rect_size = Vector2(width, height)
	
	if typeof(attr_preserve_aspect_ratio) == TYPE_STRING:
		if attr_preserve_aspect_ratio == SVGValueConstant.NONE:
			_image_sprite.scale = Vector2(
				texture_width / width,
				texture_height / height
			)
	else:
		var x_align_ratio = 0.0
		if attr_preserve_aspect_ratio.align.x == SVGValueConstant.MID:
			x_align_ratio = 0.5
		elif attr_preserve_aspect_ratio.align.x == SVGValueConstant.MAX:
			x_align_ratio = 1.0
		var y_align_ratio = 0.0
		if attr_preserve_aspect_ratio.align.y == SVGValueConstant.MID:
			y_align_ratio = 0.5
		elif attr_preserve_aspect_ratio.align.y == SVGValueConstant.MAX:
			y_align_ratio = 1.0
		if attr_preserve_aspect_ratio.meet_or_slice == SVGValueConstant.SLICE:
			if (texture_width / texture_height) > (width / height):
				var scale_y = height / texture_height
				_image_sprite.scale = Vector2(
					scale_y,
					scale_y
				)
				var leftover_space = width - (texture_width * _image_sprite.scale.x)
				_image_sprite.position = Vector2(x_align_ratio * leftover_space, 0.0)
			else:
				var scale_x = width / texture_width
				_image_sprite.scale = Vector2(
					scale_x,
					scale_x
				)
				var leftover_space = height - (texture_height * _image_sprite.scale.y)
				_image_sprite.position = Vector2(0.0, y_align_ratio * leftover_space)
		else: # MEET
			if (texture_width / texture_height) > (width / height):
				var scale_x = width / texture_width
				_image_sprite.scale = Vector2(
					scale_x,
					scale_x
				)
				var leftover_space = height - (texture_height * _image_sprite.scale.y)
				_image_sprite.position = Vector2(0.0, y_align_ratio * leftover_space)
			else:
				var scale_y = height / texture_height
				_image_sprite.scale = Vector2(
					scale_y,
					scale_y
				)
				var leftover_space = width - (texture_width * _image_sprite.scale.x)
				_image_sprite.position = Vector2(x_align_ratio * leftover_space, 0.0)

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
		if width == SVGValueConstant.AUTO:
			attr_width = width
		else:
			attr_width = SVGLengthPercentage.new(width)
	apply_props()

func _set_attr_height(height):
	if typeof(height) != TYPE_STRING:
		attr_height = height
	else:
		if height == SVGValueConstant.AUTO:
			attr_height = height
		else:
			attr_height = SVGLengthPercentage.new(height)
	apply_props()

func _set_attr_href(href):
	attr_href = href
	apply_props()

func _set_attr_xlink_href(xlink_href):
	_set_attr_href(xlink_href)

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
				"meet_or_slice": split[1] if split[1].length() > 1 else SVGValueConstant.MEET,
			}
	apply_props()
