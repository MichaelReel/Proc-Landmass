extends Object

class_name MapGenerator

var map_data_queue = []
var map_data_mutex = Mutex.new()

signal map_data_callback(chunk_key, chunk_data)
signal map_mesh_callback(chunk_key, chunk_data)

func request_map(request_data : NoiseLib.ChunkRequest):
	var data_thread = Thread.new()
	request_data.handler_thread = data_thread
	data_thread.start(self, "map_thread", request_data)

func map_thread(request_data : NoiseLib.ChunkRequest):
	var land_chunk : Landmass3D
	
	if request_data is ChunkRequestData:
		land_chunk = Landmass3D.new()
		land_chunk.update_terrain_data()
	elif request_data is ChunkRequestMesh:
		land_chunk = (request_data as ChunkRequestMesh).land_chunk
		land_chunk.update_terrain_mesh()
	else:
		print("Unrecognised Chunk Request: " + str(request_data))
		
	enqueue(QueuedRequest.new(request_data, land_chunk))

func update():
	while not map_data_queue.empty():
		var land_chunk_response := dequeue()
		var key : Vector2 = land_chunk_response.request.chunk_coord
		var data : Landmass3D = land_chunk_response.response
		if land_chunk_response.request is ChunkRequestData:
			emit_signal("map_data_callback", key, data)
		elif land_chunk_response.request is ChunkRequestMesh:
			emit_signal("map_mesh_callback", key, data)
		var handler_thread = land_chunk_response.request.handler_thread
		handler_thread.wait_to_finish()

func dequeue() -> NoiseLib.ChunkRequest:
	map_data_mutex.lock()
	var land_chunk_request = map_data_queue.pop_front()
	map_data_mutex.unlock()
	return land_chunk_request

func enqueue(land_chunk_request: QueuedRequest):
	map_data_mutex.lock()
	map_data_queue.push_back(land_chunk_request)
	map_data_mutex.unlock()

class ChunkRequestData:
	extends NoiseLib.ChunkRequest
	var chunk_coord : Vector2
	
	func _init(coord : Vector2):
		chunk_coord = coord

class ChunkRequestMesh:
	extends NoiseLib.ChunkRequest
	var chunk_coord : Vector2
	var land_chunk : Landmass3D
	
	func _init(coord : Vector2, chunk : Landmass3D):
		chunk_coord = coord
		land_chunk = chunk

class QueuedRequest:
	var request : NoiseLib.ChunkRequest
	var response : Landmass3D

	func _init(req : NoiseLib.ChunkRequest, res : Landmass3D):
		request = req
		response = res
