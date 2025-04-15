extends CanvasLayer
@onready var health_bar = $VBoxContainer/HealthBar
@onready var score_label = $Score

var current_score = 0

func _ready():
	# Initialize display
	update_score(current_score)
	update_health_bar(100)  # Assuming max health is 100a

func update_score(value):
	current_score = value
	score_label.text = "Score: %s" % current_score

func update_health_bar(value):
	health_bar.value = value

func show_message(text):
	$Message.text = text
	$Message.show()
	await get_tree().create_timer(2).timeout
	$Message.hide()
