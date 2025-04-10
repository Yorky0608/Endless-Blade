extends Node2D

signal score_changed

@onready var tilemap = $World
@export var width = 20  # Number of tiles horizontally
@export var height = 10  # Number of tiles vertically
@export var platform_chance = 0.3  # Chance for a platform to appear
@export var tile_size = 32  # Tile size in pixels

var score = 0 : set = set_score

var item_scene = load("res://items/item.tscn")
var door_scene = load("res://items/door.tscn")

func _ready():
	score = 0
	$Player.reset($SpawnPoint.position)
	set_camera_limits()
	generate_level()
	
func set_camera_limits():
	var map_size = $World.get_used_rect()
	var cell_size = $World.tile_set.tile_size
	$Player/Camera2D.limit_left = (map_size.position.x - 5) * cell_size.x
	$Player/Camera2D.limit_right = (map_size.end.x + 5) * cell_size.x

func set_score(value):
	score = value
	score_changed.emit(score)

func _on_player_died():
	GameState.restart()

func generate_level():
	print(tilemap)
	for y in range(height):
		for x in range(width):
			# Randomly decide if a platform should appear
			if randf() < platform_chance:
				var tile_id = 1  # Set platform tile (ID 1)
				tilemap.set_cell(Vector2i(x, y), tile_id)  
				
				# Check if the tile has a collision shape
				if has_collision(tile_id):
					print("Tile at ", x, ",", y, " has a collision.")
			else:
				tilemap.set_cell(Vector2i(x, y), -1)  # Empty space tile (ID -1)

	# Ensure the bottom row is always solid ground
	for x in range(width):
		var tile_id = 1  # Set ground tile ID to 1
		tilemap.set_cell(Vector2i(x, height - 1), tile_id)

		# Check if ground tile has collision
		if has_collision(tile_id):
			print("Ground tile at", x, " has a collision.")

# Function to check if the tile has a collision shape
func has_collision(tile_id: int) -> bool:
	# Get the collision shape count for the tile
	if tilemap.tile_set.tile_get_shape_count(tile_id) > 0:
		return true
	return false
