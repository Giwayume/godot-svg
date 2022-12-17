tool
extends EditorPlugin

const plugin_config = preload("./plugin_config.gd")

signal svg_resources_reimported(resource_names)
signal editor_viewport_scale_changed(new_scale)

var svg_import_plugin = null
var edited_scene_viewport = null
var previous_editor_viewport_transform_scale = Vector2(1.0, 1.0)
var plugin_folder_path = plugin_config.resource_path.replace("plugin_config.gd", "")

func _init():
	name = "GodotSVGEditorPlugin"

func _process(_delta):
	if edited_scene_viewport != null:
		var canvas_transform_scale = edited_scene_viewport.global_canvas_transform.get_scale()
		if not canvas_transform_scale.is_equal_approx(previous_editor_viewport_transform_scale):
			emit_signal("editor_viewport_scale_changed", canvas_transform_scale)
		previous_editor_viewport_transform_scale = canvas_transform_scale

func _enter_tree():
	svg_import_plugin = preload("./import/svg_import.gd").new()
	add_import_plugin(svg_import_plugin)
	var svg_2d_icon = null
	if ResourceLoader.exists("res://addons/godot_svg/node/svg_2d.png"):
		svg_2d_icon = load("res://addons/godot_svg/node/svg_2d.png")
	add_custom_type("SVG2D", "Node2D", preload("./node/svg_2d.gd"), svg_2d_icon)
	var svg_rect_icon = null
	if ResourceLoader.exists("res://addons/godot_svg/node/svg_rect.png"):
		svg_rect_icon = load("res://addons/godot_svg/node/svg_rect.png")
	add_custom_type("SVGRect", "Control", preload("./node/svg_rect.gd"), svg_rect_icon)

	var editor_interface = get_editor_interface()
	editor_interface.get_resource_filesystem().connect("resources_reimported", self, "_on_resources_reimported")
	
	connect("scene_changed", self, "_on_editing_scene_changed")

func _print_rec(node, level = 0):
	var s = ""
	for i in range(0, level):
		s += "  "
	print(s + node.name + " " + node.get_class())
	for child in node.get_children():
		_print_rec(child, level + 1)

func _exit_tree():
	remove_import_plugin(svg_import_plugin)
	remove_custom_type("SVG2D")
	remove_custom_type("SVGRect")
	remove_autoload_singleton("SVGLine2DTexture")
	
	get_editor_interface().get_resource_filesystem().disconnect("resources_reimported", self, "_on_resources_reimported")
	disconnect("scene_changed", self, "_on_editing_scene_changed")
	
	svg_import_plugin = null

func _on_resources_reimported(resources):
	var svg_resources = []
	for resource_name in resources:
		if resource_name.ends_with(".svg"):
			svg_resources.push_back(resource_name)
	emit_signal("svg_resources_reimported", svg_resources)

func _find_edit_viewport(node):
	var viewport = null
	if node.get_class() == "CanvasItemEditorViewport":
		viewport = node
		for child in node.get_parent().get_children():
			if child.get_class() == "ViewportContainer":
				viewport = child.get_children()[0]
				break
	else:
		for child in node.get_children():
			viewport = _find_edit_viewport(child)
			if viewport != null:
				break
	return viewport

func _on_editing_scene_changed(scene_root):
	edited_scene_viewport = _find_edit_viewport(get_editor_interface().get_editor_viewport())

# Public methods

func overwrite_svg_resource(resource):
	ResourceSaver.save(resource.resource_path, resource)
	var error = SVGResourceFormatSaver.new().save(resource.imported_path, resource, 0)
	return error

