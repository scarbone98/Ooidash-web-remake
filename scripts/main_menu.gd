extends Control

const SETTINGS_PATH := "user://settings.cfg"

var main_scene: PackedScene = preload("res://main_scene.tscn")
var music_enabled := true

@onready var music_toggle: CheckButton = $VBoxContainer/MusicRow/MusicToggle

func _ready() -> void:
	_load_settings()
	music_toggle.set_pressed_no_signal(music_enabled)
	_apply_music_setting()


func _load_settings() -> void:
	var config = ConfigFile.new()
	var error = config.load(SETTINGS_PATH)
	if error == OK:
		music_enabled = config.get_value("audio", "music_enabled", true)


func _save_settings() -> void:
	var config = ConfigFile.new()
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
