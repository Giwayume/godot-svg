class_name SVGHelper

# SANE array slicing where end is non-inclusive, like every other SANE language out there
static func array_slice(array, start = null, end = null, step = null):
	var stop = array.size()
	var sliced = []
	if step == null:
		step = 1
	if start == null:
		return array
	if start < 0:
		start = start + array.size()
	if end != null:
		if end >= 0:
			stop = min(array.size(), end)
		else:
			stop = array.size() + end
	for i in range(start, stop, step):
		sliced.push_back(array[i])
	return sliced

static func array_add(array, number):
	for i in range(0, array.size()):
		array[i] += number
	return array

static func array_sum(array):
	var sum = 0.0
	for i in range(0, array.size()):
		sum += float(array[i])
	return sum

static func regex_string_split(regex_split_match: String, search: String, allow_empty = true) -> Array:
	var result = []
	var regex = RegEx.new()
	regex.compile(regex_split_match)
	var last_match_index = 0
	for regex_match in regex.search_all(search):
		var start = regex_match.get_start()
		if start != last_match_index or allow_empty:
			result.push_back(
				search.substr(last_match_index, start - last_match_index)
			)
		last_match_index = regex_match.get_end()
	if last_match_index != search.length() or allow_empty:
		result.push_back(
			search.substr(last_match_index, search.length() - last_match_index)
		)
	return result

static func get_point_list_bounds(points):
	var left = INF
	var right = -INF
	var top = INF
	var bottom = -INF
	for point in points:
		if point.x < left:
			left = point.x
		if point.x > right:
			right = point.x
		if point.y < top:
			top = point.y
		if point.y > bottom:
			bottom = point.y
	return Rect2(left, top, right - left, bottom - top)
