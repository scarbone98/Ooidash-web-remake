extends Control

@onready var game_manager = get_node('/root/MainScene/GameManager')
@onready var player = get_node('/root/MainScene/Player')
@onready var label: Label = $VBoxContainer/Label

const BAR_WIDTH := 64.0
const BOSS_BAR_WIDTH := 120.0

var _shown_score := -1
var _depth_label: Label
var _power_box: HBoxContainer
var _power_icon: TextureRect
var _power_fill: ColorRect
var _shown_power := ""
var _shield_icon: TextureRect
var _slow_tint: ColorRect
var _boss_box: VBoxContainer
var _boss_name: Label
var _boss_fill: ColorRect

func _ready() -> void:
	theme = ScareathonTheme.build()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.theme_type_variation = "ScoreLabel"
	label.add_theme_stylebox_override("normal", ScareathonTheme.pill_box())

	_slow_tint = ColorRect.new()
	_slow_tint.color = Color(ScareathonTheme.PURPLE, 0.0)
	_slow_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_slow_tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_slow_tint)
	move_child(_slow_tint, 0)

	_depth_label = Label.new()
	_depth_label.theme_type_variation = "HintLabel"
	_depth_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_depth_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_depth_label.position.y = 12
	_depth_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(_depth_label)

	_shield_icon = _icon(_power_texture("shield"), 28)
	_shield_icon.position = Vector2(12, 40)
	_shield_icon.visible = false
	add_child(_shield_icon)

	_power_box = HBoxContainer.new()
	_power_box.add_theme_constant_override("separation", 6)
	_power_box.anchor_left = 1.0
	_power_box.anchor_right = 1.0
	_power_box.offset_left = -12 - 28 - 6 - BAR_WIDTH
	_power_box.offset_right = -12
	_power_box.offset_top = 40
	_power_box.visible = false
	add_child(_power_box)
	_power_icon = _icon(null, 28)
	_power_box.add_child(_power_icon)
	var bar := ColorRect.new()
	bar.color = Color(ScareathonTheme.PURPLE_DARK, 0.8)
	bar.custom_minimum_size = Vector2(BAR_WIDTH, 8)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_power_box.add_child(bar)
	_power_fill = ColorRect.new()
	_power_fill.color = ScareathonTheme.AMBER
	_power_fill.size = Vector2(BAR_WIDTH, 8)
	bar.add_child(_power_fill)

	_build_boss_bar()
	game_manager.zone_changed.connect(_show_zone_banner)
	_show_hint()

func _build_boss_bar() -> void:
	_boss_box = VBoxContainer.new()
	_boss_box.add_theme_constant_override("separation", 2)
	_boss_box.anchor_left = 0.5
	_boss_box.anchor_right = 0.5
	_boss_box.offset_left = -BOSS_BAR_WIDTH / 2
	_boss_box.offset_right = BOSS_BAR_WIDTH / 2
	_boss_box.offset_top = 34
	_boss_box.visible = false
	add_child(_boss_box)
	_boss_name = Label.new()
	_boss_name.theme_type_variation = "HintLabel"
	_boss_name.add_theme_color_override("font_color", ScareathonTheme.BLOOD)
	_boss_name.add_theme_font_size_override("font_size", 15)
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_box.add_child(_boss_name)
	var bar := ColorRect.new()
	bar.color = Color(ScareathonTheme.BLOOD_DARK, 0.85)
	bar.custom_minimum_size = Vector2(BOSS_BAR_WIDTH, 10)
	_boss_box.add_child(bar)
	_boss_fill = ColorRect.new()
	_boss_fill.color = ScareathonTheme.BLOOD
	_boss_fill.size = Vector2(BOSS_BAR_WIDTH, 10)
	bar.add_child(_boss_fill)

func _icon(texture: Texture2D, size: float) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(size, size)
	icon.size = Vector2(size, size)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon

func _power_texture(power: String) -> Texture2D:
	var icon: Dictionary = Powerup.ICONS[power]
	if not icon.has("frames"):
		return icon.texture
	var atlas := AtlasTexture.new()
	atlas.atlas = icon.texture
	atlas.region = Rect2(Vector2.ZERO, icon.texture.get_size() / Vector2(icon.frames, 1))
	return atlas

func _process(delta: float) -> void:
	if game_manager.player_score != _shown_score:
		_shown_score = game_manager.player_score
		label.text = str(_shown_score)
	_depth_label.text = "%d m  ·  %s" % [int(game_manager.depth), RunConfig.ZONES[game_manager.zone_index].name]

	_shield_icon.visible = player.has_shield
	if player.timed_power != _shown_power:
		_shown_power = player.timed_power
		_power_box.visible = _shown_power != ""
		if _shown_power != "":
			_power_icon.texture = _power_texture(_shown_power)
	_power_fill.size.x = BAR_WIDTH * player.timed_ratio()

	var boss := get_tree().get_first_node_in_group("boss")
	_boss_box.visible = boss != null
	if boss:
		_boss_name.text = boss.display_name()
		_boss_fill.size.x = BOSS_BAR_WIDTH * boss.health_ratio()

	var target_tint := 0.14 if player.timed_power == "slow" else 0.0
	_slow_tint.color.a = move_toward(_slow_tint.color.a, target_tint, delta * 0.6)

func _show_zone_banner(index: int) -> void:
	var zone: Dictionary = RunConfig.ZONES[index]
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)

	var title := Label.new()
	title.text = zone.name
	title.theme_type_variation = "TitleLabel"
	title.add_theme_font_size_override("font_size", 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var sub := Label.new()
	sub.text = "%s approaches!" % Boss.BOSSES[zone.boss].name if zone.has("boss") else "%d m" % zone.depth
	sub.theme_type_variation = "HintLabel"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)

	box.modulate.a = 0.0
	var tween := box.create_tween()
	tween.tween_property(box, "modulate:a", 1.0, 0.25)
	tween.tween_interval(1.4)
	tween.tween_property(box, "modulate:a", 0.0, 0.5)
	tween.tween_callback(box.queue_free)

func _show_hint() -> void:
	var hint := Label.new()
	hint.text = "Tap a side to dodge"
	hint.theme_type_variation = "HintLabel"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(hint)
	var tween := hint.create_tween()
	tween.tween_interval(2.5)
	tween.tween_property(hint, "modulate:a", 0.0, 0.6)
	tween.tween_callback(hint.queue_free)
