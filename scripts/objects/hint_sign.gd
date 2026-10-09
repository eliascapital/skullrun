extends Area2D
## A wooden sign that shows a tip when you walk past it.

var text := ""

var _panel: PanelContainer


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(150, 96)
	shape.shape = rect
	shape.position = Vector2(0, -24)
	add_child(shape)

	_panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Config.COLOR_PANEL
	sb.border_color = Color(Config.COLOR_ACCENT, 0.8)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(10)
	_panel.add_theme_stylebox_override("panel", sb)
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Config.COLOR_BONE)
	_panel.add_child(label)
	_panel.z_index = 50
	_panel.modulate.a = 0.0
	add_child(_panel)

	body_entered.connect(_on_body.bind(true))
	body_exited.connect(_on_body.bind(false))


func _on_body(body: Node2D, entered: bool) -> void:
	if body.is_in_group("player"):
		_show(entered)


func _show(on: bool) -> void:
	# centre the bubble above the sign
	_panel.reset_size()
	var s := _panel.get_combined_minimum_size()
	_panel.position = Vector2(-s.x * 0.5, -34 - s.y)
	var tw := create_tween()
	tw.tween_property(_panel, "modulate:a", 1.0 if on else 0.0, 0.2)


func _draw() -> void:
	var wood := Color("6b4f36")
	draw_rect(Rect2(-2, -6, 4, 22), wood.darkened(0.3))
	draw_rect(Rect2(-13, -20, 26, 16), wood)
	draw_rect(Rect2(-13, -20, 26, 3), wood.lightened(0.2))
	draw_string(ThemeDB.fallback_font, Vector2(-4, -7), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Config.COLOR_BONE)
