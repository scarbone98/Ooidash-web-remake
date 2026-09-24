class_name LaneBeam
extends Area2D

# A boss beam that fills one lane. It flashes a warning outline first, then turns
# deadly for a moment. Only the shield's grace period protects against it.

const TELEGRAPH := 0.9
const ACTIVE := 0.45
const FADE := 0.2

var color := Color("#a3e635")
var width := 120.0
var top_y := -400.0
var bottom_y := 200.0

var _time := 0.0
var _active := false

func _ready() -> void:
	z_index = 4

func is_dead() -> bool:
	return false

# Beams can't be sliced or smashed; this keeps the hazard interface uniform.
func break_apart() -> void:
	pass

func _process(delta: float) -> void:
	_time += delta
	if not _active and _time >= TELEGRAPH:
		_activate()
	if _active and _time >= TELEGRAPH + ACTIVE and is_in_group("enemy"):
		remove_from_group("enemy")
		set_deferred("monitorable", false)
	if _time >= TELEGRAPH + ACTIVE + FADE:
		queue_free()
	queue_redraw()

func _activate() -> void:
	_active = true
	add_to_group("enemy")
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(width * 0.5, bottom_y - top_y)
	shape.position.y = (top_y + bottom_y) / 2
	add_child(shape)
	Effects.shake(get_viewport().get_camera_2d(), 5.0)

func _draw() -> void:
	var half := width * 0.3
	if not _active:
		var blink := 0.35 + 0.65 * float(int(_time / 0.1) % 2)
		var warn := Color(ScareathonTheme.BLOOD, blink)
		draw_line(Vector2(-half, top_y), Vector2(-half, bottom_y), warn, 2.0)
		draw_line(Vector2(half, top_y), Vector2(half, bottom_y), warn, 2.0)
		return
	var fade := 1.0 - clampf((_time - TELEGRAPH - ACTIVE) / FADE, 0.0, 1.0)
	var flicker := 0.85 + 0.15 * sin(_time * 60.0)
	draw_rect(Rect2(-half, top_y, half * 2, bottom_y - top_y), Color(color, 0.55 * fade * flicker))
	draw_rect(Rect2(-half * 0.4, top_y, half * 0.8, bottom_y - top_y), Color(1, 1, 1, 0.85 * fade))
