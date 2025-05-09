extends CanvasLayer

var dam_price = 500
var rad_price = 500
var run_price = 500
var health_price = 500

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var ui = get_node("/root/Main/Level/Entities/Player/UI")
	if ui.current_score < dam_price:
		$Damage.disabled = true
	else:
		$Damage.disabled = false
	
	if ui.current_score < rad_price:
		$AttackRadius.disabled = true
	else:
		$AttackRadius.disabled = false
	
	if ui.current_score < run_price:
		$RunSpeed.disabled = true
	else:
		$RunSpeed.disabled = false
	
	if ui.current_score < health_price:
		$Health.disabled = true
	else:
		$Health.disabled = false
	
	ui.update_score(ui.current_score)


func _on_close_pressed() -> void:
	$AnimationPlayer.play("invisible")
	var ui = get_node("/root/Main/Level/Entities/Player/UI")
	ui.ui_vis()
	var menu = get_parent().find_child("AnimationPlayer")
	menu.play("visible")


func _on_damage_pressed() -> void:
	var player = get_node("/root/Main/Level/Entities/Player")
	player.damage += 1
	var ui = get_node("/root/Main/Level/Entities/Player/UI")
	ui.current_score -= dam_price


func _on_attack_radius_pressed() -> void:
	var player = get_node("/root/Main/Level/Entities/Player")
	player.attack_radius += 1
	player.find_child("AttackPivot").find_child("AttackArea").find_child("CollisionShape2D").shape.size.x = player.attack_radius
	player.find_child("AttackPivot").find_child("AttackArea").find_child("CollisionShape2D").position.x += .5
	var ui = get_node("/root/Main/Level/Entities/Player/UI")
	ui.current_score -= rad_price


func _on_run_speed_pressed() -> void:
	var player = get_node("/root/Main/Level/Entities/Player")
	player.run_speed += 5
	var ui = get_node("/root/Main/Level/Entities/Player/UI")
	ui.current_score -= run_price


func _on_health_pressed() -> void:
	var player = get_node("/root/Main/Level/Entities/Player")
	player.health += 5
	player.max_health += 5
	var ui = get_node("/root/Main/Level/Entities/Player/UI")
	ui.current_score -= health_price
	ui.find_child("HealthBar").max_value = player.max_health
	ui.update_health_bar(player.health)
