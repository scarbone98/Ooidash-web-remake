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
	if area.is_in_group("enemy"):
		emit_signal("player_died")
	elif area.is_in_group("item"):
		area.call_deferred("queue_free")
		game_manager.player_score += 10
		_show_pickup(area.global_position)

func _show_pickup(at: Vector2) -> void:
	var label := Label.new()
	label.text = "+10"
	label.add_theme_font_override("font", ScareathonTheme.BODY_FONT)
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", ScareathonTheme.AMBER)
	label.add_theme_color_override("font_outline_color", ScareathonTheme.SHADOW)
	label.add_theme_constant_override("outline_size", 6)
	label.z_index = 10
	get_parent().add_child(label)
	label.global_position = at - Vector2(20, 20)

	var tween := label.create_tween().set_parallel()
	tween.tween_property(label, "position:y", label.position.y + 60, 0.6).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.2)
	tween.chain().tween_callback(label.queue_free)

	var sprite: Node2D = $Sprite2D
	var base_scale := Vector2(2, 2)
	var pop := create_tween()
	pop.tween_property(sprite, "scale", base_scale * 1.2, 0.06)
	pop.tween_property(sprite, "scale", base_scale, 0.1)

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

		# Tap on either side of the player to step that way
		if click_position.x < global_position.x:
			direction.x -= 1
		else:
			direction.x += 1

	# Apply movement (e.g., move the player)
	if direction != Vector2.ZERO:
		column_index += direction.x
		column_index = max(column_index, 0)
		column_index = min(column_index, column_manager.column_positions.size() - 1)
	
	update_position()
