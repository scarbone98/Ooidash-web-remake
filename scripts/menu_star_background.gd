extends Control

@export var texture: Texture2D
@export var scroll_speed: Vector2 = Vector2(0, -50)

var offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _process(delta: float) -> void:
	if texture == null:
		return

	var tile_size = texture.get_size()
	offset += scroll_speed * delta
	offset.x = fposmod(offset.x, tile_size.x)
	offset.y = fposmod(offset.y, tile_size.y)
	queue_redraw()

func _draw() -> void:
	if texture == null:
		return

	var tile_size = texture.get_size()
	if tile_size.x <= 0 or tile_size.y <= 0:
		return

	var start = Vector2(offset.x - tile_size.x, offset.y - tile_size.y)
	var columns = int(ceil(size.x / tile_size.x)) + 2
	var rows = int(ceil(size.y / tile_size.y)) + 2

	for x in range(columns):
		for y in range(rows):
			var tile_position = start + Vector2(x * tile_size.x, y * tile_size.y)
			draw_texture_rect(texture, Rect2(tile_position, tile_size), false)
