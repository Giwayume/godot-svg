extends Resource
class_name SVGClockValue

export(float) var milliseconds = null

func _init(attribute: String):
	milliseconds = 0.0
	attribute = attribute.strip_edges()
	var multiplier = 0.0
	if attribute.ends_with("ms"):
		multiplier = 1.0
	elif attribute.ends_with("s"):
		multiplier = 1000.0
	elif attribute.ends_with("m"):
		multiplier = 60000.0
	elif attribute.ends_with("h"):
		multiplier = 3600000.0
	var letters_regex = RegEx.new()
	letters_regex.compile("[a-zA-Z]")
	attribute = letters_regex.sub(attribute, "", true)
	
	if multiplier == 0.0:
		var time_delimiter_regex = RegEx.new()
		time_delimiter_regex.compile("\\[:.]+")
		var search_results = time_delimiter_regex.search_all(attribute)
		search_results.invert()
		var multipliers = [1.0, 1000.0, 60000.0, 3600000.0]
		if attribute.find(".") == -1:
			multipliers.pop_front()
		for search_result in search_results:
			milliseconds += search_result.get_string().to_float() * multipliers.pop_front()
	else:
		milliseconds = attribute.to_float() * multiplier

func get_milliseconds() -> float:
	return milliseconds

func get_seconds() -> float:
	return milliseconds / 1000.0

func get_minutes() -> float:
	return milliseconds / 60000.0

func get_hours() -> float:
	return milliseconds / 3600000.0

static func is_clock_value(attribute: String):
	var clock_value_regex = RegEx.new()
	clock_value_regex.compile("^([0-9]*?(h|m|s|ms)|([0-9]{2,}:)?([0-9]{2}:)?[0-9]{2}(.[0-9]{3})?|[0-9]{1,})$")
	return clock_value_regex.search(attribute) != null
