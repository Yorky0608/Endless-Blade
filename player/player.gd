extends CharacterBody2D

signal died
signal chunk_changed(current_chunk_x: int)  # Changed to only track x-axis
signal update_health_bar(new_health)

@export var gravity = 750
@export var run_speed = 150
@export var jump_speed = -300
@export var invincibility_time = 1.0

var invincible = false

var walk_texture = preload("res://sprites/2/Walk.png")
var attack1_texture = preload("res://sprites/2/Attack1.png")
var attack2_texture = preload("res://sprites/2/Attack2.png")
var death_texture = preload("res://sprites/2/Death.png")
var fall_attack_texture = preload("res://sprites/2/FallAttack.png")
var hurt_texture = preload("res://sprites/2/Hurt.png")
var idle_texture = preload("res://sprites/2/Idle.png")
var jump_texture = preload("res://sprites/2/Jump.png")
var jump_attack_texture = preload("res://sprites/2/JumpAttack.png")
var run_texture = preload("res://sprites/2/Run.png")
var run_attack1_texture = preload("res://sprites/2/RunAttack1.png")
var run_attack2_texture = preload("res://sprites/2/RunAttack2.png")
var walk_attack1_texture = preload("res://sprites/2/WalkAttack1.png")
var walk_attack2_texture = preload("res://sprites/2/WalkAttack2.png")
var death_texture = preload("res://sprites/2/Death.png")

enum {IDLE, RUN, JUMP, HURT, DEAD, ATTACK}
var state = IDLE
var life = 100
var can_be_damaged = true

# Chunk tracking (simplified for horizontal only)
const CHUNK_WIDTH = 1152  # Must match level.gd value
var current_chunk_x = 0  # Now just tracking x-axis

@export var damage: int = 25  # The damage this attack deals

func _ready():
	# Get the root Viewport (not Window)
	var viewport = get_viewport()

	# For pixel art games (disable anti-aliasing)
	viewport.msaa_2d = Viewport.MSAA_DISABLED  # Correct property name in Godot 4.3
	viewport.msaa_3d = Viewport.MSAA_DISABLED  # If using 3D elements

	# Enable nearest-neighbor filtering for crisp pixels
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST

	# Disable FXAA (another form of anti-aliasing)
	viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	
	change_state(IDLE)

func reset(_position):
	position = _position
	show()
	change_state(IDLE)
	life = 100
	current_chunk_x = floor(position.x / CHUNK_WIDTH)

# Modify hurt function:
func hurt():
	life = 27
	update_health_bar.emit(life)
	if state != HURT:
		$HurtSound.play()
		change_state(HURT)
		# Flash effect
		$Sprite2D.modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		$Sprite2D.modulate = Color.WHITE

func get_input():
	if state == HURT:
		return  # don't allow movement during hurt state
	var right = Input.is_action_pressed("right")
	var left = Input.is_action_pressed("left")
	var jump = Input.is_action_just_pressed("jump")
	var attack = Input.is_action_just_pressed("attack")

	# movement occurs in all states
	velocity.x = 0
	if right:
		velocity.x += run_speed
		$Sprite2D.flip_h = false
	if left:
		velocity.x -= run_speed
		$Sprite2D.flip_h = true
	# only allow jumping when on the ground
	if jump and is_on_floor():
		$JumpSound.play()
		change_state(JUMP)
		velocity.y = jump_speed
	# IDLE transitions to RUN when moving
	if state == IDLE and velocity.x != 0:
		change_state(RUN)
	# RUN transitions to IDLE when standing still
	if state == RUN and velocity.x == 0:
		change_state(IDLE)
	# transition to JUMP when in the air
	if state in [IDLE, RUN] and !is_on_floor():
		change_state(JUMP)
	# transition from running or jumping to attacking
	if attack and not right and not left and not jump:
		$Sprite2D.set_frame(0)
		change_state(ATTACK)
	if state == ATTACK and !$AnimationPlayer.is_playing():
		change_state(IDLE)
	# RUN transitions to IDLE when standing still
	if state == RUN and attack:
		$AnimationPlayer.speed_scale = 5.0
		$AttackArea.monitoring = true
		$Sprite2D.texture = run_attack2_texture
		$Sprite2D.set_hframes(6)
		$AnimationPlayer.play("RunAttack2")
		await $AnimationPlayer.animation_finished
		$AttackArea.monitoring = false
		$AnimationPlayer.speed_scale = 3.0
		change_state(RUN)

func change_state(new_state):
	state = new_state
	match state:
		IDLE:
			$Sprite2D.set_hframes(4)
			$Sprite2D.texture = idle_texture
			$AnimationPlayer.play("Idle")
		RUN:
			$Sprite2D.set_hframes(6)
			$Sprite2D.texture = run_texture
			$AnimationPlayer.play("Run")
		HURT:
			$Sprite2D.set_hframes(4)
			$Sprite2D.texture = hurt_texture
			$AnimationPlayer.play("Hurt")
			velocity.y = -200
			velocity.x = -200 * sign(velocity.x)
			change_state(IDLE)
			if life <= 0:
				change_state(DEAD)
		JUMP:
			$Sprite2D.texture = jump_texture
			$Sprite2D.set_hframes(8)
			$AnimationPlayer.play("Jump")
		DEAD:
			$Sprite2D.set_hframes(8)
			$Sprite2D.texture = death_texture
			$AnimationPlayer.play("Death")
			died.emit()
			hide()
		ATTACK:
			$AnimationPlayer.speed_scale = 5.0
			$AttackArea.monitoring = true
			$Sprite2D.texture = attack2_texture
			$Sprite2D.set_hframes(6)
			$AnimationPlayer.play("Attack2")
			await $AnimationPlayer.animation_finished
			$AttackArea.monitoring = false
			$AnimationPlayer.speed_scale = 3.0

func _physics_process(delta):    
	velocity.y += gravity * delta
	get_input()
	
	move_and_slide()
	if state == HURT:
		return
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision.get_collider().is_in_group("danger"):
			hurt()
	
	if state == JUMP and is_on_floor():
		change_state(IDLE)
		$Dust.emitting = true
	
	# Simplified chunk tracking - only x-axis
	var new_chunk_x = floor(position.x / CHUNK_WIDTH)
	if new_chunk_x != current_chunk_x:
		current_chunk_x = new_chunk_x
		emit_signal("chunk_changed", current_chunk_x)

func take_damage(amount):
	if invincible or state == DEAD:
		return

	life -= amount
	update_health_bar.emit(life)
	hurt()

	invincible = true
	$InvincibilityTimer.start(invincibility_time)
	await $InvincibilityTimer.timeout
	invincible = false
	
	if life <= 0:
		change_state(DEAD)




func _on_hit_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		take_damage(body.contact_damage)
