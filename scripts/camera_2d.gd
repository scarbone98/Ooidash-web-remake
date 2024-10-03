extends Camera2D

@onready var column_manager = get_node("/root/MainScene/ColumnManager")

func _ready():
	update_camera()
	# Connect to viewport size change signal to update camera on resize
	get_viewport().connect("size_changed", Callable(self, "_on_viewport_size_changed"))

# This function adjusts the camera's zoom or position to ensure all columns are visible
func update_camera():
	# Get the first and last column positions to calculate the full width
	var first_column_pos = column_manager.get_column_position(0)
	var last_column_pos = column_manager.get_column_position(column_manager.num_columns - 1)
	
	# Calculate the width that the camera needs to cover
	var column_width = last_column_pos.x - first_column_pos.x

	# Center the camera between the first and last column
	var center_x = (first_column_pos.x + last_column_pos.x) / 2
	position.x = center_x

func _on_viewport_size_changed():
	update_camera()
