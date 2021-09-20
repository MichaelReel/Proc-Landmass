tool
extends TextureRect

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

enum DRAW_MODE { NoiseMap, ColorMap }
export(DRAW_MODE) var draw_mode = DRAW_MODE.NoiseMap setget set_draw_mode
export (float, 1.0, 2048.0) var noise_scale : float = 64.0 setget set_period
export (int) var octaves : int = 4 setget set_octaves
export (float, 0.0, 1.0) var persistence : float = 0.5 setget set_persistence
export (float) var lacunarity : float = 2.0 setget set_lacunarity
export (Dictionary) var terrain_types : Dictionary = {
	0.3: regions["Water Deep"],
	0.4: regions["Water Shallow"],
	0.45: regions["Sand"],
	0.55: regions["Grass 1"],
	0.6: regions["Grass 2"],
	0.7: regions["Rock 1"],
	0.9: regions["Rock 2"],
	1.0: regions["Snow"],
} setget set_terrain_types


func _ready():
	update_texture_rect()

func set_draw_mode(value):
	draw_mode = value
	update_texture_rect()

func set_period(value : float):
	noise_scale = value
	update_texture_rect()

func set_octaves(value : int):
	octaves = value
	update_texture_rect()

func set_persistence(value : float):
	persistence = value
	update_texture_rect()

func set_lacunarity(value : float):
	lacunarity = value
	update_texture_rect()

func set_terrain_types(value : Dictionary):
	terrain_types = value
	update_texture_rect()

func update_texture_rect():
	var width : int = rect_size.x
	var height : int = rect_size.y

	var noise_map = generate_noise_map(width, height, 3, noise_scale, octaves, persistence, lacunarity)
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
			for height in terrain_types:
				if map_height <= height:
					var color : Color = terrain_types[height]
					bytes.append(color.r8)
					bytes.append(color.g8)
					bytes.append(color.b8)
					bytes.append(color.a8)
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

func create_region(n : String, h : float, c : Color) -> TerrainType:
	var region : TerrainType = TerrainType.new()
	region.terrain_name = n
	region.height = h
	region.color = c
	return region
