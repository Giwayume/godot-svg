extends Control

const SVG2D = preload("res://addons/godot_svg/node/svg_2d.gd")

@onready var test_list_tree: Tree = %TestListTree
@onready var test_preview_sub_viewport_container: SubViewportContainer = %TestPreviewSubViewportContainer
@onready var test_preview_sub_viewport: SubViewport = %TestPreviewSubViewport
@onready var test_preview_background: ColorRect = %TestPreviewBackground
@onready var mark_correct_button: Button = %MarkCorrectButton

var test_list_root: TreeItem
var test_svg = null
var test_svg_filepath = ""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	test_list_tree.connect("item_selected", Callable(self, "_on_test_list_selected"))
	mark_correct_button.connect("pressed", Callable(self, "_on_mark_correct"))
	_populate_test_list()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _populate_test_list():
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
		var folder_dir = DirAccess.open(base_folder_path + "/" + category_folder)
		var files = folder_dir.get_files()
		for filename in files:
			if filename.ends_with(".svg"):
				var file = test_list_tree.create_item(folder)
				file.set_text(0, filename)
				file.set_metadata(0, {
					"filepath": base_folder_path + "/" + category_folder + "/" + filename
				})

func _on_test_list_selected():
	var selected_item = test_list_tree.get_selected()
	var metadata = selected_item.get_metadata(0)
	if metadata != null and metadata.filepath:
		_load_svg(metadata.filepath)

func _on_mark_correct():
	var viewport_image = test_preview_sub_viewport.get_texture().get_image()
	print_debug(viewport_image)

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
