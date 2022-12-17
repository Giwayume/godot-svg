tool
extends ResourceFormatSaver
class_name SVGResourceFormatSaver

const SVGResource = preload("../resource/svg_resource.gd")

func get_recognized_extensions(resource: Resource) -> PoolStringArray:
	return PoolStringArray(["gdsvg"])

func recognize(resource: Resource) -> bool:
	resource = resource as SVGResource
	if resource:
		return true
	return false

func save(path: String, resource: Resource, flags: int) -> int:
	
	# Save the XML string
	var file: File = File.new()
	var error = file.open(path, File.WRITE)
	if error != OK:
		printerr('Can\'t write file: "%s"! code: %d.' % [path, error])
		return error
	file.store_string(
		JSON.print({
			"xml": resource.xml,
			"render_cache": var2str(resource.render_cache)
		})
	)
	file.close()
	
	return OK
