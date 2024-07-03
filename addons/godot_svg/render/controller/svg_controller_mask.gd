extends "svg_controller_element.gd"

#------------#
# Attributes #
#------------#

var attr_height = SVGLengthPercentage.new("120%"): set = _set_attr_height
var attr_mask_content_units = SVGValueConstant.USER_SPACE_ON_USE: set = _set_attr_mask_content_units
var attr_mask_units = SVGValueConstant.OBJECT_BOUNDING_BOX: set = _set_attr_mask_units
var attr_x = SVGLengthPercentage.new("-10%"): set = _set_attr_x
var attr_y = SVGLengthPercentage.new("-10%"): set = _set_attr_y
var attr_width = SVGLengthPercentage.new("120%"): set = _set_attr_width

#---------------------#
# Internal Properties #
#---------------------#

var _mask_background = null
var _mask_viewport = null
var _mask_update_queue = []
var _current_mask_update_target = null
var _current_mask_tick_count = 0

#-----------#
# Lifecycle #
#-----------#

func _init():
	node_name = "mask"
	is_renderable = false
	_mask_viewport = SubViewport.new()
	_mask_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_mask_viewport.name = "mask_viewport"
	_mask_background = ColorRect.new()
	_mask_background.color = Color(0, 0, 0, 1)
	_mask_viewport.add_child(_mask_background)

func _ready():
	super.add_child(_mask_viewport)

func _process(_delta):
	if _current_mask_update_target != null:
		call_deferred("_on_mask_draw_deferred")

#------------------#
# Internal Methods #
#------------------#

func _on_mask_draw_deferred():
	if _current_mask_update_target != null:
		var viewport_texture = _mask_viewport.get_texture()
		_current_mask_update_target._mask_updated(viewport_texture, self)
	if _mask_update_queue.size() > 0:
		_current_mask_update_target = _mask_update_queue.pop_front()
		_current_mask_tick_count = 0
		_prepare_viewport_for_draw()
	else:
		_mask_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		_current_mask_update_target = null

func _prepare_viewport_for_draw():
	if _mask_viewport != null:
		if _current_mask_update_target != null:
			var scale_factor = _current_mask_update_target.get_root_scale_factor()
			_mask_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
			
			var target_bounding_box = _current_mask_update_target.get_stroked_bounding_box()
			var mask_content_relative_size = target_bounding_box.size
			
			# Mask Units
			var mask_unit_bounding_box = get_mask_unit_bounding_box(_current_mask_update_target)
			_mask_viewport.size = mask_unit_bounding_box.size * scale_factor
			
			# Mask Content Units
			var mask_content_unit_bounding_box = get_mask_content_unit_bounding_box(_current_mask_update_target)
			
			# Mask Viewport Transform
			var transform_scale = null
			var transform_origin = null
			if attr_mask_content_units == SVGValueConstant.OBJECT_BOUNDING_BOX:
				transform_scale = (mask_content_relative_size / mask_content_unit_bounding_box.size) * scale_factor
				transform_origin = (-mask_unit_bounding_box.position + target_bounding_box.position) * scale_factor
			else:
				transform_scale = scale_factor
				transform_origin = (-mask_unit_bounding_box.position) * scale_factor
			if transform_scale.is_equal_approx(Vector2()):
				transform_scale = Vector2(1.0, 1.0)
			_mask_viewport.canvas_transform = Transform2D().scaled(transform_scale)
			_mask_viewport.canvas_transform.origin = transform_origin

			_mask_background.position = -_mask_viewport.canvas_transform.origin / scale_factor
			if attr_mask_content_units == SVGValueConstant.OBJECT_BOUNDING_BOX:
				_mask_background.size = Vector2(_mask_viewport.size) * _mask_viewport.canvas_transform.get_scale()
			else:
				_mask_background.size = mask_content_unit_bounding_box.size
			_update_view_box_recursive(mask_content_unit_bounding_box, element_resource)
			

func _update_view_box_recursive(new_view_box, parent = null):
	for child in parent.children:
		if root_controller._element_resource_to_controller_map.has(child):
			var controller = root_controller._element_resource_to_controller_map[child]
			if controller.node_name != "viewport":
				controller.inherited_view_box = new_view_box
				_update_view_box_recursive(new_view_box, child)
			controller.controlled_node.queue_redraw()

#----------------#
# Public Methods #
#----------------#

func add_child(new_child, legible_unique_name = false):
	if _mask_viewport != null:
		_mask_viewport.add_child(new_child, legible_unique_name)

func get_mask_unit_bounding_box(mask_target):
	var mask_unit_bounding_box = Rect2()
	if attr_mask_units == SVGValueConstant.OBJECT_BOUNDING_BOX:
		mask_unit_bounding_box = mask_target.get_stroked_bounding_box()
	else: # USER_SPACE_ON_USE
		mask_unit_bounding_box = mask_target.inherited_view_box
	mask_unit_bounding_box.position.x += attr_x.get_length(mask_unit_bounding_box.size.x)
	mask_unit_bounding_box.position.y += attr_y.get_length(mask_unit_bounding_box.size.y)
	mask_unit_bounding_box.size.x = attr_width.get_length(mask_unit_bounding_box.size.x)
	mask_unit_bounding_box.size.y = attr_height.get_length(mask_unit_bounding_box.size.y)
	return mask_unit_bounding_box

func get_mask_content_unit_bounding_box(mask_target):
	var mask_content_unit_bounding_box = Rect2()
	if attr_mask_content_units == SVGValueConstant.OBJECT_BOUNDING_BOX:
		mask_content_unit_bounding_box = Rect2(0, 0, 1, 1) # mask_target.get_bounding_box()
	else: # USER_SPACE_ON_USE
		mask_content_unit_bounding_box = mask_target.inherited_view_box
	return mask_content_unit_bounding_box

func request_mask_update(callback_node):
	_mask_update_queue.push_back(callback_node)
	if _current_mask_update_target == null and _mask_update_queue.size() > 0:
		_current_mask_update_target = _mask_update_queue.pop_front()
		_current_mask_tick_count = 0
		_prepare_viewport_for_draw()

#-------------------#
# Getters / Setters #
#-------------------#

func _set_attr_height(height):
	if typeof(height) != TYPE_STRING:
		attr_height = height
	else:
		attr_height = SVGLengthPercentage.new(height)
	apply_props("height")

func _set_attr_mask_content_units(mask_content_units):
	attr_mask_content_units = mask_content_units
	apply_props("content_units")

func _set_attr_mask_units(mask_units):
	attr_mask_units = mask_units
	apply_props("mask_units")

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
