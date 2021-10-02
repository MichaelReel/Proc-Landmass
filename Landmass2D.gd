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

export (int) var noise_seed : int = NoiseLib.Defaults.zeed setget set_seed
export (Vector2) var noise_position : Vector2 = Vector2.ZERO setget set_noise_position
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

func set_seed(value : int):
	noise_seed = value
	update_texture_rect()

func set_noise_position(value : Vector2):
	noise_position = value
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

	var noise_map = NoiseLib.generate_noise_map(width, height, noise_seed, noise_position, noise_scale, octaves, persistence, lacunarity, NoiseLib.NormalizeMode.LOCAL)
	var noise_color_array : PoolByteArray
	match draw_mode:
		DRAW_MODE.NoiseMap:
			noise_color_array = NoiseLib.generate_height_array(noise_map)
		DRAW_MODE.ColorMap:
			noise_color_array = NoiseLib.generate_region_array(noise_map, terrain_types)
	var noise_texture = NoiseLib.generate_texture(width, height, noise_color_array, "Land Mass")
	self.texture = noise_texture
