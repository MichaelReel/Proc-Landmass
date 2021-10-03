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
			map[j][i] = evaluate_falloff_curve(value)
	return map

static func evaluate_falloff_curve(var value : float) -> float:
	var a : float = 3.0
	var b : float = 2.2
	
	# f(x) = x^a / (x^a + (b - b*x)^a)
	var x_to_a := pow(value, a)
	var b_min_bx_to_a := pow(b - (b * value), 1)
	return x_to_a / (x_to_a + b_min_bx_to_a)
	
