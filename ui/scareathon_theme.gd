class_name ScareathonTheme
extends RefCounted

# Palette mirrors the Scareathon site (Tailwind red/purple/amber/orange scales).
const BLOOD := Color("#ef4444")
const BLOOD_DEEP := Color("#7f1d1d")
const BLOOD_DARK := Color("#450a0a")
const PURPLE := Color("#c084fc")
const PURPLE_DARK := Color("#3b0764")
const AMBER := Color("#fcd34d")
const BONE := Color("#ffedd5")
const SHADOW := Color(0, 0, 0, 0.85)

const HEADING_FONT := preload("res://assets/fonts/zombie.ttf")
const BODY_FONT := preload("res://assets/fonts/scoobydoo.ttf")

static func build() -> Theme:
	var theme := Theme.new()
	theme.default_font = BODY_FONT
	theme.default_font_size = 26

	theme.set_color("font_color", "Label", BONE)
	theme.set_color("font_outline_color", "Label", SHADOW)
	theme.set_constant("outline_size", "Label", 6)

	theme.set_type_variation("TitleLabel", "Label")
	theme.set_font("font", "TitleLabel", HEADING_FONT)
	theme.set_font_size("font_size", "TitleLabel", 64)
	theme.set_color("font_color", "TitleLabel", BLOOD)
	theme.set_constant("outline_size", "TitleLabel", 10)

	theme.set_type_variation("ScoreLabel", "Label")
	theme.set_font_size("font_size", "ScoreLabel", 34)
	theme.set_color("font_color", "ScoreLabel", AMBER)

	theme.set_type_variation("HintLabel", "Label")
	theme.set_font_size("font_size", "HintLabel", 18)
	theme.set_color("font_color", "HintLabel", Color(BONE, 0.75))

	theme.set_stylebox("normal", "Button", _box(BLOOD_DARK, BLOOD, BLOOD, 3))
	theme.set_stylebox("hover", "Button", _box(BLOOD_DEEP, AMBER, AMBER, 3))
	theme.set_stylebox("pressed", "Button", _box(BLOOD_DEEP, AMBER, AMBER, 1))
	theme.set_stylebox("focus", "Button", _focus_box())
	theme.set_color("font_color", "Button", BONE)
	theme.set_color("font_hover_color", "Button", AMBER)
	theme.set_color("font_pressed_color", "Button", AMBER)
	theme.set_color("font_focus_color", "Button", BONE)
	theme.set_color("font_outline_color", "Button", SHADOW)
	theme.set_constant("outline_size", "Button", 4)
	theme.set_font_size("font_size", "Button", 30)

	for state in ["normal", "hover", "pressed", "focus"]:
		theme.set_stylebox(state, "CheckButton", StyleBoxEmpty.new())
	theme.set_color("font_color", "CheckButton", BONE)
	theme.set_color("font_hover_color", "CheckButton", AMBER)
	theme.set_color("font_pressed_color", "CheckButton", BONE)

	theme.set_stylebox("panel", "PanelContainer", _panel_box())
	return theme

static func _box(fill: Color, border: Color, glow: Color, glow_size: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(3)
	box.set_corner_radius_all(14)
	box.shadow_color = Color(glow, 0.45)
	box.shadow_size = glow_size * 3
	box.content_margin_left = 28
	box.content_margin_right = 28
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	return box

static func _focus_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.draw_center = false
	box.border_color = AMBER
	box.set_border_width_all(2)
	box.set_corner_radius_all(16)
	box.set_expand_margin_all(4)
	return box

static func _panel_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(PURPLE_DARK, 0.92)
	box.border_color = PURPLE
	box.set_border_width_all(2)
	box.set_corner_radius_all(18)
	box.shadow_color = Color(PURPLE, 0.35)
	box.shadow_size = 14
	box.content_margin_left = 28
	box.content_margin_right = 28
	box.content_margin_top = 24
	box.content_margin_bottom = 24
	return box

static func pill_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(BLOOD_DARK, 0.8)
	box.border_color = BLOOD
	box.set_border_width_all(2)
	box.set_corner_radius_all(20)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 4
	box.content_margin_bottom = 4
	return box
