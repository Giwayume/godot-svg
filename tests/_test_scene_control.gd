extends Node2D

onready var camera = $Camera2D
var zoom_step = 3.4
var mouse_position = null
var is_panning = false

var zoom_at_step = 1.0
var zoom_at_point = Vector2()
var zoom_timer = 0.0
var is_zooming_in = true

func _ready():
	mouse_position = get_viewport().get_mouse_position()

func _process(delta):
	if zoom_timer > 0.0:
		zoom_timer -= delta
		var delta_zoom_step = 1.0 + ((1.0 - zoom_step) * delta)
		if !is_zooming_in:
			zoom_at_step = 1.0 / delta_zoom_step
		else:
			zoom_at_step = delta_zoom_step
		_zoom_at_point(zoom_at_step, zoom_at_point)
		if zoom_timer < 0.0:
			zoom_timer = 0.0

func _input(event):
	if event is InputEventMouse:
		if event is InputEventMouseMotion:
			var previous_mouse_position = mouse_position
			mouse_position = event.position
			if is_panning:
				_pan(previous_mouse_position - mouse_position)
		else:
			if event.is_pressed() and not event.is_echo():
				mouse_position = event.position
				if event.button_index == BUTTON_WHEEL_UP:
					is_zooming_in = true
					zoom_at_point = mouse_position
					zoom_timer = 0.3
					zoom_step = 4.0
				elif event.button_index == BUTTON_WHEEL_DOWN:
					is_zooming_in = false
					zoom_at_point = mouse_position
					zoom_timer = 0.3
					zoom_step = 4.0
			if event.button_index == BUTTON_LEFT or event.button_index == BUTTON_MIDDLE or event.button_index == BUTTON_RIGHT:
				is_panning = event.is_pressed()
	if event is InputEventKey:
		if event.is_pressed() and not event.is_echo():
			if event.physical_scancode == KEY_0:
				zoom_timer = 0.3
				is_zooming_in = false
				zoom_step = 10.0
#				camera.zoom = Vector2(1.0, 1.0)

func _zoom_at_point(zoom_change, point):
	var c0 = camera.global_position
	var v0 = camera.get_viewport().size
	var c1
	var z0 = camera.zoom
	var z1 = z0 * zoom_change
	c1 = c0 + (-0.5 * v0 + point) * (z0 - z1)
	camera.zoom = z1
	camera.global_position = c1

func _pan(delta):
	camera.global_position += delta * camera.zoom
