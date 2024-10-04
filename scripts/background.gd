extends Node2D

@export var planets: Array[PackedScene] = []
@export var stars: Array[PackedScene] = []
@export var bg_element: PackedScene

var camera: Camera2D

var active_bg_elements: Array[Node2D] = []
var planet_index: int = 0

var star_timer: Timer
var planet_timer: Timer

func get_random_int_in_range(min: int, max: int) -> int:
	return randi() % (max - min + 1) + min

func _get_random_spawn_position() -> Vector2:
	var position = Vector2()
	position.x = (get_viewport_rect().size.y / camera.zoom.y) + 150
	position.y = get_random_int_in_range(-(get_viewport_rect().size.x / camera.zoom.x), (get_viewport_rect().size.x / camera.zoom.x))
	return position

func _spawn_bg_element(sprite: AnimatedSprite2D, speed: float) -> Node2D:
	var bg_item = bg_element.instantiate()
	bg_item.sprite = sprite
	bg_item.move_speed = speed
	bg_item.position = _get_random_spawn_position()
	bg_item.auto_destroy_height = -(get_viewport_rect().size.y / camera.zoom.y) / 2 - 150
	add_child(bg_item)
	return bg_item
	
func _spawn_star() -> void:
	var star_index = get_random_int_in_range(0, stars.size() - 1)
	var initialized_star_sprite = stars[star_index].instantiate()
	var star_speed = get_random_int_in_range(10, 500)
	active_bg_elements.append(_spawn_bg_element(initialized_star_sprite, star_speed))

func _spawn_planet() -> void:
	var initialized_planet_sprite = planets[planet_index].instantiate()
	var planet_speed = get_random_int_in_range(50, 250)
	active_bg_elements.append(_spawn_bg_element(initialized_planet_sprite, planet_speed))
	planet_index += (planet_index + 1) % planets.size()

func _ready() -> void:
	camera = get_viewport().get_camera_2d()  # Get the currently active Camera2D
	if camera != null:
		star_timer = Timer.new()
		planet_timer = Timer.new()
		add_child(star_timer)
		add_child(planet_timer)

		star_timer.set_wait_time(0.3)
		planet_timer.set_wait_time(15)
		
		star_timer.start()
		planet_timer.start()

		star_timer.timeout.connect(_spawn_star)
		planet_timer.timeout.connect(_spawn_planet)
	

func _process(delta: float) -> void:
	active_bg_elements = active_bg_elements.filter(func(bg_element):
		return bg_element != null  # Keep only non-null entries
	)
