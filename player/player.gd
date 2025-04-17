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

enum {IDLE, RUN, JUMP, HURT, DEAD, ATTACK}
var state = IDLE
var life = 100
var can_be_damaged = true

# Chunk tracking (simplified for horizontal only)
const CHUNK_WIDTH = 1152  # Must match level.gd value
var current_chunk_x = 0  # Now just tracking x-axis

@export var damage: int = 25  # The damage this attack deals

func _ready():
	$AttackPivot/AttackArea.monitoring = false
	
	# Get the root Viewport (not Window)
	var viewport = get_viewport()

	# For pixel art games (disable anti-aliasing)
	viewport.msaa_2d = Viewport.MSAA_DISABLED  # Correct property name in Godot 4.3
	viewport.msaa_3d = Viewport.MSAA_DISABLED  # If using 3D elements

	# Enable nearest-neighbor filtering for crisp pixels
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST

	# Disable FXAA (another form of anti-aliasing)
	viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	
	change_state(IDLE, idle_texture, "Idle")

func reset(_position):
	position = _position
	show()
	change_state(IDLE, idle_texture, "Idle")
	life = 100
	current_chunk_x = floor(position.x / CHUNK_WIDTH)

# Modify hurt function:
func hurt():
	var ui = get_tree().get_first_node_in_group("ui")
	if ui:
		ui.update_health_bar(life)
	if state != HURT:
		$HurtSound.play()
		change_state(HURT, hurt_texture, "Hurt")

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
		$Sprite2D.offset.x = 0
	if left:
		velocity.x -= run_speed
		$Sprite2D.flip_h = true
		$Sprite2D.offset.x = -11
	# only allow jumping when on the ground
	if jump and is_on_floor():
		$JumpSound.play()
		change_state(JUMP, jump_texture, "Jump")
		velocity.y = jump_speed
	# IDLE transitions to RUN when moving
	if state == IDLE and velocity.x != 0:
		change_state(RUN, run_texture, "Run")
	# RUN transitions to IDLE when standing still
	if state == RUN and velocity.x == 0:
		change_state(IDLE, idle_texture, "Idle")
	# transition to JUMP when in the air
	if state in [IDLE, RUN] and !is_on_floor():
		change_state(JUMP, jump_texture, "Jump")
	# transition from running or jumping to attacking
	if attack and not right and not left and not jump:
		$Sprite2D.set_frame(0)
		change_state(ATTACK, attack2_texture, "Attack2")
	# RUN transitions to IDLE when standing still
	if state == RUN and attack:
		change_state(ATTACK, run_attack2_texture, "RunAttack2")
	$AttackPivot.scale.x = -1 if $Sprite2D.flip_h else 1

func change_state(new_state, texture, animation):
	state = new_state
	match state:
		IDLE:
			$Sprite2D.set_hframes(4)
			$Sprite2D.texture = texture
			$AnimationPlayer.play(animation)
		RUN:
			$Sprite2D.set_hframes(6)
			$Sprite2D.texture = texture
			$AnimationPlayer.play("Run")
		HURT:
			$Sprite2D.set_hframes(4)
			$Sprite2D.texture =texture
			$AnimationPlayer.play(animation)
			await $AnimationPlayer.animation_finished
			change_state(IDLE, idle_texture, "Idle")
		JUMP:
			$Sprite2D.texture = texture
			$Sprite2D.set_hframes(8)
			$AnimationPlayer.play(animation)
		DEAD:
			$Sprite2D.set_hframes(8)
			$Sprite2D.texture = texture
			$AnimationPlayer.play(animation)
			await $AnimationPlayer.animation_finished
			died.emit()
			hide()
		ATTACK:
			$AnimationPlayer.speed_scale = 5.0
			$AttackPivot/AttackArea.monitoring = true
			$Sprite2D.texture = texture
			$Sprite2D.set_hframes(6)
			$AnimationPlayer.play(animation)
			await $AnimationPlayer.animation_finished
			$AttackPivot/AttackArea.monitoring = false
			$AnimationPlayer.speed_scale = 3.0
			if texture == run_attack2_texture or texture == run_attack1_texture:
				change_state(RUN, run_texture, "Run")
			else:
				change_state(IDLE, idle_texture, "Idle")

func _physics_process(delta):
	velocity.y += gravity * delta
	get_input()
	
	move_and_slide()
	
	if state == HURT:
		return
	
	if state == JUMP and is_on_floor():
		change_state(IDLE, idle_texture, "Idle")
		$Dust.emitting = true
	
	# Simplified chunk tracking - only x-axis
	var new_chunk_x = floor(position.x / CHUNK_WIDTH)
	if new_chunk_x != current_chunk_x:
		current_chunk_x = new_chunk_x
		emit_signal("chunk_changed", current_chunk_x)

func take_damage(node, amount):
	#invincible = true
	if invincible or state == DEAD:
		velocity.x = 50
		return
	if not node.get_node("Sprite2D").flip_h:
		velocity.x = 100
		velocity.y = -100
	else:
		velocity.x = -100
		velocity.y = -100
	life -= amount
	print(life, amount)
	hurt()

	invincible = true
	$HitBox.set_deferred("monitoring", false)
	print($HitBox.monitoring)
	$InvincibilityTimer.start(invincibility_time)
	await $InvincibilityTimer.timeout
	invincible = false
	$HitBox.monitoring = true
	
	if life <= 0:
		change_state(DEAD, death_texture, "Death")

func _on_attack_area_area_entered(area: Area2D):
	print("Attack area hit something:", area.name)
	if area.is_in_group("enemy_hitbox"):
		var node = area
		while node:
			if node.has_method("apply_damage"):
				print("Applying damage to:", node.name)
				node.apply_damage(damage)
				break
			node = node.get_parent() 


func _on_hit_box_area_entered(area: Area2D) -> void:
	print("Touched Enemy:", area.name)
	if area.is_in_group("enemy_hitbox"):
		var node = area.get_parent()
		take_damage(node, node.contact_damage)
