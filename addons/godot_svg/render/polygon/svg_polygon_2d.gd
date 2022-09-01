# Adapted from Godot Antialiased Line2D
# https://github.com/godot-extended-libraries/godot-antialiased-line2d/blob/master/LICENSE.md
# Open source under the MIT License.
# Copyright © 2022 Hugo Locurcio and contributors 

tool
extends Polygon2D

const SVGLine2D = preload("svg_line_2d.gd")

export var stroke_color = Color(0.4, 0.5, 1.0) setget set_stroke_color
export(float, 0.0, 1000.0) var stroke_width = 10.0 setget set_stroke_width
export(int, "Sharp", "Bevel", "Round") var stroke_joint_mode = Line2D.LINE_JOINT_SHARP setget set_stroke_joint_mode
export(float, 0.0, 1000.0) var stroke_sharp_limit = 2.0 setget set_stroke_sharp_limit
export(int, 1, 32) var stroke_round_precision = 8 setget set_stroke_round_precision

var line_2d = Line2D.new()


func _ready() -> void:
	line_2d.texture = SVGLine2DTexture.texture
	line_2d.texture_mode = Line2D.LINE_TEXTURE_TILE
	if polygon.size() >= 1:
		line_2d.points = SVGLine2D.construct_closed_line(polygon)
	add_child(line_2d)


func _set(property: String, value) -> bool:
	if property == "polygon":
		line_2d.points = SVGLine2D.construct_closed_line(value)
	return false


func set_stroke_color(p_stroke_color: Color) -> void:
	stroke_color = p_stroke_color
	line_2d.default_color = stroke_color


func set_stroke_width(p_stroke_width: float) -> void:
	stroke_width = p_stroke_width
	line_2d.width = stroke_width


func set_stroke_joint_mode(p_stroke_joint_mode: int) -> void:
	stroke_joint_mode = p_stroke_joint_mode
	line_2d.joint_mode = stroke_joint_mode


func set_stroke_sharp_limit(p_stroke_sharp_limit: float) -> void:
	stroke_sharp_limit = p_stroke_sharp_limit
	line_2d.sharp_limit = stroke_sharp_limit


func set_stroke_round_precision(p_stroke_round_precision: int) -> void:
	stroke_round_precision = p_stroke_round_precision
	line_2d.round_precision = stroke_round_precision
