extends Node2D

const PathCommand = SVGValueConstant.PathCommand

var TEST_SVG_PATH = "res://tests/w3c_1.1_test_suite/svg/paths/paths-data-01-t.svg"
var ZOOM = 4.0
var PAN = Vector2(0.0, 0.0)

var test_svg = null
var background = null
var draw_timer: Timer = Timer.new()
var shape_debugs = []
var current_shape_debug_index = -1
var current_shape_debug_log_index = 0
var is_skip_next_draw_timer_timeout = false

var end_point = null
var intersection_points = []
var draw_path = []
var old_draw_path = []
var draw_turn_direction = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_viewport().canvas_transform = Transform2D().translated(PAN).scaled(Vector2(ZOOM, ZOOM)) * get_viewport().canvas_transform
	
	test_svg = Node2D.new()
	test_svg.set_script(preload("res://addons/godot_svg/node/svg_2d.gd"))
	test_svg.disable_render_cache = true
	test_svg.svg = load(TEST_SVG_PATH)
	test_svg.controller.connect("node_structure_generated", Callable(self, "_svg_ready"))
	
	call_deferred("_place_test_svg")
	
	background = ColorRect.new()
	background.size = get_viewport().size
	background.color = Color(0.25, 0.25, 0.25, 0.75)
	
	draw_timer.autostart = true
	draw_timer.wait_time = 0.5
	draw_timer.one_shot = false
	draw_timer.connect("timeout", Callable(self, "_draw_timer_timeout"))
	add_child(draw_timer)

func _place_test_svg():
	var parent = get_parent()
	var current_index = parent.get_children().find(self)
	parent.add_child(background)
	parent.move_child(background, current_index)
	parent.add_child(test_svg)
	parent.move_child(test_svg, current_index)

func _svg_ready():
	call_deferred("_svg_ready_deferred")

func _svg_ready_deferred():
	var paths = test_svg.get_elements_by_name("path")
	for path in paths:
		var controller = path.controller
		shape_debugs = controller._path_solver_debug
		current_shape_debug_index = 0
		current_shape_debug_log_index = 0
	print_debug(JSON.stringify(shape_debugs[current_shape_debug_index], "  "))

func _draw_timer_timeout():
	if is_skip_next_draw_timer_timeout:
		is_skip_next_draw_timer_timeout = false
		draw_path = []
		old_draw_path = []
		draw_timer.stop()
		draw_timer.start(0.5)
		return
	
	if current_shape_debug_index < 0:
		return
	var shape_debug = shape_debugs[current_shape_debug_index]
	var log = shape_debug.log[current_shape_debug_log_index]
	var path_shapes = _path_commands_to_shapes(shape_debug.paths)
	
	old_draw_path = draw_path
	var draw_shape = null
	var draw_shape_slice = [0, 1]
	draw_turn_direction = []
	end_point = null
	
	draw_timer.wait_time = 0.5
	
	if log.type == "intersection":
		intersection_points.push_back(log.point)
		draw_timer.wait_time = 0.05
	#elif log.type == "loop_add_rest_of_shape_to_path":
		#draw_shape = path_shapes[log.current_shape_index]
		#draw_shape_slice = log.shape_slice
	elif log.type == "loop_found_next_intersection":
		draw_shape = path_shapes[log.current_shape_index]
		draw_shape_slice = log.shape_slice
	elif log.type == "loop_no_intersection_found":
		draw_shape = path_shapes[log.current_shape_index]
		draw_shape_slice = log.shape_slice
	elif log.type == "loop_found_right_turn":
		var shape = path_shapes[log.new_shape_index]
		if shape != null:
			draw_turn_direction.push_back([
				shape.find_point_at(log.new_t),
				shape.find_point_at(log.new_t + log.traverse_direction * 0.1),
			])
	elif log.type == "loop_reached_back_to_start":
		draw_shape = path_shapes[log.current_shape_index]
		draw_shape_slice = log.shape_slice
		end_point = draw_shape.find_point_at(log.shape_slice[1])
		is_skip_next_draw_timer_timeout = true
	else:
		draw_timer.wait_time = 0.01
	
	if draw_shape != null:
		draw_path = []
		var range_length = 8.0
		var slice_max = maxf(draw_shape_slice[1], draw_shape_slice[0])
		var slice_min = minf(draw_shape_slice[1], draw_shape_slice[0])
		var range_step = (1.0 / range_length) * (slice_max - slice_min)
		var loop_start = 0 if draw_shape_slice[1] > draw_shape_slice[0] else range_length
		var loop_end = range_length if draw_shape_slice[1] > draw_shape_slice[0] else 0
		var loop_increment = 1 if loop_end > loop_start else -1
		for i in range(loop_start, loop_end, loop_increment):
			draw_path.push_back([
				draw_shape.find_point_at(slice_min + i * range_step),
				draw_shape.find_point_at(slice_min + ((i + loop_increment) * range_step)),
			])
	
	current_shape_debug_log_index += 1
	
	draw_timer.stop()
	draw_timer.start()
	if current_shape_debug_log_index >= len(shape_debug.log):
		draw_timer.stop()

#func _create_shape(paths, index):
	#var path = paths[index]
	#var previous_point = Vector2()
	#if index > 0:
		#var previous_command = paths[index - 1]
		#previous_point = previous_command.points[len(previous_command.points) - 1]
	#if path.command == PathCommand.LINE_TO:
		#return SVGPathSolver.PathSegment.new(previous_point, path.points[0])
	#elif path.command == PathCommand.QUADRATIC_BEZIER_CURVE:
		#return SVGPathSolver.PathQuadraticBezier.new(previous_point, path.points[0], path.points[1])
	#elif path.command == PathCommand.CUBIC_BEZIER_CURVE:
		#return SVGPathSolver.PathCubicBezier.new(previous_point, path.points[0], path.points[1], path.points[2])
	#SVGPathSolver.PathSegment.new(Vector2(), Vector2())

func _path_commands_to_shapes(paths):
	var path_shapes = []
	var current_loop_start = 0
	var current_point = Vector2()
	var current_loop_start_point = Vector2()
	
	# TODO - this only accounts for the very last shape defined, fix to consider all closed shapes
	var last_shape_index = paths.size() - 1
	if paths[last_shape_index].command == PathCommand.CLOSE_PATH:
		last_shape_index -= 1
	
	for i in range(0, paths.size()):
		var previous_instruction = paths[i - 1] if i > 0 else null
		var command = paths[i].command
		var points = paths[i].points if paths[i].has("points") else []
		var is_implicit_path_close = previous_instruction != null and paths[i].command == PathCommand.MOVE_TO and previous_instruction.command != PathCommand.CLOSE_PATH

		match command:
			PathCommand.MOVE_TO:
				if is_implicit_path_close and not current_point.is_equal_approx(current_loop_start_point):
					path_shapes.push_back(SVGPathSolver.PathSegment.new(current_point, current_loop_start_point, true))
				current_point = points[0]
			PathCommand.LINE_TO:
				var shape_end_point = points[0]
				if i == last_shape_index and shape_end_point.is_equal_approx(current_loop_start_point):
					shape_end_point = current_loop_start_point
				path_shapes.push_back(SVGPathSolver.PathSegment.new(current_point, shape_end_point))
				current_point = shape_end_point
			PathCommand.QUADRATIC_BEZIER_CURVE:
				var shape_end_point = points[1]
				if i == last_shape_index and shape_end_point.is_equal_approx(current_loop_start_point):
					shape_end_point = current_loop_start_point
				path_shapes.push_back(SVGPathSolver.PathQuadraticBezier.new(current_point, points[0], shape_end_point))
				current_point = shape_end_point
			PathCommand.CUBIC_BEZIER_CURVE:
				var shape_end_point = points[2]
				if i == last_shape_index and shape_end_point.is_equal_approx(current_loop_start_point):
					shape_end_point = current_loop_start_point
				path_shapes.push_back(SVGPathSolver.PathCubicBezier.new(current_point, points[0], points[1], shape_end_point))
				current_point = shape_end_point
		
		var is_end_of_paths = (i == paths.size() - 1 and current_loop_start < i)
		if (
			paths[i].command == PathCommand.CLOSE_PATH or
			is_implicit_path_close or
			is_end_of_paths
		):
			if current_loop_start < path_shapes.size():
				if is_end_of_paths and not current_point.is_equal_approx(current_loop_start_point):
					path_shapes.push_back(SVGPathSolver.PathSegment.new(current_point, current_loop_start_point))
			current_loop_start = path_shapes.size()
		
		if command == PathCommand.MOVE_TO:
			current_loop_start_point = points[0]
	
	return path_shapes

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	queue_redraw()

func _draw():
	for point in intersection_points:
		draw_circle(point, 2.0 / ZOOM, Color.RED)
	if end_point != null:
		draw_circle(end_point, 2.0 / ZOOM, Color.YELLOW)
	for line_segment in old_draw_path:
		draw_line(line_segment[0], line_segment[1], Color.GRAY, 2.0 / ZOOM)
	var i = 0.0
	for line_segment in draw_path:
		draw_line(line_segment[0], line_segment[1], Color.BLACK, 2.0 / ZOOM)
		i += 1.0
		if (
			len(draw_turn_direction) == 0 and
			(1.0 - (i / float(len(draw_path))) < draw_timer.time_left / draw_timer.wait_time)
		):
			break
	for line_segment in draw_turn_direction:
		draw_line(line_segment[0], line_segment[1], Color.GREEN, 2.0 / ZOOM)
