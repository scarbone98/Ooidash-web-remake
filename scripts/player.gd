extends Node2D

signal player_died

var column_index: int = 0

@onready var column_manager = get_node("/root/MainScene/ColumnManager")
@onready var game_manager = get_node("/root/MainScene/GameManager")

var camera: Camera2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	camera = get_viewport().get_camera_2d()  # Get the currently active Camera2D
	
	connect("player_died", Callable(game_manager, "on_player_died"))
	column_index = column_manager.column_positions.size() / 2
	update_position()
	# Connect to viewport size change signal to update player position on resize
	get_viewport().connect("size_changed", Callable(self, "_on_viewport_size_changed"))


func update_position():
	position = column_manager.get_column_position(column_index)
	position.y = -((get_viewport_rect().size.y / camera.zoom.y) / 2) + 75
	
func _on_area_2d_area_entered(area: Area2D) -> void:
	emit_signal("player_died")
	
func _process(delta: float) -> void:
	handle_movement()

func handle_movement() -> void:
	var direction = Vector2.ZERO

	# Check for left/right arrow keys
	if Input.is_action_just_pressed("move_left"):
		direction.x -= 1
	elif Input.is_action_just_pressed("move_right"):
		direction.x += 1

	# Check for taps (screen touches)
	if Input.is_action_just_pressed("mouse_button_left"):
		var click_position = get_global_mouse_position()
		
		# Assuming your player is centered horizontally
		if click_position.x < 0:
			direction.x -= 1
		else:
			direction.x += 1

	# Apply movement (e.g., move the player)
	if direction != Vector2.ZERO:
		column_index += direction.x
		column_index = max(column_index, 0)
		column_index = min(column_index, column_manager.column_positions.size() - 1)
	
	update_position()
