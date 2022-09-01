class_name SVGAttributeParser

static func to_snake_case(attribute_name):
	var camel_case_regex = RegEx.new()
	camel_case_regex.compile("([A-Z])")
	attribute_name = camel_case_regex.sub(attribute_name, "_$1", true)
	attribute_name = attribute_name.to_lower().replace("-", "_")
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


static func parse_transform_list(transform_attr):
	var transform = Transform2D()
	if typeof(transform_attr) != TYPE_STRING:
		transform = transform_attr
	else:
		if SVGValueConstant.NONE == transform_attr:
			transform = Transform2D()
		else:
			var split = transform_attr.split(" ", false)
			var transform_matrix = Transform()
			for transform_command in split:
				transform_command = transform_command.strip_edges()
				if transform_command.begins_with("rotate("):
					var values = transform_command.replace("rotate(", "").rstrip(")").strip_edges().split(" ", false)
					if values.size() == 1:
						transform_matrix = transform_matrix.rotated(Vector3(0, 0, 1), deg2rad(values[0].to_float()))
					elif values.size() == 3:
						transform_matrix = transform_matrix.rotated(Vector3(1, 0, 0), deg2rad(values[0].to_float()))
						transform_matrix = transform_matrix.rotated(Vector3(0, 1, 0), deg2rad(values[1].to_float()))
						transform_matrix = transform_matrix.rotated(Vector3(0, 0, 1), deg2rad(values[2].to_float()))
				elif transform_command.begins_with("translate("):
					var values = transform_command.replace("translate(", "").rstrip(")").strip_edges().split(" ", false)
					if values.size() >= 2:
						transform_matrix = transform_matrix.translated(
							values[0].to_float(),
							values[1].to_float(),
							-values[2].to_float() if values.size() == 3 else 0.0
						)
				elif transform_command.begins_with("scale("):
					var values = transform_command.replace("scale(", "").rstrip(")").strip_edges().split(" ", false)
					if values.size() >= 2:
						transform_matrix = transform_matrix.scaled(
							values[0].to_float(),
							values[1].to_float(),
							values[2].to_float() if values.size() == 3 else 0.0
						)
			transform = Transform2D(transform_matrix)
	return transform
