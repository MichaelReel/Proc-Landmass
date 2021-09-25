tool
extends MeshInstance

class_name Landmass3D

const map_chunk_size : int = 65
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

export (int) var noise_seed : int = 3 setget set_seed
export (float, EXP, 1.0, 2048.0) var noise_scale : float = 64.0 setget set_period
export (int) var octaves : int = 4 setget set_octaves
export (float, 0.0, 1.0, 0.05) var persistence : float = 0.5 setget set_persistence
export (float) var lacunarity : float = 2.0 setget set_lacunarity
export (int, 0, 5) var level_of_detail : int = 0 setget set_level_of_detail
export (float, 0.0, 2.0, 0.05) var terrain_multiplier : float = 1.0 setget set_terrain_multiplier
export (Curve) var terrain_height_curve : Curve = default_terrain_curve()

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
	update_terrain_mesh()

func set_seed(value : int):
	noise_seed = value
	update_terrain_mesh()

func set_period(value : float):
	noise_scale = value
	update_terrain_mesh()

func set_octaves(value : int):
	octaves = value
	update_terrain_mesh()

func set_persistence(value : float):
	persistence = value
	update_terrain_mesh()

func set_lacunarity(value : float):
	lacunarity = value
	update_terrain_mesh()

func set_terrain_types(value : Dictionary):
	terrain_types = value
	update_terrain_mesh()

func set_level_of_detail(value : int):
	level_of_detail = value
	update_terrain_mesh()

func set_terrain_multiplier(value : float):
	terrain_multiplier = value
	update_terrain_mesh()

func update_terrain_mesh():
	var map_data = ChunkLib.generate_map_data(
		map_chunk_size, 
		map_chunk_size, 
		noise_seed,
		noise_scale, 
		octaves, 
		persistence, 
		lacunarity,
		terrain_types
	)
	var map_scale : Vector3 = Vector3(scale.x, scale.y * terrain_multiplier, scale.z)
	mesh = ChunkLib.generate_terrain_mesh(map_data.height_map, map_scale, terrain_height_curve, level_of_detail)
	var spatial_material : Material = mesh.surface_get_material(0)
	if not spatial_material is SpatialMaterial:
		spatial_material = SpatialMaterial.new()
	spatial_material.albedo_texture = map_data.texture_map
	mesh.surface_set_material(0, spatial_material)



