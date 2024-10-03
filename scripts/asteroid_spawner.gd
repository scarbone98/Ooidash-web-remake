extends Node2D

@export var asteroid_scene: PackedScene  # Drag your Asteroid.tscn here in the inspector
@export var spawn_interval: float = 1  # Time interval between spawns
@export var asteroid_speed: float = 200  # Speed at which the asteroids fall

var spawn_timer: Timer
@onready var column_manager = get_node("/root/MainScene/ColumnManager")

var camera: Camera2D

var last_asteroid: Node2D

func _ready() -> void:
	camera = get_node('/root/MainScene/Camera2D')
	_spawn_asteroid()
	
	spawn_timer = Timer.new()
	spawn_timer.set_wait_time(spawn_interval)
	spawn_timer.connect("timeout", Callable(self, "_increase_speed"))
	add_child(spawn_timer)
	spawn_timer.start()

func _process(delta: float) -> void:
	if last_asteroid != null and last_asteroid.position.y <= 0:
		_spawn_asteroid()
	
func get_random_int_in_range(min: int, max: int) -> int:
	return randi() % (max - min + 1) + min

func _spawn_asteroid():
	var spawn_positions = column_manager.column_positions.duplicate()
	for i in range(0, get_random_int_in_range(1,column_manager.column_positions.size()-1)):
		var index_to_spawn = get_random_int_in_range(0, spawn_positions.size()-1)
		
		var spawn_position = column_manager.get_column_position(index_to_spawn)
		spawn_position.y = (get_viewport_rect().size.y / camera.zoom.y) / 2 + 50  # Start at the bottom of the screen
		
		spawn_positions.remove_at(index_to_spawn)
		
		# Instantiate a new asteroid from the PackedScene
		var asteroid = asteroid_scene.instantiate()
		asteroid.position = spawn_position
		asteroid.speed = asteroid_speed
		asteroid.auto_destroy_height = -(get_viewport_rect().size.y / camera.zoom.y) / 2 - 50
		add_child(asteroid)
		
		last_asteroid = asteroid
	
func _increase_speed():
	asteroid_speed += 10
