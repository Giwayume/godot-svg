tool
extends EditorImportPlugin

enum Presets { DEFAULT }

func get_importer_name():
	return "giwayume.godotsvg"

func get_visible_name():
	return "GodotSVG"

func get_recognized_extensions():
	return ["svg"]

func get_save_extension():
	return "res"

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
	var xml_parser = XMLParser.new()
	var error = xml_parser.open(source_file)
	if error != OK:
		return error
	
	var svg_source = SVGSource.new()
	
	var parent_stack = [{
		"resource": svg_source,
		"global_attributes": {},
	}]
	while xml_parser.read() == OK:
		var node_type = xml_parser.get_node_type()
		if node_type == XMLParser.NODE_ELEMENT:
			var node_name = xml_parser.get_node_name()
			var new_resource
			match node_name:
				"svg":
					if parent_stack[0].resource == svg_source:
						svg_source.viewport = SVGSourceElement.new()
						new_resource = svg_source.viewport
					else:
						new_resource = SVGSourceElement.new()
						parent_stack[0].resource.add_child(new_resource)
				_:
					new_resource = SVGSourceElement.new()
					parent_stack[0].resource.add_child(new_resource)
			new_resource.node_name = node_name
			new_resource.children = []
			var attributes = {}
			var global_attributes = parent_stack[0].global_attributes.duplicate()
			for attribute_index in xml_parser.get_attribute_count():
				var attribute_name = xml_parser.get_attribute_name(attribute_index).to_lower().replace("-", "_")
				var attribute_value = xml_parser.get_attribute_value(attribute_index).strip_edges()
				attributes[attribute_name] = attribute_value
				if SVGValueConstant.GLOBAL_ATTRIBUTE_NAMES.has(attribute_name):
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
	
	var save_error = ResourceSaver.save("%s.%s" % [save_path, get_save_extension()], svg_source)
	return save_error


