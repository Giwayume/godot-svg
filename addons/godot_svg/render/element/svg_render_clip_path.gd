extends "svg_render_element.gd"

var attr_clip_path_units = SVGValueConstant.USER_SPACE_ON_USE setget _set_attr_clip_path_units

var _clip_path_background = null
var _clip_path_viewport = null
var _clip_path_update_queue = []
var _current_clip_path_update_target = null

# Lifecycle

func _init():
	node_name = "clipPath"
	_clip_path_viewport = Viewport.new()
	_clip_path_viewport.usage = Viewport.USAGE_2D_NO_SAMPLING
	_clip_path_viewport.render_target_update_mode = Viewport.UPDATE_DISABLED
	_clip_path_viewport.render_target_v_flip = true
	_clip_path_viewport.name = "clip_path_viewport"
	_clip_path_background = ColorRect.new()
	_clip_path_background.color = Color(0, 0, 0, 1)
	_clip_path_viewport.add_child(_clip_path_background)
	.add_child(_clip_path_viewport)
	hide()

func _process(_delta):
	if _current_clip_path_update_target != null:
		call_deferred("_on_clip_path_draw_deferred")

# Internal Methods

func _on_clip_path_draw_deferred():
	if _current_clip_path_update_target != null:
		var viewport_texture = _clip_path_viewport.get_texture()
		_current_clip_path_update_target._clip_path_updated(viewport_texture, self)
	if _clip_path_update_queue.size() > 0:
		_current_clip_path_update_target = _clip_path_update_queue.pop_front()
		_prepare_viewport_for_draw()
	else:
		_clip_path_viewport.render_target_update_mode = Viewport.UPDATE_DISABLED
		_current_clip_path_update_target = null

func _prepare_viewport_for_draw():
	if _clip_path_viewport != null:
		if _current_clip_path_update_target != null:
			var scale_factor = _current_clip_path_update_target.get_root_scale_factor()
			_clip_path_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
			
			var target_bounding_box = _current_clip_path_update_target.get_stroked_bounding_box()
			var clip_path_content_relative_size = target_bounding_box.size
			
			# Clip Path Units
			var clip_path_unit_bounding_box = get_clip_path_unit_bounding_box(_current_clip_path_update_target)
			_clip_path_viewport.size = clip_path_unit_bounding_box.size * scale_factor
			
			# Clip Path Content Units
			var clip_path_content_unit_bounding_box = get_clip_path_content_unit_bounding_box(_current_clip_path_update_target)
			
			# Clip Path Viewport Transform
			var transform_scale = null
			var transform_origin = null
			if attr_clip_path_units == SVGValueConstant.OBJECT_BOUNDING_BOX:
				transform_scale = (clip_path_content_relative_size / clip_path_content_unit_bounding_box.size) * scale_factor
				transform_origin = (-clip_path_unit_bounding_box.position + target_bounding_box.position) * scale_factor
			else:
				transform_scale = scale_factor
				transform_origin = (-clip_path_unit_bounding_box.position) * scale_factor
			if transform_scale.is_equal_approx(Vector2()):
				transform_scale = Vector2(1.0, 1.0)
			_clip_path_viewport.canvas_transform = Transform2D().scaled(transform_scale)
			_clip_path_viewport.canvas_transform.origin = transform_origin
			
			
#			var transform_scale = (clip_path_unit_bounding_box.size / clip_path_content_unit_bounding_box.size + clip_path_unit_bounding_box.position) * scale_factor
#			if transform_scale.is_equal_approx(Vector2()):
#				transform_scale = Vector2(1.0, 1.0)
#			_clip_path_viewport.canvas_transform = Transform2D().scaled(transform_scale)
#			_clip_path_viewport.canvas_transform.origin = -clip_path_unit_bounding_box.position * scale_factor
			
			_clip_path_background.rect_position = (-_clip_path_viewport.canvas_transform.origin / scale_factor) + Vector2(-5.0, -5.0)
			if attr_clip_path_units == SVGValueConstant.OBJECT_BOUNDING_BOX:
				_clip_path_background.rect_size = (_clip_path_viewport.size * _clip_path_viewport.canvas_transform.get_scale()) + Vector2(10.0, 10.0)
			else:
				_clip_path_background.rect_size = clip_path_content_unit_bounding_box.size + Vector2(10.0, 10.0)
			_update_view_box_recursive(clip_path_content_unit_bounding_box, element_resource)

func _update_view_box_recursive(new_view_box, parent = null):
	for child in parent.children:
		if svg_node._renderer_map.has(child):
			var renderer = svg_node._renderer_map[child]
			if renderer.node_name != "viewport":
				renderer.inherited_view_box = new_view_box
				_update_view_box_recursive(new_view_box, child)
			renderer.update()

# Public Methods

func add_child(new_child, legible_unique_name = false):
	if _clip_path_viewport != null:
		_clip_path_viewport.add_child(new_child, legible_unique_name)

func get_clip_path_unit_bounding_box(clip_path_target):
	return _current_clip_path_update_target.get_stroked_bounding_box()

func get_clip_path_content_unit_bounding_box(clip_path_target):
	var clip_path_content_unit_bounding_box = Rect2()
	if attr_clip_path_units == SVGValueConstant.OBJECT_BOUNDING_BOX:
		clip_path_content_unit_bounding_box = Rect2(0, 0, 1, 1) # clip_path_target.get_bounding_box()
	else: # USER_SPACE_ON_USE
		clip_path_content_unit_bounding_box = clip_path_target.inherited_view_box
	return clip_path_content_unit_bounding_box

func request_clip_path_update(callback_node):
	_clip_path_update_queue.push_back(callback_node)
	if _current_clip_path_update_target == null and _clip_path_update_queue.size() > 0:
		_current_clip_path_update_target = _clip_path_update_queue.pop_front()
		_prepare_viewport_for_draw()

# Getters / Setters

func _set_attr_clip_path_units(clip_path_units):
	attr_clip_path_units = clip_path_units
	
