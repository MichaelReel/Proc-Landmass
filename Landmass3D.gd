tool
extends Spatial

class_name Landmass3D

const lod_levels := 6

export (int) var noise_seed : int = NoiseLib.Defaults.zeed setget set_seed
export (Vector2) var noise_position : Vector2 = Vector2.ZERO setget set_noise_position
export (float, EXP, 1.0, 2048.0) var period : float = NoiseLib.Defaults.period setget set_period
export (int) var octaves : int = NoiseLib.Defaults.octaves setget set_octaves
export (float, 0.0, 1.0, 0.05) var persistence : float = NoiseLib.Defaults.persistence setget set_persistence
export (float) var lacunarity : float = NoiseLib.Defaults.lacunarity setget set_lacunarity
export (int, 0, 5) var level_of_detail : int = NoiseLib.Defaults.level_of_detail setget set_level_of_detail
export (float, 0.0, 2.0, 0.05) var terrain_multiplier : float = NoiseLib.Defaults.terrain_multiplier setget set_terrain_multiplier
export (Curve) var terrain_height_curve : Curve = NoiseLib.Defaults.default_terrain_curve()
export (Dictionary) var terrain_types : Dictionary = NoiseLib.Defaults.default_terrain_types() setget set_terrain_types
export (bool) var apply_falloff : bool = false setget set_apply_falloff

var map_data : ChunkLib.MapData
var lod_meshes : Array = []
var falloff_map : Array = []


func _init():
	# min and max LODs must be literals in export above (fix in 4.0 maybe)
	lod_meshes.resize(lod_levels)
	for lod in range(lod_levels):
		lod_meshes[lod] = LODMesh.new(lod)
		lod_meshes[lod].set_visible(false)
		add_child(lod_meshes[lod])

## Tool functions
func _ready():
	editor_updates()

func editor_updates():
	if Engine.editor_hint:
		update_terrain_data()
		for lod in range(lod_levels):
			lod_meshes[lod].set_visible(false)
			update_terrain_mesh(lod)
		lod_meshes[level_of_detail].set_visible(true)

func set_seed(value : int):
	noise_seed = value
	editor_updates()

func set_noise_position(value : Vector2):
	noise_position = value
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
	lod_meshes[level_of_detail].set_visible(false)
	level_of_detail = value
	editor_updates()
	lod_meshes[level_of_detail].set_visible(true)

func set_terrain_multiplier(value : float):
	terrain_multiplier = value
	editor_updates()

func set_apply_falloff(value : bool):
	apply_falloff = value
	if apply_falloff and falloff_map.empty():
		falloff_map = FalloffLib.generate_falloff_map(
			NoiseLib.Defaults.map_chunk_size,
			NoiseLib.Defaults.map_chunk_size
		)
	editor_updates()

func update_terrain_data():
	map_data = ChunkLib.generate_map_data(
		NoiseLib.Defaults.map_chunk_size, 
		NoiseLib.Defaults.map_chunk_size, 
		noise_seed,
		noise_position,
		period, 
		octaves, 
		persistence, 
		lacunarity,
		terrain_types,
		falloff_map
	)

func update_terrain_mesh(lod : int):
	lod_meshes[lod].update_terrain_mesh(
		map_data,
		terrain_multiplier,
		terrain_height_curve
	)

func set_values(nseed : int, npos: Vector2, period_ : float, oct : int, persistence_ : float, lac : float, lod : int, mult : float, curve : Curve, ttypes : Dictionary):
	noise_seed = nseed
	noise_position = npos
	period = period_
	octaves = oct
	persistence = persistence_
	lacunarity = lac
	level_of_detail = lod
	terrain_multiplier = mult
	terrain_height_curve = curve
	terrain_types = ttypes

func has_lod_requested(lod : int):
	return lod_meshes[lod].mesh_requested

func has_lod_available(lod : int):
	return lod_meshes[lod].has_mesh

class LODMesh:
	extends MeshInstance

	var lod : int
	var mesh_requested : bool
	var has_mesh : bool
	
	func _init(level_of_detail : int):
		lod = level_of_detail
		mesh_requested = false
		has_mesh = false
	
	func update_terrain_mesh(
		map_data: ChunkLib.MapData, 
		terrain_multiplier : float,
		terrain_height_curve : Curve
	):
		if mesh_requested:
			return
		mesh_requested = true
		var map_scale : Vector3 = Vector3(1.0, terrain_multiplier, 1.0)
		mesh = ChunkLib.generate_terrain_mesh(
			map_data.height_map,
			map_scale,
			terrain_height_curve,
			lod
		)
		var spatial_material : Material = mesh.surface_get_material(0)
		if not spatial_material is SpatialMaterial:
			spatial_material = SpatialMaterial.new()
		spatial_material.albedo_texture = map_data.texture_map
		mesh.surface_set_material(0, spatial_material)
		has_mesh = true


class ChunkRequest:
	var handler_thread : Thread
	var chunk_coord : Vector2
	var land_chunk : Spatial
	
	func _init(coord : Vector2, chunk : Spatial):
		chunk_coord = coord
		land_chunk = chunk
