extends "svg_render_element.gd"

var attr_type = "text/css" setget _set_attr_type
var attr_media = "all" setget _set_attr_media
var attr_title = "none" setget _set_attr_title

# Lifecycle

func _init():
	node_name = "style"

# Public Methods

func get_stylesheet():
	var stylesheet = []
	var is_parsing_selector = true
	var is_parsing_prop_name = true
	var current_rule = {
		"selector_paths": [],
		"selector_weights": [],
		"declarations": {},
	}
	var current_selector = ""
	var current_prop_name = ""
	var current_prop_value = ""
	for c in node_text:
		if is_parsing_selector:
			if c == "{":
				is_parsing_selector = false
				current_selector = current_selector.strip_edges()
				var paths = current_selector.split(",")
				for path in paths:
					var element_selectors = []
					var selector_weight = 0
					var element_split_regex = RegEx.new()
					element_split_regex.compile("(?=[ >+~])")
					for element_rules in element_split_regex.sub(path, "SPLIT_ME_HERE", true).split("SPLIT_ME_HERE"):
						var element_selector = {
							"is_immediate_child": false,
							"is_immediate_sibling": false,
							"is_following_sibling": false,
							"any": false,
							"node_name": null,
							"id": null,
							"class": null,
						}
						element_rules = element_rules.strip_edges()
						if element_rules.begins_with(">"):
							element_selector.is_immediate_child = true
							element_rules = element_rules.replace(">", "")
						if element_rules.begins_with("+"):
							element_selector.is_immediate_sibling = true
							element_rules = element_rules.replace("+", "")
						if element_rules.begins_with("~"):
							element_selector.is_following_sibling = true
							element_rules = element_rules.replace("~", "")
						var attr_select_split_regex = RegEx.new()
						attr_select_split_regex.compile("(?=[.#:])")
						for element_rule in attr_select_split_regex.sub(element_rules, "SPLIT_ME_HERE", true).split("SPLIT_ME_HERE"):
							if element_rule.begins_with("#"):
								element_selector.id = element_rule.replace("#", "")
								selector_weight += 100
							elif element_rule.begins_with("."):
								if element_selector.class == null:
									element_selector.class = []
								element_selector.class.push_back(element_rule.replace(".", ""))
								selector_weight += 10
							elif element_rule.begins_with(":"):
								# TODO?
								pass
							elif element_rule == "*":
								element_selector.any = true
								selector_weight += 1
							elif element_rule.strip_edges().length() > 0:
								element_selector.node_name = element_rule
								selector_weight += 1
						element_selectors.push_back(element_selector)
					current_rule.selector_paths.push_back(element_selectors)
					current_rule.selector_weights.push_back(selector_weight)
				current_selector = ""
			else:
				current_selector += c
		elif is_parsing_prop_name:
			if c == "}": # Malformed syntax
				is_parsing_selector = true
				current_prop_name = ""
				current_prop_value = ""
				stylesheet.push_back(current_rule)
				current_rule = {
					"selector_paths": [],
					"selector_weights": [],
					"declarations": {},
				}
			elif c == ":":
				is_parsing_prop_name = false
				current_prop_name = SVGAttributeParser.to_snake_case(current_prop_name.strip_edges())
			else:
				current_prop_name += c
		else: # Parsing prop value
			if c == "}":
				is_parsing_selector = true
				is_parsing_prop_name = true
				current_prop_value = current_prop_value.strip_edges()
				current_rule.declarations[current_prop_name] = current_prop_value
				stylesheet.push_back(current_rule)
				current_rule = {
					"selector_paths": [],
					"selector_weights": [],
					"declarations": {},
				}
				current_prop_name = ""
				current_prop_value = ""
			elif c == ";":
				is_parsing_prop_name = true
				current_prop_value = current_prop_value.strip_edges()
				current_rule.declarations[current_prop_name] = current_prop_value
				current_prop_name = ""
				current_prop_value = ""
			else:
				current_prop_value += c
	
	return stylesheet

# Getters / Setters

func _set_attr_type(type):
	attr_type = type
	apply_props()

func _set_attr_media(media):
	attr_media = media
	apply_props()
	
func _set_attr_title(title):
	attr_title = title
	apply_props()
