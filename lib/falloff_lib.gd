extends Object

class_name FalloffLib

static func generate_falloff_map(width: int, height: int) -> Array:
	var map := Array()
	map.resize(height)
	for j in range(height):
		map[j] = Array()
		map[j].resize(width)
		for i in range(width):
			var x : float = i / float(width) * 2 - 1
			var y : float = j / float(height) * 2 - 1
			
			var value : float = max(abs(x), abs(y))
			map[j][i] = value
	return map
