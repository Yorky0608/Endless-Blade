extends Node

func _ready():
	var path = "res://levels/levelbase.tscn"
	var level = load(path).instantiate()
	add_child(level)
	
	
