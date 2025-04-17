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
