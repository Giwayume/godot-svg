extends "svg_render_element.gd"

# Animation timing attributes
var attr_begin = [SVGClockValue.new("0s")] setget _set_attr_begin
var attr_dur = SVGValueConstant.INDEFINITE setget _set_attr_dur
var attr_end = [] setget _set_attr_end
var attr_min = SVGClockValue.new("0") setget _set_attr_min
var attr_max = null setget _set_attr_max
var attr_restart = SVGValueConstant.ALWAYS setget _set_attr_restart
var attr_repeat_count = null setget _set_attr_repeat_count
var attr_repeat_dur = null setget _set_attr_repeat_dur
# var attr_fill is overloaded

# Animation value attributes
var attr_calc_mode = SVGValueConstant.LINEAR setget _set_attr_calc_mode
var attr_values = [] setget _set_attr_values
var attr_key_times = [] setget _set_attr_key_times
var attr_key_splines = [] setget _set_attr_key_splines
var attr_from = null setget _set_attr_from
var attr_to = null setget _set_attr_to
var attr_by = null setget _set_attr_by

# Other animation attributes
var attr_attribute_name = null setget _set_attr_attribute_name
var attr_additive = SVGValueConstant.REPLACE setget _set_attr_additive
var attr_accumulate = SVGValueConstant.NONE setget _set_attr_accumulate

# Lifecycle

func _init():
	node_name = "animate"

# Getters / Setters

func _set_attr_begin(begin):
	if typeof(begin) != TYPE_STRING:
		attr_begin = begin
	else:
		var values = begin.split(";", false)
		attr_begin = []
		for value in values:
			if SVGClockValue.is_clock_value(value):
				attr_begin.push_back(SVGClockValue.new(value))
			else:
				attr_begin.push_back(value)
	apply_props()

func _set_attr_dur(dur):
	if typeof(dur) != TYPE_STRING:
		attr_dur = dur
	else:
		if SVGClockValue.is_clock_value(dur):
			attr_dur = SVGClockValue.new(dur)
		else:
			attr_dur = dur
	apply_props()

func _set_attr_end(end):
	if typeof(end) != TYPE_STRING:
		attr_end = end
	else:
		var values = end.split(";", false)
		attr_end = []
		for value in values:
			if SVGClockValue.is_clock_value(value):
				attr_end.push_back(SVGClockValue.new(value))
			else:
				attr_end.push_back(value)
	apply_props()

func _set_attr_min(new_min):
	if typeof(new_min) != TYPE_STRING:
		attr_min = new_min
	else:
		if SVGClockValue.is_clock_value(new_min):
			attr_min = SVGClockValue.new(new_min)
		else:
			attr_min = null
	apply_props()

func _set_attr_max(new_max):
	if typeof(new_max) != TYPE_STRING:
		attr_max = new_max
	else:
		if SVGClockValue.is_clock_value(new_max):
			attr_max = SVGClockValue.new(new_max)
		else:
			attr_max = null
	apply_props()

func _set_attr_restart(restart):
	attr_restart = restart
	apply_props()

func _set_attr_repeat_count(repeat_count):
	attr_repeat_count = repeat_count
	apply_props()

func _set_attr_repeat_dur(repeat_dur):
	if typeof(repeat_dur) != TYPE_STRING:
		attr_repeat_dur = repeat_dur
	else:
		if SVGClockValue.is_clock_value(repeat_dur):
			attr_repeat_dur = SVGClockValue.new(repeat_dur)
		else:
			attr_repeat_dur = null
	apply_props()

func _set_attr_fill(fill):
	attr_fill = fill
	apply_props()

func _set_attr_calc_mode(calc_mode):
	attr_calc_mode = calc_mode
	apply_props()

func _set_attr_values(values):
	if typeof(values) != TYPE_STRING:
		attr_values = values
	else:
		attr_values = values.split(";", false)
	apply_props()

func _set_attr_key_times(key_times):
	if typeof(key_times) != TYPE_STRING:
		attr_key_times = key_times
	else:
		if key_times == SVGValueConstant.NONE:
			attr_key_times = []
		else:
			attr_key_times = []
			var key_times_split = key_times.split(";", false)
			for key_time in key_times_split:
				attr_key_times.push_back(key_time.to_float())
	apply_props()

func _set_attr_key_splines(key_splines):
	if typeof(key_splines) != TYPE_STRING:
		attr_key_splines = key_splines
	else:
		if key_splines == SVGValueConstant.NONE:
			attr_key_splines = []
		else:
			attr_key_splines = []
			var key_splines_split = key_splines.split(";", false)
			for key_spline in key_splines_split:
				var key_spline_values = []
				var key_spline_split_regex = RegEx.new()
				key_spline_split_regex.compile("\\S+")
				for key_spline_value in key_spline_split_regex.search_all(key_spline):
					key_spline_values.push_back(key_spline_value.get_string().to_float())
				attr_key_splines.push_back(key_spline_values)
	apply_props()

func _set_attr_from(from):
	attr_from = from
	apply_props()

func _set_attr_to(to):
	attr_to = to
	apply_props()

func _set_attr_by(by):
	attr_by = by
	apply_props()

func _set_attr_attribute_name(attribute_name):
	attr_attribute_name = attribute_name
	apply_props()

func _set_attr_additive(additive):
	attr_additive = additive
	apply_props()

func _set_attr_accumulate(accumulate):
	attr_accumulate = accumulate
	apply_props()
