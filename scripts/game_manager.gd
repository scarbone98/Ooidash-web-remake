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
	if OS.has_feature("JavaScript"):
		var js_obj = JavaScriptObject.new.call()
		js_obj.call("eval", "parent.postMessage({ score: " + str(player_score) + " }, '*')")
	else:
		print("Not running in HTML5, cannot execute JavaScript.")
	get_tree().change_scene_to_file("res://main_menu.tscn")
