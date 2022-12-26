extends Node2D

signal bounding_box_calculated(new_bounding_box)

const PathCommand = SVGValueConstant.PathCommand

const SVGRenderBakedShader = preload("../shader/svg_render_baked_shader.tres")
const SVGRenderFillShaderGles2 = preload("../shader/svg_render_fill_shader_gles2.tres")
const SVGRenderFillShaderGles3 = preload("../shader/svg_render_fill_shader_gles3.tres")

export(Resource) var element_resource = null setget _set_element_resource
export(Rect2) var inherited_view_box = Rect2()

var SVGRenderFillShader = SVGRenderFillShaderGles2 if OS.get_current_video_driver() == OS.VIDEO_DRIVER_GLES2 else SVGRenderFillShaderGles3

# Reference to SVG2D Node

var assume_no_self_intersections = false
var assume_no_holes = false
var is_root = false
var is_in_root_viewport = true
var is_in_clip_path = false
var is_render_group = false # Child rendering elements can be drawn inside this element
var svg_node = null
var node_name = "element"
var node_text = ""
var render_cache_id = ""

# Core Attributes
var attr_id = null setget _set_attr_id
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
var attr_clip_path = SVGValueConstant.NONE setget _set_attr_clip_path
var attr_clip_rule = SVGValueConstant.NON_ZERO setget _set_attr_clip_rule
var attr_color = null setget _set_attr_color
var attr_color_interpolation = null
var attr_color_rendering = null
var attr_cursor = null
var attr_display = "inline" setget _set_attr_display
var attr_fill = SVGPaint.new("#000000") setget _set_attr_fill
var attr_fill_opacity = SVGLengthPercentage.new("100%") setget _set_attr_fill_opacity
var attr_fill_rule = SVGValueConstant.NON_ZERO setget _set_attr_fill_rule
var attr_filter = null
var attr_mask = SVGValueConstant.NONE setget _set_attr_mask
var attr_opacity = SVGLengthPercentage.new("100%") setget _set_attr_opacity
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

var _is_editor_hint = false
var _bounding_box = Rect2(0, 0, 0, 0)
var _baking_viewport = null
var _baked_sprite = null
var _paint_server_container_node = null
var _last_known_viewport_scale = Vector2()
var _shape_fills = []
var _shape_strokes = []
var _child_list = []
var _child_container = self
var _is_props_applied_scheduled = false
var _is_view_box_clip = false
var _view_box_clip_rect = null
var _is_href_duplicate = false
var _rerender_prop_cache = {}
var _paint_server_textures = {}
var _current_arc_resolution = null

# Lifecycle

func _init():
	_is_editor_hint = Engine.is_editor_hint()

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if _paint_server_container_node != null:
			if is_instance_valid(_paint_server_container_node):
				_paint_server_container_node.queue_free()
			if is_instance_valid(_baking_viewport):
				_baking_viewport.queue_free()
			if is_instance_valid(_baked_sprite):
				_baked_sprite.queue_free()

func _ready():
	connect("visibility_changed", self, "_on_visibility_changed")
	if svg_node != null:
		if (
			not svg_node.disable_render_cache and
			svg_node._svg != null and
			svg_node._svg.render_cache != null and
			svg_node._svg.render_cache.has("process_polygon") and
			svg_node._svg.render_cache.process_polygon.has(render_cache_id)
		):
			_rerender_prop_cache["processed_polygon"] = svg_node._svg.render_cache.process_polygon[render_cache_id]
		svg_node.connect("viewport_scale_changed", self, "_on_viewport_scale_changed")
		call_deferred("_on_viewport_scale_changed", svg_node._last_known_viewport_scale)

func _props_applied():
	_calculate_bounding_box()
	if (
		attr_mask != SVGValueConstant.NONE or
		attr_clip_path != SVGValueConstant.NONE or
		(is_render_group and attr_opacity.get_length(1) < 1)
	):
		if _child_container != _baking_viewport:
			var bounding_box = get_stroked_bounding_box()
			if _baked_sprite == null:
				_baked_sprite = Sprite.new()
				_baked_sprite.centered = false
				_baked_sprite.material = ShaderMaterial.new()
				_baked_sprite.material.shader = SVGRenderBakedShader
				_baked_sprite.position = bounding_box.position
				call_deferred("_add_baked_sprite_as_child")
			if _baking_viewport == null:
				_baking_viewport = Viewport.new()
				_baking_viewport.usage = Viewport.USAGE_2D_NO_SAMPLING
				_baking_viewport.transparent_bg = true
				_baking_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
				_baking_viewport.render_target_v_flip = true
				_baking_viewport.name = "baking_viewport"
#				_baking_viewport.size = bounding_box.size
				call_deferred("_add_baking_viewport_as_child", bounding_box)
			_swap_child_container(_baking_viewport)
	elif _is_view_box_clip:
		if _child_container != _view_box_clip_rect:
			if _baked_sprite != null:
				_baked_sprite.queue_free()
				_baked_sprite = null
			if _baking_viewport != null:
				_baking_viewport.queue_free()
				_baking_viewport = null
			if _view_box_clip_rect == null:
				var view_box = inherited_view_box
				if "attr_view_box" in self and self.attr_view_box is Rect2:
					view_box = self.attr_view_box
				_view_box_clip_rect = Control.new()
				_view_box_clip_rect.rect_position = Vector2()
				_view_box_clip_rect.rect_size = view_box.size
				_view_box_clip_rect.rect_clip_content = true
				.add_child(_view_box_clip_rect)
			_swap_child_container(_view_box_clip_rect)
	else:
		if _child_container != self:
			_swap_child_container(self)
			if _baked_sprite != null:
				_baked_sprite.queue_free()
				_baked_sprite = null
			if _baking_viewport != null:
				_baking_viewport.queue_free()
				_baking_viewport = null
			if _view_box_clip_rect != null:
				_view_box_clip_rect.queue_free()
				_view_box_clip_rect = null

func _draw():
	if attr_mask != SVGValueConstant.NONE and _baked_sprite != null:
		var locator_result = svg_node._resolve_resource_locator(attr_mask)
		var mask_renderer = locator_result.renderer
		if mask_renderer != null and mask_renderer.node_name == "mask":
			mask_renderer.request_mask_update(self)
	if attr_clip_path != SVGValueConstant.NONE and _baked_sprite != null:
		var locator_result = svg_node._resolve_resource_locator(attr_clip_path)
		var clip_path_renderer = locator_result.renderer
		if clip_path_renderer != null and clip_path_renderer.node_name == "clipPath":
			clip_path_renderer.request_clip_path_update(self)
	if is_render_group and attr_opacity.get_length(1) < 1 and _baked_sprite != null:
		call_deferred("_opacity_mask_updated")

# Internal Methods

func _calculate_arc_resolution(scale_factor: Vector2): # Optional override for optimization
	var applied_scale_x = pow(2, ceil(log(scale_factor.x) / log(2)) + 1)
	var applied_scale_y = pow(2, ceil(log(scale_factor.y) / log(2)) + 1)
	return Vector2(
		pow(applied_scale_x, 0.5) * 0.1,
		pow(applied_scale_y, 0.5) * 0.1
	)

func _process_polygon(): # Override me
	return {
		"fill": PoolVector2Array(),
		"stroke": PoolVector2Array()
	}

func _process_simplified_polygon():
	var time_start = OS.get_system_time_msecs()
	var polygons = _process_polygon()
	var simplified_fills = []
	var simplified_fill_clockwise_checks = []
	var simplified_holes = []
	var needs_refill = false
	var needs_restroke = false
	
	if polygons.has("fill"):
		if polygons.fill.size() > 0:
			if not polygons.fill[0] is PoolVector2Array and not polygons.fill[0] is Array:
				polygons.fill = [polygons.fill]
		
		if polygons.has("is_simple_shape") and polygons.is_simple_shape:
			simplified_fills = polygons.fill
			simplified_fill_clockwise_checks.push_back(null)
			simplified_holes = [[]]
		else:
			var fill_rule = attr_fill_rule
			if is_in_clip_path:
				fill_rule = attr_clip_rule
			
			for fill_path in polygons.fill:
				var path_simplifications = SVGPathSolver.simplify(fill_path, {
					SVGValueConstant.EVEN_ODD: SVGPolygonSolver.FillRule.EVEN_ODD,
					SVGValueConstant.NON_ZERO: SVGPolygonSolver.FillRule.NON_ZERO,
				}[fill_rule], assume_no_self_intersections, assume_no_holes)
				for path_simplification in path_simplifications:
					var simplified_fill = path_simplification.fill_instructions
					var simplified_hole = path_simplification.hole_instructions
					if simplified_fill.size() > 0:
						simplified_fills.push_back(simplified_fill)
						simplified_fill_clockwise_checks.push_back(path_simplification.is_clockwise)
					else:
						print("\n[godot-svg] Error occurred when simplifying fill path ", fill_path)
						simplified_fills.push_back(fill_path)
						simplified_fill_clockwise_checks.push_back(null)
					simplified_holes.push_back(simplified_hole)
	
	var bounds = { "left": INF, "right": -INF, "top": INF, "bottom": -INF }
	var triangulated_fills = []
	var simplified_fill_index = 0
	for simplified_fill in simplified_fills:
		if simplified_fill[0] is Dictionary:
			var fill_triangulation = SVGTriangulation.triangulate_fill_path(
				simplified_fill,
				simplified_holes[simplified_fill_index],
				simplified_fill_clockwise_checks[simplified_fill_index],
				svg_node.triangulation_method
			)
			if (
				fill_triangulation.interior_vertices.size() > 0 or
				fill_triangulation.quadratic_vertices.size() > 0 or
				fill_triangulation.cubic_vertices.size() > 0
			):
				triangulated_fills.push_back(fill_triangulation)
				SVGTriangulation.evaluate_rect_bounding_box(bounds, fill_triangulation.bounding_box)
		else:
			pass
		simplified_fill_index += 1
	
	var is_recalculate_paint = false
	if _bounding_box.size == Vector2.ZERO:
		_rerender_prop_cache.erase("stroke")
		_rerender_prop_cache.erase("fill")
		is_recalculate_paint = true
	_bounding_box = Rect2(bounds.left, bounds.top, bounds.right - bounds.left, bounds.bottom - bounds.top)
	if is_recalculate_paint:
		needs_refill = true
		needs_restroke = true
	
	var triangulated_strokes = []
	if polygons.has("stroke"):
		var stroke_width = get_visible_stroke_width()
		if polygons.stroke.size() > 0 and stroke_width > 0.0:
			var dash_array = []
			var dash_offset = 0
			if attr_stroke_dasharray.size() > 0:
				var full_percentage_size = sqrt((pow(inherited_view_box.size.x, 2) + pow(inherited_view_box.size.y, 2)) / 2)
				for size in attr_stroke_dasharray:
					dash_array.push_back(size.get_length(full_percentage_size))
				dash_offset = attr_stroke_dashoffset.get_length(full_percentage_size)
				if SVGHelper.array_sum(dash_array) == 0.0:
					dash_array = []
			var current_stroke = []
			var stroke_instruction_index = 0
			var stroke_instruction_size = polygons.stroke.size()
			for i in range(0, stroke_instruction_size + 1):
				var instruction = polygons.stroke[min(i, stroke_instruction_size - 1)]
				if instruction.command == PathCommand.MOVE_TO or stroke_instruction_index > stroke_instruction_size - 1:
					if current_stroke.size() > 0:
						if dash_array.size() > 0:
							var dasharray_path = SVGPathSolver.dash_array(current_stroke, dash_array, dash_offset)
							triangulated_strokes.push_back(
								SVGTriangulation.triangulate_stroke_path(
									dasharray_path, stroke_width, attr_stroke_linecap,
									attr_stroke_linejoin, attr_stroke_miterlimit,
									current_stroke[current_stroke.size() -1].command == PathCommand.CLOSE_PATH
								)
							)
						else:
							triangulated_strokes.push_back(
								SVGTriangulation.triangulate_stroke_subpath(
									current_stroke, stroke_width, attr_stroke_linecap,
									attr_stroke_linejoin, attr_stroke_miterlimit,
									current_stroke[current_stroke.size() -1].command == PathCommand.CLOSE_PATH
								)
							)
					current_stroke = []
				current_stroke.push_back(instruction)
				stroke_instruction_index += 1
	
#	print_debug(OS.get_system_time_msecs() - time_start)
	
	return {
		"fill": triangulated_fills,
		"needs_refill": needs_refill,
		"stroke": triangulated_strokes,
		"needs_restroke": needs_restroke,
	}

func _process_simplified_polygon_complete(polygons):
	_rerender_prop_cache["processed_polygon"] = polygons
	_props_applied()


func _calculate_bounding_box():
	pass # Override

func _apply_props_deferred():
	_is_props_applied_scheduled = false
	_props_applied()

func _clip_path_updated(clip_path_texture, clip_path_renderer):
	if _baked_sprite != null and _baking_viewport != null:
		var bounding_box = get_stroked_bounding_box()
		var scale_factor = get_scale_factor()
		var clip_path_unit_bounding_box = clip_path_renderer.get_clip_path_unit_bounding_box(self)
		if attr_mask == SVGValueConstant.NONE:
			_baked_sprite.position = bounding_box.position
			_baked_sprite.scale = Vector2(1.0, 1.0) / scale_factor
		_baking_viewport.size = clip_path_unit_bounding_box.size * scale_factor
		_baking_viewport.canvas_transform = Transform2D().scaled(scale_factor)
		_baking_viewport.canvas_transform.origin += (-clip_path_unit_bounding_box.position) * scale_factor
		_baking_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
		_baked_sprite.texture = null # Force sprite to resize
		_baked_sprite.texture = _baking_viewport.get_texture()
		if clip_path_texture != null:
			_baked_sprite.material.set_shader_param("clip_path", clip_path_texture)
		elif material != null:
			_baked_sprite.material.set_shader_param("clip_path", null)

func _mask_updated(mask_texture, mask_renderer):
	if _baked_sprite != null and _baking_viewport != null:
		var bounding_box = get_stroked_bounding_box()
		var scale_factor = get_scale_factor()
		var mask_unit_bounding_box = mask_renderer.get_mask_unit_bounding_box(self)
		_baking_viewport.size = mask_unit_bounding_box.size * scale_factor
		_baking_viewport.canvas_transform = Transform2D().scaled(scale_factor)
		_baking_viewport.canvas_transform.origin += (-mask_unit_bounding_box.position) * scale_factor
		_baking_viewport.render_target_update_mode = Viewport.UPDATE_ONCE

		_baked_sprite.position = mask_unit_bounding_box.position
		_baked_sprite.scale = Vector2(1.0, 1.0) / scale_factor
		_baked_sprite.texture = null # Force sprite to resize
		_baked_sprite.texture = _baking_viewport.get_texture()
		if mask_texture != null:
			_baked_sprite.material.set_shader_param("mask", mask_texture)
		elif material != null:
			_baked_sprite.material.set_shader_param("mask", null)

func _opacity_mask_updated():
	if _baked_sprite != null and _baking_viewport != null:
		if attr_mask == SVGValueConstant.NONE and attr_clip_path == SVGValueConstant.NONE:
			var bounding_box = get_stroked_bounding_box()
			var scale_factor = get_scale_factor()
			if (
				bounding_box.size.x > 0 and
				bounding_box.size.y > 0 and
				scale_factor.x != 0.0 and
				scale_factor.y != 0.0
			):
				_baking_viewport.size = bounding_box.size * scale_factor
				_baking_viewport.canvas_transform = Transform2D().scaled(scale_factor)
				_baking_viewport.canvas_transform.origin += (-bounding_box.position) * scale_factor
				_baking_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
				
				_baked_sprite.position = bounding_box.position
				_baked_sprite.scale = Vector2(1.0, 1.0) / scale_factor
				_baked_sprite.texture = null # Force sprite to resize
				_baked_sprite.texture = _baking_viewport.get_texture()
		_baked_sprite.self_modulate = Color(1, 1, 1, attr_opacity.get_length(1))

func _swap_child_container(new_container):
	var swapped_child_list = []
	for child in _child_list:
		if is_instance_valid(child):
			var parent = child.get_parent()
			if parent == self:
				.remove_child(child)
			else:
				parent.remove_child(child)
			if new_container == self:
				.add_child(child)
			else:
				new_container.add_child(child)
			swapped_child_list.push_back(child)
	_child_list = swapped_child_list
	_child_container = new_container

func _add_baked_sprite_as_child():
	if _baked_sprite != null:
		.add_child(_baked_sprite)

func _add_baking_viewport_as_child(bounding_box):
	if _baking_viewport != null:
		.add_child(_baking_viewport)
		_baking_viewport.canvas_transform = global_transform.inverse()
		_baking_viewport.canvas_transform.origin += bounding_box.position

func _add_child_direct(new_child, legible_unique_name = false):
	.add_child(new_child, legible_unique_name)

# Public Methods

func apply_props():
	if not _is_props_applied_scheduled:
		_is_props_applied_scheduled = true
		call_deferred("_apply_props_deferred")
		update()

func add_child(new_child, legible_unique_name = false):
	if not _child_list.has(new_child):
		_child_list.push_back(new_child)
	if _child_container == self:
		.add_child(new_child, legible_unique_name)
	else:
		_child_container.add_child(new_child, legible_unique_name)

func remove_child(child_to_remove):
	if _child_list.has(child_to_remove):
		_child_list.remove(child_to_remove)
	if _child_container == self:
		.remove_child(child_to_remove)
	else:
		_child_container.remove_child(child_to_remove)

func set_attributes(attributes: Dictionary):
	for attribute_name in attributes:
		if "attr_" + attribute_name in self:
			set("attr_" + attribute_name, attributes[attribute_name])

func apply_resource_attributes():
	if element_resource != null:
		for attribute_name in element_resource.attributes:
			if "attr_" + attribute_name in self:
				set("attr_" + attribute_name, element_resource.attributes[attribute_name])
	update()

func get_bounding_box():
	return _bounding_box

func get_stroked_bounding_box():
	var stroke_width = get_visible_stroke_width()
	var half_stroke_width = stroke_width / 2.0
	return Rect2(
		_bounding_box.position.x - half_stroke_width,
		_bounding_box.position.y - half_stroke_width,
		_bounding_box.size.x + stroke_width,
		_bounding_box.size.y + stroke_width
	)

func get_visible_stroke_width():
	var stroke_width = 0.0
	if not is_in_clip_path:
		stroke_width = attr_stroke_width.get_length(inherited_view_box.size.x)
		if typeof(attr_stroke) == TYPE_STRING:
			if attr_stroke == SVGValueConstant.NONE:
				stroke_width = 0.0
		elif attr_stroke is SVGPaint:
			if attr_stroke.color != null and attr_stroke.color.a <= 0.0:
				stroke_width = 0.0
	return stroke_width

func get_root_scale_factor():
	if svg_node == null or svg_node._fixed_scaling_ratio == 0:
		return global_scale * _last_known_viewport_scale
	else:
		return global_scale * svg_node._fixed_scaling_ratio

func get_scale_factor():
	if (svg_node == null or svg_node._fixed_scaling_ratio == 0) and not is_in_root_viewport:
		var viewport = get_viewport()
		if viewport != null:
			return viewport.canvas_transform.get_scale()
		else:
			return Vector2(1, 1)
	else:
		return get_root_scale_factor()

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
	
	if not is_render_group:
		modulate = Color(1, 1, 1, attr_opacity.get_length(1))
	
	var fill_rule = attr_fill_rule
	if is_in_clip_path:
		updates.fill_color = Color(1, 1, 1, 1)
		updates.stroke_color = Color(0, 0, 0, 0)
		fill_rule = attr_clip_rule
	
	var will_fill = updates.has("fill_color") and updates.fill_color.a > 0
	var will_stroke = updates.has("stroke_color") and updates.stroke_color.a > 0
	
	var processed_polygon = null
	var scale_factor = Vector2(1.0, 1.0)
	if will_fill or will_stroke:
		if updates.has("scale_factor"):
			scale_factor = updates.scale_factor
		if _current_arc_resolution == null:
			_current_arc_resolution = _calculate_arc_resolution(scale_factor)
		
		if _rerender_prop_cache.has("processed_polygon"):
			processed_polygon = _rerender_prop_cache["processed_polygon"]
			var new_arc_resolution = _calculate_arc_resolution(scale_factor)
			if new_arc_resolution.x != _current_arc_resolution.x or new_arc_resolution.y != _current_arc_resolution.y:
				_current_arc_resolution = new_arc_resolution
				svg_node._queue_process_polygon({
					"renderer": self,
				})
		else:
			if _is_editor_hint:
				svg_node._queue_process_polygon({
					"renderer": self,
				})
				return
			else:
				processed_polygon = _process_simplified_polygon()
				_rerender_prop_cache["processed_polygon"] = processed_polygon
		
		if processed_polygon == null:
			print_debug('[godot-svg] A processed polygon was not created.')
			return
		
		if processed_polygon.has("needs_refill"):
			processed_polygon.erase("needs_refill")
			var fill_paint = resolve_fill_paint()
			updates.fill_color = fill_paint.color
			updates.fill_texture = fill_paint.texture
			updates.fill_texture_units = fill_paint.texture_units
			updates.fill_texture_uv_transform = fill_paint.texture_uv_transform
		
		if processed_polygon.has("needs_restroke"):
			processed_polygon.erase("needs_restroke")
			var stroke_paint = resolve_stroke_paint()
			updates.stroke_color = stroke_paint.color
			updates.stroke_texture = stroke_paint.texture
			updates.stroke_texture_units = stroke_paint.texture_units
			updates.stroke_texture_uv_transform = stroke_paint.texture_uv_transform
	
	if will_fill:
		var bounding_box = get_bounding_box()
		var polygon_lists = processed_polygon.fill
		
		# Remove unused
		for shape_fill_index in range(polygon_lists.size(), _shape_fills.size()):
			var shape = _shape_fills[shape_fill_index]
			shape.get_parent().remove_child(shape)
			shape.queue_free()
		_shape_fills = SVGHelper.array_slice(_shape_fills, 0, polygon_lists.size())
		# Create new
		for point_list_index in range(_shape_fills.size(), polygon_lists.size()):
			var shape = MeshInstance2D.new()
			add_child(shape)
			_shape_fills.push_back(shape)
		
		var fill_index = 0
		for _shape_fill in _shape_fills:
			if fill_index < polygon_lists.size():
				_shape_fill.mesh = _create_mesh_from_triangulation(polygon_lists[fill_index])
				_shape_fill.material = ShaderMaterial.new()
				_shape_fill.material.shader = SVGRenderFillShader if svg_node.antialiased else SVGRenderFillShaderGles2
			_shape_fill.material.set_shader_param("fill_color", updates.fill_color)
			_shape_fill.self_modulate = Color(1, 1, 1, max(0, min(1, attr_fill_opacity.get_length(1))))
			if (
				updates.has("fill_texture") and updates.fill_texture != null and
				updates.has("fill_texture_units") and updates.fill_texture_units != null
			):
				_shape_fill.material.set_shader_param("fill_texture", updates.fill_texture)
				_update_shape_material_uv_params(_shape_fill, updates.fill_texture_units, updates.fill_texture_uv_transform, polygon_lists[fill_index])
			SVGPaintServer.apply_shader_params(self, "fill", _shape_fill)
			
			_shape_fill.show()
			fill_index += 1
	else:
		for shape in _shape_fills:
			shape.hide()
	
	if will_stroke:
		var polygon_lists = processed_polygon.stroke
		
		# Remove unused
		for shape_stroke_index in range(polygon_lists.size(), _shape_strokes.size()):
			var shape = _shape_strokes[shape_stroke_index]
			shape.get_parent().remove_child(shape)
			shape.queue_free()
		_shape_strokes = SVGHelper.array_slice(_shape_strokes, 0, polygon_lists.size())
		# Create new
		for stroke_list_index in range(_shape_strokes.size(), polygon_lists.size()):
			var shape = MeshInstance2D.new()
			add_child(shape)
			_shape_strokes.push_back(shape)
		
		var stroke_index = 0
		for _shape_stroke in _shape_strokes:
			if stroke_index < polygon_lists.size():
				_shape_stroke.mesh = _create_mesh_from_triangulation(polygon_lists[stroke_index])
				_shape_stroke.material = ShaderMaterial.new()
				_shape_stroke.material.shader = SVGRenderFillShader if svg_node.antialiased else SVGRenderFillShaderGles2
			else:
				_shape_stroke.mesh = null
			_shape_stroke.material.set_shader_param("fill_color", updates.stroke_color)
			_shape_stroke.self_modulate = Color(1, 1, 1, max(0, min(1, attr_stroke_opacity.get_length(1))))
			
			if (
				updates.has("stroke_texture") and updates.stroke_texture != null and
				updates.has("stroke_texture_units") and updates.stroke_texture_units != null
			):
				_shape_stroke.material.set_shader_param("fill_texture", updates.stroke_texture)
				_update_shape_material_uv_params(_shape_stroke, updates.stroke_texture_units, updates.stroke_texture_uv_transform, polygon_lists[stroke_index])
			SVGPaintServer.apply_shader_params(self, "stroke", _shape_stroke)
			
			if updates.has("stroke_width"):
				var applied_stroke_width = updates.stroke_width * scale_factor.x
				if applied_stroke_width < 1:
					_shape_stroke.modulate = Color(1, 1, 1, applied_stroke_width)
				else:
					_shape_stroke.modulate = Color(1, 1, 1, 1)
			
			_shape_stroke.show()
			stroke_index += 1
	else:
		for stroke in _shape_strokes:
			stroke.hide()

func resolve_fill_paint():
	if _rerender_prop_cache.has("fill"):
		return _rerender_prop_cache.fill
	else:
		_rerender_prop_cache.fill = SVGPaintServer.resolve_paint(self, attr_fill, "fill")
		return _rerender_prop_cache.fill

func resolve_stroke_paint():
	if _rerender_prop_cache.has("stroke"):
		return _rerender_prop_cache.stroke
	else:
		_rerender_prop_cache.stroke = SVGPaintServer.resolve_paint(self, attr_stroke, "stroke")
		return _rerender_prop_cache.stroke

func resolve_href():
	return null # override

# Internal Methods

func _create_mesh_from_triangulation(fill_definition):
	var mesh = ArrayMesh.new()
	var surface = []
	surface.resize(ArrayMesh.ARRAY_MAX)
	var vertices = PoolVector2Array()
	var colors = PoolColorArray()
	var uv = PoolVector2Array()
	var coordinate_index = 0
	# Interior faces
	vertices.append_array(fill_definition.interior_vertices)
	for implicit_coordinate in fill_definition.interior_implicit_coordinates:
		colors.push_back(Color(implicit_coordinate.x, implicit_coordinate.y, implicit_coordinate.z, 0.7))
	uv.append_array(fill_definition.interior_uv)
	# Quadratic edges
	vertices.append_array(fill_definition.quadratic_vertices)
	coordinate_index = 0
	for implicit_coordinate in fill_definition.quadratic_implicit_coordinates:
		colors.push_back(Color(
			implicit_coordinate.x, implicit_coordinate.y, 1.0,
			0.1 + 0.15 * float(fill_definition.quadratic_signs[coordinate_index])
		))
		coordinate_index += 1
	uv.append_array(fill_definition.quadratic_uv)
	# Cubic edges
	vertices.append_array(fill_definition.cubic_vertices)
	coordinate_index = 0
	for implicit_coordinate in fill_definition.cubic_implicit_coordinates:
		colors.push_back(Color(
			implicit_coordinate.x, implicit_coordinate.y, implicit_coordinate.z,
			0.31 + 0.15 * float(fill_definition.cubic_signs[coordinate_index])
		))
		coordinate_index += 1
	uv.append_array(fill_definition.cubic_uv)
	# Antialiased line edges
	vertices.append_array(fill_definition.antialias_edge_vertices)
	for implicit_coordinate in fill_definition.antialias_edge_implicit_coordinates:
		colors.push_back(Color(
			implicit_coordinate.x, implicit_coordinate.y, 0.0, 0.9
		))
	uv.append_array(fill_definition.antialias_edge_uv)
	# Create the mesh
	surface[ArrayMesh.ARRAY_VERTEX] = vertices
	surface[ArrayMesh.ARRAY_COLOR] = colors
	surface[ArrayMesh.ARRAY_TEX_UV] = uv
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface, [], 0)
	return mesh

func _update_shape_material_uv_params(shape_node, texture_units, texture_uv_transform, processed_polygon):
	var uv_transform_scale = Vector2(1.0, 1.0)
	var uv_transform_origin = Vector2(0.0, 0.0)
	var transform = Transform2D()
	if texture_units is Rect2:
		transform.origin = texture_units.position * (Vector2(1.0, 1.0) / processed_polygon.bounding_box.size) * uv_transform_scale
		transform = transform.scaled(processed_polygon.bounding_box.size / texture_units.size)
		texture_uv_transform.origin *= (Vector2(1.0, 1.0) / processed_polygon.bounding_box.size) * uv_transform_scale
	elif texture_units == SVGValueConstant.USER_SPACE_ON_USE:
		transform.origin = (processed_polygon.bounding_box.position - inherited_view_box.position) / inherited_view_box.size
		transform = transform.scaled(processed_polygon.bounding_box.size / inherited_view_box.size)
	transform *= texture_uv_transform
	shape_node.material.set_shader_param("uv_transform_column_1", Vector3(transform.x.x, transform.y.x, transform.origin.x))
	shape_node.material.set_shader_param("uv_transform_column_2", Vector3(transform.x.y, transform.y.y, transform.origin.y))

# Getters / Setters

func _set_element_resource(new_element_resource):
	element_resource = new_element_resource
	if element_resource != null:
		set_name(element_resource.node_name)
	apply_props()

func _set_attr_clip_path(clip_path):
	clip_path = get_style("clip_path", clip_path)
	if clip_path.begins_with("url(") or clip_path == SVGValueConstant.NONE:
		attr_clip_path = clip_path.replace("url(", "").rstrip(")").strip_edges()
	else:
		pass # TODO - basic-shape || geometry-box
	apply_props()

func _set_attr_clip_rule(clip_rule):
	attr_clip_rule = clip_rule
	apply_props()

func _set_attr_color(color):
	if typeof(color) != TYPE_STRING:
		attr_color = color
	else:
		if color == SVGValueConstant.INHERIT:
			attr_color = null
		else:
			attr_color = SVGPaint.new(color)
	_rerender_prop_cache.erase("stroke")
	_rerender_prop_cache.erase("fill")
	_rerender_prop_cache.erase("stop_color")
	_rerender_prop_cache.erase("flood_color")
	_rerender_prop_cache.erase("lighting_color")
	apply_props()

func _set_attr_display(display):
	display = get_style("display", display)
	attr_display = display
	apply_props()

func _set_attr_fill(fill):
	fill = get_style("fill", fill)
	if typeof(fill) != TYPE_STRING:
		attr_fill = fill
	else:
		if fill == SVGValueConstant.CURRENT_COLOR:
			attr_fill = fill
		elif [SVGValueConstant.NONE, SVGValueConstant.CONTEXT_FILL, SVGValueConstant.CONTEXT_STROKE].has(fill):
			attr_fill = SVGPaint.new("#00000000")
		else:
			attr_fill = SVGPaint.new(fill)
	_rerender_prop_cache.erase("fill")
	apply_props()

func _set_attr_fill_opacity(fill_opacity):
	fill_opacity = get_style("fill_opacity", fill_opacity)
	if typeof(fill_opacity) != TYPE_STRING:
		attr_fill_opacity = fill_opacity
	else:
		attr_fill_opacity = SVGLengthPercentage.new(fill_opacity)
	apply_props()

func _set_attr_fill_rule(fill_rule):
	attr_fill_rule = fill_rule
	apply_props()

func _set_attr_id(id):
	if typeof(id) == TYPE_STRING:
		if svg_node != null and svg_node._resource_locator_cache.has("#" + id):
			svg_node._resource_locator_cache.erase("#" + id)
	attr_id = id
	apply_props()

func _set_attr_mask(mask):
	if typeof(mask) != TYPE_STRING:
		attr_mask = mask
	else:
		if mask.begins_with("url(") and mask.ends_with(")"):
			attr_mask = mask.replace("url(", "").rstrip(")").strip_edges()
		else:
			attr_mask = SVGValueConstant.NONE

func _set_attr_opacity(opacity):
	opacity = get_style("opacity", opacity)
	if typeof(opacity) != TYPE_STRING:
		attr_opacity = opacity
	else:
		attr_opacity = SVGLengthPercentage.new(opacity)
	apply_props()

func _set_attr_stroke(stroke):
	stroke = get_style("stroke", stroke)
	if typeof(stroke) != TYPE_STRING:
		attr_stroke = stroke
	else:
		if stroke == SVGValueConstant.CURRENT_COLOR:
			attr_stroke = stroke
		elif [SVGValueConstant.NONE, SVGValueConstant.CONTEXT_FILL, SVGValueConstant.CONTEXT_STROKE].has(stroke):
			attr_stroke = SVGPaint.new("#00000000")
		else:
			attr_stroke = SVGPaint.new(stroke)
	_rerender_prop_cache.erase("stroke")
	apply_props()

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
	apply_props()

func _set_attr_stroke_dashoffset(stroke_dashoffset):
	stroke_dashoffset = get_style("stroke_dashoffset", stroke_dashoffset)
	if typeof(stroke_dashoffset) != TYPE_STRING:
		attr_stroke_dashoffset = stroke_dashoffset
	else:
		attr_stroke_dashoffset = SVGLengthPercentage.new(stroke_dashoffset)
	apply_props()

func _set_attr_stroke_linejoin(stroke_linejoin):
	stroke_linejoin = get_style("stroke_linejoin", stroke_linejoin)
	attr_stroke_linejoin = stroke_linejoin
	apply_props()

func _set_attr_stroke_miterlimit(stroke_miterlimit):
	stroke_miterlimit = get_style("stroke_miterlimit", stroke_miterlimit)
	if typeof(stroke_miterlimit) != TYPE_STRING:
		attr_stroke_miterlimit = stroke_miterlimit
	else:
		attr_stroke_miterlimit = stroke_miterlimit.to_float()
	apply_props()

func _set_attr_stroke_opacity(stroke_opacity):
	stroke_opacity = get_style("stroke_opacity", stroke_opacity)
	if typeof(stroke_opacity) != TYPE_STRING:
		attr_stroke_opacity = stroke_opacity
	else:
		attr_stroke_opacity = SVGLengthPercentage.new(stroke_opacity)
	apply_props()

func _set_attr_stroke_width(stroke_width):
	stroke_width = get_style("stroke_width", stroke_width)
	if typeof(stroke_width) != TYPE_STRING:
		attr_stroke_width = stroke_width
	else:
		attr_stroke_width = SVGLengthPercentage.new(stroke_width)
	apply_props()

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
	apply_props()

func _set_applied_stylesheet_style(style):
	if typeof(style) == TYPE_DICTIONARY:
		applied_stylesheet_style = style
		for attr_name in applied_stylesheet_style:
			if "attr_" + attr_name in self:
				self["attr_" + attr_name] = self["attr_" + attr_name]
	apply_props()

func _set_attr_transform(new_transform):
	new_transform = get_style("transform", new_transform)
	attr_transform = SVGAttributeParser.parse_transform_list(new_transform)
	self.transform = attr_transform
	apply_props()

# Signal Callbacks

func _on_visibility_changed():
	if visible:
		update()

func _on_viewport_scale_changed(new_viewport_scale):
	_last_known_viewport_scale = new_viewport_scale
	update()
