extends Node2D

onready var camera = $Camera2D
var is_zooming = false

func _process(delta):
	if is_zooming and camera:
		camera.zoom -= Vector2(0.2, 0.2) * delta

func _input(event):
	if event.is_action_pressed("ui_accept"):
		is_zooming = !is_zooming
