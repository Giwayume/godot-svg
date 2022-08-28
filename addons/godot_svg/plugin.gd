tool
extends EditorPlugin

var svg_import_plugin

func _enter_tree():
	svg_import_plugin = preload("./import/svg_import.gd").new()
	add_import_plugin(svg_import_plugin)
	add_custom_type("SVG2D", "Node2D", preload("./node/svg_2d.gd"), preload("./node/svg_2d.png"))

func _exit_tree():
	remove_import_plugin(svg_import_plugin)
	remove_custom_type("SVG2D")
	svg_import_plugin = null
