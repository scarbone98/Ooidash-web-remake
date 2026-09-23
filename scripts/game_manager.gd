extends Node

signal player_died

const GameOver := preload("res://scripts/game_over.gd")

var player_score: int = 0
var is_game_over := false

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
	# Two asteroids can overlap the player in the same frame; only end the run once.
	if is_game_over:
		return
	is_game_over = true

	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.parent.postMessage({ type: 'PLAYER_DIED', score: " + str(player_score) + " }, '*')", true)

	var is_new_best := HighScore.submit(player_score)
	get_tree().paused = true

	var game_over := GameOver.new()
	get_tree().current_scene.add_child(game_over)
	game_over.show_results(player_score, HighScore.load_best(), is_new_best, get_viewport().get_camera_2d())
