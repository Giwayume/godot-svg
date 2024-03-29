class_name SVGAttributeParser

const PathCommand = SVGValueConstant.PathCommand
const PathCoordinate = SVGValueConstant.PathCoordinate

static func to_snake_case(attribute_name):
	var camel_case_regex = RegEx.new()
	camel_case_regex.compile("([A-Z])")
	var snake_replace_regex = RegEx.new()
	snake_replace_regex.compile("([\\-:])")
	attribute_name = camel_case_regex.sub(attribute_name, "_$1", true)
	attribute_name = snake_replace_regex.sub(attribute_name.to_lower(), "_", true)
#	attribute_name = attribute_name.to_lower().replace("-", "_")
	return attribute_name

static func parse_number(string_representation) -> float:
	if string_representation != null:
		return string_representation.strip_edges().to_float()
	return 0.0

static func parse_integer_or_percentage(string_representation) -> int:
	if string_representation != null:
		string_representation = string_representation.strip_edges()
		if string_representation.ends_with("%"):
			var percentage = string_representation.replace("%", "").to_float()
			return int((percentage / 100.0) * 255.0)
		else:
			return string_representation.to_int()
	return 0

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
				current_name = ""
				current_value = ""
			else:
				current_value += c
	if current_name.length() > 0:
		style_dictionary[current_name] = current_value
	return style_dictionary

# https://www.w3.org/TR/css-color-4/
static func parse_css_color(attribute):
	var color = null
	var color_strings = attribute.split(" ", false)
	color_strings.invert()
	for color_string in color_strings:
		var hex_color_regex = RegEx.new()
		hex_color_regex.compile("^#[0-9abcdefABCDEF]{3,8}$")
		if hex_color_regex.search(color_string):
			if color_string.length() == 4:
				color_string = "#" + color_string[1] + color_string[1] + color_string[2] + color_string[2] + color_string[3] + color_string[3]
			elif attribute.length() == 5:
				color_string = "#" + color_string[4] + color_string[4] + color_string[1] + color_string[1] + color_string[2] + color_string[2] + color_string[3] + color_string[3]
			elif attribute.length() == 9:
				color_string = "#" + color_string.substr(7, 2) + color_string.substr(1, 6)
			color = Color(color_string)
		elif color_string.begins_with("rgb("):
			color_string = color_string.replace("rgb(", "").rstrip(")").strip_edges()
			var rgb_split = color_string.split(",")
			color = Color8(
				parse_integer_or_percentage(rgb_split[0]),
				parse_integer_or_percentage(rgb_split[1]),
				parse_integer_or_percentage(rgb_split[2])
			)
		elif color_string.begins_with("rgba("):
			color_string = color_string.replace("rgba(", "").rstrip(")").strip_edges()
			var rgba_split = color_string.split(",")
			color = Color8(
				parse_integer_or_percentage(rgba_split[0]),
				parse_integer_or_percentage(rgba_split[1]),
				parse_integer_or_percentage(rgba_split[2]),
				parse_integer_or_percentage(rgba_split[3])
			)
		elif color_string.begins_with("icc-color("):
			color_string = color_string.replace("icc-color(", "").rstrip(")").strip_edges()
			var color_values_split = color_string.split(",")
			var color_profile_name = color_values_split[0].strip_edges()
			var icc_value_1 = parse_number(color_values_split[1])
			var icc_value_2 = parse_number(color_values_split[2])
			var icc_value_3 = parse_number(color_values_split[3])
			var icc_value_4 = parse_number(color_values_split[4])
			# TODO - convert to sRGB (Godot doesn't currently support anything else)
		elif color_string.begins_with("cielab("):
			color_string = color_string.replace("cielab(", "").rstrip(")").strip_edges()
			var lab_split = color_string.split(",")
			var l = parse_number(lab_split[0])
			var a = parse_number(lab_split[1])
			var b = parse_number(lab_split[2])
			# TODO - convert to sRGB (Godot doesn't currently support anything else)
		elif color_string.begins_with("cielchab("):
			color_string = color_string.replace("cielchab(", "").rstrip(")").strip_edges()
			var lch_split = color_string.split(",")
			var l = parse_number(lch_split[0])
			var c = parse_number(lch_split[1])
			var h = parse_number(lch_split[2])
			# TODO - convert to sRGB (Godot doesn't currently support anything else)
		elif color_string.begins_with("icc-named-color("):
			color_string = color_string.replace("icc-named-color(", "").rstrip(")").strip_edges()
			var color_values_split = color_string.split(",")
			var color_profile_name = color_values_split[0].strip_edges()
			var color_name = color_values_split[1].strip_edges()
			# TODO - convert to sRGB (Godot doesn't currently support anything else)
		elif color_string.begins_with("device-gray("):
			color_string = color_string.replace("device-gray(", "").rstrip(")").strip_edges()
			var gray = parse_number(color_string)
			# TODO - convert to sRGB (Godot doesn't currently support anything else)
		elif color_string.begins_with("device-rgb("):
			color_string = color_string.replace("device-rgb(", "").rstrip(")").strip_edges()
			var rgb_split = color_string.split(",")
			var r = parse_number(rgb_split[0])
			var g = parse_number(rgb_split[1])
			var b = parse_number(rgb_split[2])
			# TODO - convert to sRGB (Godot doesn't currently support anything else)
		elif color_string.begins_with("device-cmyk("):
			color_string = color_string.replace("device-cmyk(", "").rstrip(")").strip_edges()
			var cmyk_split = color_string.split(",")
			var c = parse_number(cmyk_split[0])
			var m = parse_number(cmyk_split[1])
			var y = parse_number(cmyk_split[2])
			var k = parse_number(cmyk_split[3])
			# TODO - convert to sRGB (Godot doesn't currently support anything else)
		elif color_string.begins_with("device-nchannel("):
			color_string = color_string.replace("device-nchannel(", "").rstrip(")").strip_edges()
			var channel_split = color_string.split(",")
			for number_string in channel_split:
				pass
			# TODO - convert to sRGB (Godot doesn't currently support anything else)
		elif SVGValueConstant.CSS_COLOR_NAMES.has(color_string):
			color = SVGValueConstant.CSS_COLOR_NAMES[color_string]
		if color != null:
			break
	return color

# https://www.w3.org/TR/SVG2/types.html#InterfaceSVGNumberList
static func parse_number_list(number_list_string):
	var values = []
	var space_split = number_list_string.split(" ", false)
	for space_split_str in space_split:
		var comma_split = space_split_str.split(",", false)
		for value_str in comma_split:
			values.push_back(value_str.to_float())
	return values

static func parse_transform_list(transform_attr, is_2d = true):
	var transform = Transform2D() if is_2d else Transform()
	if typeof(transform_attr) != TYPE_STRING:
		transform = transform_attr
	else:
		if SVGValueConstant.NONE == transform_attr:
			transform = Transform2D() if is_2d else Transform()
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
						transform_matrix.origin -= Vector3(
							values[1],
							values[2],
							0.0
						)
						transform_matrix = transform_matrix.rotated(Vector3(0, 0, 1), deg2rad(values[0]))
						transform_matrix.origin += Vector3(
							values[1],
							values[2],
							0.0
						)
				elif transform_command.begins_with("rotate3d("):
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
				elif transform_command.begins_with("skewX("):
					var values = parse_number_list(transform_command.replace("skewX(", "").rstrip(")"))
					transform_matrix.basis[1] += transform_matrix.basis[0] * tan(deg2rad(values[0]))
				elif transform_command.begins_with("skewY("):
					var values = parse_number_list(transform_command.replace("skewY(", "").rstrip(")"))
					transform_matrix.basis[3] += transform_matrix.basis[4] * tan(deg2rad(values[0]))
			
			transform = Transform2D(transform_matrix) if is_2d else Transform(transform_matrix)
	return transform

static func relative_to_absolute_resource_url(relative_url, current_file_path):
	if relative_url.begins_with("/"):
		return "res:/" + relative_url
	elif relative_url.begins_with("res://") or relative_url.begins_with("user://"):
		return relative_url
	var current_path_split = current_file_path.split("/", true)
	var end_index = current_path_split.size() - 1
	var relative_path_split = relative_url.split("/", true)
	var start_index = 0
	for path_part in relative_path_split:
		if path_part == "..":
			start_index += 1
			end_index -= 1
		else:
			break
	var combined_path = []
	combined_path.append_array(SVGHelper.array_slice(current_path_split, 0, end_index))
	combined_path.append_array(SVGHelper.array_slice(relative_path_split, start_index))
	return "/".join(combined_path)

static func parse_d(d: String):
	d = d + "$"
	var attr_d = []
	var current_command = -1
	var current_coordinate = -1
	var current_values = ""
	var letter_regex = RegEx.new()
	letter_regex.compile("[a-zA-Z$]")
	var negative_split_regex = RegEx.new()
	negative_split_regex.compile("(?=-)")
	for c in d:
		if letter_regex.search(c) != null && c != "e":
			var values = []
			var space_split = current_values.split(" ", false)
			for space_token in space_split:
				var comma_split = space_token.split(",", false)
				for comma_token in comma_split:
					var negative_split = SVGHelper.regex_string_split("(?<!e)-", comma_token)
					var negative_multiplier = 1.0
					for negative_token in negative_split:
						if negative_token != "":
							var decimal_split = negative_token.split(".")
							values.push_back(negative_multiplier * ".".join(SVGHelper.array_slice(decimal_split, 0, 2)).to_float())
							if decimal_split.size() > 2:
								for decimal_index in range(2, decimal_split.size()):
									values.push_back(("." + str(decimal_split[decimal_index])).to_float())
						negative_multiplier = -1.0
			
			# Split out implicit commands
			var implicit_commands = []
			var use_implicit_command = -1
			var use_implicit_point_count = 0
			if [PathCommand.MOVE_TO, PathCommand.LINE_TO].has(current_command):
				use_implicit_command = PathCommand.LINE_TO
				use_implicit_point_count = 2
			elif current_command == PathCommand.HORIZONTAL_LINE_TO:
				use_implicit_command = PathCommand.HORIZONTAL_LINE_TO
				use_implicit_point_count = 1
			elif current_command == PathCommand.VERTICAL_LINE_TO:
				use_implicit_command = PathCommand.VERTICAL_LINE_TO
				use_implicit_point_count = 1
			elif current_command == PathCommand.CUBIC_BEZIER_CURVE:
				use_implicit_command = PathCommand.CUBIC_BEZIER_CURVE
				use_implicit_point_count = 6
			elif current_command == PathCommand.SMOOTH_CUBIC_BEZIER_CURVE:
				use_implicit_command = PathCommand.SMOOTH_CUBIC_BEZIER_CURVE
				use_implicit_point_count = 4
			elif current_command == PathCommand.QUADRATIC_BEZIER_CURVE:
				use_implicit_command = PathCommand.QUADRATIC_BEZIER_CURVE
				use_implicit_point_count = 4
			elif current_command == PathCommand.SMOOTH_QUADRATIC_BEZIER_CURVE:
				use_implicit_command = PathCommand.SMOOTH_QUADRATIC_BEZIER_CURVE
				use_implicit_point_count = 2
			elif current_command == PathCommand.ELLIPTICAL_ARC_CURVE:
				use_implicit_command = PathCommand.ELLIPTICAL_ARC_CURVE
				use_implicit_point_count = 7
			if use_implicit_command > -1:
				var implicit_values = SVGHelper.array_slice(values, use_implicit_point_count)
				for point_group_index in range(0, implicit_values.size(), use_implicit_point_count):
					if point_group_index + use_implicit_point_count - 1 < implicit_values.size():
						implicit_commands.push_back({
							"command": use_implicit_command,
							"coordinate_type": current_coordinate,
							"values": SVGHelper.array_slice(implicit_values, point_group_index, point_group_index + use_implicit_point_count)
						})
			attr_d.push_back({
				"command": current_command,
				"coordinate_type": current_coordinate,
				"values": values,
			})
			if implicit_commands.size() > 0:
				for implicit_command in implicit_commands:
					attr_d.push_back(implicit_command)
			current_command = -1
			current_coordinate = -1
			current_values = ""
		if c == "M":
			current_command = PathCommand.MOVE_TO
			current_coordinate = PathCoordinate.ABSOLUTE
		elif c == "m":
			current_command = PathCommand.MOVE_TO
			current_coordinate = PathCoordinate.RELATIVE
		elif c == "L":
			current_command = PathCommand.LINE_TO
			current_coordinate = PathCoordinate.ABSOLUTE
		elif c == "l":
			current_command = PathCommand.LINE_TO
			current_coordinate = PathCoordinate.RELATIVE
		elif c == "H":
			current_command = PathCommand.HORIZONTAL_LINE_TO
			current_coordinate = PathCoordinate.ABSOLUTE
		elif c == "h":
			current_command = PathCommand.HORIZONTAL_LINE_TO
			current_coordinate = PathCoordinate.RELATIVE
		elif c == "V":
			current_command = PathCommand.VERTICAL_LINE_TO
			current_coordinate = PathCoordinate.ABSOLUTE
		elif c == "v":
			current_command = PathCommand.VERTICAL_LINE_TO
			current_coordinate = PathCoordinate.RELATIVE
		elif c == "C":
			current_command = PathCommand.CUBIC_BEZIER_CURVE
			current_coordinate = PathCoordinate.ABSOLUTE
		elif c == "c":
			current_command = PathCommand.CUBIC_BEZIER_CURVE
			current_coordinate = PathCoordinate.RELATIVE
		elif c == "S":
			current_command = PathCommand.SMOOTH_CUBIC_BEZIER_CURVE
			current_coordinate = PathCoordinate.ABSOLUTE
		elif c == "s":
			current_command = PathCommand.SMOOTH_CUBIC_BEZIER_CURVE
			current_coordinate = PathCoordinate.RELATIVE
		elif c == "Q":
			current_command = PathCommand.QUADRATIC_BEZIER_CURVE
			current_coordinate = PathCoordinate.ABSOLUTE
		elif c == "q":
			current_command = PathCommand.QUADRATIC_BEZIER_CURVE
			current_coordinate = PathCoordinate.RELATIVE
		elif c == "T":
			current_command = PathCommand.SMOOTH_QUADRATIC_BEZIER_CURVE
			current_coordinate = PathCoordinate.ABSOLUTE
		elif c == "t":
			current_command = PathCommand.SMOOTH_QUADRATIC_BEZIER_CURVE
			current_coordinate = PathCoordinate.RELATIVE
		elif c == "A":
			current_command = PathCommand.ELLIPTICAL_ARC_CURVE
			current_coordinate = PathCoordinate.ABSOLUTE
		elif c == "a":
			current_command = PathCommand.ELLIPTICAL_ARC_CURVE
			current_coordinate = PathCoordinate.RELATIVE
		elif c == "Z":
			current_command = PathCommand.CLOSE_PATH
			current_coordinate = PathCoordinate.ABSOLUTE
		elif c == "z":
			current_command = PathCommand.CLOSE_PATH
			current_coordinate = PathCoordinate.RELATIVE
		else:
			current_values += c
	return attr_d

static func serialize_d_points(points):
	var ps = ""
	for point in points:
		ps += str(point.x) + "," + str(point.y) + " "
	return ps.strip_edges()

static func serialize_d(path):
	var d = ""
	for instruction in path:
		match instruction.command:
			PathCommand.MOVE_TO:
				d += " M " + serialize_d_points(instruction.points)
			PathCommand.LINE_TO:
				d += " L " + serialize_d_points(instruction.points)
			PathCommand.QUADRATIC_BEZIER_CURVE:
				d += " Q " + serialize_d_points(instruction.points)
			PathCommand.CUBIC_BEZIER_CURVE:
				d += " C " + serialize_d_points(instruction.points)
			PathCommand.CLOSE_PATH:
				d += " Z "
	return d.strip_edges()

static func serialize_point_list_as_d(points: Array):
	var d = ""
	var first = points.pop_front()
	d += "M " + serialize_d_points([first])
	for point in points:
		d += " L " + serialize_d_points([point])
	return d.strip_edges()
