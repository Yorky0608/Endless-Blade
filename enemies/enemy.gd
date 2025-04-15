extends CharacterBody2D

@onready var player = get_tree().get_first_node_in_group("player")  # More reliable player reference

@export var speed = 50
@export var gravity = 900
@export var contact_damage = 1
@export var score_value = 100
@export var health: int = 25

var dead = false
var death_texture = preload("res://monsters3/Skeleton/Dead.png")

func _ready():
	# Set up hitbox area
	$HitBox.body_entered.connect(_on_hit_box_body_entered)
	add_to_group("enemies")

func _physics_process(delta):
	if dead: return
	
	velocity.y += gravity * delta
	
	if player and not dead:
		var direction = (player.global_position - global_position).normalized()
		velocity.x = direction.x * speed
		$Sprite2D.flip_h = velocity.x < 0
	
	move_and_slide()
	
	# Player collision
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision.get_collider().is_in_group("player"):
			collision.get_collider().take_damage(contact_damage)
			# Knockback
			collision.get_collider().velocity = -collision.get_normal() * 300

func apply_damage(amount: int):
	if dead: return
	
	health -= amount
	$HitFlash.play("hit")  # Add this animation
	
	if health <= 0:
		death()

func _on_hit_box_body_entered(body):
	if body.is_in_group("player_attack") and not dead:
		var knockback_dir = (global_position - body.global_position).normalized()
		apply_damage(body.damage)
		velocity = knockback_dir * 300

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
