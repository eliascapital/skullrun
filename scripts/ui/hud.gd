extends CanvasLayer
## In-game overlay: gem counter, timer, deaths, banners, the pause menu
## and the level-complete screen.

signal restart_requested
signal next_requested
signal menu_requested

const UI = preload("res://scripts/ui/ui.gd")
const SkullArt = preload("res://scripts/skull_art.gd")

var _level_label: Label
var _gems_label: Label
var _time_label: Label
var _deaths_label: Label
var _banner: Label
var _banner_tween: Tween
var _pause_layer: Control
var _pause_first: Button
var _complete_layer: Control
var _complete_box: VBoxContainer
var _is_complete := false
var _boss_box: VBoxContainer
var _boss_label: Label
var _boss_bar: Control
var _boss_hp := 0
var _boss_max := 1


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# --- top bar --------------------------------------------------------
	var bar := MarginContainer.new()
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	for side in ["left", "right", "top"]:
		bar.add_theme_constant_override("margin_" + side, 16)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bar)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(row)
	_level_label = _stat_label(Config.COLOR_BONE)
	row.add_child(_level_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(spacer)
	row.add_child(_icon("gem"))
	_gems_label = _stat_label(Config.COLOR_GEM)
	row.add_child(_gems_label)
	row.add_child(_gap(22))
	row.add_child(_icon("skull"))
	_deaths_label = _stat_label(Config.COLOR_ACCENT)
	row.add_child(_deaths_label)
	row.add_child(_gap(22))
	_time_label = _stat_label(Config.COLOR_BONE)
	_time_label.custom_minimum_size.x = 64
	row.add_child(_time_label)

	# --- banner (level name / new ability) -----------------------------
	_banner = UI.make_label("", 26, Config.COLOR_BONE)
	_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_banner.offset_top = 70
	_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner.add_theme_color_override("font_outline_color", Config.COLOR_BG)
	_banner.add_theme_constant_override("outline_size", 8)
	_banner.modulate.a = 0.0
	root.add_child(_banner)

	_build_boss_bar(root)
	_build_pause(root)
	_build_complete(root)


func set_level_name(text: String) -> void:
	_level_label.text = text


func update_stats(gems: int, total_gems: int, time: float, deaths: int) -> void:
	_gems_label.text = "%d/%d" % [gems, total_gems]
	_deaths_label.text = str(deaths)
	_time_label.text = Game.format_time(time)


func show_banner(text: String, duration: float = 3.0, size: int = 26) -> void:
	_banner.text = text
	_banner.add_theme_font_size_override("font_size", size)
	if _banner_tween:
		_banner_tween.kill()
	_banner_tween = create_tween()
	_banner_tween.tween_property(_banner, "modulate:a", 1.0, 0.3)
	_banner_tween.tween_interval(duration)
	_banner_tween.tween_property(_banner, "modulate:a", 0.0, 0.6)


# ---------------------------------------------------------------------
#  Boss health bar
# ---------------------------------------------------------------------
func show_boss_bar(boss_name: String, max_hp: int) -> void:
	_boss_label.text = boss_name
	_boss_max = max_hp
	_boss_hp = max_hp
	_boss_bar.queue_redraw()
	_boss_box.visible = true
	_boss_box.modulate.a = 0.0
	create_tween().tween_property(_boss_box, "modulate:a", 1.0, 0.5)


func set_boss_hp(hp: int) -> void:
	_boss_hp = hp
	_boss_bar.queue_redraw()


func hide_boss_bar() -> void:
	_boss_box.visible = false


func _build_boss_bar(root: Control) -> void:
	_boss_box = VBoxContainer.new()
	_boss_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_boss_box.offset_top = 44
	_boss_box.offset_bottom = 96
	_boss_box.offset_left = -200
	_boss_box.offset_right = 200
	_boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_box.visible = false
	root.add_child(_boss_box)
	_boss_label = UI.make_title("", 26)
	_boss_label.add_theme_constant_override("shadow_offset_y", 3)
	_boss_box.add_child(_boss_label)
	_boss_bar = Control.new()
	_boss_bar.custom_minimum_size = Vector2(400, 16)
	_boss_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_bar.draw.connect(func():
		var w := _boss_bar.size.x
		_boss_bar.draw_rect(Rect2(0, 0, w, 16), Color(0, 0, 0, 0.6))
		var seg := (w - 4.0) / _boss_max
		for i in _boss_hp:
			_boss_bar.draw_rect(Rect2(2 + i * seg + 1, 2, seg - 2, 12), Config.COLOR_ACCENT)
			_boss_bar.draw_rect(Rect2(2 + i * seg + 1, 2, seg - 2, 4), Config.COLOR_ACCENT.lightened(0.3))
		_boss_bar.draw_rect(Rect2(0, 0, w, 16), Config.COLOR_BONE, false, 2.0)
	)
	_boss_box.add_child(_boss_bar)


# ---------------------------------------------------------------------
#  Pause menu
# ---------------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if _is_complete:
		return
	if event.is_action_pressed("pause"):
		set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("restart") and not get_tree().paused:
		restart_requested.emit()
		get_viewport().set_input_as_handled()


func set_paused(paused: bool) -> void:
	get_tree().paused = paused
	_pause_layer.visible = paused
	if paused:
		_pause_first.grab_focus()


func _build_pause(root: Control) -> void:
	_pause_layer = _dim_layer(root)
	var panel := UI.make_panel(360)
	_pause_layer.get_child(0).add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	box.add_child(UI.make_title("PAUSED", 54))
	_pause_first = UI.make_button("RESUME", true)
	_pause_first.pressed.connect(set_paused.bind(false))
	box.add_child(_pause_first)
	var restart := UI.make_button("RESTART LEVEL")
	restart.pressed.connect(func(): restart_requested.emit())
	box.add_child(restart)
	var menu := UI.make_button("MAIN MENU")
	menu.pressed.connect(func(): menu_requested.emit())
	box.add_child(menu)


# ---------------------------------------------------------------------
#  Level complete
# ---------------------------------------------------------------------
func show_complete(time: float, gems: int, total_gems: int, deaths: int, new_best: bool, is_last: bool) -> void:
	_is_complete = true
	for c in _complete_box.get_children():
		c.queue_free()
	_complete_box.add_child(UI.make_title("LEVEL CLEAR!", 56))
	var stats := GridContainer.new()
	stats.columns = 2
	stats.add_theme_constant_override("h_separation", 30)
	stats.add_theme_constant_override("v_separation", 4)
	var time_text := Game.format_time(time) + ("   NEW BEST!" if new_best else "")
	var gem_text := "%d / %d" % [gems, total_gems] + ("   ALL FOUND!" if gems == total_gems and total_gems > 0 else "")
	for pair in [["Time", time_text], ["Soul gems", gem_text], ["Deaths", str(deaths)]]:
		stats.add_child(UI.make_label(pair[0], 18, Config.COLOR_MUTED, HORIZONTAL_ALIGNMENT_RIGHT))
		stats.add_child(UI.make_label(pair[1], 18, Config.COLOR_BONE, HORIZONTAL_ALIGNMENT_LEFT))
	var center := CenterContainer.new()
	center.add_child(stats)
	_complete_box.add_child(center)
	if is_last:
		var more := UI.make_label("That's every level for now —\nmore are coming soon!", 16, Config.COLOR_GOLD)
		_complete_box.add_child(more)
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 6
	_complete_box.add_child(spacer)
	var first: Button
	if not is_last:
		first = UI.make_button("NEXT LEVEL", true)
		first.pressed.connect(func(): next_requested.emit())
		_complete_box.add_child(first)
	var retry := UI.make_button("PLAY AGAIN", is_last)
	retry.pressed.connect(func(): restart_requested.emit())
	_complete_box.add_child(retry)
	var menu := UI.make_button("MAIN MENU")
	menu.pressed.connect(func(): menu_requested.emit())
	_complete_box.add_child(menu)
	if first == null:
		first = retry
	_complete_layer.visible = true
	_complete_layer.modulate.a = 0.0
	create_tween().tween_property(_complete_layer, "modulate:a", 1.0, 0.4)
	first.grab_focus()


func _build_complete(root: Control) -> void:
	_complete_layer = _dim_layer(root)
	var panel := UI.make_panel(420)
	_complete_layer.get_child(0).add_child(panel)
	_complete_box = VBoxContainer.new()
	_complete_box.add_theme_constant_override("separation", 10)
	panel.add_child(_complete_box)


# ---------------------------------------------------------------------
func _dim_layer(root: Control) -> ColorRect:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.visible = false
	root.add_child(dim)
	dim.add_child(UI.make_center())
	return dim


func _stat_label(color: Color) -> Label:
	var l := UI.make_label("", 18, color, HORIZONTAL_ALIGNMENT_LEFT)
	l.add_theme_color_override("font_outline_color", Config.COLOR_BG)
	l.add_theme_constant_override("outline_size", 6)
	return l


func _icon(kind: String) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(26, 24)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var m := Vector2(11, 12)
		if kind == "gem":
			c.draw_colored_polygon(PackedVector2Array([m + Vector2(0, -9), m + Vector2(7, 0), m + Vector2(0, 9), m + Vector2(-7, 0)]), Config.COLOR_GEM)
		else:
			SkullArt.draw_skull(c, m + Vector2(0, -1), 8.0, Config.COLOR_BONE, Config.COLOR_ACCENT)
	)
	return c


func _gap(w: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size.x = w
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c
