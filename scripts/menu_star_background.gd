extends Control

@export var texture: Texture2D
@export var scroll_speed: Vector2 = Vector2(0, -50)

var offset: Vector2 = Vector2.ZERO
var _haze: GradientTexture2D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	_haze = _build_haze()

# Transparent at the top, fading into Scareathon purple and a hint of blood red at the bottom
func _build_haze() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(ScareathonTheme.PURPLE_DARK, 0.0))
	gradient.set_color(1, Color(ScareathonTheme.BLOOD_DARK, 0.55))
	gradient.add_point(0.6, Color(ScareathonTheme.PURPLE_DARK, 0.45))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0, 0)
	texture.fill_to = Vector2(0, 1)
	return texture

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

	draw_texture_rect(_haze, Rect2(Vector2.ZERO, size), false)
