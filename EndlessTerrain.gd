extends Spatial

export (float) var max_view_distance : float = 128

onready var camera_control = get_node("../CameraControl")
onready var viewer_position : Vector2 = Vector2(camera_control.translation.x, camera_control.translation.z)
onready var map_generator : MapGenerator = MapGenerator.new()

var chunk_size : int
var chunks_visible_in_view : int
var terrain_chunk_dict : Dictionary = {}
var terrain_chunks_last_visible : Array = []

const DEBUG_RATE = 2.0
var debug_tick = 0.0

func _ready():
	chunk_size = Landmass3D.map_chunk_size - 1
	chunks_visible_in_view = int(round(max_view_distance / chunk_size))
	var _err = map_generator.connect("map_data_callback", self, "_on_map_data_callback")

func _process(delta):
	viewer_position = Vector2(camera_control.translation.x, camera_control.translation.z)
	update_visible_chunks()
	map_generator.update()
	debug_tick -= delta
	if debug_tick <= 0.0:
#		print(str(len(terrain_chunk_dict)))
		debug_tick += DEBUG_RATE

func update_visible_chunks():
	
	for chunk in terrain_chunks_last_visible:
		chunk.set_visible(false)
	terrain_chunks_last_visible.clear()
	
	var current_chunk_coord_x := int(round(camera_control.translation.x / chunk_size))
	var current_chunk_coord_y := int(round(camera_control.translation.z / chunk_size))
	
	for y_offset in range(-chunks_visible_in_view, chunks_visible_in_view + 1):
		for x_offset in range(-chunks_visible_in_view, chunks_visible_in_view + 1):
			var viewed_chunk_coord := Vector2(
				current_chunk_coord_x + x_offset,
				current_chunk_coord_y + y_offset
			)
			
			if terrain_chunk_dict.has(viewed_chunk_coord):
				terrain_chunk_dict[viewed_chunk_coord].update_terrain_chunk(viewer_position, max_view_distance)
				if terrain_chunk_dict[viewed_chunk_coord].visible:
					terrain_chunks_last_visible.append(terrain_chunk_dict[viewed_chunk_coord])
			else:
				terrain_chunk_dict[viewed_chunk_coord] = TerrainChunk.new(
					viewed_chunk_coord, 
					chunk_size,
					map_generator
				)
				add_child(terrain_chunk_dict[viewed_chunk_coord])

func _on_map_data_callback(chunk_coord : Vector2, chunk_data : Landmass3D):
	if terrain_chunk_dict.has(chunk_coord):
		terrain_chunk_dict[chunk_coord].on_map_data_received(chunk_data)


class TerrainChunk:
	extends Spatial
	
	var position_2d : Vector2
	var mesh_object : MeshInstance
	var bounds : Rect2
	
	func _init(coord: Vector2, size: int, map_generator : MapGenerator):
		self.set_name("terrain(" + str(coord.x) + "," + str(coord.y) + ")")
		position_2d = coord * size
		self.translation = Vector3(position_2d.x, 0.0, position_2d.y)
		bounds = Rect2(position_2d, Vector2.ONE * size).abs()
#		print("bounds created: " + str(bounds))
		
		mesh_object = MeshInstance.new()
		mesh_object.mesh = PlaneMesh.new()
		mesh_object.scale = Vector3.ONE * size
		self.set_visible(false)
		add_child(mesh_object)
		
		var request = MapGenerator.ChunkRequestData.new(coord)
		map_generator.request_map_data(request)
	
	func update_terrain_chunk(viewer_position : Vector2, max_view_distance: float):
		var viewer_distance_nearest_edge : float = ChunkLib.distance(bounds, viewer_position)
		self.set_visible(viewer_distance_nearest_edge <= max_view_distance)
	
	func on_map_data_received(_landmass : Landmass3D):
		print(self.name + " : map data received")
