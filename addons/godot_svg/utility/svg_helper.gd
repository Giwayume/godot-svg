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
