extends Object

class_name NoiseLib

enum NormalizeMode {LOCAL, GLOBAL}

static func generate_noise_map(
	width: int, 
	height: int, 
	nseed: int,
	npos: Vector2,
	period: float, 
	octaves: int, 
	persistence: float, 
	lacunarity: float,
	normalize_mode: int,
	falloff_map = null
) -> Array:
	var noise_base : OpenSimplexNoise = OpenSimplexNoise.new()

	# Configure noise
	noise_base.seed = nseed
	noise_base.set_octaves(octaves)
	noise_base.set_period(period)
	noise_base.set_persistence(persistence)
	noise_base.set_lacunarity(lacunarity)
	
	# These are estimates
	var min_possible_global_height : float = -0.71
	var max_possible_global_height : float = 0.75
	# These will be adjusted
	var min_local_noise_height : float = 1.0
	var max_local_noise_height : float = -1.0
	
	var noise_map : Array = []
	for y in range(height):
		noise_map.append([])
		noise_map[y].resize(width)
		for x in range(width):
			var base_noise := noise_base.get_noise_2d(x + npos.x, y + npos.y)
			if falloff_map != null:
				base_noise -= falloff_map[y][x]
				base_noise = clamp(base_noise, -1.0, 1.0)
			noise_map[y][x] = base_noise
			min_local_noise_height = min(min_local_noise_height, base_noise)
			max_local_noise_height = max(max_local_noise_height, base_noise)
	
	var min_height : float = min_local_noise_height
	var max_height : float = max_local_noise_height
	if normalize_mode == NormalizeMode.GLOBAL:
		min_height = min_possible_global_height
		max_height = max_possible_global_height
	
	for y in range(0, height):
		for x in range(0, width):
			noise_map[y][x] = inverse_lerp(min_height, max_height, noise_map[y][x])
	return noise_map


static func generate_height_array(noise_map : Array) -> PoolByteArray:
	var bytes := PoolByteArray()
	for row in noise_map:
		for map_height in row:
			var color_byte : int = lerp(0, 255, map_height)
			bytes.append(color_byte)
			bytes.append(color_byte)
			bytes.append(color_byte)
			bytes.append(255)
	return bytes


static func generate_region_array(noise_map : Array, height_color_map: Dictionary) -> PoolByteArray:
	var bytes := PoolByteArray()
	for row in noise_map:
		for map_height in row:
			for height in height_color_map:
				if map_height <= height:
					var color : Color = height_color_map[height]
					bytes.append(color.r8)
					bytes.append(color.g8)
					bytes.append(color.b8)
					bytes.append(color.a8)
					break
	return bytes


static func generate_texture(width : int, height : int, noise_color_array : PoolByteArray, texture_name : String) -> Texture:
	var noise_image : Image = Image.new()
	noise_image.create_from_data(width, height, false, Image.FORMAT_RGBA8, noise_color_array)
	var noise_texture := ImageTexture.new()
	noise_texture.create_from_image(noise_image)
	noise_texture.resource_name = texture_name
	noise_texture.set_flags(noise_texture.get_flags() & ~Texture.FLAG_FILTER)
	return noise_texture


class Defaults:
	const map_chunk_size : int = 65
	const zeed : int = 3
	const period : float = float(map_chunk_size - 1)
	const octaves : int = 4
	const persistence : float = 0.55
	const lacunarity : float = 2.5
	const level_of_detail : int = 0
	const terrain_multiplier : float = 10.0 / float(map_chunk_size - 1)
	const regions = {
		"Water Deep": Color(0.0, 0.25, 1.0),
		"Water Shallow": Color(0.0, 0.5, 1.0),
		"Sand": Color(0.94, 0.9, 0.55),
		"Grass 1": Color(0.16, 0.66, 0.16),
		"Grass 2": Color(0.08, 0.42, 0.08),
		"Rock 1": Color(0.37, 0.24, 0.11),
		"Rock 2": Color(0.3, 0.2, 0.1),
		"Snow": Color(0.9, 0.9, 0.9),
	}

	static func default_terrain_curve() -> Curve:
		var terrain_curve = Curve.new()
		terrain_curve.add_point(Vector2(0.0, 0.0))
		terrain_curve.add_point(Vector2(0.4, 0.0))
		terrain_curve.add_point(Vector2(1.0, 1.0))
		return terrain_curve

	static func default_terrain_types() -> Dictionary:
		var types : Dictionary = {
			0.3: regions["Water Deep"],
			0.4: regions["Water Shallow"],
			0.45: regions["Sand"],
			0.55: regions["Grass 1"],
			0.6: regions["Grass 2"],
			0.7: regions["Rock 1"],
			0.9: regions["Rock 2"],
			1.0: regions["Snow"],
		}
		return types

	static func default_lod_distances() -> Array:
		var levels : Array = [0, 64, 128, 192, 256, 320]
		return levels

