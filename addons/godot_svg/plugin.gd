tool
extends EditorPlugin

signal svg_resources_reimported(resource_names)

var svg_import_plugin

func _init():
	name = "GodotSVGEditorPlugin"

func _enter_tree():
	svg_import_plugin = preload("./import/svg_import.gd").new()
	add_import_plugin(svg_import_plugin)
	add_custom_type("SVG2D", "Node2D", preload("./node/svg_2d.gd"), preload("./node/svg_2d.png"))
	add_autoload_singleton("SVGLine2DTexture", "res://addons/godot_svg/render/polygon/svg_line_texture.gd")

	get_editor_interface().get_resource_filesystem().connect("resources_reimported", self, "_on_resources_reimported")

func _exit_tree():
	remove_import_plugin(svg_import_plugin)
	remove_custom_type("SVG2D")
	remove_autoload_singleton("SVGLine2DTexture")
	
	get_editor_interface().get_resource_filesystem().disconnect("resources_reimported", self, "_on_resources_reimported")
	
	svg_import_plugin = null

func _on_resources_reimported(resources):
	var svg_resources = []
	for resource_name in resources:
		if resource_name.ends_with(".svg"):
			svg_resources.push_back(resource_name)
	emit_signal("svg_resources_reimported", svg_resources)
