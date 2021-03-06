extends Object

class_name MapGenerator

var map_data_queue = []
var map_data_mutex = Mutex.new()

signal map_data_callback(chunk_key, chunk_data)
signal map_mesh_callback(chunk_key, chunk_data, lod)

func request_map(request_data : Landmass3D.ChunkRequest):
	var data_thread = Thread.new()
	request_data.handler_thread = data_thread
	data_thread.start(self, "map_thread", request_data)

func map_thread(request_data : Landmass3D.ChunkRequest):
	var land_chunk : Landmass3D = request_data.land_chunk
	if request_data is ChunkRequestData:
		land_chunk.update_terrain_data()
	elif request_data is ChunkRequestMesh:
		land_chunk.update_terrain_mesh(request_data.lod)
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
			emit_signal("map_mesh_callback", key, data, land_chunk_response.request.lod)
		var handler_thread = land_chunk_response.request.handler_thread
		handler_thread.wait_to_finish()

func dequeue() -> Landmass3D.ChunkRequest:
	map_data_mutex.lock()
	var land_chunk_request = map_data_queue.pop_front()
	map_data_mutex.unlock()
	return land_chunk_request

func enqueue(land_chunk_request: QueuedRequest):
	map_data_mutex.lock()
	map_data_queue.push_back(land_chunk_request)
	map_data_mutex.unlock()

class ChunkRequestData:
	extends Landmass3D.ChunkRequest
	func _init(coord, chunk).(coord, chunk):
		pass

class ChunkRequestMesh:
	extends Landmass3D.ChunkRequest
	var lod : int
	func _init(coord, chunk, level_of_detail).(coord, chunk):
		lod = level_of_detail

class QueuedRequest:
	var request : Landmass3D.ChunkRequest
	var response : Spatial

	func _init(req : Landmass3D.ChunkRequest, res : Landmass3D):
		request = req
		response = res
