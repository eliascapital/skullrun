extends RefCounted
## Helpers that build menu widgets in the SKULLRUN style.

const TITLE_FONT := preload("res://assets/fonts/Creepster-Regular.ttf")


static func style_box(bg: Color, border: Color, border_width: int = 2, radius: int = 8) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_width)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb


static func make_button(text: String, primary: bool = false, min_width: float = 240.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_width, 48)
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_size_override("font_size", 20)
	var accent := Config.COLOR_ACCENT
	var normal_bg := Color(accent, 0.9) if primary else Color(0, 0, 0, 0.25)
	var normal_border := accent if primary else Color(Config.COLOR_BONE, 0.35)
	b.add_theme_stylebox_override("normal", style_box(normal_bg, normal_border))
	b.add_theme_stylebox_override("hover", style_box(accent.lightened(0.1), accent.lightened(0.3)))
	b.add_theme_stylebox_override("pressed", style_box(Config.COLOR_ACCENT_DARK, accent))
	b.add_theme_stylebox_override("focus", style_box(Color(0, 0, 0, 0), Config.COLOR_BONE, 2))
	b.add_theme_stylebox_override("disabled", style_box(Color(0, 0, 0, 0.3), Color(Config.COLOR_MUTED, 0.25)))
	b.add_theme_color_override("font_color", Config.COLOR_BONE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_focus_color", Config.COLOR_BONE)
	b.add_theme_color_override("font_disabled_color", Color(Config.COLOR_MUTED, 0.6))
	b.mouse_entered.connect(func():
		if not b.disabled:
			Sfx.play("hover")
	)
	b.pressed.connect(func(): Sfx.play("click"))
	return b


static func make_label(text: String, size: int = 18, color: Color = Config.COLOR_BONE,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func make_title(text: String, size: int = 120) -> Label:
	var l := make_label(text, size, Config.COLOR_BONE)
	l.add_theme_font_override("font", TITLE_FONT)
	l.add_theme_color_override("font_shadow_color", Config.COLOR_ACCENT_DARK)
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 6)
	l.add_theme_color_override("font_outline_color", Config.COLOR_BG)
	l.add_theme_constant_override("outline_size", 10)
	return l


static func make_panel(width: float = 520.0) -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(width, 0)
	var sb := style_box(Config.COLOR_PANEL, Color(Config.COLOR_ACCENT, 0.7), 2, 14)
	sb.content_margin_left = 34
	sb.content_margin_right = 34
	sb.content_margin_top = 26
	sb.content_margin_bottom = 26
	sb.shadow_color = Color(0, 0, 0, 0.6)
	sb.shadow_size = 18
	p.add_theme_stylebox_override("panel", sb)
	return p


## A full-screen container that keeps its child centred.
static func make_center() -> CenterContainer:
	var c := CenterContainer.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return c
