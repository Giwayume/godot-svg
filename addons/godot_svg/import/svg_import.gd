tool
extends EditorImportPlugin

enum Presets { DEFAULT }

func get_importer_name():
	return "giwayume.godotsvg"

func get_visible_name():
	return "SVG"

func get_recognized_extensions():
	return ["svg"]

func get_save_extension():
	return "gdsvg"

func get_resource_type():
	return "Resource"

func get_preset_count():
	return Presets.size()

func get_preset_name(preset):
	match preset:
		Presets.DEFAULT:
			return "Default"
		_:
			return "Unknown"

func get_import_options(preset):
	match preset:
		Presets.DEFAULT:
			return []
		_:
			return []

func get_option_visibility(option, options):
	return true

func import(source_file, save_path, options, r_platform_variants, r_gen_files):
	var file = File.new()
	if file.open(source_file, File.READ) != OK:
		return FAILED
	
	var svg_resource = SVGResource.new()
	svg_resource.xml = file.get_as_text()
	
	var save_error = ResourceSaver.save("%s.%s" % [save_path, get_save_extension()], svg_resource)
	return OK


