extends Node2D

# Tints the backdrop as Terry falls into each new zone.

@onready var game_manager = $GameManager
@onready var star_background: CanvasItem = $BackgroundLayer/StarBackground
@onready var background: CanvasItem = $Background

func _ready() -> void:
	game_manager.zone_changed.connect(_on_zone_changed)

func _on_zone_changed(index: int) -> void:
	var tint: Color = RunConfig.ZONES[index].tint
	var tween := create_tween().set_parallel()
	tween.tween_property(star_background, "modulate", tint, 2.0)
	tween.tween_property(background, "modulate", tint, 2.0)
