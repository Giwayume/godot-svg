tool
extends Polygon2D

signal drawn

func _draw():
	emit_signal("drawn")

func set_vertex_color_bypass(new_vertex_colors):
	vertex_colors = new_vertex_colors
