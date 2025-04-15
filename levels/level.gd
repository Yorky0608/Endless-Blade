extends Node2D

# Preload your chunk scenes
const SPAWN_CHUNK = preload("res://levels/spawn_chunk.tscn")
const CHUNK_UP = preload("res://levels/chunkup.tscn")
const CHUNK_DOWN = preload("res://levels/chunk_down.tscn")

# Chunk size (should match your tilemap dimensions)
const CHUNK_WIDTH = 1024  # Adjust based on your chunk size
const CHUNK_HEIGHT = 600  # Adjust based on your chunk size

# Player reference
var player: Node2D
var current_chunk_position: Vector2 = Vector2.ZERO
var loaded_chunks = {}

func _ready():
	# Load the initial spawn chunk
	load_chunk(Vector2.ZERO, SPAWN_CHUNK)
	
	# Find the player node
	player = $Entities/Player

func _on_player_chunk_changed(new_chunk_pos):
	# Handle when player moves to a new chunk
	update_chunks(new_chunk_pos)

func update_chunks(player_chunk_pos):
	# Unload chunks that are too far away
	unload_distant_chunks(player_chunk_pos)
	
	# Load nearby chunks
	for x in range(player_chunk_pos.x - 1, player_chunk_pos.x + 2):
		for y in range(player_chunk_pos.y - 1, player_chunk_pos.y + 2):
			var chunk_pos = Vector2(x, y)
			if not loaded_chunks.has(chunk_pos):
				load_random_chunk(chunk_pos)

func load_random_chunk(position: Vector2):
	# Randomly choose a chunk type (you can add more logic here)
	var chunk_scene
	var rand_val = randf()
	
	if rand_val < 0.4:
		chunk_scene = CHUNK_UP
	elif rand_val < 0.8:
		chunk_scene = CHUNK_DOWN
	else:
		chunk_scene = SPAWN_CHUNK  # or create more chunk types
	
	load_chunk(position, chunk_scene)

func load_chunk(position: Vector2, chunk_scene):
	var chunk_instance = chunk_scene.instantiate()  # Fixed: .instantiate() instead of .instance()
	chunk_instance.position = Vector2(position.x * CHUNK_WIDTH, position.y * CHUNK_HEIGHT)
	add_child(chunk_instance)
	loaded_chunks[position] = chunk_instance

func unload_distant_chunks(player_chunk_pos):
	var chunks_to_unload = []
	
	for chunk_pos in loaded_chunks:
		if abs(chunk_pos.x - player_chunk_pos.x) > 2 or abs(chunk_pos.y - player_chunk_pos.y) > 2:
			chunks_to_unload.append(chunk_pos)
	
	for chunk_pos in chunks_to_unload:
		loaded_chunks[chunk_pos].queue_free()
		loaded_chunks.erase(chunk_pos)
