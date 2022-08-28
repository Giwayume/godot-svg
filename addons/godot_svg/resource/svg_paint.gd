extends Resource
class_name SVGPaint

export(Color) var color = null
export(String) var url = null

func _init(attribute: String):
	if attribute.begins_with("url(") and attribute.ends_with(")"):
		url = attribute.replace("url(", "").rstrip(")").strip_edges()
	else:
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
		else:
			color = null
