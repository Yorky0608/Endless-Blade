extends CharacterBody2D

@onready var player = get_tree().get_first_node_in_group("player")  # More reliable player reference

@export var speed = 160
@export var jump_speed = -350
@export var jump_check_distance = 10
@export var gravity = 750
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
	
	if is_on_floor():
			# Check if player is above and within jump check distance
			var player_above = player.global_position.y < global_position.y
			var vertical_distance = abs(player.global_position.y - global_position.y)
			var horizontal_distance = abs(player.global_position.x - global_position.x)
			
			if player_above and vertical_distance > jump_check_distance and 100 > horizontal_distance and horizontal_distance > 40 and player.is_on_floor():
				velocity.y = jump_speed
	
	move_and_slide()

func apply_damage(amount: int):
	if dead: 
		return
	
	health -= amount
	
	if health <= 0:
		death()

func death():
	dead = true
	$Death.play()
	$CollisionShape2D.set_deferred("disabled", true)
	$HitBox/CollisionShape2D.set_deferred("disabled", true)
	$Sprite2D.set_hframes(3)
	#$AnimationPlayer.speed_scale = 2.0
	$Sprite2D.texture = death_texture
	$AnimationPlayer.play("death")
	
	# Add score
	var ui = get_tree().get_first_node_in_group("ui")
	if ui:
		ui.update_score(ui.current_score + score_value)
	
	await $AnimationPlayer.animation_finished
	queue_free()
