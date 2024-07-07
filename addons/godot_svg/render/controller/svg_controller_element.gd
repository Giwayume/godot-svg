
#---------#
# Signals #
#---------#

signal bounding_box_calculated(new_bounding_box)
signal distribute_inherited_properties(inherited_props)

#-----------#
# Constants #
#-----------#

const PathCommand = SVGValueConstant.PathCommand
const SVGRenderBakedShader2D = preload("../shader/svg_render_baked_shader_2d.tres")
const SVGRenderBakedShader3D = preload("../shader/svg_render_baked_shader_3d.tres")
const SVGRenderFillShader2D = preload("../shader/svg_render_fill_shader_2d.tres")
const SVGRenderFillShader3D = preload("../shader/svg_render_fill_shader_3d.tres")
const SORTING_GAP_3D = 0.001
const RENDER_GAP_3D = -0.01

#-------------------#
# Public properties #
#-------------------#

var controlled_node: Node: set = _set_controlled_node
var element_resource = null: set = _set_element_resource
var inherited_view_box: Rect2 = Rect2(0, 0, 0, 0)
var is_cacheable: bool = true
var is_canvas_group: bool = false # Used for svg <g> tags, where opacity impacts entire group together
var is_clip_children_to_view_box: bool # Uses control's rect_clip to limit visibility outside view box
var is_in_root_viewport: bool = false
var is_in_clip_path: bool = false
var is_renderable: bool = true # Disable for elements that shouldn't attempt to display anything
var is_root_element: bool = false # <svg> tag; SVGControllerViewport
var node_name: String = ""
var node_text: String = ""
var render_cache_id: String = ""
var render_order = 0.0
var root_controller = null # SVGControllerRoot instance
var parent_controller = null: set = _set_parent_controller
var parent_viewport_controller = null: set = _set_parent_viewport_controller

var global_default_property_values = {
	"id": null,
	"lang": null,
	"tabindex": 0,
	"class": "",
	"style": {},
	"required_extensions": null,
	"required_features": null,
	"system_language": null,
	"clip_path": SVGValueConstant.NONE,
	"clip_rule": SVGValueConstant.NON_ZERO,
	"color": null,
	"color_interpolation": SVGValueConstant.AUTO,
	"color_rendering": null,
	"cursor": null,
	"display": "inline",
	"fill": SVGPaint.new("#000000"),
	"fill_opacity": SVGLengthPercentage.new("100%"),
	"fill_rule": SVGValueConstant.NON_ZERO,
	"filter": null,
	"mask": SVGValueConstant.NONE,
	"opacity": SVGLengthPercentage.new("100%"),
	"pointer_events": null,
	"shape_rendering": null,
	"stroke": SVGPaint.new("#00000000"),
	"stroke_dasharray": [],
	"stroke_dashoffset": SVGLengthPercentage.new("0"),
	"stroke_linecap": null,
	"stroke_linejoin": SVGValueConstant.MITER,
	"stroke_miterlimit": 4.0,
	"stroke_opacity": SVGLengthPercentage.new("100%"),
	"stroke_width": SVGLengthPercentage.new("1px"),
	"transform": Transform2D(),
	"vector_effect": SVGValueConstant.NONE,
	"visibility": SVGValueConstant.VISIBLE,
}

# Core Attributes
var attr_id = global_default_property_values["id"]: set = _set_attr_id
var attr_lang = global_default_property_values["lang"]: set = _set_attr_lang
var attr_tabindex = global_default_property_values["tabindex"]: set = _set_attr_tabindex

# Styling Attributes
var attr_class = global_default_property_values["class"]
var attr_style = global_default_property_values["style"]: set = _set_attr_style

# Conditional Processing Attributes
var attr_required_extensions = global_default_property_values["required_extensions"]: set = _set_attr_required_extensions
var attr_required_features = global_default_property_values["required_features"]: set = _set_attr_required_features
var attr_system_language = global_default_property_values["system_language"]: set = _set_attr_system_language

# Presentation Attributes
var attr_clip_path = global_default_property_values["clip_path"]: set = _set_attr_clip_path
var attr_clip_rule = global_default_property_values["clip_rule"]: set = _set_attr_clip_rule
var attr_color = global_default_property_values["color"]: set = _set_attr_color
var attr_color_interpolation = global_default_property_values["color_interpolation"]: set = _set_attr_color_interpolation
var attr_color_rendering = global_default_property_values["color_rendering"]: set = _set_attr_color_rendering
var attr_cursor = global_default_property_values["cursor"]: set = _set_attr_cursor
var attr_display = global_default_property_values["display"]: set = _set_attr_display
var attr_fill = global_default_property_values["fill"]: set = _set_attr_fill
var attr_fill_opacity = global_default_property_values["fill_opacity"]: set = _set_attr_fill_opacity
var attr_fill_rule = global_default_property_values["fill_rule"]: set = _set_attr_fill_rule
var attr_filter = global_default_property_values["filter"]: set = _set_attr_filter
var attr_mask = global_default_property_values["mask"]: set = _set_attr_mask
var attr_opacity = global_default_property_values["opacity"]: set = _set_attr_opacity
var attr_pointer_events = global_default_property_values["pointer_events"]: set = _set_attr_pointer_events
var attr_shape_rendering = global_default_property_values["shape_rendering"]: set = _set_attr_shape_rendering
var attr_stroke = global_default_property_values["stroke"]: set = _set_attr_stroke
var attr_stroke_dasharray = global_default_property_values["stroke_dasharray"]: set = _set_attr_stroke_dasharray
var attr_stroke_dashoffset = global_default_property_values["stroke_dashoffset"]: set = _set_attr_stroke_dashoffset
var attr_stroke_linecap = global_default_property_values["stroke_linecap"]: set = _set_attr_stroke_linecap
var attr_stroke_linejoin = global_default_property_values["stroke_linejoin"]: set = _set_attr_stroke_linejoin
var attr_stroke_miterlimit = global_default_property_values["stroke_miterlimit"]: set = _set_attr_stroke_miterlimit
var attr_stroke_opacity = global_default_property_values["stroke_opacity"]: set = _set_attr_stroke_opacity
var attr_stroke_width = global_default_property_values["stroke_width"]: set = _set_attr_stroke_width
var attr_transform = global_default_property_values["transform"]: set = _set_attr_transform
var attr_vector_effect = global_default_property_values["vector_effect"]: set = _set_attr_vector_effect
var attr_visibility = global_default_property_values["visibility"]: set = _set_attr_visibility

#-------------------#
# Getters / Setters #
#-------------------#

func _set_attr_clip_path(clip_path):
	clip_path = get_style("clip_path", clip_path)
	if clip_path.begins_with("url(") or clip_path == SVGValueConstant.NONE:
		attr_clip_path = clip_path.replace("url(", "").rstrip(")").strip_edges()
	else:
		pass # TODO - basic-shape || geometry-box
	apply_props("clip_path")

func _set_attr_clip_rule(clip_rule):
	clip_rule = _get_global_inherited_prop_value("clip_rule", clip_rule)
	attr_clip_rule = clip_rule
	apply_props("clip_rule")

func _set_attr_color(color):
	color = _get_global_inherited_prop_value("color", color)
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
	apply_props("color")

func _set_attr_color_interpolation(color_interpolation):
	color_interpolation = _get_global_inherited_prop_value("color_interpolation", color_interpolation)
	attr_color_interpolation = color_interpolation
	apply_props("color_interpolation")

func _set_attr_color_rendering(color_rendering):
	color_rendering = _get_global_inherited_prop_value("color_rendering", color_rendering)
	attr_color_rendering = color_rendering
	apply_props("color_rendering")

func _set_attr_cursor(cursor):
	cursor = _get_global_inherited_prop_value("cursor", cursor)
	attr_cursor = cursor
	apply_props("cursor")

func _set_attr_display(display):
	display = _get_global_inherited_prop_value("display", display)
	display = get_style("display", display)
	attr_display = display
	apply_props("display")

func _set_attr_fill(fill):
	fill = _get_global_inherited_prop_value("fill", fill)
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
	apply_props("fill")

func _set_attr_fill_opacity(fill_opacity):
	fill_opacity = _get_global_inherited_prop_value("fill_opacity", fill_opacity)
	fill_opacity = get_style("fill_opacity", fill_opacity)
	if typeof(fill_opacity) != TYPE_STRING:
		attr_fill_opacity = fill_opacity
	else:
		attr_fill_opacity = SVGLengthPercentage.new(fill_opacity)
	apply_props("fill_opacity")

func _set_attr_fill_rule(fill_rule):
	fill_rule = _get_global_inherited_prop_value("fill_rule", fill_rule)
	attr_fill_rule = fill_rule
	apply_props("fill_rule")

func _set_attr_filter(filter):
	filter = _get_global_inherited_prop_value("filter", filter)
	attr_filter = filter
	apply_props("filter")

func _set_attr_lang(lang):
	lang = _get_global_inherited_prop_value("lang", lang)
	attr_lang = lang
	apply_props("lang")

func _set_attr_id(id):
	if typeof(id) == TYPE_STRING:
		if root_controller != null and root_controller._url_cache.has("#" + id):
			root_controller._url_cache.erase("#" + id)
	attr_id = id
	apply_props("id")

func _set_attr_mask(mask):
	if typeof(mask) != TYPE_STRING:
		attr_mask = mask
	else:
		if mask.begins_with("url(") and mask.ends_with(")"):
			attr_mask = mask.replace("url(", "").rstrip(")").strip_edges()
		else:
			attr_mask = SVGValueConstant.NONE
	apply_props("mask")

func _set_attr_opacity(opacity):
	opacity = get_style("opacity", opacity)
	if typeof(opacity) != TYPE_STRING:
		attr_opacity = opacity
	else:
		attr_opacity = SVGLengthPercentage.new(opacity)
	apply_props("opacity")

func _set_attr_pointer_events(pointer_events):
	pointer_events = _get_global_inherited_prop_value("pointer_events", pointer_events)
	attr_pointer_events = pointer_events
	apply_props("pointer_events")

func _set_attr_required_extensions(required_extensions):
	required_extensions = _get_global_inherited_prop_value("required_extensions", required_extensions)
	attr_required_extensions = required_extensions
	apply_props("required_extensions")

func _set_attr_required_features(required_features):
	required_features = _get_global_inherited_prop_value("required_features", required_features)
	attr_required_features = required_features
	apply_props("required_features")

func _set_attr_shape_rendering(shape_rendering):
	shape_rendering = _get_global_inherited_prop_value("shape_rendering", shape_rendering)
	attr_shape_rendering = shape_rendering
	apply_props("shape_rendering")

func _set_attr_stroke(stroke):
	stroke = _get_global_inherited_prop_value("stroke", stroke)
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
	apply_props("stroke")

func _set_attr_stroke_dasharray(stroke_dasharray):
	stroke_dasharray = _get_global_inherited_prop_value("stroke_dasharray", stroke_dasharray)
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
	apply_props("stroke_dasharray")

func _set_attr_stroke_dashoffset(stroke_dashoffset):
	stroke_dashoffset = _get_global_inherited_prop_value("stroke_dashoffset", stroke_dashoffset)
	stroke_dashoffset = get_style("stroke_dashoffset", stroke_dashoffset)
	if typeof(stroke_dashoffset) != TYPE_STRING:
		attr_stroke_dashoffset = stroke_dashoffset
	else:
		attr_stroke_dashoffset = SVGLengthPercentage.new(stroke_dashoffset)
	apply_props("stroke_dashoffset")

func _set_attr_stroke_linecap(stroke_linecap):
	stroke_linecap = _get_global_inherited_prop_value("stroke_linecap", stroke_linecap)
	attr_stroke_linecap = stroke_linecap
	apply_props("stroke_linecap")

func _set_attr_stroke_linejoin(stroke_linejoin):
	stroke_linejoin = _get_global_inherited_prop_value("stroke_linejoin", stroke_linejoin)
	stroke_linejoin = get_style("stroke_linejoin", stroke_linejoin)
	attr_stroke_linejoin = stroke_linejoin
	apply_props("stroke_linejoin")

func _set_attr_stroke_miterlimit(stroke_miterlimit):
	stroke_miterlimit = _get_global_inherited_prop_value("stroke_miterlimit", stroke_miterlimit)
	stroke_miterlimit = get_style("stroke_miterlimit", stroke_miterlimit)
	if typeof(stroke_miterlimit) != TYPE_STRING:
		attr_stroke_miterlimit = stroke_miterlimit
	else:
		attr_stroke_miterlimit = stroke_miterlimit.to_float()
	apply_props("stroke_miterlimit")

func _set_attr_stroke_opacity(stroke_opacity):
	stroke_opacity = _get_global_inherited_prop_value("stroke_opacity", stroke_opacity)
	stroke_opacity = get_style("stroke_opacity", stroke_opacity)
	if typeof(stroke_opacity) != TYPE_STRING:
		attr_stroke_opacity = stroke_opacity
	else:
		attr_stroke_opacity = SVGLengthPercentage.new(stroke_opacity)
	apply_props("stroke_opacity")

func _set_attr_stroke_width(stroke_width):
	stroke_width = _get_global_inherited_prop_value("stroke_width", stroke_width)
	stroke_width = get_style("stroke_width", stroke_width)
	if typeof(stroke_width) != TYPE_STRING:
		attr_stroke_width = stroke_width
	else:
		attr_stroke_width = SVGLengthPercentage.new(stroke_width)
	apply_props("stroke_width")

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
	apply_props("style")

func _set_attr_system_language(system_language):
	system_language = _get_global_inherited_prop_value("system_language", system_language)
	attr_system_language = system_language
	apply_props("system_language")

func _set_attr_tabindex(tabindex):
	tabindex = _get_global_inherited_prop_value("tabindex", tabindex)
	attr_tabindex = tabindex
	apply_props("tabindex")

func _set_attr_transform(new_transform):
	new_transform = get_style("transform", new_transform)
	attr_transform = SVGAttributeParser.parse_transform_list(new_transform, root_controller.is_2d)
	controlled_node.transform = attr_transform
	apply_props("transform")

func _set_attr_vector_effect(vector_effect):
	vector_effect = _get_global_inherited_prop_value("vector_effect", vector_effect)
	attr_vector_effect = vector_effect
	apply_props("vector_effect")

func _set_attr_visibility(visibility):
	visibility = _get_global_inherited_prop_value("visibility", visibility)
	attr_visibility = visibility
	apply_props("visibility")

func _set_controlled_node(new_controlled_node):
	controlled_node = new_controlled_node
	if _child_container == null:
		_child_container = controlled_node

func _set_element_resource(new_element_resource):
	element_resource = new_element_resource
	if controlled_node != null and element_resource != null:
		controlled_node.set_name(element_resource.node_name)

func _set_parent_controller(new_parent_controller):
	var old_parent_controller = parent_controller
	parent_controller = new_parent_controller
	if old_parent_controller != null and old_parent_controller.is_connected("distribute_inherited_properties", Callable(self, "_on_inherited_properties_updated")):
		old_parent_controller.disconnect("distribute_inherited_properties", Callable(self, "_on_inherited_properties_updated"))
	if parent_controller != null:
		parent_controller.connect("distribute_inherited_properties", Callable(self, "_on_inherited_properties_updated"))

func _set_parent_viewport_controller(new_parent_viewport_controller):
	parent_viewport_controller = new_parent_viewport_controller

#---------------------#
# Internal properties #
#---------------------#

var _applied_stylesheet_style: Dictionary = {}
var _apply_props_notify_list: Array = []
var _assigned_global_property_names = [] # List of properties that were explicity assigned (not inherited)
var _baked_sprite = null # Sprite2D that displays the _baking_viewport image
var _baking_viewport = null # SubViewport used for rendering raster effects, like mask
var _baking_canvas_group = null # Canvas group used for group opacity and other effects that a separate viewport was previously used for
var _bounding_box = Rect2(0, 0, 0, 0) # Bounding box for the current shape (not including stroke)
var _child_container = null # Node where controlled_node should place its children via add_child()
var _child_list = [] # List of children that should be inside of _child_container
var _inherited_property_values = {} # Values of properties inherited from all of the parent nodes
var _is_href_duplicate = false # Used while resolving href (gradients, etc) to mark that this is a duplicate controller of existing one.
var _paint_server_container_node = null # Node that contains paint server assets, like viewports
var _paint_server_textures = {} # Cache for paint server responses, key is store_name
var _path_solver_debug = [] # Output of debug commands from path solver
var _rerender_prop_cache = {} # Cache for certain computed values, such as fill and stroke
var _shape_fills = [] # List of MeshInstance2D nodes representing the fill of the path
var _shape_strokes = [] # List of MeshInstance2D nodes representing the stroke of the path
var _view_box_clip_container = null # Control node used to visibly clip children to view box rectangle for <svg> node.
var _view_box_transform_container = null # Control node used to translate the x/y position of children nodes inside a view box.

#-----------#
# Lifecycle #
#-----------#

func _init():
	pass

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if _paint_server_container_node != null:
			if is_instance_valid(_paint_server_container_node):
				_paint_server_container_node.queue_free()
			if is_instance_valid(_baking_canvas_group):
				_baking_canvas_group.queue_free()
			if is_instance_valid(_baking_viewport):
				_baking_viewport.queue_free()
			if is_instance_valid(_baked_sprite):
				_baked_sprite.queue_free()

func _ready():
	# Handle my node visiblity changed.
	controlled_node.connect("visibility_changed", Callable(self, "_on_visibility_changed"))
	
	connect("bounding_box_calculated", Callable(self, "_on_bounding_box_calculated"))
	
	if not is_renderable:
		controlled_node.hide()
		if root_controller.is_2d:
			controlled_node.modulate = Color(1, 1, 1, 0)
	
	if root_controller != null:
		# Pull processed polygon from render cache, if applicable
		if (
			not root_controller.disable_render_cache and
			is_cacheable and
			root_controller.svg != null and
			not root_controller.svg.render_cache.is_empty() and
			root_controller.svg.render_cache.has("process_polygon") and
			root_controller.svg.render_cache.process_polygon.has(render_cache_id)
		):
			var processed_polygon = root_controller.svg.render_cache.process_polygon[render_cache_id]
			if processed_polygon != null and processed_polygon.has("interior_vertices"):
				if root_controller.is_2d and not processed_polygon.interior_vertices is PackedVector2Array:
					processed_polygon.interior_vertices = _convert_render_cache_vertices_to_vector2(processed_polygon.interior_vertices)
					processed_polygon.quadratic_vertices = _convert_render_cache_vertices_to_vector2(processed_polygon.quadratic_vertices)
					processed_polygon.cubic_vertices = _convert_render_cache_vertices_to_vector2(processed_polygon.cubic_vertices)
					processed_polygon.antialias_edge_vertices = _convert_render_cache_vertices_to_vector2(processed_polygon.antialias_edge_vertices)
				elif not root_controller.is_2d and not processed_polygon.interior_vertices is PackedVector3Array:
					processed_polygon.interior_vertices = _convert_render_cache_vertices_to_vector3(processed_polygon.interior_vertices)
					processed_polygon.quadratic_vertices = _convert_render_cache_vertices_to_vector3(processed_polygon.quadratic_vertices)
					processed_polygon.cubic_vertices = _convert_render_cache_vertices_to_vector3(processed_polygon.cubic_vertices)
					processed_polygon.antialias_edge_vertices = _convert_render_cache_vertices_to_vector3(processed_polygon.antialias_edge_vertices)
			_rerender_prop_cache["processed_polygon"] = processed_polygon
		
		# Handle viewport scale change callbacks
		root_controller.connect("viewport_scale_changed", Callable(self, "_on_viewport_scale_changed"))
		call_deferred("_on_viewport_scale_changed", root_controller.last_known_viewport_scale)

func _props_applied(prop_list = []):
	_distribute_inherited_properties(prop_list)
	if is_renderable:
		_calculate_bounding_box()
		_reorganize_baking_containers()
		_generate_shape_nodes(prop_list)

func _draw():
	if attr_mask != SVGValueConstant.NONE and _baked_sprite != null:
		var locator_result = root_controller.resolve_url(attr_mask)
		var mask_controller = locator_result.controller
		if mask_controller != null and mask_controller.node_name == "mask":
			mask_controller.request_mask_update(self)
	if attr_clip_path != SVGValueConstant.NONE and _baked_sprite != null:
		var locator_result = root_controller.resolve_url(attr_clip_path)
		var clip_path_controller = locator_result.controller
		if clip_path_controller != null and clip_path_controller.node_name == "clipPath":
			clip_path_controller.request_clip_path_update(self)
	if is_canvas_group and attr_opacity.get_length(1) < 1 and _baked_sprite != null:
		call_deferred("_canvas_group_opacity_mask_updated")

#------------------#
# Internal methods #
#------------------#

func _add_baked_sprite_as_child():
	if _baked_sprite != null:
		controlled_node.add_child_to_root(_baked_sprite)

func _add_baking_viewport_as_child(bounding_box):
	if _baking_viewport != null:
		controlled_node.add_child_to_root(_baking_viewport)
		_baking_viewport.canvas_transform = controlled_node.global_transform.inverse()
		_baking_viewport.canvas_transform.origin += bounding_box.position

# apply_props() can be called multiple times per frame, visual updates happen on deferred frame 
func _apply_props_deferred():
	var apply_props_notify_list = _apply_props_notify_list
	_apply_props_notify_list = []
	_props_applied(apply_props_notify_list)
	if root_controller.is_2d and controlled_node != null:
		controlled_node.queue_redraw()

# The controller for specific shape should override this to provide an efficient implementation
func _calculate_bounding_box():
	pass # Override

# For <g> elements with opacity < 1, update the baked sprite for the viewport
func _canvas_group_opacity_mask_updated():
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
				_baking_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
				
				if root_controller.is_2d:
					_baked_sprite.position = bounding_box.position
				else:
					_baked_sprite.position = bounding_box.position
				if root_controller.is_2d:
					_baked_sprite.scale = Vector2(1.0, 1.0) / scale_factor
				else:
					_baked_sprite.scale = Vector3(1.0, 1.0, 1.0) / scale_factor
				_baked_sprite.texture = null # Force sprite to resize
				_baked_sprite.texture = _baking_viewport.get_texture()
		_baked_sprite.self_modulate = Color(1, 1, 1, attr_opacity.get_length(1))

func _convert_render_cache_vertices_to_vector3(array: PackedVector2Array) -> PackedVector3Array:
	var new_array = PackedVector3Array()
	var size = array.size()
	new_array.resize(size)
	var i = 0
	for vector in array:
		new_array[i] = SVGMath.to_3d_point(vector, false)
		i += 1
	return new_array

func _convert_render_cache_vertices_to_vector2(array: PackedVector3Array) -> PackedVector2Array:
	var new_array = PackedVector2Array()
	var size = array.size()
	new_array.resize(size)
	var i = 0
	for vector in array:
		new_array[i] = SVGMath.to_2d_point(vector)
		i += 1
	return new_array

# Accepts a triangulation result from SVGTriangulation.simplify_fill_path()
# and generates a MeshInstance2D from it.
func _create_mesh_from_triangulation(fill_definition):
	var mesh = ArrayMesh.new()
	var surface = []
	surface.resize(ArrayMesh.ARRAY_MAX)
	var vertices = PackedVector2Array() if root_controller.is_2d else PackedVector3Array()
	var implicit_coordinates = PackedFloat32Array()
	var uv = PackedVector2Array()
	var coordinate_index = 0
	# Interior faces
	vertices.append_array(fill_definition.interior_vertices)
	for implicit_coordinate in fill_definition.interior_implicit_coordinates:
		implicit_coordinates.append_array([implicit_coordinate.x, implicit_coordinate.y, implicit_coordinate.z, 0.7])
	uv.append_array(fill_definition.interior_uv)
	# Quadratic edges
	vertices.append_array(fill_definition.quadratic_vertices)
	coordinate_index = 0
	for implicit_coordinate in fill_definition.quadratic_implicit_coordinates:
		implicit_coordinates.append_array([
			implicit_coordinate.x, implicit_coordinate.y, 1.0,
			0.1 + 0.15 * float(fill_definition.quadratic_signs[coordinate_index])
		])
		coordinate_index += 1
	uv.append_array(fill_definition.quadratic_uv)
	# Cubic edges
	vertices.append_array(fill_definition.cubic_vertices)
	coordinate_index = 0
	for implicit_coordinate in fill_definition.cubic_implicit_coordinates:
		implicit_coordinates.append_array([
			implicit_coordinate.x, implicit_coordinate.y, implicit_coordinate.z,
			0.31 + 0.15 * float(fill_definition.cubic_signs[coordinate_index])
		])
		coordinate_index += 1
	uv.append_array(fill_definition.cubic_uv)
	# Antialiased line edges
	vertices.append_array(fill_definition.antialias_edge_vertices)
	for implicit_coordinate in fill_definition.antialias_edge_implicit_coordinates:
		implicit_coordinates.append_array([
			implicit_coordinate.x, implicit_coordinate.y, 0.0, 0.9
		])
	uv.append_array(fill_definition.antialias_edge_uv)
	# Create the mesh
	var max_vertex_length = floor(len(vertices) / 3) * 3
	if len(vertices) == max_vertex_length:
		surface[ArrayMesh.ARRAY_VERTEX] = vertices
		surface[ArrayMesh.ARRAY_CUSTOM0] = implicit_coordinates
		surface[ArrayMesh.ARRAY_TEX_UV] = uv
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface, [], {}, Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT)
	else:
		print("[godot-svg] Triangulation of a surface returned an unexpected amount of vertices ", len(vertices))
	return mesh

# Pass props down to child controllers
func _distribute_inherited_properties(prop_list):
	var inherited_props = {}
	for prop_name in prop_list:
		if (
			SVGValueConstant.GLOBAL_INHERITED_ATTRIBUTE_NAMES.has(prop_name) and
			"attr_" + prop_name in self
		):
			inherited_props[prop_name] = self["attr_" + prop_name]
	if inherited_props.size() > 0:
		emit_signal("distribute_inherited_properties", inherited_props)

# Creates/destroys MeshInstance2D nodes that represent the fill/stroke of the shape
func _generate_shape_nodes(changed_prop_list: Array = []):
	if not controlled_node.visible: # TODO - test hide, update, show
		return
	
	var scale_factor = get_scale_factor()
	
	var fill_paint = resolve_fill_paint()
	var fill_color = fill_paint.color
	var fill_texture = fill_paint.texture
	var fill_texture_units = fill_paint.texture_units
	var fill_texture_uv_transform = fill_paint.texture_uv_transform
	
	var stroke_paint = resolve_stroke_paint()
	var stroke_color = stroke_paint.color
	var stroke_texture = stroke_paint.texture
	var stroke_texture_units = stroke_paint.texture_units
	var stroke_texture_uv_transform = stroke_paint.texture_uv_transform
	
	var stroke_width = attr_stroke_width.get_length(inherited_view_box.size.x)
	
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
	
	if not is_canvas_group:
		if root_controller.is_2d:
			controlled_node.modulate = Color(1, 1, 1, attr_opacity.get_length(1))
		else:
			pass # TODO - can group opacity be implemented in 3D?
	
	var fill_rule = attr_fill_rule
	if is_in_clip_path:
		fill_color = Color(1, 1, 1, 1)
		stroke_color = Color(0, 0, 0, 0)
		fill_rule = attr_clip_rule
	
	var will_fill = fill_color.a > 0
	var will_stroke = stroke_color.a > 0
	
	var processed_polygon = null
	if will_fill or will_stroke:
		
		if is_cacheable and _rerender_prop_cache.has("processed_polygon"):
			processed_polygon = _rerender_prop_cache["processed_polygon"]
		else:
			if root_controller.is_editor_hint:
				root_controller._queue_process_polygon({
					"controller": self,
				})
				return
			else:
				processed_polygon = _process_simplified_polygon()
				_rerender_prop_cache["processed_polygon"] = processed_polygon
		
		if processed_polygon == null:
			print('[godot-svg] A processed polygon was not created.')
			return
		
		if processed_polygon.has("needs_refill"):
			processed_polygon.erase("needs_refill")
			fill_paint = resolve_fill_paint()
			fill_color = fill_paint.color
			fill_texture = fill_paint.texture
			fill_texture_units = fill_paint.texture_units
			fill_texture_uv_transform = fill_paint.texture_uv_transform
		
		if processed_polygon.has("needs_restroke"):
			processed_polygon.erase("needs_restroke")
			stroke_paint = resolve_stroke_paint()
			stroke_color = stroke_paint.color
			stroke_texture = stroke_paint.texture
			stroke_texture_units = stroke_paint.texture_units
			stroke_texture_uv_transform = stroke_paint.texture_uv_transform
	
	if will_fill:
		var polygon_lists = processed_polygon.fill
		
		# Remove unused
		for shape_fill_index in range(polygon_lists.size(), _shape_fills.size()):
			var shape = _shape_fills[shape_fill_index]
			shape.get_parent().remove_child(shape)
			shape.queue_free()
		_shape_fills = SVGHelper.array_slice(_shape_fills, 0, polygon_lists.size())
		# Create new
		for point_list_index in range(_shape_fills.size(), polygon_lists.size()):
			var shape = MeshInstance2D.new() if root_controller.is_2d else MeshInstance3D.new()
			add_child(shape)
			if not root_controller.is_2d:
				shape.sorting_use_aabb_center = true
				#shape.custom_aabb = AABB(_get_parent_viewport_sort_offset_position(), Vector3(0, 0, 0))
				shape.sorting_offset = render_order * SORTING_GAP_3D
				shape.position.z = render_order * RENDER_GAP_3D
			_shape_fills.push_back(shape)
		
		if _bounding_box.size == Vector2.ZERO && processed_polygon.bounding_box.size != Vector2.ZERO:
			_bounding_box = processed_polygon.bounding_box
			
			#print_debug(processed_polygon.bounding_box)
			#var bounding_boxes = []
			#for polygon_list in polygon_lists:
				#if (polygon_list.has("bounding_box")):
					##print_debug(polygon_list.bounding_box)
					#bounding_boxes.push_back(polygon_list.bounding_box)
			#if len(bounding_boxes) > 0:
				#_bounding_box = SVGHelper.merge_bounding_boxes(bounding_boxes)
		
		var fill_index = 0
		for _shape_fill in _shape_fills:
			var material = _shape_fill.material if root_controller.is_2d else _shape_fill.material_override
			if fill_index < polygon_lists.size():
				_shape_fill.mesh = _create_mesh_from_triangulation(polygon_lists[fill_index])
				material = ShaderMaterial.new()
				material.shader = SVGRenderFillShader2D if root_controller.is_2d else SVGRenderFillShader3D
				material.set_shader_parameter("antialiased", root_controller.antialiased)
				if root_controller.is_2d:
					_shape_fill.material = material
				else:
					_shape_fill.material_override = material
			material.set_shader_parameter("fill_color", fill_color)
			if root_controller.is_2d:
				_shape_fill.self_modulate = Color(1, 1, 1, max(0, min(1, attr_fill_opacity.get_length(1))))
			else:
				pass # TODO - equivalent for 3D?
			if fill_texture != null:
				material.set_shader_parameter("fill_texture", fill_texture)
			if fill_texture_units != null:
				_update_shape_material_uv_params(_shape_fill, fill_texture_units, fill_texture_uv_transform, polygon_lists[fill_index])
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
			var shape = MeshInstance2D.new() if root_controller.is_2d else MeshInstance3D.new()
			add_child(shape)
			if not root_controller.is_2d:
				shape.sorting_use_aabb_center = true
				#shape.custom_aabb = AABB(_get_parent_viewport_sort_offset_position(), Vector3(0, 0, 0))
				shape.sorting_offset = render_order * SORTING_GAP_3D
				shape.position.z = render_order * RENDER_GAP_3D
			_shape_strokes.push_back(shape)
		
		var stroke_index = 0
		for _shape_stroke in _shape_strokes:
			var material = _shape_stroke.material if root_controller.is_2d else _shape_stroke.material_override
			if stroke_index < polygon_lists.size():
				_shape_stroke.mesh = _create_mesh_from_triangulation(polygon_lists[stroke_index])
				material = ShaderMaterial.new()
				material.shader = SVGRenderFillShader2D if root_controller.is_2d else SVGRenderFillShader3D
				material.set_shader_parameter("antialiased", root_controller.antialiased)
				if root_controller.is_2d:
					_shape_stroke.material = material
				else:
					_shape_stroke.material_override = material
			else:
				_shape_stroke.mesh = null
			material.set_shader_parameter("fill_color", stroke_color)
			if root_controller.is_2d:
				_shape_stroke.self_modulate = Color(1, 1, 1, max(0, min(1, attr_stroke_opacity.get_length(1))))
			else:
				pass # TODO - equivalent for 3D?
			if stroke_texture != null:
				material.set_shader_parameter("fill_texture", stroke_texture)
			if stroke_texture_units != null:
				_update_shape_material_uv_params(_shape_stroke, stroke_texture_units, stroke_texture_uv_transform, polygon_lists[stroke_index])
			SVGPaintServer.apply_shader_params(self, "stroke", _shape_stroke)
			
			if root_controller.is_2d:
				var applied_stroke_width = stroke_width * scale_factor.x
				if applied_stroke_width < 1:
					_shape_stroke.modulate = Color(1, 1, 1, applied_stroke_width)
				else:
					_shape_stroke.modulate = Color(1, 1, 1, 1)
		
			_shape_stroke.show()
			stroke_index += 1
	else:
		for stroke in _shape_strokes:
			stroke.hide()

# Used in the setter function for global attributes to keep track of which were manually assigned
func _get_global_inherited_prop_value(prop_name: String, prop_value):
	if prop_value == null:
		_assigned_global_property_names.erase(prop_name)
		if _inherited_property_values.has(prop_name):
			prop_value = _inherited_property_values[prop_name]
		else:
			prop_value = global_default_property_values[prop_name]
	else:
		if not _assigned_global_property_names.has(prop_name):
			_assigned_global_property_names.push_back(prop_name)
	return prop_value

 # Individual shape controller overrides this to define the commands that draw the shape
func _process_polygon():
	return {
		"fill": [],
		"stroke": []
	}

# Takes the commands from _process_polygon():
# 1. Simplifies those paths by splitting self-intersecting paths into multiple paths
# 2. Triangulates each simplified path
# Returns the triangulation result. This function may be called in a thread
# in the editor because it can be extremely slow.
func _process_simplified_polygon():
	var polygons = _process_polygon()
	var simplified_fills = []
	var simplified_fill_clockwise_checks = []
	var simplified_holes = []
	var needs_refill = false
	var needs_restroke = false
	_path_solver_debug = []
	
	if polygons.has("fill"):
		if polygons.fill.size() > 0:
			if not polygons.fill[0] is PackedVector2Array and not polygons.fill[0] is Array:
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
				var simplify_result = SVGPathSolver.simplify(
					fill_path,
					{
						SVGValueConstant.EVEN_ODD: SVGPolygonSolver.FillRule.EVEN_ODD,
						SVGValueConstant.NON_ZERO: SVGPolygonSolver.FillRule.NON_ZERO,
					}[fill_rule],
					root_controller.assume_no_self_intersections,
					root_controller.assume_no_holes
				)
				_path_solver_debug.push_back({
					"paths": fill_path,
					"log": simplify_result.debug,
				})
				for path_simplification in simplify_result.instruction_groups:
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
				root_controller.triangulation_method,
				root_controller.is_2d
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
	var bounding_box = Rect2(bounds.left, bounds.top, bounds.right - bounds.left, bounds.bottom - bounds.top) if bounds.left != INF and bounds.right != INF else Rect2()
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
									current_stroke[current_stroke.size() -1].command == PathCommand.CLOSE_PATH,
									root_controller.is_2d
								)
							)
						else:
							triangulated_strokes.push_back(
								SVGTriangulation.triangulate_stroke_subpath(
									current_stroke, stroke_width, attr_stroke_linecap,
									attr_stroke_linejoin, attr_stroke_miterlimit,
									current_stroke[current_stroke.size() -1].command == PathCommand.CLOSE_PATH,
									root_controller.is_2d
								)
							)
					current_stroke = []
				current_stroke.push_back(instruction)
				stroke_instruction_index += 1
	return {
		"fill": triangulated_fills,
		"needs_refill": needs_refill,
		"stroke": triangulated_strokes,
		"needs_restroke": needs_restroke,
		"bounding_box": bounding_box
	}

# The root_controller will call this with the result from _process_simplified_polygon from a thread
func _process_simplified_polygon_complete(polygons):
	_rerender_prop_cache["processed_polygon"] = polygons
	_props_applied()

# Depending on if a mask, clip path, or translucent group is used,
# the child node structure needs to be changed arround to support each.
func _reorganize_baking_containers():
	if (
		attr_mask != SVGValueConstant.NONE or
		attr_clip_path != SVGValueConstant.NONE or
		(is_canvas_group and attr_opacity.get_length(1) < 1)
	):
		if _child_container != _baking_viewport:
			var bounding_box = get_stroked_bounding_box()
			if _baked_sprite == null:
				if root_controller.is_2d:
					_baked_sprite = Sprite2D.new()
					_baked_sprite.centered = false
					_baked_sprite.material = ShaderMaterial.new()
					_baked_sprite.material.shader = SVGRenderBakedShader2D
					_baked_sprite.position = bounding_box.position
				else:
					_baked_sprite = Sprite3D.new()
					_baked_sprite.centered = false
					_baked_sprite.material_override = ShaderMaterial.new()
					_baked_sprite.material_override.shader = SVGRenderBakedShader3D
					_baked_sprite.position = bounding_box.position
				call_deferred("_add_baked_sprite_as_child")
			if _baking_viewport == null:
				_baking_viewport = SubViewport.new()
#				_baking_viewport.usage = SubViewport.USAGE_2D_NO_SAMPLING if root_controller.is_2d else SubViewport.USAGE_3D_NO_EFFECTS
				_baking_viewport.transparent_bg = true
				_baking_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
				_baking_viewport.name = "baking_viewport"
#				_baking_viewport.size = bounding_box.size
				call_deferred("_add_baking_viewport_as_child", bounding_box)
			_swap_child_container(_baking_viewport)
	elif is_clip_children_to_view_box:
		if _child_container != _view_box_transform_container:
			var view_box = inherited_view_box
			if "attr_view_box" in self and self.attr_view_box is Rect2:
				view_box = self.attr_view_box
			if _baked_sprite != null:
				_baked_sprite.queue_free()
				_baked_sprite = null
			if _baking_viewport != null:
				_baking_viewport.queue_free()
				_baking_viewport = null
			if _view_box_clip_container == null:
				_view_box_clip_container = Control.new() if root_controller.is_2d else Node3D.new()
				if root_controller.is_2d:
					_view_box_clip_container.position = Vector2()
					_view_box_clip_container.size = view_box.size
					_view_box_clip_container.clip_contents = true
				else:
					pass # TODO - can we even clip in 3D?
				controlled_node.add_child_to_root(_view_box_clip_container)
				_view_box_clip_container.name = node_name + "_viewbox_clip"
			if _view_box_transform_container == null:
				_view_box_transform_container = Node2D.new() if root_controller.is_2d else Node3D.new()
				if root_controller.is_2d:
					_view_box_transform_container.position = -view_box.position
				else:
					_view_box_transform_container.scale = Vector3(0.001, 0.001, 0.011)
					_view_box_transform_container.rotation = Vector3(PI, 0.0, 0.0)
					_view_box_transform_container.position = Vector3(0.0, view_box.size.y * 0.001, 0.0)
					# TODO - which way are we orienting 3D nodes?
				_view_box_clip_container.add_child(_view_box_transform_container)
				_view_box_transform_container.name = node_name + "_viewbox_transform"	
			_swap_child_container(_view_box_transform_container)
	else:
		if _child_container != controlled_node:
			_swap_child_container(controlled_node)
			if _baked_sprite != null:
				_baked_sprite.queue_free()
				_baked_sprite = null
			if _baking_viewport != null:
				_baking_viewport.queue_free()
				_baking_viewport = null
			if _view_box_clip_container != null:
				_view_box_clip_container.queue_free()
				_view_box_clip_container = null
			if _view_box_transform_container != null:
				_view_box_transform_container.queue_free()
				_view_box_transform_container = null

# Used to switch between the node used to host a child nodes,
# Such as when enabling/disabling baked raster rendering to a viewport
func _swap_child_container(new_container):
	var swapped_child_list = []
	var child_list = _child_list.duplicate()
	for child in child_list:
		if is_instance_valid(child):
			var parent = child.get_parent()
			if parent == self:
				controlled_node.remove_child_from_root(child)
			elif parent != null:
				parent.remove_child(child)
			if new_container == self:
				controlled_node.add_child_to_root(child)
			else:
				new_container.add_child(child)
			swapped_child_list.push_back(child)
	_child_list = swapped_child_list
	_child_container = new_container

# Applies shader params to a MeshInstance2D for passing a UV coordinate transformation matrix
func _update_shape_material_uv_params(shape_node, texture_units, texture_uv_transform, processed_polygon):
	var uv_transform_scale = Vector2(1.0, 1.0)
	var uv_transform_origin = Vector2(0.0, 0.0)
	var transform = Transform2D()
	if texture_units == null:
		pass
	elif texture_units is Rect2:
		transform.origin = texture_units.position * (Vector2(1.0, 1.0) / processed_polygon.bounding_box.size) * uv_transform_scale
		transform = transform.scaled(processed_polygon.bounding_box.size / texture_units.size)
		texture_uv_transform.origin *= (Vector2(1.0, 1.0) / processed_polygon.bounding_box.size) * uv_transform_scale
		transform *= texture_uv_transform
	elif texture_units == SVGValueConstant.USER_SPACE_ON_USE:
		var ellipse_ratio = Vector2(1.0, 1.0)
		if processed_polygon.bounding_box.size.x > processed_polygon.bounding_box.size.y:
			ellipse_ratio = Vector2(1.0, processed_polygon.bounding_box.size.y / processed_polygon.bounding_box.size.x)
		else:
			ellipse_ratio = Vector2(processed_polygon.bounding_box.size.x / processed_polygon.bounding_box.size.y, 1.0)

		texture_uv_transform.origin *= ellipse_ratio / processed_polygon.bounding_box.size
		transform *= texture_uv_transform.affine_inverse() * texture_uv_transform * texture_uv_transform.affine_inverse()
	var material = shape_node.material if root_controller.is_2d else shape_node.material_override
	# material.set_shader_param("uv_transform_column_1", Vector3(transform.x.x, transform.y.x, transform.origin.x))
	# material.set_shader_param("uv_transform_column_2", Vector3(transform.x.y, transform.y.y, transform.origin.y))

func _get_parent_viewport_sort_offset_position():
	var check_controller = parent_controller
	var transform_list = [controlled_node.transform]
	while check_controller != null and check_controller.node_name != "viewport":
		if check_controller.controlled_node != null:
			transform_list.push_front(check_controller.controlled_node.transform)
		check_controller = check_controller.parent_controller
	var transform = Transform3D()
	for element_transform in transform_list:
		transform *= element_transform
	return Vector3.ZERO * transform

#------------------#
# Signal callbacks #
#------------------#

func _on_bounding_box_calculated(new_bounding_box):
	if controlled_node != null:
		controlled_node.emit_signal("bounding_box_calculated", new_bounding_box)

func _on_inherited_properties_updated(inherited_props: Dictionary):
	_inherited_property_values = inherited_props
	for prop_name in inherited_props:
		if not _assigned_global_property_names.has(prop_name):
			set("attr_" + prop_name, inherited_props[prop_name])
			_assigned_global_property_names.erase(prop_name)

func _on_visibility_changed():
	if controlled_node.visible:
		if root_controller.is_2d:
			controlled_node.queue_redraw()

func _on_viewport_scale_changed(new_viewport_scale):
	if root_controller.is_2d:
		controlled_node.queue_redraw()

#----------------#
# Public methods #
#----------------#

# Adds a child to the current child container
func add_child(new_child, legible_unique_name = true):
	if not _child_list.has(new_child):
		_child_list.push_back(new_child)
	if _child_container != null:
		if _child_container == controlled_node:
			_child_container.add_child_to_root(new_child, legible_unique_name)
		else:
			_child_container.add_child(new_child, legible_unique_name)
	else:
		controlled_node.add_child_to_root(new_child, legible_unique_name)

# Call after updating any SVG attribute
func apply_props(changed_prop_name):
	if _apply_props_notify_list.size() == 0:
		call_deferred("_apply_props_deferred")
	if not _apply_props_notify_list.has(changed_prop_name):
		_apply_props_notify_list.push_back(changed_prop_name)

func get_bounding_box():
	return _bounding_box

func get_root_scale_factor():
	if root_controller == null or root_controller.fixed_scaling_ratio == 0:
		return controlled_node.global_scale * root_controller.last_known_viewport_scale
	else:
		return controlled_node.global_scale * root_controller.fixed_scaling_ratio

func get_scale_factor():
	if root_controller.is_2d:
		if (root_controller == null or root_controller.fixed_scaling_ratio == 0) and not is_in_root_viewport:
			var viewport = controlled_node.get_viewport()
			if viewport != null:
				return viewport.canvas_transform.get_scale()
			else:
				return Vector2(1, 1)
		else:
			return get_root_scale_factor()
	else:
		return Vector3(1, 1, 1)

func get_stroked_bounding_box():
	var stroke_width = get_visible_stroke_width()
	var half_stroke_width = stroke_width / 2.0
	return Rect2(
		_bounding_box.position.x - half_stroke_width,
		_bounding_box.position.y - half_stroke_width,
		_bounding_box.size.x + stroke_width,
		_bounding_box.size.y + stroke_width
	)

func get_style(attribute_name, default_value):
	var value = default_value
	if attr_style.has(attribute_name):
		value = attr_style[attribute_name]
	elif _applied_stylesheet_style.has(attribute_name):
		value = _applied_stylesheet_style[attribute_name]
	return value

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

func read_attributes_from_element_resource() -> PackedStringArray:
	var assigned_attribute_names = PackedStringArray()
	if element_resource != null:
		for attribute_name in element_resource.attributes:
			if "attr_" + attribute_name in self:
				assigned_attribute_names.append(attribute_name)
				set("attr_" + attribute_name, element_resource.attributes[attribute_name])
	return assigned_attribute_names

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

# Controllers can override this as applicable
func resolve_href():
	return null # Override

# Removes a child from the current child container
func remove_child(child_to_remove):
	if _child_list.has(child_to_remove):
		_child_list.erase(child_to_remove)
	if _child_container == controlled_node:
		controlled_node.remove_child_from_root(child_to_remove)
	else:
		_child_container.remove_child(child_to_remove)

func set_applied_stylesheet_style(applied_stylesheet_style):
	if typeof(applied_stylesheet_style) == TYPE_DICTIONARY:
		_applied_stylesheet_style = applied_stylesheet_style
		for attr_name in _applied_stylesheet_style:
			if "attr_" + attr_name in self:
				self["attr_" + attr_name] = self["attr_" + attr_name]
				apply_props(attr_name)

func set_attributes(attributes_definition: Dictionary):
	for name in attributes_definition:
		var attr_name = "attr_" + name
		if attr_name in self:
			self[attr_name] = attributes_definition[name]
