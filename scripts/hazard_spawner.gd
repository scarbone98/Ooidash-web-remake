extends Node2D

# Spawns rows of hazards below the screen. Rows are spaced by distance travelled,
# and every row keeps a gap Terry can reach with at most one step from the
# previous row's gap, so no layout is impossible.

signal row_spawned(open_positions: Array, speed: float)

const WARNING_TEXTURE := preload("res://assets/sprites/warning.png")
const FIRST_ROW_DISTANCE := 120.0

@onready var column_manager = get_node("/root/MainScene/ColumnManager")
@onready var game_manager = get_node("/root/MainScene/GameManager")
@onready var player = get_node("/root/MainScene/Player")

var camera: Camera2D
var _distance_since_row := 0.0
var _next_gap := FIRST_ROW_DISTANCE
var _prev_safe: Array = []

func _ready() -> void:
	camera = get_viewport().get_camera_2d()
	_prev_safe = range(column_manager.column_positions.size())

func _process(delta: float) -> void:
	if game_manager.is_game_over:
		return
	var speed: float = game_manager.current_speed()
	_distance_since_row += speed * delta
	if _distance_since_row >= _next_gap:
		_distance_since_row = 0.0
		_next_gap = RunConfig.row_gap(speed)
		_spawn_row(speed)

func _half_view_height() -> float:
	return (get_viewport_rect().size.y / camera.zoom.y) / 2

func _spawn_row(speed: float) -> void:
	var zone: Dictionary = RunConfig.ZONES[game_manager.zone_index]
	var lanes: int = column_manager.column_positions.size()
	var spawn_y := _half_view_height() + 50

	var special := ""
	if not zone.specials.is_empty() and randf() < zone.special_chance:
		special = RunConfig.pick_weighted(zone.specials)

	# Skulls home in on the lane Terry is in right now.
	var forced := int(player.column_index) if special == "skull" else -1
	var blocked := _pick_blocked(lanes, zone.double_chance, forced)
	var safe := range(lanes).filter(func(lane): return lane not in blocked)
	_prev_safe = safe

	var special_lane := -1
	if special == "skull":
		special_lane = forced
	elif special == "ghost":
		var drift_lanes := blocked.filter(func(l): return (l - 1) in safe or (l + 1) in safe)
		if not drift_lanes.is_empty():
			special_lane = drift_lanes.pick_random()
	elif special != "":
		special_lane = blocked.pick_random()

	var ghost_start := -1
	for lane in blocked:
		var kind := special if lane == special_lane else ("rock" if randf() < 0.3 else "meteor")
		var hazard := Hazard.new()
		hazard.kind = kind
		hazard.speed = speed
		hazard.auto_destroy_height = -_half_view_height() - 80
		var start_lane: int = lane

		if kind == "ghost":
			# Ghosts start in an open neighbouring lane and drift into their real one.
			start_lane = [lane - 1, lane + 1].filter(func(l): return l in safe).pick_random()
			ghost_start = start_lane
			hazard.drift_to_x = column_manager.column_positions[lane].x

		var speed_mult: float = Hazard.KINDS[hazard.kind].get("speed_mult", 1.0)
		if speed_mult > 1.0:
			var travel: float = spawn_y - player.position.y
			hazard.speed = speed * speed_mult
			hazard.delay = travel / speed - travel / hazard.speed
			_show_warning(column_manager.column_positions[lane].x, hazard.delay, hazard.kind == "skull")

		hazard.position = Vector2(column_manager.column_positions[start_lane].x, spawn_y)
		add_child(hazard)

	var open_positions: Array = []
	for lane in safe:
		if lane != ghost_start:
			open_positions.append(Vector2(column_manager.column_positions[lane].x, spawn_y))
	row_spawned.emit(open_positions, speed)

# Picks which lanes to block. The result always leaves a lane within one step of
# a lane that was open in the previous row.
func _pick_blocked(lanes: int, double_chance: float, forced: int) -> Array:
	var count := 2 if randf() < double_chance else 1
	count = min(count, lanes - 1)
	while count >= 1:
		for attempt in 12:
			var pool := range(lanes)
			pool.shuffle()
			var blocked: Array = [] if forced < 0 else [forced]
			for lane in pool:
				if blocked.size() >= count:
					break
				if lane not in blocked:
					blocked.append(lane)
			if _is_reachable(lanes, blocked):
				return blocked
		count -= 1
	return [] if forced < 0 else [forced]

func _is_reachable(lanes: int, blocked: Array) -> bool:
	for lane in lanes:
		if lane in blocked:
			continue
		for prev in _prev_safe:
			if abs(lane - prev) <= 1:
				return true
	return false

func _show_warning(x: float, duration: float, homing: bool) -> void:
	var warning := Sprite2D.new()
	warning.texture = WARNING_TEXTURE
	warning.scale = Vector2(3, 3)
	warning.modulate = ScareathonTheme.BLOOD if homing else Color.WHITE
	warning.z_index = 8
	warning.position = Vector2(x, _half_view_height() - 120)  # clear of the score pill
	add_child(warning)
	var blink := warning.create_tween().set_loops(max(1, int(duration / 0.2)))
	blink.tween_property(warning, "modulate:a", 0.25, 0.1)
	blink.tween_property(warning, "modulate:a", 1.0, 0.1)
	get_tree().create_timer(duration, false).timeout.connect(warning.queue_free)
