extends CharacterBody2D

@onready var player = get_parent().get_node("Player")

@export var speed = 50
@export var gravity = 900

var facing = 1
var health: int = 25  # The enemy's health

func _physics_process(delta):
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
	$HitSound.play()
	$AnimationPlayer.play("death")
	$CollisionShape2D.set_deferred("disabled", true)
	set_physics_process(false)


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "death":
		queue_free()

func apply_damage(amount: int):
	health -= amount
	if health <= 0:
		death()
