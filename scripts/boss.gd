class_name Boss
extends Node2D

# A zone boss. It rises from below Terry and fires lane attacks until its health
# (seconds of survival) runs out; katana slices on its shots take extra health.
# Attacks are weighted per boss:
#   volley    one or two lanes at once
#   far_wall  every lane but one, with the gap as far from Terry as possible
#   sweep     lane after lane toward one hole to hide in
#   aimed     three quick shots at Terry's current lane
#   beam      a column-wide beam down Terry's lane after a long telegraph

signal finished

const BOSSES := {
	"ufo": {
		"name": "The Mothership",
		"texture": preload("res://assets/sprites/ufo.png"), "frames": 6, "fps": 8.0, "scale": 4.0,
		"health": 16.0, "rest": 0.75, "beam_color": Color("#a3e635"),
		"shots": ["comet"],
		"attacks": {"volley": 3, "beam": 2, "far_wall": 1},
	},
	"shadowbeast": {
		"name": "The Shadow Beast",
		"texture": preload("res://assets/sprites/shadowbeast.png"), "frames": 6, "fps": 8.0, "scale": 4.0,
		"health": 18.0, "rest": 0.65, "beam_color": Color("#c084fc"),
		"shots": ["ghost"],
		"attacks": {"volley": 2, "sweep": 2, "far_wall": 2},
	},
	"scarecrow": {
		"name": "The Scarecrow",
		"texture": preload("res://assets/sprites/scarecrow.png"), "frames": 6, "fps": 8.0, "scale": 3.0,
		"health": 20.0, "rest": 0.6, "beam_color": Color("#fb923c"),
		"shots": ["pumpkin"],
		"attacks": {"aimed": 2, "far_wall": 2, "sweep": 1, "volley": 1},
	},
	"swampthing": {
		"name": "The Swamp Thing",
		"texture": preload("res://assets/sprites/swampthing.png"), "frames": 6, "fps": 7.0, "scale": 2.6,
		"health": 24.0, "rest": 0.5, "beam_color": Color("#4ade80"),
		"shots": ["meteor", "pumpkin", "skull", "ghost"],
		"attacks": {"volley": 1, "sweep": 2, "far_wall": 2, "beam": 2, "aimed": 1},
	},
}

const WARN_TIME := 0.6
const FAR_WALL_WARN_TIME := 0.85
const SWEEP_WARN_TIME := 0.45
const AIMED_WARN_TIME := 0.5

var id := "ufo"
var spawner: Node2D
var health := 1.0
var max_health := 1.0

@onready var game_manager = get_node("/root/MainScene/GameManager")
@onready var item_spawner = get_node("/root/MainScene/ItemSpawner")

var _def: Dictionary
var _sprite: Sprite2D
var _frame_size: Vector2
var _frame := 0
var _frame_time := 0.0
var _age := 0.0
var _home_x := 0.0
var _target_x := 0.0
var _defeated := false

func _ready() -> void:
	add_to_group("boss")
	_def = BOSSES[id]
	max_health = _def.health
	health = max_health

	_sprite = Sprite2D.new()
	_sprite.texture = _def.texture
	_sprite.scale = Vector2.ONE * _def.scale
	_sprite.region_enabled = true
	_frame_size = _def.texture.get_size() / Vector2(_def.frames, 1)
	_set_frame(0)
	add_child(_sprite)

	_home_x = (spawner.lane_x(0) + spawner.lane_x(spawner.lane_count() - 1)) / 2
	_target_x = _home_x
	position = Vector2(_home_x, spawner.bottom_y() + _frame_size.y * _def.scale)
	var rise := create_tween()
	rise.tween_property(self, "position:y", spawner.bottom_y() - 150, 1.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Effects.shake(get_viewport().get_camera_2d(), 10.0)
	_attack_loop()

func display_name() -> String:
	return _def.name

func health_ratio() -> float:
	return clampf(health / max_health, 0.0, 1.0)

func take_hit(amount: float) -> void:
	if _defeated:
		return
	health -= amount
	_sprite.modulate = Color(2.5, 2.5, 2.5)
	create_tween().tween_property(_sprite, "modulate", Color.WHITE, 0.2)

func _process(delta: float) -> void:
	_age += delta
	_frame_time += delta
	if _frame_time >= 1.0 / _def.fps:
		_frame_time = 0.0
		_set_frame((_frame + 1) % _def.frames)
	_sprite.position.y = sin(_age * 3.0) * 6.0
	queue_redraw()
	position.x = move_toward(position.x, _target_x, 260.0 * delta)

	if not _defeated:
		health -= delta
		if health <= 0.0:
			_defeat()

# A soft aura in the boss's color so dark bosses stand out from the void.
func _draw() -> void:
	if _defeated:
		return
	var radius: float = maxf(_frame_size.x, _frame_size.y) * _def.scale * 0.55
	var pulse := 0.5 + 0.5 * sin(_age * 4.0)
	for i in 3:
		draw_circle(_sprite.position, radius * (1.0 - i * 0.22), Color(_def.beam_color, 0.07 + 0.03 * pulse))

func _set_frame(index: int) -> void:
	_frame = index
	_sprite.region_rect = Rect2(Vector2(_frame_size.x * index, 0), _frame_size)

func _alive() -> bool:
	return not _defeated and is_inside_tree()

# Waits on a child Timer so a pending attack simply stops if the boss is freed.
func _wait(seconds: float) -> void:
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = seconds
	add_child(timer)
	timer.start()
	await timer.timeout
	timer.queue_free()

func _attack_loop() -> void:
	await _wait(1.6)
	while _alive():
		match RunConfig.pick_weighted(_def.attacks):
			"volley":
				await _attack_volley()
			"far_wall":
				await _attack_far_wall()
			"sweep":
				await _attack_sweep()
			"aimed":
				await _attack_aimed()
			"beam":
				await _attack_beam()
		if not _alive():
			return
		await _wait(_def.rest)

func _fire(lanes: Array, warn: float) -> void:
	for lane in lanes:
		spawner.show_warning(lane, warn, false, position.y - _frame_size.y * _def.scale / 2 - 40)
	await _wait(warn)
	if not _alive():
		return
	for lane in lanes:
		spawner.launch_shot(lane, _def.shots.pick_random(), position.y - 30)
	var recoil := create_tween()
	recoil.tween_property(_sprite, "scale", Vector2.ONE * _def.scale * Vector2(1.1, 0.9), 0.06)
	recoil.tween_property(_sprite, "scale", Vector2.ONE * _def.scale, 0.12)

func _attack_volley() -> void:
	var lanes := range(spawner.lane_count())
	lanes.shuffle()
	await _fire(lanes.slice(0, 2 if randf() < 0.5 else 1), WARN_TIME)

func _attack_far_wall() -> void:
	var player_lane: int = spawner.player_lane()
	var gap := 0
	for lane in spawner.lane_count():
		if abs(lane - player_lane) > abs(gap - player_lane) or (abs(lane - player_lane) == abs(gap - player_lane) and randf() < 0.5):
			gap = lane
	await _fire(range(spawner.lane_count()).filter(func(lane): return lane != gap), FAR_WALL_WARN_TIME)

func _attack_sweep() -> void:
	# Shots start at the far side and chase Terry toward the hole, so dodging never
	# means crossing a lane that already has a shot in it.
	var hole: int = randi() % spawner.lane_count()
	var order := range(spawner.lane_count()).filter(func(lane): return lane != hole)
	order.sort_custom(func(a, b): return abs(a - hole) > abs(b - hole))
	for lane in order:
		await _fire([lane], SWEEP_WARN_TIME)
		if not _alive():
			return

func _attack_aimed() -> void:
	for i in 3:
		await _fire([spawner.player_lane()], AIMED_WARN_TIME)
		if not _alive():
			return

func _attack_beam() -> void:
	var lane: int = spawner.player_lane()
	_target_x = spawner.lane_x(lane)
	var beam := LaneBeam.new()
	beam.color = _def.beam_color
	beam.width = spawner.lane_width()
	beam.top_y = spawner.player_y() - 200
	beam.bottom_y = position.y
	beam.position.x = spawner.lane_x(lane)
	spawner.add_child(beam)
	await _wait(LaneBeam.TELEGRAPH + LaneBeam.ACTIVE)
	_target_x = _home_x

func _defeat() -> void:
	_defeated = true
	remove_from_group("boss")
	# Called-off attacks: beams and warnings vanish with the boss.
	for child in spawner.get_children():
		if child is LaneBeam or (child is Sprite2D and child.texture == HazardSpawner.WARNING_TEXTURE):
			child.queue_free()
	var parent := get_parent()
	Effects.split_sprite(parent, _sprite, _sprite.global_position)
	for i in 3:
		Effects.burst(parent, global_position + Vector2(randf_range(-40, 40), randf_range(-30, 30)), _def.beam_color, 20)
	Effects.shake(get_viewport().get_camera_2d(), 12.0)
	game_manager.add_bonus(RunConfig.BOSS_BONUS)
	Effects.popup_text(parent, "Boss down! +%d" % RunConfig.BOSS_BONUS, global_position - Vector2(0, 80), ScareathonTheme.AMBER, 34)

	# Leave a power behind in the lane nearest the wreck.
	var nearest := 0
	for lane in spawner.lane_count():
		if abs(spawner.lane_x(lane) - position.x) < abs(spawner.lane_x(nearest) - position.x):
			nearest = lane
	var drop := Powerup.new()
	drop.power = RunConfig.pick_weighted(RunConfig.POWER_WEIGHTS)
	item_spawner.place(drop, Vector2(spawner.lane_x(nearest), position.y), game_manager.current_speed())

	finished.emit()
	queue_free()
