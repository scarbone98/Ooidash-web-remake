extends Node2D

var move_speed: int = 100
var auto_destroy_height: float

var sprite: AnimatedSprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sprite.position.x = 0
	sprite.position.y = 0
	add_child(sprite)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position.x -= delta * move_speed
	
	# Check if the asteroid is outside the viewport
	if position.y < auto_destroy_height:  # Adjust the threshold if needed based on the size of your asteroid
		call_deferred("queue_free")  # Remove the asteroid from the scene
