extends Resource
class_name SVGPaint

var color = null # Color
var url = null # String

func _init(attribute: String):
	if attribute.begins_with("url(") and attribute.ends_with(")"):
		url = attribute.replace("url(", "").rstrip(")").strip_edges()
	else:
		color = SVGAttributeParser.parse_css_color(attribute)
