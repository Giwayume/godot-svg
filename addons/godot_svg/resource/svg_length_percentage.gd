extends Resource
class_name SVGLengthPercentage

export(float) var length = null
export(float) var percentage = null

func _init(attribute: String):
	var is_percentage = false
	if attribute.find("%") > -1:
		attribute = attribute.replace("%", "")
		is_percentage = true
	if is_percentage:
		percentage = attribute.to_float() / 100
	else:
		length = attribute.to_float()

func get_length(percentage_size: float = 1, offset: float = 0):
	if length != null:
		return length
	elif percentage != null:
		return offset + (percentage_size * percentage)
	else:
		return 0

func get_normalized_length(percentage_size: float = 1, offset: float = 0):
	var length = get_length(percentage_size, offset)
	return (length - offset) / percentage_size

static func calculate_normalized_length(length: float, percentage_size: float = 1, offset: float = 0):
	return (length - offset) / percentage_size
