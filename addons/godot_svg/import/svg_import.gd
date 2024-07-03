@tool
extends EditorImportPlugin

enum Presets { DEFAULT }

func _get_importer_name():
	return "giwayume.godotsvg"

func _get_visible_name():
	return "SVG"

func _get_recognized_extensions():
	return ["svg"]

func _get_save_extension():
	return "gdsvg"

func _get_resource_type():
	return "Resource"

func _get_preset_count():
	return Presets.size()

func _get_preset_name(preset_index):
	match preset_index:
		Presets.DEFAULT:
			return "Default"
		_:
			return "Unknown"

func _get_priority():
	return 1

func _get_import_options(path, preset_index):
	match preset_index:
		Presets.DEFAULT:
			return []
		_:
			return []

func _get_import_order():
	return 0

func _get_option_visibility(path, option_name, options):
	return true

func _import(source_file, save_path, options, r_platform_variants, r_gen_files):
	var file = FileAccess.open(source_file, FileAccess.READ)
	if file.get_error() != OK:
		return FAILED
	
	var svg_resource = SVGResource.new()
	svg_resource.xml = file.get_as_text()
	
	var save_error = ResourceSaver.save(svg_resource, "%s.%s" % [save_path, _get_save_extension()])
	return OK
