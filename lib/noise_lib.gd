extends Reference

class_name NoiseLib


static func generate_noise_map(width: int, height: int, nseed: int, period: float, octaves: int, persistence: float, lacunarity: float) -> Array:
	var noise_base : OpenSimplexNoise = OpenSimplexNoise.new()

	# Configure noise
	noise_base.seed = nseed
	noise_base.set_octaves(octaves)
	noise_base.set_period(period)
	noise_base.set_persistence(persistence)
	noise_base.set_lacunarity(lacunarity)
	
	var min_noise_height = 1.0
	var max_noise_height = -1.0
	
	var noise_map : Array = []
	for y in range(height):
		noise_map.append([])
		noise_map[y].resize(width)
		for x in range(width):
			var base_noise := noise_base.get_noise_2d(x, y)
			noise_map[y][x] = base_noise
			min_noise_height = min(min_noise_height, base_noise)
			max_noise_height = max(max_noise_height, base_noise)
	
	for y in range(0, height):
		for x in range(0, width):
			noise_map[y][x] = inverse_lerp(min_noise_height, max_noise_height, noise_map[y][x])
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
