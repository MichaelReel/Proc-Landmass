extends Object

class_name ChunkLib


class MapData:
	var height_map : Array
	var color_map : PoolByteArray
	var texture_map : Texture
	
	func _init(hm : Array, cm : PoolByteArray, tm : Texture):
		self.height_map = hm
		self.color_map = cm
		self.texture_map = tm


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


static func generate_map_data(
	width: int, 
	height: int, 
	nseed: int, 
	period: float, 
	octaves: int, 
	persistence: float, 
	lacunarity: float,
	height_color_map: Dictionary
) -> MapData:
	var noise_map := NoiseLib.generate_noise_map(
		width, 
		height, 
		nseed,
		period, 
		octaves, 
		persistence, 
		lacunarity
	)
	var noise_color_array := NoiseLib.generate_region_array(
		noise_map, 
		height_color_map
	)
	var noise_texture : Texture = NoiseLib.generate_texture(width, height, noise_color_array, "Terrain Albedo")
	return MapData.new(noise_map, noise_color_array, noise_texture)


static func generate_terrain_mesh(
	noise_map : Array, 
	mesh_scale : Vector3, 
	mesh_height_curve : Curve, 
	lod_exp : int
) -> Mesh:
	var width := len(noise_map[0])
	var breadth := len(noise_map)
	var start_x := (width - 1) / -2.0
	var start_y := -0.5
	var start_z := (breadth - 1) / -2.0
	var mesh_lod_increment := int(pow(2, lod_exp))
	#warning-ignore:integer_division
	var verts_per_line = ((width - 1) / mesh_lod_increment) + 1
	
	var mesh_data = MeshData.new(verts_per_line, verts_per_line)
	var vertex_index = 0
	for z in range(0, breadth, mesh_lod_increment):
		for x in range(0, width, mesh_lod_increment):
			var y : float = mesh_height_curve.interpolate(noise_map[z][x])
			mesh_data.vertices[vertex_index] = Vector3(
				(start_x + x) * mesh_scale.x / width, 
				(start_y + y) * mesh_scale.y,
				(start_z + z) * mesh_scale.z / breadth
			)
			mesh_data.uvs[vertex_index] = Vector2(x / float(width), z / float(breadth))
			
			if x < width - 1 and z < breadth - 1:
				mesh_data.add_quad(
					vertex_index,
					vertex_index + 1,
					vertex_index + verts_per_line,
					vertex_index + verts_per_line + 1
				)
			
			vertex_index += 1
	
	return mesh_data.create_mesh()


static func distance(bounds: Rect2, point: Vector2) -> float:
	var dx = max(0, max(bounds.position.x - point.x, point.x - bounds.end.x))
	var dy = max(0, max(bounds.position.y - point.y, point.y - bounds.end.y))
	return sqrt(dx * dx + dy * dy)
