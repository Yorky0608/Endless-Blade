extends Node2D

signal score_changed

@onready var tilemap = $World
@export var width = 20  # Number of tiles horizontally
@export var height = 10  # Number of tiles vertically
@export var platform_chance = 0.3  # Chance for a platform to appear
@export var tile_size = 32  # Tile size in pixels

const WIDTH = 80  # Width of the cave in cells
const HEIGHT = 60  # Height of the cave in cells
const CELL_SIZE = 16  # Size of each cell in pixels
var grid = []

func _ready():
	
	randomize()  # Initialize the random number generator
	initialize_grid()
	generate_cave()
	draw_cave()
	$Player.reset($SpawnPoint.position)



func _on_player_died():
	GameState.restart()

func initialize_grid():
	# Create a 2D array filled with random walls and floors
	for x in range(WIDTH):
		grid.append([])
		for y in range(HEIGHT):
			# 45% chance of being a wall (true), 55% chance of being empty (false)
			grid[x].append(randf() < 0.45)

func generate_cave():
	# Apply cellular automata rules to create cave-like structures
	for i in range(4):  # Number of iterations
		var new_grid = grid.duplicate(true)  # Create a deep copy of the grid
		for x in range(WIDTH):
			for y in range(HEIGHT):
				var wall_count = count_neighboring_walls(x, y)
				if grid[x][y]:  # If it's a wall
					# Turn into empty space if not enough surrounding walls
					new_grid[x][y] = wall_count > 3
				else:  # If it's a floor
					# Turn into a wall if too many surrounding walls
					new_grid[x][y] = wall_count > 4
		grid = new_grid  # Update the grid for the next iteration
 
func count_neighboring_walls(x, y):
	# Count the number of walls in the 8 neighboring cells
	var count = 0
	for i in range(-1, 2):
		for j in range(-1, 2):
			if i == 0 and j == 0:
				continue  # Skip the center cell
			var nx = x + i
			var ny = y + j
			# Check if the neighboring cell is out of bounds
			if nx < 0 or nx >= WIDTH or ny < 0 or ny >= HEIGHT:
				count += 1  # Count out-of-bounds as walls
			elif grid[nx][ny]:
				count += 1  # Count walls
	return count
 
func draw_cave():
	# Visualize the cave using ColorRect nodes
	for x in range(WIDTH):
		for y in range(HEIGHT):
			var cell = ColorRect.new()
			cell.size = Vector2(CELL_SIZE, CELL_SIZE)
			cell.position = Vector2(x * CELL_SIZE, y * CELL_SIZE)
			cell.color = Color.BLACK if grid[x][y] else 1
			add_child(cell)
		 	# Add collision for black cells
			if grid[x][y]:  # If the cell is black (truthy)
				var body = StaticBody2D.new()
				var collision = CollisionShape2D.new()
				var shape = RectangleShape2D.new()
					
				shape.extents = Vector2(CELL_SIZE/2, CELL_SIZE/2)
				collision.shape = shape
				body.position = Vector2(x * CELL_SIZE + CELL_SIZE/2, 
										  y * CELL_SIZE + CELL_SIZE/2)
					
				add_child(body)
				body.add_child(collision)
