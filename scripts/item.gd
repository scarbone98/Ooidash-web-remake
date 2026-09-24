extends Area2D
class_name Item

var move_speed: float = 100
var auto_destroy_height: float = -1000

func _process(delta: float) -> void:
	position.y -= delta * move_speed

	if position.y < auto_destroy_height:
		call_deferred("queue_free")
