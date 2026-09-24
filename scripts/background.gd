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

# This node is rotated 90°, so local x runs along the screen's height and local y
# along its width. Returns the visible half size in those local axes.
func _visible_half_size() -> Vector2:
	var half: Vector2 = get_viewport_rect().size / camera.zoom / 2
	return Vector2(half.y, half.x)

# Half the sprite's diagonal, so it is fully off screen at this distance past the edge.
func _sprite_radius(sprite: AnimatedSprite2D) -> float:
	var texture := sprite.sprite_frames.get_frame_texture(sprite.animation, 0)
	return texture.get_size().length() / 2 * maxf(sprite.scale.x, sprite.scale.y)

func _spawn_bg_element(sprite: AnimatedSprite2D, speed: float) -> Node2D:
	var center = to_local(camera.get_screen_center_position())
	var half = _visible_half_size()
	var margin := _sprite_radius(sprite) + 20
	var bg_item = bg_element.instantiate()
	bg_item.sprite = sprite
	bg_item.move_speed = speed
	# Start fully below the screen and leave only once fully above it
	bg_item.position = Vector2(center.x + half.x + margin, center.y + randf_range(-half.y, half.y))
	bg_item.auto_destroy_x = center.x - half.x - margin
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
	planet_index = (planet_index + 1) % planets.size()

func _ready() -> void:
	camera = get_viewport().get_camera_2d()  # Get the currently active Camera2D
	if camera != null:
		star_timer = Timer.new()
		planet_timer = Timer.new()
		add_child(star_timer)
		add_child(planet_timer)

		star_timer.set_wait_time(1)
		planet_timer.set_wait_time(15)
		
		star_timer.start()
		planet_timer.start()

		star_timer.timeout.connect(_spawn_star)
		planet_timer.timeout.connect(_spawn_planet)
	

func _process(delta: float) -> void:
	active_bg_elements = active_bg_elements.filter(func(bg_element):
		return bg_element != null  # Keep only non-null entries
	)
