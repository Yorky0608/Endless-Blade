extends CharacterBody2D

@onready var player = get_tree().get_first_node_in_group("player")  # More reliable player reference

@export var speed = 100
@export var gravity = 900
@export var contact_damage = 10
@export var score_value = 100
@export var health: int = 25

var dead = false
var death_texture = preload("res://monsters3/Skeleton/Dead.png")

func _physics_process(delta):
	if dead: 
		return
	
	velocity.y += gravity * delta

	if player and not dead:
		var direction = (player.global_position - global_position).normalized()
		velocity.x = direction.x * speed
		$Sprite2D.flip_h = velocity.x < 0
	
	move_and_slide()
	
	# Improved collision handling
	handle_player_collisions()

func handle_player_collisions():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider.is_in_group("player"):
			if is_player_above(collider):
				# Player is on top - damage PLAYER (not enemy)
				collider.take_damage(contact_damage)
				# Optional: Small bounce to prevent "sticking"
				collider.velocity.y = -100  # Light upward push
			else:
				# Player on sides/bottom - also damage player
				collider.take_damage(contact_damage)

func is_player_above(player) -> bool:
	# More reliable position-based check
	var enemy_top = global_position.y - $CollisionShape2D.shape.extents.y
	var player_bottom = player.global_position.y + player.get_node("CollisionShape2D").shape.extents.y

	# Check if player's bottom is above enemy's top (with margin)
	var vertical_check = player_bottom < enemy_top + 10

	# Check if player is roughly centered horizontally
	var x_distance = abs(player.global_position.x - global_position.x)
	var horizontal_check = x_distance < $CollisionShape2D.shape.extents.x * 0.8
	return vertical_check and horizontal_check

func apply_damage(amount: int):
	print(health)
	if dead: 
		return
	
	health -= amount
	
	if health <= 0:
		death()

func death():
	dead = true
	$CollisionShape2D.set_deferred("disabled", true)
	$Sprite2D.texture = death_texture
	$AnimationPlayer.play("death")
	
	# Add score
	var ui = get_tree().get_first_node_in_group("ui")
	if ui:
		ui.update_score(ui.current_score + score_value)
	
	await $AnimationPlayer.animation_finished
	queue_free()
