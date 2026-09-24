extends Node2D

signal player_died

const SHIELD_TEXTURE := preload("res://assets/sprites/shield_bubble.png")
const SHIELD_FRAMES := 8
const KATANA_TEXTURE := preload("res://assets/sprites/katana.png")
const SLASH_TEXTURE := preload("res://assets/sprites/slash.png")

# The katana cuts anything in Terry's lane or the lanes beside it once it gets this close.
const KATANA_REACH := 150.0
const KATANA_COOLDOWN := 0.12
const MAGNET_REACH := 420.0
const MAGNET_PULL := 700.0
# After the shield pops Terry smashes through hazards for a moment instead of dying.
const SHIELD_GRACE := 1.0
const BASE_SCALE := Vector2(2, 2)
# Terry's center sits this far below the top of the screen, plus half his height,
# so his sprite starts below the HUD rows.
const TOP_MARGIN := 75.0

var column_index: int = 0

var has_shield := false
var timed_power := ""
var timed_left := 0.0
var _grace_left := 0.0
var _slash_cooldown := 0.0

@onready var column_manager = get_node("/root/MainScene/ColumnManager")
@onready var game_manager = get_node("/root/MainScene/GameManager")
@onready var sprite: AnimatedSprite2D = $Sprite2D

var camera: Camera2D
var _shield_sprite: Sprite2D
var _katana_sprite: Sprite2D

func _ready() -> void:
	camera = get_viewport().get_camera_2d()
	# Draw Terry over hazards and beams so he's never hidden
	z_index = 9

	connect("player_died", Callable(game_manager, "on_player_died"))
	column_index = column_manager.column_positions.size() / 2
	update_position()
	position.x = column_manager.get_column_position(column_index).x
	get_viewport().connect("size_changed", Callable(self, "_on_viewport_size_changed"))

	_shield_sprite = Sprite2D.new()
	_shield_sprite.texture = SHIELD_TEXTURE
	_shield_sprite.hframes = SHIELD_FRAMES
	_shield_sprite.scale = BASE_SCALE
	_shield_sprite.visible = false
	add_child(_shield_sprite)

	_katana_sprite = Sprite2D.new()
	_katana_sprite.texture = KATANA_TEXTURE
	_katana_sprite.scale = BASE_SCALE
	_katana_sprite.position = Vector2(26, 6)
	_katana_sprite.visible = false
	add_child(_katana_sprite)

func _on_viewport_size_changed() -> void:
	update_position()

func update_position():
	var half_height: float = sprite.sprite_frames.get_frame_texture(sprite.animation, 0).get_height() * BASE_SCALE.y / 2
	position.y = -((get_viewport_rect().size.y / camera.zoom.y) / 2) + TOP_MARGIN + half_height

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy"):
		_on_hazard_hit(area)
	elif area.is_in_group("item"):
		area.call_deferred("queue_free")
		if area is Powerup:
			activate_power(area.power)
		else:
			game_manager.add_bonus(RunConfig.GEM_BONUS)
			Effects.popup_text(get_parent(), "+%d" % RunConfig.GEM_BONUS, area.global_position)
			_pop()

func _on_hazard_hit(hazard: Area2D) -> void:
	if hazard is Hazard and hazard.is_dead():
		return
	if timed_power == "katana" and hazard is Hazard:
		_slash(hazard)
	elif _grace_left > 0.0:
		hazard.break_apart()
	elif has_shield:
		_set_shield(false)
		_grace_left = SHIELD_GRACE
		hazard.break_apart()
		Effects.burst(get_parent(), global_position, Color("#67e8f9"), 20)
		Effects.shake(camera, 8.0)
	else:
		emit_signal("player_died")

func activate_power(power: String) -> void:
	Effects.popup_text(get_parent(), Powerup.NAMES[power], global_position + Vector2(0, 40), ScareathonTheme.PURPLE, 32)
	_pop()
	if power == "shield":
		_set_shield(true)
		return

	_end_timed_power()
	timed_power = power
	timed_left = RunConfig.POWER_DURATIONS[power]
	match power:
		"katana":
			_katana_sprite.visible = true
		"slow":
			Engine.time_scale = RunConfig.SLOW_TIME_SCALE
			_set_music_pitch(0.8)

func timed_ratio() -> float:
	if timed_power == "":
		return 0.0
	return timed_left / RunConfig.POWER_DURATIONS[timed_power]

func _end_timed_power() -> void:
	match timed_power:
		"katana":
			_katana_sprite.visible = false
		"slow":
			Engine.time_scale = 1.0
			_set_music_pitch(1.0)
	timed_power = ""
	timed_left = 0.0

func _set_shield(on: bool) -> void:
	has_shield = on
	var tween := _shield_sprite.create_tween()
	if on:
		# Blow the bubble up around Terry
		_shield_sprite.visible = true
		_shield_sprite.modulate.a = 1.0
		_shield_sprite.scale = BASE_SCALE * 0.3
		tween.tween_property(_shield_sprite, "scale", BASE_SCALE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		# Pop: the bubble swells and fades out
		tween.set_parallel()
		tween.tween_property(_shield_sprite, "scale", BASE_SCALE * 1.5, 0.18).set_ease(Tween.EASE_OUT)
		tween.tween_property(_shield_sprite, "modulate:a", 0.0, 0.18)
		tween.chain().tween_callback(_shield_sprite.hide)

func _set_music_pitch(pitch: float) -> void:
	for player in get_tree().get_nodes_in_group("audio"):
		player.pitch_scale = pitch

func _pop() -> void:
	var pop := create_tween()
	pop.tween_property(sprite, "scale", BASE_SCALE * 1.2, 0.06)
	pop.tween_property(sprite, "scale", BASE_SCALE, 0.1)

func _process(delta: float) -> void:
	handle_movement(delta)

	# Power timers run on real time so slow-mo doesn't stretch itself out.
	var real_delta := delta / Engine.time_scale
	if timed_power != "":
		timed_left -= real_delta
		if timed_left <= 0.0:
			_end_timed_power()
	if _grace_left > 0.0:
		_grace_left -= real_delta
		sprite.visible = _grace_left <= 0.0 or fmod(_grace_left, 0.16) > 0.08

	if has_shield:
		_shield_sprite.frame = int(Time.get_ticks_msec() / 90.0) % SHIELD_FRAMES

	match timed_power:
		"katana":
			_slash_cooldown -= delta
			if _slash_cooldown <= 0.0:
				var target := _katana_target()
				if target:
					_slash(target)
		"magnet":
			_pull_items(delta)

func _katana_target() -> Hazard:
	var lane_width: float = column_manager.column_positions[1].x - column_manager.column_positions[0].x
	var nearest: Hazard = null
	for hazard in get_tree().get_nodes_in_group("enemy"):
		if not hazard is Hazard or hazard.is_dead():
			continue
		var ahead: float = hazard.global_position.y - global_position.y
		if ahead < -20.0 or ahead > KATANA_REACH:
			continue
		if abs(hazard.global_position.x - global_position.x) > lane_width * 1.2:
			continue
		if nearest == null or hazard.global_position.y < nearest.global_position.y:
			nearest = hazard
	return nearest

func _slash(hazard: Area2D) -> void:
	_slash_cooldown = KATANA_COOLDOWN
	var slash := Sprite2D.new()
	slash.texture = SLASH_TEXTURE
	slash.hframes = 3
	slash.scale = Vector2(3, 3)
	slash.z_index = 7
	slash.rotation = (hazard.global_position - global_position).angle() + PI / 2
	get_parent().add_child(slash)
	slash.global_position = hazard.global_position
	var tween := slash.create_tween()
	tween.tween_property(slash, "frame", 2, 0.12)
	tween.tween_property(slash, "modulate:a", 0.0, 0.1)
	tween.tween_callback(slash.queue_free)

	var swing := create_tween()
	swing.tween_property(_katana_sprite, "rotation", 1.6, 0.05)
	swing.tween_property(_katana_sprite, "rotation", 0.0, 0.12)

	hazard.break_apart()
	game_manager.add_bonus(RunConfig.SLICE_BONUS)
	Effects.popup_text(get_parent(), "+%d" % RunConfig.SLICE_BONUS, hazard.global_position, ScareathonTheme.BONE, 24)
	Effects.shake(camera, 3.0)

func _pull_items(delta: float) -> void:
	for item in get_tree().get_nodes_in_group("item"):
		if item is Powerup:
			continue
		var offset: Vector2 = global_position - item.global_position
		if offset.y < -MAGNET_REACH or offset.y > 30.0:
			continue
		item.global_position.x = move_toward(item.global_position.x, global_position.x, MAGNET_PULL * delta)

func handle_movement(delta: float) -> void:
	var direction = Vector2.ZERO

	if Input.is_action_just_pressed("move_left"):
		direction.x -= 1
	elif Input.is_action_just_pressed("move_right"):
		direction.x += 1

	# Tap on either side of the player to step that way
	if Input.is_action_just_pressed("mouse_button_left"):
		var click_position = get_global_mouse_position()
		if click_position.x < global_position.x:
			direction.x -= 1
		else:
			direction.x += 1

	if direction != Vector2.ZERO:
		column_index = clampi(column_index + int(direction.x), 0, column_manager.column_positions.size() - 1)

	# Glide into the lane quickly instead of teleporting
	var target_x: float = column_manager.get_column_position(column_index).x
	position.x = lerpf(position.x, target_x, 1.0 - exp(-40.0 * delta))
