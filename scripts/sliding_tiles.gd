extends Node2D

@export var slide_speed: float = 50  # Speed of the background sliding
@export var slide_direction: Vector2 = Vector2.LEFT  # Direction of the slide (LEFT, RIGHT, UP, DOWN)

@onready var bg_1: TextureRect = $bg_1
@onready var bg_2: TextureRect = $bg_2

@export var planets: Array[Node2D] = []

var camera: Camera2D
var texture_size: Vector2

func _ready() -> void:
	camera = get_viewport().get_camera_2d()  # Get the currently active Camera2D

	# Assuming both bg_1 and bg_2 have the same texture and size
	texture_size = bg_1.texture.get_size()

	# Position bg_2 right after bg_1
	if slide_direction == Vector2.LEFT or slide_direction == Vector2.RIGHT:
		bg_2.position.x = bg_1.position.x + texture_size.x
	else:
		bg_2.position.y = bg_1.position.y + texture_size.y

func _process(delta: float) -> void:
	# Move both backgrounds in the desired direction
	bg_1.position += slide_direction * slide_speed * delta
	bg_2.position += slide_direction * slide_speed * delta
	
	# If the backgrounds move out of view, loop them around to the other side
	if slide_direction == Vector2.LEFT or slide_direction == Vector2.RIGHT:
		# Loop bg_1
		if slide_direction == Vector2.LEFT and bg_1.position.x <= -texture_size.x:
			bg_1.position.x = bg_2.position.x + texture_size.x
		elif slide_direction == Vector2.RIGHT and bg_1.position.x >= texture_size.x:
			bg_1.position.x = bg_2.position.x - texture_size.x
		
		# Loop bg_2
		if slide_direction == Vector2.LEFT and bg_2.position.x <= -texture_size.x:
			bg_2.position.x = bg_1.position.x + texture_size.x
		elif slide_direction == Vector2.RIGHT and bg_2.position.x >= texture_size.x:
			bg_2.position.x = bg_1.position.x - texture_size.x
	
	elif slide_direction == Vector2.UP or slide_direction == Vector2.DOWN:
		# Loop bg_1
		if slide_direction == Vector2.UP and bg_1.position.y <= -texture_size.y:
			bg_1.position.y = bg_2.position.y + texture_size.y
		elif slide_direction == Vector2.DOWN and bg_1.position.y >= texture_size.y:
			bg_1.position.y = bg_2.position.y - texture_size.y
		
		# Loop bg_2
		if slide_direction == Vector2.UP and bg_2.position.y <= -texture_size.y:
			bg_2.position.y = bg_1.position.y + texture_size.y
		elif slide_direction == Vector2.DOWN and bg_2.position.y >= texture_size.y:
			bg_2.position.y = bg_1.position.y - texture_size.y
