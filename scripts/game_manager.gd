extends Node

signal player_died

var player_score: int = 0

func _ready() -> void:
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.one_shot = false
	timer.autostart = true
	add_child(timer)
	timer.connect("timeout", Callable(self, "_update_score"))

func _update_score() -> void:
	player_score += 1

func on_player_died():
	pass
	#get_tree().change_scene_to_file("res://main_menu.tscn")
