extends Node2D

@export var chunk_size = 32
@export var render_distance = 3
@export var wall_chance = 0.45
@export var tile_size = 16
@export var max_wall_height = 3  # Maximum height for walls/borders
@export var wall_variation = 2   # How much shorter walls can be than max
@export var main_floor_tile = Vector2i(1, 0)  # Different tile for main walkable area
@export var border_tile = Vector2i(0, 0)  # Tile for walls/borders

var world_seed = 0
var noise = FastNoiseLite.new()
var generated_chunks = {}
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
	generated_chunks[chunk_coords] = true
	
	var chunk_data = []
	# Initialize empty chunk
	for x in range(chunk_size):
		chunk_data.append([])
		for y in range(chunk_size):
			chunk_data[x].append(false)  # Start with all floor
	
	for x in range(chunk_size):
		# Determine actual wall height for this column
		var wall_height = max_wall_height - randi() % wall_variation
		wall_height = clamp(wall_height, 1, max_wall_height)  # Ensure min 1 wall
		
		for y in range(wall_height):
			var world_x = chunk_coords.x * chunk_size + x
			var world_y = chunk_coords.y * chunk_size + y

			# Add some organic variation
			if y == wall_height - 1:  # Top of wall
				var noise_value = noise.get_noise_2d(world_x, world_y)
				if noise_value > 0.3:  # Make occasional gaps
					continue
			
			chunk_data[x][chunk_size - 1 - y] = true  # Fill from bottom up
	
	# Ensure connectivity - make sure all floor tiles are connected
	ensure_floor_connectivity(chunk_data)
	
	# Place tiles
	for x in range(chunk_size):
		for y in range(chunk_size):
			var map_pos = Vector2i(
				chunk_coords.x * chunk_size + x,
				chunk_coords.y * chunk_size + y
			)
			tilemap.set_cell(0, map_pos, 
				0 if chunk_data[x][y] else -1,
				border_tile if chunk_data[x][y] else Vector2i.ZERO
			)

func ensure_floor_connectivity(chunk_data):
	# Find all floor areas and connect them
	var visited = []
	var floor_groups = []

	# Initialize visited array
	for x in range(chunk_size):
		visited.append([])
		for y in range(chunk_size):
			visited[x].append(false)
	
	# Find all floor groups
	for x in range(chunk_size):
		for y in range(chunk_size):
			if not chunk_data[x][y] and not visited[x][y]:
				var group = flood_find(chunk_data, x, y, false, visited)
				floor_groups.append(group)
	
	# If multiple floor groups exist, connect them
	if floor_groups.size() > 1:
		# Sort by size (largest first)
		floor_groups.sort_custom(func(a, b): return a.size() > b.size())

		# Connect all smaller groups to the main group
		for i in range(1, floor_groups.size()):
			connect_groups(chunk_data, floor_groups[0], floor_groups[i])

func connect_groups(chunk_data, group_a, group_b):
	# Simple connection - find closest points and carve a path
	var best_a = find_most_surface_point(group_a, chunk_data)
	var best_b = find_most_surface_point(group_b, chunk_data)
	
	var path = get_walkable_path(best_a, best_b, chunk_data)

	# Carve out the path
	for point in path:
		carve_path_segment(point.x, point.y, chunk_data)

func find_most_surface_point(group: Array, chunk_data: Array) -> Vector2i:
	# Prefer points that are near other floor tiles
	var best_point = group[0]
	var best_score = -INF

	for point in group:
		var floor_neighbors = 0
		# Check 8-directional neighbors
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				if dx == 0 and dy == 0:
					continue
				var nx = point.x + dx
				var ny = point.y + dy
				if nx >= 0 and nx < chunk_size and ny >= 0 and ny < chunk_size:
					if not chunk_data[nx][ny]:
						floor_neighbors += 1
		
		# Higher score for points with more floor neighbors and lower y-position
		var score = floor_neighbors - (point.y * 0.1)
		if score > best_score:
			best_score = score
			best_point = point
	
	return best_point

func get_walkable_path(start: Vector2i, end: Vector2i, chunk_data: Array) -> Array:
	var path = []
	var current = Vector2(start)
	var target = Vector2(end)
	var dir = (target - current).normalized()
	var steps = current.distance_to(target) * 1.2  # Slightly more steps to ensure reach

	for i in range(int(steps)):
		var t = i / steps
		var point = current.lerp(target, t)
		var ix = int(round(point.x))
		var iy = int(round(point.y))

		if ix >= 0 and ix < chunk_size and iy >= 0 and iy < chunk_size:
			path.append(Vector2i(ix, iy))
	
	# Add some natural-looking jitter to the path
	if path.size() > 4:
		for i in range(1, path.size() - 1):
			if randf() < 0.3:  # 30% chance to offset
				path[i].x += randi() % 3 - 1  # -1, 0, or 1
	
	return path

func carve_path_segment(x: int, y: int, chunk_data: Array):
	# Carve a 3x3 area (adjust size as needed)
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var nx = x + dx
			var ny = y + dy
			if nx >= 0 and nx < chunk_size and ny >= 0 and ny < chunk_size:
				# Only modify areas ABOVE max wall height
				if ny > max_wall_height:  # Or ">= max_wall_height" depending on your needs
					chunk_data[nx][ny] = false  # Make it floor
				# For visual debugging of the constraint line:
				elif ny == max_wall_height:
					chunk_data[nx][ny] = false

func flood_find(chunk_data: Array, start_x: int, start_y: int, target_value: bool, visited: Array) -> Array:
	var queue = [Vector2i(start_x, start_y)]
	var group = []
	visited[start_x][start_y] = true

	# Use 8-directional flood fill for more natural connections
	var directions = [
		Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN,
		Vector2i(-1,-1), Vector2i(-1,1), Vector2i(1,-1), Vector2i(1,1)
	]
	
	while not queue.is_empty():
		var current = queue.pop_front()
		group.append(current)

		for dir in directions:
			var nx = current.x + dir.x
			var ny = current.y + dir.y

			if nx >= 0 and nx < chunk_size and ny >= 0 and ny < chunk_size:
				if not visited[nx][ny] and chunk_data[nx][ny] == target_value:
					visited[nx][ny] = true
					queue.append(Vector2i(nx, ny))
	
	return group

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
