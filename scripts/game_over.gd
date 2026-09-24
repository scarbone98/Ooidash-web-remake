extends CanvasLayer

const MENU_SCENE := "res://main_menu.tscn"

var _root: Control
var _flash: ColorRect

func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	_root = Control.new()
	_root.theme = ScareathonTheme.build()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	_flash = ColorRect.new()
	_flash.color = Color(ScareathonTheme.BLOOD, 0.0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_flash)

func show_results(score: int, best: int, is_new_best: bool, depth: int, zone_name: String, camera: Camera2D) -> void:
	visible = true
	var tween := create_tween()
	tween.tween_property(_flash, "color:a", 0.55, 0.06)
	tween.tween_property(_flash, "color", Color(0.03, 0.0, 0.06, 0.65), 0.35)
	if camera:
		var shake := create_tween()
		for i in 6:
			var strength := 10.0 * (1.0 - i / 6.0)
			shake.tween_property(camera, "offset", Vector2(randf_range(-strength, strength), randf_range(-strength, strength)), 0.04)
		shake.tween_property(camera, "offset", Vector2.ZERO, 0.04)
	tween.tween_callback(_build_panel.bind(score, best, is_new_best, depth, zone_name))

func _build_panel(score: int, best: int, is_new_best: bool, depth: int, zone_name: String) -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)

	var panel := PanelContainer.new()
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)

	box.add_child(_label("Game Over", "TitleLabel"))
	box.add_child(_label("Fell %d m into %s" % [depth, zone_name], "HintLabel"))
	box.add_child(_label("Score  %d" % score, "ScoreLabel"))
	box.add_child(_label("New best!" if is_new_best else "Best  %d" % best, "HintLabel"))

	var again := Button.new()
	again.text = "Play Again"
	again.pressed.connect(_on_play_again)
	box.add_child(again)

	var menu := Button.new()
	menu.text = "Menu"
	menu.pressed.connect(_on_menu)
	box.add_child(menu)

	panel.scale = Vector2(0.85, 0.85)
	panel.pivot_offset = panel.get_combined_minimum_size() / 2
	create_tween().tween_property(panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	again.grab_focus()

func _label(text: String, variation: StringName) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label

func _on_play_again() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)
