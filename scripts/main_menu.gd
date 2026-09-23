extends Control

const SETTINGS_PATH := "user://settings.cfg"

var main_scene: PackedScene = preload("res://main_scene.tscn")
var music_enabled := true

@onready var title: Label = $VBoxContainer/Label
@onready var start_button: Button = $VBoxContainer/StartButton
@onready var best_label: Label = $VBoxContainer/BestLabel
@onready var music_toggle: CheckButton = $VBoxContainer/MusicRow/MusicToggle

func _ready() -> void:
	theme = ScareathonTheme.build()
	title.theme_type_variation = "TitleLabel"
	title.label_settings = null

	var best := HighScore.load_best()
	best_label.visible = best > 0
	best_label.text = "Best  %d" % best

	_load_settings()
	music_toggle.set_pressed_no_signal(music_enabled)
	_apply_music_setting()
	start_button.grab_focus()
	_pulse_title()


func _pulse_title() -> void:
	title.pivot_offset = title.size / 2
	var tween := create_tween().set_loops()
	tween.tween_property(title, "scale", Vector2(1.05, 1.05), 1.2).set_trans(Tween.TRANS_SINE)
	tween.tween_property(title, "scale", Vector2.ONE, 1.2).set_trans(Tween.TRANS_SINE)


func _load_settings() -> void:
	var config = ConfigFile.new()
	var error = config.load(SETTINGS_PATH)
	if error == OK:
		music_enabled = config.get_value("audio", "music_enabled", true)


func _save_settings() -> void:
	# Load first so other sections (like the best score) survive the save
	var config = ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("audio", "music_enabled", music_enabled)
	config.save(SETTINGS_PATH)


func _apply_music_setting() -> void:
	var master_bus = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(master_bus, not music_enabled)

func _on_start_button_button_down() -> void:
	get_tree().change_scene_to_packed(main_scene)


func _on_music_toggle_toggled(toggled_on: bool) -> void:
	music_enabled = toggled_on
	_apply_music_setting()
	_save_settings()
