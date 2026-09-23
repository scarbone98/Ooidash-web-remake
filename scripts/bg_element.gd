extends Node2D

var move_speed: int = 100
var auto_destroy_x: float

var sprite: AnimatedSprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sprite.position.x = 0
	sprite.position.y = 0
	add_child(sprite)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position.x -= delta * move_speed

	# Elements scroll right-to-left, so free them once they pass the left edge
	if position.x < auto_destroy_x:
		call_deferred("queue_free")
