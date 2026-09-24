extends Node2D

@export var items: Array[ItemData] = []

@onready var game_manager = get_node("/root/MainScene/GameManager")
@onready var player = get_node("/root/MainScene/Player")

var _since_power := 0.0

func _process(delta: float) -> void:
	_since_power += delta

func _on_row_spawned(open_positions: Array, speed: float) -> void:
	if open_positions.is_empty():
		return
	var free_positions := open_positions.duplicate()
	free_positions.shuffle()

	if _should_spawn_power():
		_since_power = 0.0
		var powerup := Powerup.new()
		powerup.power = _pick_power()
		place(powerup, free_positions.pop_back(), speed)

	for item in items:
		if free_positions.is_empty():
			break
		if randf() <= item.spawn_probability:
			place(item.item_scene.instantiate(), free_positions.pop_back(), speed)

func place(item: Item, at: Vector2, speed: float) -> void:
	item.move_speed = speed
	item.position = at
	item.auto_destroy_height = -get_viewport_rect().size.y / 2 - 80
	add_child(item)

func _should_spawn_power() -> bool:
	if game_manager.depth < RunConfig.POWER_MIN_DEPTH or _since_power < RunConfig.POWER_COOLDOWN:
		return false
	if player.timed_power != "":
		return false
	if get_children().any(func(child): return child is Powerup):
		return false
	return randf() < RunConfig.POWER_CHANCE_PER_ROW

func _pick_power() -> String:
	var weights: Dictionary = RunConfig.POWER_WEIGHTS.duplicate()
	if player.has_shield:
		weights.erase("shield")
	return RunConfig.pick_weighted(weights)
