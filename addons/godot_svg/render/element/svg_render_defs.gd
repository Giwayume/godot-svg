extends "svg_render_element.gd"

# Lifecycle

func _init():
	node_name = "defs"

func _draw():
	._draw()
	modulate = Color(1, 1, 1, 0)
	hide()
