extends Area2D

var speed = 200  # Adjust to make faster or slower
var auto_destroy_height: float

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position.y -= speed * delta
	
	# Check if the asteroid is outside the viewport
	if position.y < auto_destroy_height:  # Adjust the threshold if needed based on the size of your asteroid
		call_deferred("queue_free")
