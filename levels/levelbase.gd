extends Node2D

@export var chunk_size = 32  # Size of each chunk in cells
@export var render_distance = 3  # Chunks to render around player
@export var wall_chance = 0.45  # Initial wall probability
@export var tile_size = 16  # Size of each cell in pixels

var world_seed = 0
var noise = FastNoiseLite.new()
var generated_chunks = {}  # Dictionary to track generated chunks
var player_last_chunk = Vector2i.ZERO

@onready var tilemap = $World
@onready var player = $Player

func _ready():
	randomize()
	world_seed = randi()
	noise.seed = world_seed
	noise.frequency = 0.05
	player_last_chunk = get_chunk_coords(player.position)
	generate_initial_world()

func _process(_delta):
	var current_chunk = get_chunk_coords(player.position)
	if current_chunk != player_last_chunk:
		player_last_chunk = current_chunk
		update_world()

func get_chunk_coords(position: Vector2) -> Vector2i:
	return Vector2i(
		floor(position.x / (chunk_size * tile_size)),
		floor(position.y / (chunk_size * tile_size))
	)

func generate_initial_world():
	for x in range(-render_distance, render_distance + 1):
		for y in range(-render_distance, render_distance + 1):
			generate_chunk(Vector2i(x, y))

func update_world():
	# Generate new chunks around player
	for x in range(player_last_chunk.x - render_distance, player_last_chunk.x + render_distance + 1):
		for y in range(player_last_chunk.y - render_distance, player_last_chunk.y + render_distance + 1):
			var chunk_coords = Vector2i(x, y)
			if not generated_chunks.has(chunk_coords):
				generate_chunk(chunk_coords)
	
	# Remove distant chunks (optional for memory management)
	cleanup_distant_chunks()

func generate_chunk(chunk_coords: Vector2i):
	# Mark chunk as generated
	generated_chunks[chunk_coords] = true
	
	# Generate chunk using noise for consistency
	for x in range(chunk_size):
		for y in range(chunk_size):
			var world_x = chunk_coords.x * chunk_size + x
			var world_y = chunk_coords.y * chunk_size + y
			
			# Use noise for organic patterns
			var noise_value = noise.get_noise_2d(world_x, world_y)
			var is_wall = noise_value > 0.2  # Adjust threshold as needed
			
			# Place tile in the world
			var map_pos = Vector2i(
				chunk_coords.x * chunk_size + x,
				chunk_coords.y * chunk_size + y
			)
			
			if is_wall:
				tilemap.set_cell(0, map_pos, 0, Vector2i(0, 0))
			else:
				tilemap.set_cell(0, map_pos, -1)  # -1 means empty

func cleanup_distant_chunks():
	var chunks_to_remove = []
	for chunk_coords in generated_chunks:
		if abs(chunk_coords.x - player_last_chunk.x) > render_distance or \
		   abs(chunk_coords.y - player_last_chunk.y) > render_distance:
			chunks_to_remove.append(chunk_coords)
			erase_chunk(chunk_coords)
	
	for chunk in chunks_to_remove:
		generated_chunks.erase(chunk)

func erase_chunk(chunk_coords: Vector2i):
	for x in range(chunk_size):
		for y in range(chunk_size):
			var map_pos = Vector2i(
				chunk_coords.x * chunk_size + x,
				chunk_coords.y * chunk_size + y
			)
			tilemap.set_cell(0, map_pos, -1)  # Clear cell

func _on_player_died():
	GameState.restart()
