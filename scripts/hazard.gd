class_name Hazard
extends Area2D

# Anything that ends the run if it reaches Terry. Built in code from KINDS so new
# hazards only need a sprite sheet and a row here.
#   frames/fps     sprite sheet laid out horizontally
#   radius         hitbox, a little smaller than the art so near misses feel fair
#   spin           degrees per second of sprite rotation
#   speed_mult     fast hazards launch late (after a warning) so they reach Terry
#                  together with the rest of their row instead of overtaking it
#   trail          color of the particle trail, if any
const KINDS := {
	"meteor": {"texture": preload("res://assets/sprites/meteor.png"), "frames": 1, "scale": 1.0, "radius": 24.0, "spin": 45.0},
	"rock": {"texture": preload("res://assets/sprites/3829rock.png"), "frames": 1, "scale": 1.5, "radius": 19.0, "spin": -70.0},
	"comet": {"texture": preload("res://assets/sprites/comet.png"), "frames": 1, "scale": 1.5, "radius": 18.0, "spin": 220.0, "speed_mult": 1.7, "trail": Color("#67e8f9")},
	"ghost": {"texture": preload("res://assets/sprites/ghost.png"), "frames": 6, "fps": 8.0, "scale": 2.6, "radius": 20.0, "alpha": 0.9},
	"pumpkin": {"texture": preload("res://assets/sprites/pumpkin.png"), "frames": 6, "fps": 8.0, "scale": 2.8, "radius": 18.0, "spin": 160.0, "trail": Color("#fb923c")},
	"skull": {"texture": preload("res://assets/sprites/skull.png"), "frames": 6, "fps": 10.0, "scale": 2.4, "radius": 19.0, "speed_mult": 1.4, "trail": Color("#f97316")},
}

# Ghosts lean toward their target lane below this height, then drift at drift_y.
const GHOST_TELEGRAPH_Y := 230.0
const GHOST_DRIFT_Y := 60.0

var kind := "meteor"
var speed := 200.0
var delay := 0.0
var auto_destroy_height := -1000.0
var drift_to_x := NAN
# Fired by a boss; katana slices on these damage the boss.
var boss_shot := false

var _def: Dictionary
var _sprite: Sprite2D
var _frame_size: Vector2
var _frame := 0
var _frame_time := 0.0
var _age := 0.0
var _leaning := false
var _drifted := false
var _dead := false

func _ready() -> void:
	add_to_group("enemy")
	_def = KINDS[kind]

	_sprite = Sprite2D.new()
	_sprite.texture = _def.texture
	_sprite.scale = Vector2.ONE * _def.scale
	_frame_size = _def.texture.get_size() / Vector2(_def.frames, 1)
	_sprite.region_enabled = true
	_sprite.modulate.a = _def.get("alpha", 1.0)
	_set_frame(randi() % _def.frames)
	add_child(_sprite)

	var shape := CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	shape.shape.radius = _def.radius
	add_child(shape)

	if _def.has("trail"):
		add_child(_build_trail(_def.trail))

func is_dead() -> bool:
	return _dead

func _process(delta: float) -> void:
	if delay > 0.0:
		delay -= delta
		return

	_age += delta
	position.y -= speed * delta
	_sprite.rotation_degrees += _def.get("spin", 0.0) * delta
	if kind == "skull":
		_sprite.position.x = sin(_age * 14.0) * 4.0

	if _def.frames > 1:
		_frame_time += delta
		if _frame_time >= 1.0 / _def.fps:
			_frame_time = 0.0
			_set_frame((_frame + 1) % _def.frames)

	if not is_nan(drift_to_x):
		_update_drift()

	if position.y < auto_destroy_height:
		queue_free()

func _update_drift() -> void:
	var direction := signf(drift_to_x - position.x)
	if not _leaning and position.y < GHOST_TELEGRAPH_Y:
		_leaning = true
		_sprite.flip_h = direction < 0
		var lean := create_tween().set_loops(3)
		lean.tween_property(_sprite, "rotation", direction * 0.35, 0.12)
		lean.tween_property(_sprite, "rotation", direction * 0.1, 0.12)
	if not _drifted and position.y < GHOST_DRIFT_Y:
		_drifted = true
		var drift := create_tween().set_parallel()
		drift.tween_property(self, "position:x", drift_to_x, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		drift.tween_property(_sprite, "rotation", 0.0, 0.3)

func _set_frame(index: int) -> void:
	_frame = index
	_sprite.region_rect = Rect2(Vector2(_frame_size.x * index, 0), _frame_size)

# Sliced by the katana or smashed on a shield.
func break_apart() -> void:
	if _dead:
		return
	_dead = true
	set_deferred("monitorable", false)
	var parent := get_parent()
	Effects.split_sprite(parent, _sprite, _sprite.global_position)
	Effects.burst(parent, global_position, _def.get("trail", ScareathonTheme.BONE), 10)
	queue_free()

func _build_trail(color: Color) -> CPUParticles2D:
	var trail := CPUParticles2D.new()
	trail.local_coords = false
	trail.amount = 28
	trail.lifetime = 0.35
	trail.direction = Vector2(0, 1)
	trail.spread = 12.0
	trail.gravity = Vector2.ZERO
	trail.initial_velocity_min = 20.0
	trail.initial_velocity_max = 60.0
	trail.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	trail.emission_sphere_radius = 8.0
	trail.scale_amount_min = 3.0
	trail.scale_amount_max = 6.0
	trail.color_ramp = Effects.fade_ramp(color)
	trail.show_behind_parent = true
	return trail
