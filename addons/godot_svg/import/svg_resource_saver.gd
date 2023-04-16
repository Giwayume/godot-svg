@tool
extends ResourceFormatSaver
class_name SVGResourceFormatSaver

const SVGResource = preload("../resource/svg_resource.gd")

func _get_recognized_extensions(resource: Resource) -> PackedStringArray:
	return PackedStringArray(["gdsvg"])

func _recognize(resource: Resource) -> bool:
	resource = resource as SVGResource
	if resource:
		return true
	return false

func _save(resource: Resource, path: String, flags: int) -> Error:
	# Save the XML string
	var file = FileAccess.open(path, FileAccess.WRITE)
	var error = file.get_error()
	if error != OK:
		printerr('Can\'t write file: "%s"! code: %d.' % [path, error])
		return error
	file.store_string(
		JSON.stringify({
			"xml": resource.xml,
			"render_cache": var_to_str(resource.render_cache)
		})
	)
	file.close()
	
	return OK
