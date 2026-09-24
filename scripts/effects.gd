class_name Effects
extends RefCounted

# Small one-shot visual effects shared by the player, hazards and pickups.

static func popup_text(parent: Node, text: String, at: Vector2, color: Color = ScareathonTheme.AMBER, size: int = 28) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", ScareathonTheme.BODY_FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", ScareathonTheme.SHADOW)
	label.add_theme_constant_override("outline_size", 6)
	label.z_index = 20
	parent.add_child(label)
	label.global_position = at - Vector2(label.get_combined_minimum_size().x / 2, 20)

	var tween := label.create_tween().set_parallel()
	tween.tween_property(label, "position:y", label.position.y + 60, 0.6).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.2)
	tween.chain().tween_callback(label.queue_free)

# Cuts a sprite's current frame into left and right halves that fly apart.
static func split_sprite(parent: Node, sprite: Sprite2D, at: Vector2) -> void:
	var region := sprite.region_rect if sprite.region_enabled else Rect2(Vector2.ZERO, sprite.texture.get_size())
	var half_width := region.size.x / 2
	for side in [-1, 1]:
		var half := Sprite2D.new()
		half.texture = sprite.texture
		half.region_enabled = true
		half.region_rect = Rect2(region.position + Vector2(half_width if side > 0 else 0.0, 0), Vector2(half_width, region.size.y))
		half.scale = sprite.scale
		half.flip_h = sprite.flip_h
		half.modulate = sprite.modulate
		half.z_index = 5
		parent.add_child(half)
		half.global_position = at + Vector2(side * half_width * sprite.scale.x / 2, 0).rotated(sprite.global_rotation)
		half.global_rotation = sprite.global_rotation

		var tween := half.create_tween().set_parallel()
		tween.tween_property(half, "position", half.position + Vector2(side * 70, -30), 0.45).set_ease(Tween.EASE_OUT)
		tween.tween_property(half, "rotation", half.rotation + side * 1.8, 0.45)
		tween.tween_property(half, "modulate:a", 0.0, 0.45).set_delay(0.1)
		tween.chain().tween_callback(half.queue_free)

static func burst(parent: Node, at: Vector2, color: Color, amount: int = 14) -> void:
	var particles := CPUParticles2D.new()
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = amount
	particles.lifetime = 0.45
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 80.0
	particles.initial_velocity_max = 200.0
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 6.0
	particles.color_ramp = fade_ramp(color)
	particles.z_index = 6
	parent.add_child(particles)
	particles.global_position = at
	particles.emitting = true
	particles.finished.connect(particles.queue_free)

static func shake(camera: Camera2D, strength: float = 6.0) -> void:
	if camera == null:
		return
	var tween := camera.create_tween()
	for i in 5:
		var s := strength * (1.0 - i / 5.0)
		tween.tween_property(camera, "offset", Vector2(randf_range(-s, s), randf_range(-s, s)), 0.03)
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.03)

static func fade_ramp(color: Color) -> Gradient:
	var gradient := Gradient.new()
	gradient.set_color(0, color)
	gradient.set_color(1, Color(color, 0.0))
	return gradient
