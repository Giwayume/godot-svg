@tool
extends ResourceFormatLoader
class_name SVGResourceFormatLoader

const SVGResource = preload("../resource/svg_resource.gd")

func _get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray(["gdsvg"])

func _get_resource_type(path: String) -> String:
	var ext = path.get_extension().to_lower()
	if ext == "gdsvg":
		return "Resource"
	return ""

func _handles_type(typename: StringName) -> bool:
	return ClassDB.is_parent_class(typename, "Resource")

func _load(path: String, original_path: String, use_sub_threads: bool, cache_mode: int):
	var file = FileAccess.open(path, FileAccess.READ)
	var error = file.get_error()
	if error != OK:
		return error
	
	var file_text = file.get_as_text()
	file.close()
	
	var xml_string = ""
	var xml_buffer = null
	var render_cache = {}
	if file_text.begins_with("{"):
		var test_json_conv = JSON.new()
		var test_json_conv_error = test_json_conv.parse(file_text)
		if test_json_conv_error == OK:
			var parse_result = test_json_conv.data
			if parse_result.has("xml"):
				xml_string = parse_result.xml
			if parse_result.has("render_cache"):
				render_cache = parse_result.render_cache
	else:
		xml_string = file_text
	
	var svg_resource = SVGResource.new()
	svg_resource.xml = xml_string
	svg_resource.render_cache = {} if render_cache.is_empty() else str_to_var(render_cache)
	svg_resource.imported_path = path
	return load_svg_resource_from_buffer(svg_resource, xml_string.to_utf8_buffer())

func load_svg_resource_from_buffer(svg_resource, xml_string_buffer: PackedByteArray):
	var parent_stack = [{
		"resource": svg_resource,
		"global_attributes": {},
	}]
	var xml_parser = XMLParser.new()
	if xml_parser.open_buffer(xml_string_buffer) == OK:
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
#				var global_attributes = parent_stack[0].global_attributes.duplicate()
				for attribute_index in xml_parser.get_attribute_count():
					var attribute_name = SVGAttributeParser.to_snake_case(xml_parser.get_attribute_name(attribute_index))
					var attribute_value = xml_parser.get_attribute_value(attribute_index).strip_edges()
					attributes[attribute_name] = attribute_value
#					if SVGValueConstant.GLOBAL_INHERITED_ATTRIBUTE_NAMES.has(attribute_name):
#						global_attributes[attribute_name] = attribute_value
#				for attribute_name in global_attributes:
#					if not attributes.has(attribute_name):
#						attributes[attribute_name] = global_attributes[attribute_name]
				new_resource.attributes = attributes
				if not xml_parser.is_empty():
					parent_stack.push_front({
						"resource": new_resource,
#						"global_attributes": global_attributes,
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
