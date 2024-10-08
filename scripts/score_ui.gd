extends Control

@onready var game_manager = get_node('/root/MainScene/GameManager')
@onready var label: Label = $VBoxContainer/Label
@onready var fps: Label = $VBoxContainer/FPS
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	label.text = "Score: %d" % [game_manager.player_score]
	fps.text = "FPS: %d" % [Engine.get_frames_per_second()]
