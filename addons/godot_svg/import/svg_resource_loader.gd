tool
extends ResourceFormatLoader
class_name SVGResourceFormatLoader

const SVGResource = preload("../resource/svg_resource.gd")

func get_recognized_extensions() -> PoolStringArray:
	return PoolStringArray(["gdsvg"])

func get_resource_type(path: String) -> String:
	var ext = path.get_extension().to_lower()
	if ext == "gdsvg":
		return "Resource"
	return ""

func handles_type(typename: String) -> bool:
	return ClassDB.is_parent_class(typename, "Resource")

func load(path: String, original_path: String):
	var xml_parser = XMLParser.new()
	var file: File = File.new()
	var error = file.open(path, File.READ)
	if error != OK:
		return error
	
	var file_text = file.get_as_text()
	file.close()
	
	var xml_string = ""
	var xml_buffer = null
	var render_cache = null
	if file_text.begins_with("{"):
		var parse_result = JSON.parse(file_text)
		if parse_result.error == OK:
			if parse_result.result.has("xml"):
				xml_string = parse_result.result.xml
			if parse_result.result.has("render_cache"):
				render_cache = parse_result.result.render_cache
	else:
		xml_string = file_text
	
	var svg_resource = SVGResource.new()
	svg_resource.xml = xml_string
	svg_resource.render_cache = null if render_cache == null else str2var(render_cache)
	svg_resource.imported_path = path
	
	var parent_stack = [{
		"resource": svg_resource,
		"global_attributes": {},
	}]
	if xml_parser.open_buffer(xml_string.to_utf8()) == OK:
		while xml_parser.read() == OK:
			var node_type = xml_parser.get_node_type()
			if node_type == XMLParser.NODE_ELEMENT:
				var node_name = xml_parser.get_node_name()
				var new_resource
				match node_name:
					"svg":
						if parent_stack[0].resource == svg_resource:
							svg_resource.viewport = SVGResourceElement.new()
							new_resource = svg_resource.viewport
						else:
							new_resource = SVGResourceElement.new()
							parent_stack[0].resource.add_child(new_resource)
					_:
						new_resource = SVGResourceElement.new()
						parent_stack[0].resource.add_child(new_resource)
				new_resource.node_name = node_name
				new_resource.children = []
				var attributes = {}
				var global_attributes = parent_stack[0].global_attributes.duplicate()
				for attribute_index in xml_parser.get_attribute_count():
					var attribute_name = SVGAttributeParser.to_snake_case(xml_parser.get_attribute_name(attribute_index))
					var attribute_value = xml_parser.get_attribute_value(attribute_index).strip_edges()
					attributes[attribute_name] = attribute_value
					if SVGValueConstant.GLOBAL_INHERITED_ATTRIBUTE_NAMES.has(attribute_name):
						global_attributes[attribute_name] = attribute_value
				for attribute_name in global_attributes:
					if not attributes.has(attribute_name):
						attributes[attribute_name] = global_attributes[attribute_name]
				new_resource.attributes = attributes
				if not xml_parser.is_empty():
					parent_stack.push_front({
						"resource": new_resource,
						"global_attributes": global_attributes,
					})
			
			elif node_type == XMLParser.NODE_ELEMENT_END:
				var node_name = xml_parser.get_node_name()
				if node_name == parent_stack[0].resource.node_name:
					parent_stack.pop_front()
			
			elif node_type == XMLParser.NODE_TEXT:
				var node_text = xml_parser.get_node_data()
				parent_stack[0].resource.text += node_text
			
			elif node_type == XMLParser.NODE_CDATA:
				pass
				
	
	return svg_resource
