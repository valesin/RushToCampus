class_name MenuStyle
extends RefCounted
# Shared styling for the menu / end screens so they all look consistent without
# a hand-authored .tres theme. Mirrors the SpriteUtil static-helper pattern.

static func style_title(l: Label, size: int = 54) -> void:
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_constant_override("outline_size", 12)
	l.add_theme_color_override("font_outline_color", Color(0.10, 0.12, 0.22))

static func style_button(b: Button) -> void:
	b.custom_minimum_size = Vector2(220, 52)
	b.add_theme_font_size_override("font_size", 24)
	b.add_theme_color_override("font_color", Color(1, 1, 1))
	b.add_theme_color_override("font_hover_color", Color(1, 1, 0.86))
	b.add_theme_color_override("font_focus_color", Color(1, 1, 1))
	b.add_theme_stylebox_override("normal", _sb(Color(0.20, 0.46, 0.86)))
	b.add_theme_stylebox_override("hover", _sb(Color(0.29, 0.58, 0.98)))
	b.add_theme_stylebox_override("pressed", _sb(Color(0.16, 0.36, 0.70)))
	# Focus must NOT look like hover: same fill as normal, just a bright outline.
	b.add_theme_stylebox_override("focus", _sb_focus())

static func _sb_focus() -> StyleBoxFlat:
	# Same fill as the normal state so a focused button doesn't read as "hovered";
	# a bright thin border keeps keyboard focus visible.
	var s := _sb(Color(0.20, 0.46, 0.86))
	s.set_border_width_all(3)
	s.border_color = Color(1.0, 0.95, 0.6, 0.95)
	return s

static func _sb(c: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.set_corner_radius_all(12)
	s.set_content_margin_all(12)
	s.border_width_bottom = 4
	s.border_color = Color(0, 0, 0, 0.35)
	s.shadow_size = 4
	s.shadow_color = Color(0, 0, 0, 0.25)
	return s
