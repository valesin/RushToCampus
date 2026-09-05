class_name MenuStyle
extends RefCounted
# Rush-to-Campus menu styling: cream cards, thick navy borders, pink accents.

const NAVY := Color("#1a2438")
const CREAM := Color("#f7f1e4")
const PINK := Color("#e85a7a")
const TITLE_BLUE := Color("#9fd4ef")
const MUTED := Color("#2c3a52")

static func style_display_title(l: Label, size: int = 56) -> void:
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", TITLE_BLUE)
	l.add_theme_constant_override("outline_size", 14)
	l.add_theme_color_override("font_outline_color", NAVY)
	l.add_theme_color_override("font_shadow_color", PINK)
	l.add_theme_constant_override("shadow_offset_x", 3)
	l.add_theme_constant_override("shadow_offset_y", 3)

static func style_title(l: Label, size: int = 54) -> void:
	style_display_title(l, size)

static func style_subtitle(l: Label, size: int = 22) -> void:
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", MUTED)

static func style_body(l: Label, size: int = 18) -> void:
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	l.add_theme_constant_override("outline_size", 4)
	l.add_theme_color_override("font_outline_color", Color(0.08, 0.1, 0.16, 0.85))

static func style_stat(l: Label, size: int = 22) -> void:
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", NAVY)

static func style_button(b: Button) -> void:
	b.custom_minimum_size = Vector2(280, 56)
	b.add_theme_font_size_override("font_size", 26)
	b.add_theme_color_override("font_color", NAVY)
	b.add_theme_color_override("font_hover_color", NAVY)
	b.add_theme_color_override("font_focus_color", NAVY)
	b.add_theme_color_override("font_pressed_color", NAVY)
	b.add_theme_stylebox_override("normal", _pill(CREAM))
	b.add_theme_stylebox_override("hover", _pill(Color("#fffaf0")))
	b.add_theme_stylebox_override("pressed", _pill(Color("#ebe3d4")))
	b.add_theme_stylebox_override("focus", _pill_focus())

static func style_secondary_button(b: Button) -> void:
	style_button(b)
	b.custom_minimum_size = Vector2(200, 44)
	b.add_theme_font_size_override("font_size", 18)

static func style_hotspot(b: Button) -> void:
	# Invisible click target over baked art CTAs; keep a pink focus ring for keyboard.
	b.flat = true
	b.text = ""
	var empty := StyleBoxEmpty.new()
	b.add_theme_stylebox_override("normal", empty)
	b.add_theme_stylebox_override("hover", empty)
	b.add_theme_stylebox_override("pressed", empty)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color(1, 1, 1, 0.0)
	focus.set_border_width_all(3)
	focus.border_color = PINK
	focus.set_corner_radius_all(16)
	b.add_theme_stylebox_override("focus", focus)

static func card_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = CREAM
	s.set_corner_radius_all(28)
	s.set_border_width_all(5)
	s.border_color = NAVY
	s.shadow_size = 10
	s.shadow_offset = Vector2(0, 6)
	s.shadow_color = Color(0, 0, 0, 0.28)
	s.content_margin_left = 28
	s.content_margin_right = 28
	s.content_margin_top = 24
	s.content_margin_bottom = 24
	return s

static func badge_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(1, 1, 1, 0.92)
	s.set_corner_radius_all(14)
	s.set_border_width_all(3)
	s.border_color = NAVY
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s

static func _pill(c: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.set_corner_radius_all(18)
	s.set_border_width_all(4)
	s.border_color = NAVY
	s.set_content_margin_all(14)
	s.shadow_size = 3
	s.shadow_color = Color(0, 0, 0, 0.18)
	return s

static func _pill_focus() -> StyleBoxFlat:
	var s := _pill(CREAM)
	s.set_border_width_all(5)
	s.border_color = PINK
	return s
