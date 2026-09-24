extends Node

signal zone_changed(index: int)

const GameOver := preload("res://scripts/game_over.gd")

# Score is how deep Terry fell plus bonuses from gems and katana slices.
var depth := 0.0
var bonus := 0
var player_score: int = 0
var zone_index := 0
var is_game_over := false

func _ready() -> void:
	Engine.time_scale = 1.0

func _process(delta: float) -> void:
	if is_game_over:
		return
	depth += current_speed() * delta / RunConfig.PIXELS_PER_METER
	player_score = int(depth) + bonus

	var zone := RunConfig.zone_index_at(depth)
	if zone != zone_index:
		zone_index = zone
		zone_changed.emit(zone)

func current_speed() -> float:
	return RunConfig.speed_at(depth)

func add_bonus(amount: int) -> void:
	bonus += amount
	player_score = int(depth) + bonus

func on_player_died():
	# Two hazards can overlap the player in the same frame; only end the run once.
	if is_game_over:
		return
	is_game_over = true
	Engine.time_scale = 1.0

	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.parent.postMessage({ type: 'PLAYER_DIED', score: " + str(player_score) + " }, '*')", true)

	var is_new_best := HighScore.submit(player_score)
	get_tree().paused = true

	var game_over := GameOver.new()
	get_tree().current_scene.add_child(game_over)
	game_over.show_results(player_score, HighScore.load_best(), is_new_best, int(depth), RunConfig.ZONES[zone_index].name, get_viewport().get_camera_2d())
