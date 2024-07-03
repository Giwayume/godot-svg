extends Control

const SVG2D = preload("res://addons/godot_svg/node/svg_2d.gd")
const check_circle_icon = preload("res://tests/assets/icons/check_circle.svg")
const clock_icon = preload("res://tests/assets/icons/clock.svg")
const image_icon = preload("res://tests/assets/icons/image.svg")
const x_circle_icon = preload("res://tests/assets/icons/x_circle.svg")

@onready var test_list_tree: Tree = %TestListTree
@onready var test_preview_sub_viewport_container: SubViewportContainer = %TestPreviewSubViewportContainer
@onready var test_preview_sub_viewport: SubViewport = %TestPreviewSubViewport
@onready var test_preview_background: ColorRect = %TestPreviewBackground
@onready var start_test_button: Button = %StartTestButton
@onready var stop_test_button: Button = %StopTestButton
@onready var mark_correct_button: Button = %MarkCorrectButton

var test_list_root: TreeItem
var test_svg = null
var test_svg_filepath = ""

var is_running_test = false
var current_testing_tree_item = null
var test_deferred_timer = Timer.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	test_list_tree.connect("item_selected", Callable(self, "_on_test_list_selected"))
	start_test_button.connect("pressed", Callable(self, "_on_start_test"))
	stop_test_button.connect("pressed", Callable(self, "_on_stop_test"))
	mark_correct_button.connect("pressed", Callable(self, "_on_mark_correct"))
	
	test_deferred_timer.one_shot = true
	test_deferred_timer.connect("timeout", Callable(self, "_compare_test_image"))
	add_child(test_deferred_timer)
	
	_populate_test_list()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _populate_test_list():
	test_list_tree.columns = 2
	test_list_tree.set_column_expand(1, false)
	test_list_tree.set_column_clip_content(1, false)
	test_list_tree.set_column_custom_minimum_width(1, 32)
	test_list_root = test_list_tree.create_item()
	test_list_tree.hide_root = true
	
	var base_folder_path = "res://tests/w3c_1.1_test_suite/svg"
	var dir = DirAccess.open(base_folder_path)
	var category_folders = dir.get_directories()
	for category_folder in category_folders:
		var folder = test_list_tree.create_item(test_list_root)
		folder.collapsed = true
		folder.set_text(0, category_folder)
		folder.set_selectable(0, false)
		folder.set_selectable(1, false)
		var folder_dir = DirAccess.open(base_folder_path + "/" + category_folder)
		var files = folder_dir.get_files()
		for filename in files:
			if filename.ends_with(".svg"):
				var file = test_list_tree.create_item(folder)
				var filepath = base_folder_path + "/" + category_folder + "/" + filename
				if _has_saved_test_result(filepath):
					file.set_icon(1, image_icon)
				file.set_selectable(1, false)
				file.set_text(0, filename)
				file.set_metadata(0, {
					"filepath": filepath
				})

func _get_saved_filepath(filepath):
	return filepath.replace("res://", "user://").replace("/svg/", "/test_result/").replace(".svg", ".png")

func _has_saved_test_result(filepath):
	var saved_path = _get_saved_filepath(filepath)
	return FileAccess.file_exists(saved_path)

func _on_test_list_selected():
	if is_running_test:
		return
	var selected_item = test_list_tree.get_selected()
	var metadata = selected_item.get_metadata(0)
	if metadata != null and metadata.filepath:
		_load_svg(metadata.filepath)

func _on_mark_correct():
	if is_running_test:
		return
	var viewport_image = test_preview_sub_viewport.get_texture().get_image()
	var save_path = _get_saved_filepath(test_svg_filepath)
	var dir = DirAccess.open("user://")
	dir.make_dir_recursive(save_path.get_base_dir())
	var error = viewport_image.save_png(save_path)
	if error == OK:
		var selected_item = test_list_tree.get_selected()
		selected_item.set_icon(1, image_icon)

func _on_start_test():
	is_running_test = true
	
	var replace_icon_item: TreeItem = test_list_root
	while replace_icon_item != null:
		if replace_icon_item.get_icon(1) != null:
			replace_icon_item.set_icon(1, clock_icon)
		replace_icon_item = replace_icon_item.get_next_in_tree()
	
	current_testing_tree_item = test_list_root
	_find_next_testable_tree_item()

func _find_next_testable_tree_item():
	if not is_running_test:
		return
	current_testing_tree_item = current_testing_tree_item.get_next_in_tree()
	while current_testing_tree_item != null:
		if current_testing_tree_item.get_icon(1) != null:
			break
		current_testing_tree_item = current_testing_tree_item.get_next_in_tree()
	if current_testing_tree_item == null:
		is_running_test = false
	else:
		var metadata = current_testing_tree_item.get_metadata(0)
		if metadata != null and metadata.filepath:
			_load_svg(metadata.filepath)
		else:
			_find_next_testable_tree_item()

func _compare_test_image():
	if not is_running_test:
		return
	var metadata = current_testing_tree_item.get_metadata(0)
	if metadata == null or not metadata.filepath:
		return
	var saved_path = _get_saved_filepath(metadata.filepath)
	
	var viewport_test_image = test_preview_sub_viewport.get_texture().get_image()
	var saved_image = Image.load_from_file(saved_path)
	var is_image_equal = _compare_images(viewport_test_image, saved_image)
	if is_image_equal:
		current_testing_tree_item.set_icon(1, check_circle_icon)
	else:
		current_testing_tree_item.set_icon(1, x_circle_icon)
		current_testing_tree_item.uncollapse_tree()
	
	_find_next_testable_tree_item()

func _compare_images(image1: Image, image2: Image):
	if image1.get_width() != image2.get_width():
		return false
	if image1.get_height() != image2.get_height():
		return false
	var bytes1: PackedByteArray = image1.get_data()
	var bytes2: PackedByteArray = image2.get_data()
	for i in range(0, bytes1.size()):
		if bytes1[i] != bytes2[i]:
			return false
	return true

func _on_stop_test():
	is_running_test = false

func _load_svg(filepath):
	if test_svg != null and is_instance_valid(test_svg):
		test_svg.queue_free()
		test_svg = null
	
	test_svg_filepath = filepath
	test_svg = SVG2D.new()
	test_svg.controller.connect("node_structure_generated", Callable(self, "_on_svg_loaded"))
	test_svg.disable_render_cache = true
	test_svg.svg = load(filepath)
	test_preview_sub_viewport.add_child(test_svg)

func _on_svg_loaded():
	var test_svg_rect = test_svg._edit_get_rect()
	test_preview_background.size = test_svg_rect.size
	test_preview_sub_viewport_container.size = test_svg_rect.size
	test_preview_sub_viewport.size = test_svg_rect.size
	
	if is_running_test:
		test_deferred_timer.call_deferred("start", 0.1)
