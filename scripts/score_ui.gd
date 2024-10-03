extends Control

@onready var game_manager = get_node('/root/MainScene/GameManager')
@onready var label: Label = $Label
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	label.text = "Score: %d" % [game_manager.player_score]
