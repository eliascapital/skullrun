extends Control
## Level select: one button per level file found in the levels folder.

const UI = preload("res://scripts/ui/ui.gd")
const MenuBackground = preload("res://scripts/ui/menu_background.gd")

const COLUMNS := 5


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(MenuBackground.new())

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)

	box.add_child(UI.make_title("CHOOSE A LEVEL", 58))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	center.add_child(grid)

	var first: Button = null
	for i in Game.level_count():
		var b := _level_button(i)
		grid.add_child(b)
		if first == null or i == Game.continue_level():
			first = b

	if Game.level_count() == 0:
		box.add_child(UI.make_label("No levels found in " + Config.LEVELS_DIR, 18, Config.COLOR_ACCENT))

	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 12)
	box.add_child(bottom)
	var back := UI.make_button("BACK", false, 180)
	back.pressed.connect(Game.goto_title)
	bottom.add_child(back)

	if first:
		first.grab_focus()
	else:
		back.grab_focus()


func _level_button(i: int) -> Button:
	var locked := i >= Game.unlocked
	var b := UI.make_button("", i == Game.continue_level() and not locked, 160)
	b.custom_minimum_size = Vector2(168, 104)
	b.disabled = locked
	b.clip_text = true
	var key := str(i)
	var text := "%d\n%s" % [i + 1, Game.level_name(i)]
	if locked:
		text = "%d\nLOCKED" % (i + 1)
	elif Game.best_times.has(key):
		text += "\nBest %s" % Game.format_time(Game.best_times[key])
	b.text = text
	b.add_theme_font_size_override("font_size", 15)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb: StyleBoxFlat = b.get_theme_stylebox(state).duplicate()
		sb.content_margin_left = 6
		sb.content_margin_right = 6
		b.add_theme_stylebox_override(state, sb)
	b.pressed.connect(Game.start_level.bind(i))
	return b


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		Game.goto_title()
