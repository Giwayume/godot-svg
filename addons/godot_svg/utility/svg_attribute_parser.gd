class_name SVGAttributeParser

static func to_snake_case(attribute_name):
	var camel_case_regex = RegEx.new()
	camel_case_regex.compile("([A-Z])")
	var snake_replace_regex = RegEx.new()
	snake_replace_regex.compile("([\\-:])")
	attribute_name = camel_case_regex.sub(attribute_name, "_$1", true)
	attribute_name = snake_replace_regex.sub(attribute_name.to_lower(), "_", true)
#	attribute_name = attribute_name.to_lower().replace("-", "_")
	return attribute_name

# https://www.w3.org/TR/SVG/styling.html#PresentationAttributes
static func parse_css_style(style):
	var style_dictionary = {}
	var is_parsing_name = true
	var current_name = ""
	var current_value = ""
	for c in style:
		if is_parsing_name:
			if c == ":":
				current_name = to_snake_case(current_name.strip_edges())
				is_parsing_name = false
			else:
				current_name += c
		else:
			if c == ";":
				current_value = current_value.strip_edges()
				is_parsing_name = true
				style_dictionary[current_name] = current_value
			else:
				current_value += c
	if current_name.length() > 0:
		style_dictionary[current_name] = current_value
	return style_dictionary

static func parse_css_color(attribute):
	var color = null
	var hex_color_regex = RegEx.new()
	hex_color_regex.compile("^#[0-9abcdefABCDEF]{3,8}$")
	if hex_color_regex.search(attribute):
		if attribute.length() == 4:
			attribute = "#" + attribute[1] + attribute[1] + attribute[2] + attribute[2] + attribute[3] + attribute[3]
		elif attribute.length() == 5:
			attribute = "#" + attribute[4] + attribute[4] + attribute[1] + attribute[1] + attribute[2] + attribute[2] + attribute[3] + attribute[3]
		elif attribute.length() == 9:
			attribute = "#" + attribute.substr(7, 2) + attribute.substr(1, 6)
		color = Color(attribute)
	elif attribute.begins_with("rgb("):
		attribute = attribute.replace("rgb(", "").rstrip(")").strip_edges()
		var rgb_split = attribute.split(",")
		color = Color8(
			rgb_split[0].strip_edges().to_int(),
			rgb_split[1].strip_edges().to_int(),
			rgb_split[2].strip_edges().to_int()
		)
	elif attribute.begins_with("rgba("):
		attribute = attribute.replace("rgba(", "").rstrip(")").strip_edges()
		var rgba_split = attribute.split(",")
		color = Color8(
			rgba_split[0].strip_edges().to_int(),
			rgba_split[1].strip_edges().to_int(),
			rgba_split[2].strip_edges().to_int(),
			rgba_split[3].strip_edges().to_int()
		)
	elif SVGValueConstant.CSS_COLOR_NAMES.has(attribute):
		color = SVGValueConstant.CSS_COLOR_NAMES[attribute]
	return color

static func parse_number_list(number_list_string):
	var values = []
	var space_split = number_list_string.split(" ", false)
	for space_split_str in space_split:
		var comma_split = space_split_str.split(",", false)
		for value_str in comma_split:
			values.push_back(value_str.to_float())
	return values

static func parse_transform_list(transform_attr):
	var transform = Transform2D()
	if typeof(transform_attr) != TYPE_STRING:
		transform = transform_attr
	else:
		if SVGValueConstant.NONE == transform_attr:
			transform = Transform2D()
		else:
			var split = transform_attr.split(")", false)
			var transform_matrix = Transform()
			for command_index in range(split.size() - 1, -1, -1):
				var transform_command = split[command_index]
				transform_command = transform_command.strip_edges()
				if transform_command.begins_with("matrix("):
					var values = parse_number_list(transform_command.replace("matrix(", "").rstrip(")"))
					if values.size() == 6:
						transform_matrix = Transform2D(
							Vector2(values[0], values[1]),
							Vector2(values[2], values[3]),
							Vector2(values[4], values[5])
						)
				elif transform_command.begins_with("rotate("):
					var values = parse_number_list(transform_command.replace("rotate(", "").rstrip(")"))
					if values.size() == 1:
						transform_matrix = transform_matrix.rotated(Vector3(0, 0, 1), deg2rad(values[0]))
					elif values.size() == 3:
						transform_matrix = transform_matrix.rotated(Vector3(1, 0, 0), deg2rad(values[0]))
						transform_matrix = transform_matrix.rotated(Vector3(0, 1, 0), deg2rad(values[1]))
						transform_matrix = transform_matrix.rotated(Vector3(0, 0, 1), deg2rad(values[2]))
				elif transform_command.begins_with("translate("):
					var values = parse_number_list(transform_command.replace("translate(", "").rstrip(")"))
					if values.size() >= 2:
						transform_matrix.origin += Vector3(
							values[0],
							values[1],
							-values[2] if values.size() == 3 else 0.0
						)
				elif transform_command.begins_with("scale("):
					var values = parse_number_list(transform_command.replace("scale(", "").rstrip(")"))
					if values.size() == 1:
						transform_matrix = transform_matrix.scaled(Vector3(
							values[0],
							values[0],
							values[0]
						))
					if values.size() >= 2:
						transform_matrix = transform_matrix.scaled(Vector3(
							values[0],
							values[1],
							values[2] if values.size() == 3 else 1.0
						))
			transform = Transform2D(transform_matrix)
	return transform
