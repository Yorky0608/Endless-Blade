extends CanvasLayer
@onready var health_bar = $HealthBar
@onready var score_label = $Score

var survival_time: float = 0.0
var timer_running: bool = true

var current_score = 0

func _ready():
	# Initialize display
	update_score(current_score)
	update_health_bar(100)  # Assuming max health is 100

func _process(delta):
	if timer_running:
		survival_time += delta
		$SurvivalTimeUpdate.text = format()

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


func _on_survival_time_timeout() -> void:
	# Optional: If you're using a Timer node instead of process
	if timer_running:
		survival_time += 1.0

func format():
	var minutes = floor(survival_time / 60 /2)
	var seconds = fmod(survival_time /2, 60)
	return "%02d:%05.2f" % [minutes, seconds]
