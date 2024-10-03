extends Node2D

@export var num_columns: int = 3  # You can change this in the inspector
var column_positions = []

# Reference to the camera
var camera: Camera2D

func _ready():
	camera = get_viewport().get_camera_2d()  # Get the currently active Camera2D
	
	calculate_column_positions()
	get_viewport().connect("size_changed", Callable(self, "_on_viewport_size_changed"))

func calculate_column_positions():
	# Calculate the visible width of the camera
	var screen_width = get_viewport_rect().size.x / camera.zoom.x
	var column_width = screen_width / num_columns
	column_positions.clear()

	for i in range(num_columns):
		var x_position = (column_width * i) + column_width / 2 + (camera.position.x - screen_width / 2)
		column_positions.append(Vector2(x_position, 0))  # Y position is 0 here, adjust for your game needs

func get_column_position(index: int) -> Vector2:
	if index >= 0 and index < num_columns:
		return column_positions[index]
	else:
		return Vector2()  # Return an empty vector if index is out of range

func get_random_column_position() -> Vector2:
	return column_positions[randi() % num_columns]

func _on_viewport_size_changed():
	calculate_column_positions()
