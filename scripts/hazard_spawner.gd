class_name HazardSpawner
extends Node2D

# Spawns rows of hazards below the screen. Rows are spaced by distance travelled.
# Most rows keep a gap Terry can reach with one step from the previous row's gap;
# "far gap" rows put the only gap two lanes away but arrive later to allow for it.
# Entering a zone with a boss pauses the rows until the boss is beaten.

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
var _next_far := false
var _boss_active := false
var _boss_queue: Array = []

func _ready() -> void:
	camera = get_viewport().get_camera_2d()
	_prev_safe = range(column_manager.column_positions.size())
	game_manager.zone_changed.connect(_on_zone_changed)

func _process(delta: float) -> void:
	if game_manager.is_game_over or _boss_active:
		return
	var speed: float = game_manager.current_speed()
	_distance_since_row += speed * delta
	if _distance_since_row >= _next_gap:
		var zone: Dictionary = RunConfig.ZONES[game_manager.zone_index]
		_distance_since_row = 0.0
		_spawn_row(speed, _next_far)
		# Decide now whether the next row is a far-gap row so it can arrive later.
		_next_far = randf() < zone.far_gap_chance
		_next_gap = RunConfig.row_gap(speed) * (RunConfig.FAR_GAP_SPACING if _next_far else 1.0)

func _on_zone_changed(index: int) -> void:
	var zone: Dictionary = RunConfig.ZONES[index]
	if not zone.has("boss"):
		return
	# One boss at a time; a zone crossed mid-fight sends its boss in afterwards.
	if _boss_active:
		_boss_queue.append(zone.boss)
		return
	_boss_active = true
	get_tree().create_timer(RunConfig.BOSS_ARRIVAL_DELAY, false).timeout.connect(_spawn_boss.bind(zone.boss))

func _spawn_boss(id: String) -> void:
	var boss := Boss.new()
	boss.id = id
	boss.spawner = self
	boss.finished.connect(_on_boss_finished)
	add_child(boss)

func _on_boss_finished() -> void:
	if not _boss_queue.is_empty():
		get_tree().create_timer(RunConfig.BOSS_ARRIVAL_DELAY, false).timeout.connect(_spawn_boss.bind(_boss_queue.pop_front()))
		return
	_boss_active = false
	_prev_safe = range(column_manager.column_positions.size())
	_next_far = false
	_distance_since_row = 0.0
	_next_gap = FIRST_ROW_DISTANCE

func lane_count() -> int:
	return column_manager.column_positions.size()

func lane_x(lane: int) -> float:
	return column_manager.column_positions[lane].x

func lane_width() -> float:
	return column_manager.column_positions[1].x - column_manager.column_positions[0].x

func player_lane() -> int:
	return player.column_index

func player_y() -> float:
	return player.position.y

func bottom_y() -> float:
	return _half_view_height()

# Fires a boss projectile straight up a lane.
func launch_shot(lane: int, kind: String, from_y: float) -> Hazard:
	var hazard := Hazard.new()
	hazard.kind = kind
	hazard.speed = game_manager.current_speed() * Hazard.KINDS[kind].get("speed_mult", 1.0)
	hazard.boss_shot = true
	hazard.auto_destroy_height = -_half_view_height() - 80
	hazard.position = Vector2(lane_x(lane), from_y)
	add_child(hazard)
	return hazard

func _half_view_height() -> float:
	return (get_viewport_rect().size.y / camera.zoom.y) / 2

func _spawn_row(speed: float, far: bool) -> void:
	var zone: Dictionary = RunConfig.ZONES[game_manager.zone_index]
	var lanes: int = column_manager.column_positions.size()
	var spawn_y := _half_view_height() + 50

	var special := ""
	if not zone.specials.is_empty() and randf() < zone.special_chance:
		special = RunConfig.pick_weighted(zone.specials)

	# Skulls home in on the lane Terry is in right now.
	var forced := int(player.column_index) if special == "skull" else -1
	var blocked := _pick_far_blocked(lanes) if far and forced < 0 else _pick_blocked(lanes, zone.double_chance, forced)
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
			show_warning(lane, hazard.delay, hazard.kind == "skull")

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

# Leaves one gap, as far as possible from where Terry could be.
func _pick_far_blocked(lanes: int) -> Array:
	var gap := 0
	var best_distance := -1
	for lane in lanes:
		var distance: int = _prev_safe.map(func(prev): return abs(lane - prev)).min()
		if distance < 2:
			distance = abs(lane - player.column_index)
		if distance > best_distance or (distance == best_distance and randf() < 0.5):
			gap = lane
			best_distance = distance
	return range(lanes).filter(func(lane): return lane != gap)

func _is_reachable(lanes: int, blocked: Array) -> bool:
	for lane in lanes:
		if lane in blocked:
			continue
		for prev in _prev_safe:
			if abs(lane - prev) <= 1:
				return true
	return false

func show_warning(lane: int, duration: float, homing: bool, y: float = NAN) -> void:
	var warning := Sprite2D.new()
	warning.texture = WARNING_TEXTURE
	warning.scale = Vector2(3, 3)
	warning.modulate = ScareathonTheme.BLOOD if homing else Color.WHITE
	warning.z_index = 8
	# Default spot is just clear of the score pill
	warning.position = Vector2(lane_x(lane), _half_view_height() - 120 if is_nan(y) else y)
	add_child(warning)
	var blink := warning.create_tween().set_loops(max(1, int(duration / 0.2)))
	blink.tween_property(warning, "modulate:a", 0.25, 0.1)
	blink.tween_property(warning, "modulate:a", 1.0, 0.1)
	get_tree().create_timer(duration, false).timeout.connect(warning.queue_free)
