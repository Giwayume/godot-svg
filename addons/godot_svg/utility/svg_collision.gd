class_name SVGCollision

class Quadtree:

	const MAX_OBJECTS = 10
	const MAX_LEVELS = 100

	var level: int = 0
	var objects: Array = []
	var object_bounds: Array = []
	var bounds: Rect2
	var nodes: Array = []

	func _init(level: int, bounds: Rect2):
		self.level = level
		self.bounds = bounds
		objects = []
		object_bounds = []
		nodes = [null, null, null, null]
	
	func clear():
		objects.clear()
		object_bounds.clear()
		for i in range(0, nodes.size()):
			if nodes[i] != null:
				nodes[i].clear()
				nodes[i] = null
	
	func split():
		var sub_width: int = int(bounds.size.x) / 2
		var sub_height: int = int(bounds.size.y) / 2
		var x: int = int(bounds.position.x)
		var y: int = int(bounds.position.y)
		
		nodes[0] = Quadtree.new(level + 1, Rect2(x + sub_width, y, sub_width, sub_height))
		nodes[1] = Quadtree.new(level + 1, Rect2(x, y, sub_width, sub_height))
		nodes[2] = Quadtree.new(level + 1, Rect2(x, y + sub_height, sub_width, sub_height))
		nodes[3] = Quadtree.new(level + 1, Rect2(x + sub_width, y + sub_height, sub_width, sub_height))
	
	func get_insertion_index(p_rect: Rect2) -> int:
		var index: int = -1
		var vertical_midpoint: float = bounds.position.x + (bounds.size.x / 2)
		var horizontal_midpoint: float = bounds.position.y + (bounds.size.y / 2)
		var top_quadrant: bool = (p_rect.position.y < horizontal_midpoint and p_rect.position.y + p_rect.size.y < horizontal_midpoint)
		var bottom_quadrant: bool = p_rect.position.y > horizontal_midpoint
		if p_rect.position.x < vertical_midpoint and p_rect.position.x + p_rect.size.x < vertical_midpoint:
			if top_quadrant:
				index = 1
			elif bottom_quadrant:
				index = 2
		elif p_rect.position.x > vertical_midpoint:
			if top_quadrant:
				index = 0
			elif bottom_quadrant:
				index = 3
		return index
	
	func find_indices(p_rect: Rect2) -> PoolIntArray:
		var indices = PoolIntArray()
		if nodes[0] != null:
			for i in range(0, nodes.size()):
				var node = nodes[i]
				if (not(
					p_rect.position.x > node.bounds.position.x + node.bounds.size.x or
					p_rect.position.x + p_rect.size.x < node.bounds.position.x or
					p_rect.position.y > node.bounds.position.y + node.bounds.size.y or
					p_rect.position.y + p_rect.size.y < node.bounds.position.y
				)):
					indices.append(i)
		return indices
	
	func insert(object, p_rect: Rect2):
		if nodes[0] != null:
			var index: int = get_insertion_index(p_rect)
			if index != -1:
				nodes[index].insert(object, p_rect)
				return
		objects.push_back(object)
		object_bounds.push_back(p_rect)
		if objects.size() > MAX_OBJECTS and level < MAX_LEVELS:
			if nodes[0] == null:
				split()
			var i: int = 0
			while i < objects.size():
				var index: int = get_insertion_index(object_bounds[i])
				if index != -1:
					nodes[index].insert(
						objects.pop_at(i),
						object_bounds.pop_at(i)
					)
				else:
					i += 1
	
	func retrieve(p_rect: Rect2, return_objects = []):
		var indices = find_indices(p_rect)
		for index in indices:
			return_objects = nodes[index].retrieve(p_rect, return_objects)
		return_objects.append_array(objects)
		return return_objects
	


