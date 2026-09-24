class_name Powerup
extends Item

# A floating power pickup. The icon sits on a pulsing glow so it reads as
# different from a gem at a glance.
const ICONS := {
	"shield": {"texture": preload("res://assets/sprites/shield_icon.png"), "scale": 1.5, "frames": 6, "fps": 8.0},
	"katana": {"texture": preload("res://assets/sprites/katana.png"), "scale": 2.0},
	"slow": {"texture": preload("res://assets/sprites/invinc.png"), "scale": 1.0, "frames": 4, "fps": 8.0},
	"magnet": {"texture": preload("res://assets/sprites/magnet.png"), "scale": 2.2},
}
const NAMES := {"shield": "Shield!", "katana": "Katana!", "slow": "Slow-mo!", "magnet": "Magnet!"}

var power := "shield"
var _glow := 0.0
var _icon: Sprite2D

func _ready() -> void:
	add_to_group("item")
	var shape := CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	shape.shape.radius = 18.0
	add_child(shape)
	_icon = icon_sprite(power)
	add_child(_icon)

static func icon_sprite(power_name: String) -> Sprite2D:
	var icon: Dictionary = ICONS[power_name]
	var sprite := Sprite2D.new()
	sprite.texture = icon.texture
	sprite.scale = Vector2.ONE * icon.scale
	if icon.has("frames"):
		sprite.hframes = icon.frames
	return sprite

func _process(delta: float) -> void:
	super(delta)
	_glow += delta
	var icon: Dictionary = ICONS[power]
	if icon.has("frames"):
		_icon.frame = int(_glow * icon.fps) % icon.frames
	queue_redraw()

func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_glow * 6.0)
	draw_circle(Vector2.ZERO, 22.0 + pulse * 3.0, Color(ScareathonTheme.PURPLE_DARK, 0.55))
	draw_arc(Vector2.ZERO, 22.0 + pulse * 3.0, 0, TAU, 24, Color(ScareathonTheme.AMBER, 0.5 + pulse * 0.5), 2.0)
