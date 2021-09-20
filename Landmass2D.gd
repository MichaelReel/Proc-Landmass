extends TextureRect

enum DRAW_MODE { NoiseMap, ColorMap }
export(DRAW_MODE) var draw_mode = DRAW_MODE.NoiseMap

export (float) var noise_scale : float = 128.0
export (int) var octives : int = 4
export (float, 0.0, 1.0) var persistence : float = 0.5
export (float) var lacunarity : float = 2.0
export (Array, Resource) var terrain_types : Array


func _ready():
	var width : int = rect_size.x
	var height : int = rect_size.y

	var noise_map = generate_noise_map(width, height, 3, noise_scale, octives, persistence, lacunarity)
	var noise_color_array : PoolByteArray
	match draw_mode:
		DRAW_MODE.NoiseMap:
			noise_color_array = generate_height_array(noise_map)
		DRAW_MODE.ColorMap:
			noise_color_array = generate_region_array(noise_map)
	var noise_image = generate_image(width, height, noise_color_array)
	display_image(noise_image)

func generate_noise_map(width: int, height: int, nseed: int, period: float, octaves: int, persistence: float, lacunarity: float) -> Array:
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
	for y in range(0, height):
		noise_map.append([])
		noise_map[y].resize(width)
		for x in range(0, width):
			var base_noise := noise_base.get_noise_2d(x, y)
			noise_map[y][x] = base_noise
			min_noise_height = min(min_noise_height, base_noise)
			max_noise_height = max(max_noise_height, base_noise)
	
	for y in range(0, height):
		for x in range(0, width):
			noise_map[y][x] = inverse_lerp(min_noise_height, max_noise_height, noise_map[y][x])
	return noise_map

func generate_height_array(noise_map : Array) -> PoolByteArray:
	var bytes := PoolByteArray()
	for row in noise_map:
		for map_height in row:
			var color_byte : int = lerp(0, 255, map_height)
			bytes.append(color_byte)
			bytes.append(color_byte)
			bytes.append(color_byte)
			bytes.append(255)
	return bytes

func generate_region_array(noise_map : Array) -> PoolByteArray:
	var bytes := PoolByteArray()
	for row in noise_map:
		for map_height in row:
			for region in terrain_types:
				if map_height <= region.height:
					bytes.append(region.color.r8)
					bytes.append(region.color.g8)
					bytes.append(region.color.b8)
					bytes.append(region.color.a8)
					break
	return bytes

func generate_image(width, height, noise_color_array: PoolByteArray) -> Image:
	var noise_image : Image = Image.new()
	noise_image.create_from_data(width, height, false, Image.FORMAT_RGBA8, noise_color_array)
	return noise_image
	
func display_image(noise_image : Image):
	var imageTexture := ImageTexture.new()
	imageTexture.create_from_image(noise_image)
	self.texture = imageTexture
	imageTexture.resource_name = "Land Mass"
