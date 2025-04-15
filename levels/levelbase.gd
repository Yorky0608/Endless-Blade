extends Node2D

# Tile IDs from your World tileset
const FLOOR_TILES = [
	Vector2i(9, 2),  # Floor tile variant 1
	Vector2i(10, 2), # Floor tile variant 2
	Vector2i(11, 2), # Floor tile variant 3
	Vector2i(12, 2), # Floor tile variant 4
	Vector2i(13, 2)  # Floor tile variant 5
]
const LEFT_WALL_TILE = Vector2i(16, 0)  # Left wall tile
const RIGHT_WALL_TILE = Vector2i(17, 0) # Right wall tile
const UNDERGROUND_TILE = Vector2i(2, 2) # Underground tile (adjust to your tileset)

# Generation parameters
const CHUNK_WIDTH = 20
const VIEW_DISTANCE = 40
const MIN_FLOOR_HEIGHT = -10
const MAX_FLOOR_HEIGHT = 10
const WALL_HEIGHT = 10
const UNDERGROUND_DEPTH = 50 # How many tiles below floor to fill

@onready var tilemap = $World
@onready var player = $Player

var last_chunk_x = 0
var generated_chunks = {}

func _ready():
	generate_initial_world()

func _process(_delta):
	var player_chunk_x = floor(player.position.x / (CHUNK_WIDTH * tilemap.tile_set.tile_size.x))
	
	if player_chunk_x != last_chunk_x:
		generate_chunks_around(player_chunk_x)
		last_chunk_x = player_chunk_x
		cleanup_chunks(player_chunk_x)

func generate_initial_world():
	var start_chunk_x = floor(player.position.x / (CHUNK_WIDTH * tilemap.tile_set.tile_size.x))
	generated_chunks[start_chunk_x] = 0
	generate_chunks_around(start_chunk_x)

func generate_chunks_around(center_chunk_x):
	for x in range(center_chunk_x - VIEW_DISTANCE, center_chunk_x + VIEW_DISTANCE + 1):
		if not generated_chunks.has(x):
			var floor_height = determine_floor_height(x)
			generate_chunk(x, floor_height)
			generated_chunks[x] = floor_height

func determine_floor_height(chunk_x):
	var left_height = generated_chunks.get(chunk_x - 1)
	var right_height = generated_chunks.get(chunk_x + 1)
	
	if left_height != null and right_height != null:
		return (left_height + right_height) / 2
	elif left_height != null:
		return left_height + randi_range(-1, 1)
	elif right_height != null:
		return right_height + randi_range(-1, 1)
	else:
		return randi_range(MIN_FLOOR_HEIGHT, MAX_FLOOR_HEIGHT)

func cleanup_chunks(current_chunk_x):
	var chunks_to_remove = []
	for chunk_x in generated_chunks:
		if abs(chunk_x - current_chunk_x) > VIEW_DISTANCE:
			chunks_to_remove.append(chunk_x)
			clear_chunk(chunk_x)
	
	for chunk_x in chunks_to_remove:
		generated_chunks.erase(chunk_x)

func generate_chunk(chunk_x, floor_height):
	var start_x = chunk_x * CHUNK_WIDTH
	var end_x = start_x + CHUNK_WIDTH

	floor_height = clamp(floor_height, MIN_FLOOR_HEIGHT, MAX_FLOOR_HEIGHT)

	for x in range(start_x, end_x):
		# 1. Place surface tile first (top-most layer)
		var floor_tile = FLOOR_TILES[randi() % FLOOR_TILES.size()]
		tilemap.set_cell(0, Vector2i(x, floor_height), 0, floor_tile)

		# 2. Now fill everything BELOW with underground tiles
		# We'll scan downward until we hit existing underground tiles
		var current_y = floor_height + 1
		var safety_counter = 0
		var max_depth = 100  # Prevent infinite loops

		while safety_counter < max_depth:
			# Stop if we hit an existing underground tile or reach max depth
			if tilemap.get_cell_source_id(0, Vector2i(x, current_y)) != -1 && tilemap.get_cell_atlas_coords(0, Vector2i(x, current_y)) == UNDERGROUND_TILE:
				break
				
			# Place underground tile
			tilemap.set_cell(0, Vector2i(x, current_y), 0, UNDERGROUND_TILE)
			current_y += 1
			safety_counter += 1
		
		# 3. Generate walls ABOVE the surface
		for y in range(floor_height - 1, floor_height - WALL_HEIGHT - 1, -1):
			if x == start_x:
				tilemap.set_cell(0, Vector2i(x, y), 0, LEFT_WALL_TILE)
			elif x == end_x - 1:
				tilemap.set_cell(0, Vector2i(x, y), 0, RIGHT_WALL_TILE)
			else:
				tilemap.set_cell(0, Vector2i(x, y), 0, FLOOR_TILES[0])

func clear_chunk(chunk_x):
	var start_x = chunk_x * CHUNK_WIDTH
	var end_x = start_x + CHUNK_WIDTH
	
	for x in range(start_x, end_x):
		for y in range(-100, 100):
			tilemap.erase_cell(0, Vector2i(x, y))

func _on_player_died():
	# Handle player death
	pass
