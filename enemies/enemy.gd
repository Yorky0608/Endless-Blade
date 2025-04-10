extends CharacterBody2D

@onready var player = get_parent().get_node("Player")

@export var speed = 50
@export var gravity = 900
@export var contact_damage = 1

var death_texture = preload("res://monsters3/Skeleton/Dead.png")

var facing = 1
var health: int = 25  # The enemy's health
var damage_enabled = false
var alive = true

func _ready():
	await get_tree().create_timer(0.5).timeout
	damage_enabled = true

func _physics_process(delta):
	if not alive:
		return
	velocity.y += gravity * delta

	if player:
		var direction = (player.global_position - global_position).normalized()
		velocity.x = direction.x * speed
		$Sprite2D.flip_h = velocity.x < 0

	move_and_slide()
	
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision.get_collider().name == "Player":
			collision.get_collider().hurt()
			
		if abs(collision.get_normal().x) > 0.9:
			facing = sign(collision.get_normal().x)
			velocity.y = -100
		
func death():
	alive = false
	damage_enabled = false
	$Sprite2D.set_hframes(3)
	$Sprite2D.texture = death_texture
	$AnimationPlayer.play("death")
	await $AnimationPlayer.animation_finished
	await get_tree().create_timer(2.0).timeout
	queue_free()

func apply_damage(amount: int):
	health -= amount
	if health <= 0:
		death()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if damage_enabled and body.is_in_group("player"):
		body.take_damage(contact_damage)
