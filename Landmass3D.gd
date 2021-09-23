tool
extends MeshInstance

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

export (float, EXP, 1.0, 2048.0) var noise_scale : float = 64.0 setget set_period
export (int) var octaves : int = 4 setget set_octaves
export (float, 0.0, 1.0, 0.05) var persistence : float = 0.5 setget set_persistence
export (float) var lacunarity : float = 2.0 setget set_lacunarity
export (int) var sample_width : int = 50 setget set_width
export (int) var sample_height : int = 50 setget set_height
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

func set_width(value : int):
	sample_width = value
	update_terrain_mesh()

func set_height(value : int):
	sample_height = value
	update_terrain_mesh()
	
func set_terrain_multiplier(value : float):
	terrain_multiplier = value
	update_terrain_mesh()

func update_terrain_mesh():	
	var noise_map = NoiseLib.generate_noise_map(sample_width, sample_height, 3, noise_scale, octaves, persistence, lacunarity)
	var map_scale : Vector3 = Vector3(scale.x, scale.y * terrain_multiplier, scale.z)
	mesh = generate_terrain_mesh(noise_map, map_scale, terrain_height_curve)
	
	var noise_color_array : PoolByteArray = NoiseLib.generate_region_array(noise_map, terrain_types)
	var noise_texture : Texture = NoiseLib.generate_texture(sample_width, sample_height, noise_color_array, "Terrain Albedo")
	var spatial_material : Material = mesh.surface_get_material(0)
	if not spatial_material is SpatialMaterial:
		spatial_material = SpatialMaterial.new()
	spatial_material.albedo_texture = noise_texture
	
	mesh.surface_set_material(0, spatial_material)

class MeshData:
	var vertices : PoolVector3Array
	var uvs : PoolVector2Array
	var normals : PoolVector3Array
	var triangles : PoolIntArray
	var triangle_index : int = 0

	func _init(mesh_width : int, mesh_height : int):
		vertices = PoolVector3Array()
		uvs = PoolVector2Array()
		normals = PoolVector3Array()
		triangles = PoolIntArray()
		vertices.resize(mesh_width * mesh_height)
		uvs.resize(mesh_width * mesh_height)
		normals.resize(mesh_width * mesh_height)
		triangles.resize((mesh_width - 1) * (mesh_height - 1) * 6)

	func add_quad(a : int, b : int, c : int, d : int):
		# A-----B
		# | \   |
		# |   \ |
		# C-----D

		triangles[triangle_index] = a
		triangles[triangle_index+1] = b
		triangles[triangle_index+2] = d
		triangles[triangle_index+3] = a
		triangles[triangle_index+4] = d
		triangles[triangle_index+5] = c
		triangle_index += 6
	
	func create_mesh() -> Mesh:
		var mesh := ArrayMesh.new()
	
		var arr = []
		arr.resize(ArrayMesh.ARRAY_MAX)
		# Assign arrays to mesh array.
		arr[Mesh.ARRAY_VERTEX] = vertices
		arr[Mesh.ARRAY_TEX_UV] = uvs
		arr[Mesh.ARRAY_NORMAL] = normals
		arr[Mesh.ARRAY_INDEX] = triangles

		# Create mesh surface from mesh array.
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		# Normals was an empty array
		mesh.regen_normalmaps()
		return mesh

func generate_terrain_mesh(noise_map : Array, mesh_scale : Vector3, mesh_height_curve: Curve) -> Mesh:
	var width := len(noise_map[0])
	var breadth := len(noise_map)
	var start_x := (width - 1) / -2.0
	var start_y := -0.5
	var start_z := (breadth - 1) / -2.0
	
	var mesh_data = MeshData.new(width, breadth)
	var vertex_index = 0
	for z in range(breadth):
		for x in range(width):
			var y : float = mesh_height_curve.interpolate(noise_map[z][x])
			mesh_data.vertices[vertex_index] = Vector3(
				(start_x + x) * mesh_scale.x / width, 
				(start_y + y) * mesh_scale.y,
				(start_z + z) * mesh_scale.z / breadth
			)
			mesh_data.uvs[vertex_index] = Vector2(x / float(width), z / float(breadth))
			
			if x < width - 1 and z < breadth - 1:
				mesh_data.add_quad(vertex_index, vertex_index + 1, vertex_index + width, vertex_index + width + 1)
			
			vertex_index += 1
			
	return mesh_data.create_mesh()
	
