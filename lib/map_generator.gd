extends Object

class_name MapGenerator

var map_data_queue = []
var map_data_mutex = Mutex.new()

signal map_data_callback(chunk_key, chunk_data)

func request_map_data(request_data : ChunkRequestData):
	var data_thread = Thread.new()
	data_thread.start(self, "map_data_thread", request_data)

func map_data_thread(request_data : ChunkRequestData):
	var land_chunk = Landmass3D.new()
	# TODO: Probably need to set values here
	land_chunk.update_terrain_mesh()
	enqueue(QueuedRequestData.new(request_data, land_chunk))

# This is not auto-called, needs to be called from main EndlessTerrain, probably
func update():
	while not map_data_queue.empty():
		var land_chunk_response := dequeue()
		var key : Vector2 = land_chunk_response.request.chunk_coord
		var data : Landmass3D = land_chunk_response.response
		emit_signal("map_data_callback", key, data)
		
func dequeue() -> ChunkRequestData:
	map_data_mutex.lock()
	var land_chunk_request = map_data_queue.pop_front()
	map_data_mutex.unlock()
	return land_chunk_request

func enqueue(land_chunk_request: QueuedRequestData):
	map_data_mutex.lock()
	map_data_queue.push_back(land_chunk_request)
	map_data_mutex.unlock()

class ChunkRequestData:
	var chunk_coord : Vector2
	
	func _init(coord : Vector2):
		chunk_coord = coord

class QueuedRequestData:
	var request : ChunkRequestData
	var response: Landmass3D

	func _init(req : ChunkRequestData, res : Landmass3D):
		request = req
		response = res
