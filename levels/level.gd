extends Node2D

class_name LevelManager

## Chunk configuration - EDIT THESE TO MATCH YOUR GAME ##
const CHUNK_SCENES := [
	preload("res://levels/spawn_chunk.tscn"),
	preload("res://levels/chunk_down.tscn"),
	preload("res://levels/chunkup.tscn")
	# Add more chunks here as you create them
]
const CHUNK_WIDTH = 1152  # Must match your chunk scene width
const GROUND_Y = 500      # Y-position where chunks will spawn
const LOAD_DISTANCE = 2   # Number of chunks to load ahead/behind player
const START_CHUNK_X = 0   # Initial chunk position

## Internal variables ##
var loaded_chunks = {}    # Dictionary tracking spawned chunks {x_index: chunk_instance}
var player_ref: CharacterBody2D
var spawn_marker_position: Vector2
var player_health = 20

func _ready():
	# Load spawn chunk first
	_spawn_chunk(0, true)
	
	# Position player at spawn marker
	player_ref = get_node_or_null("Entities/Player")
	if spawn_marker_position:
		player_ref.position = spawn_marker_position
	
	# Load initial chunks
	_on_player_chunk_changed(START_CHUNK_X)
	
	$Entities/Player/UI.show_message("Get Ready!")

func _spawn_chunk(x_index: int, is_spawn_chunk: bool = false):
	var chunk_scene = CHUNK_SCENES[0 if is_spawn_chunk else randi() % CHUNK_SCENES.size()]
	var new_chunk = chunk_scene.instantiate()

	new_chunk.position = Vector2(x_index * CHUNK_WIDTH, 0)
	add_child(new_chunk)
	loaded_chunks[x_index] = new_chunk

	# If this is the spawn chunk, find its marker
	if is_spawn_chunk:
		var marker = new_chunk.get_node_or_null("SpawnMarker")
		if marker:
			spawn_marker_position = marker.global_position
			print("Found spawn marker at: ", spawn_marker_position)
		else:
			push_error("WARNING: Spawn chunk missing SpawnMarker")
			spawn_marker_position = Vector2(x_index * CHUNK_WIDTH + 100, 230)  # Fallback position

func _on_player_chunk_changed(current_chunk_x: int):
	# Unload chunks outside loading distance
	_unload_distant_chunks(current_chunk_x)
	
	# Load new chunks around player
	_load_nearby_chunks(current_chunk_x)

func _load_nearby_chunks(center_x: int):
	# Load chunks in range [center-LOAD_DISTANCE, center+LOAD_DISTANCE]
	for x in range(center_x - LOAD_DISTANCE, center_x + LOAD_DISTANCE + 1):
		if not loaded_chunks.has(x):
			_spawn_chunk(x)

func _unload_distant_chunks(center_x: int):
	var chunks_to_unload := []
	
	# Find chunks outside loading distance
	for x in loaded_chunks:
		if abs(x - center_x) > LOAD_DISTANCE:
			chunks_to_unload.append(x)
	
	# Remove those chunks
	for x in chunks_to_unload:
		loaded_chunks[x].queue_free()
		loaded_chunks.erase(x)

func _on_player_died():
	GameState.restart()
