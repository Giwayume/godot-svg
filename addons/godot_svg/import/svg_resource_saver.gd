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
	var error: int
	var file: File = File.new()
	error = file.open(path, File.WRITE)
	
	if error != OK:
		printerr('Can\'t write file: "%s"! code: %d.' % [path, error])
		return error
	
	file.store_string(resource.xml)
	file.close()
	return OK
