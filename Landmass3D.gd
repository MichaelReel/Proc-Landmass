tool
extends MeshInstance

class_name Landmass3D

export (int) var noise_seed : int = NoiseLib.Defaults.zeed setget set_seed
export (float, EXP, 1.0, 2048.0) var period : float = NoiseLib.Defaults.period setget set_period
export (int) var octaves : int = NoiseLib.Defaults.octaves setget set_octaves
export (float, 0.0, 1.0, 0.05) var persistence : float = NoiseLib.Defaults.persistence setget set_persistence
export (float) var lacunarity : float = NoiseLib.Defaults.lacunarity setget set_lacunarity
export (int, 0, 5) var level_of_detail : int = NoiseLib.Defaults.level_of_detail setget set_level_of_detail
export (float, 0.0, 2.0, 0.05) var terrain_multiplier : float = NoiseLib.Defaults.terrain_multiplier setget set_terrain_multiplier
export (Curve) var terrain_height_curve : Curve = NoiseLib.Defaults.default_terrain_curve()
export (Dictionary) var terrain_types : Dictionary = NoiseLib.Defaults.default_terrain_types() setget set_terrain_types

var map_data : ChunkLib.MapData

## Tool functions
func _ready():
	editor_updates()

func editor_updates():
	if Engine.editor_hint:
		update_terrain_data()
		update_terrain_mesh()

func set_seed(value : int):
	noise_seed = value
	editor_updates()

func set_period(value : float):
	period = value
	editor_updates()

func set_octaves(value : int):
	octaves = value
	editor_updates()

func set_persistence(value : float):
	persistence = value
	editor_updates()

func set_lacunarity(value : float):
	lacunarity = value
	editor_updates()

func set_terrain_types(value : Dictionary):
	terrain_types = value
	editor_updates()

func set_level_of_detail(value : int):
	level_of_detail = value
	editor_updates()

func set_terrain_multiplier(value : float):
	terrain_multiplier = value
	editor_updates()

func update_terrain_data():
	map_data = ChunkLib.generate_map_data(
		NoiseLib.Defaults.map_chunk_size, 
		NoiseLib.Defaults.map_chunk_size, 
		noise_seed,
		period, 
		octaves, 
		persistence, 
		lacunarity,
		terrain_types
	)

func update_terrain_mesh():
	var map_scale : Vector3 = Vector3(1.0, terrain_multiplier, 1.0)
	mesh = ChunkLib.generate_terrain_mesh(map_data.height_map, map_scale, terrain_height_curve, level_of_detail)
	var spatial_material : Material = mesh.surface_get_material(0)
	if not spatial_material is SpatialMaterial:
		spatial_material = SpatialMaterial.new()
	spatial_material.albedo_texture = map_data.texture_map
	mesh.surface_set_material(0, spatial_material)

func set_values(nseed : int, period : float, oct : int, per : float, lac : float, lod : int, mult : float, curve : Curve, ttypes : Dictionary):
	noise_seed = nseed
	period = period
	octaves = oct
	persistence = per
	lacunarity = lac
	level_of_detail = lod
	terrain_multiplier = mult
	terrain_height_curve = curve
	terrain_types = ttypes


