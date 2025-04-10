extends CharacterBody2D

signal life_changed
signal died

@export var gravity = 750
@export var run_speed = 150
@export var jump_speed = -300
@export var climb_speed = 50

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
var last_floor = false
var is_on_ladder = false
var life = 100
var can_be_damaged = true

@export var damage: int = 25  # The damage this attack deals

func _ready():
	change_state(IDLE)
	$AttackArea.body_entered.connect(_on_attack_area_body_entered)

func reset(_position):
	position = _position
	show()
	change_state(IDLE)
	life = 100

func hurt():
	if state != HURT:
		$HurtSound.play()
		change_state(HURT)

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
			velocity.x = -100 * sign(velocity.x)
			change_state(IDLE)
			if life <= 0:
				change_state(DEAD)
		JUMP:
			$Sprite2D.texture = jump_texture
			$Sprite2D.set_hframes(8)
			$AnimationPlayer.play("Jump")
		DEAD:
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
	last_floor = is_on_floor()

func take_damage(amount):
	if not can_be_damaged:
		return
	life -= amount
	hurt()
	can_be_damaged = false
	await get_tree().create_timer(1.0).timeout  # 1 second of invincibility
	can_be_damaged = true

func set_life(value):
	life = value
	life_changed.emit(life)

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		# Apply damage to the enemy
		body.apply_damage(damage)
