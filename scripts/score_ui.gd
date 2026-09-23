extends Control

@onready var game_manager = get_node('/root/MainScene/GameManager')
@onready var label: Label = $VBoxContainer/Label

var _shown_score := -1

func _ready() -> void:
	theme = ScareathonTheme.build()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.theme_type_variation = "ScoreLabel"
	label.add_theme_stylebox_override("normal", ScareathonTheme.pill_box())

func _process(_delta: float) -> void:
	if game_manager.player_score != _shown_score:
		_shown_score = game_manager.player_score
		label.text = str(_shown_score)
