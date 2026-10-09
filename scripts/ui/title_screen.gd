extends Control
## The opening screen: title, description and the main menu buttons.
## To change the words, edit scripts/config.gd.

const UI = preload("res://scripts/ui/ui.gd")
const MenuBackground = preload("res://scripts/ui/menu_background.gd")

var _title: Label
var _help_layer: Control
var _play_button: Button
var _time := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(MenuBackground.new())

	var center := UI.make_center()
	add_child(center)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 6)
	center.add_child(box)

	_title = UI.make_title(Config.GAME_TITLE, 124)
	_title.pivot_offset = Vector2(0, 0)
	box.add_child(_title)

	var tagline := UI.make_label(Config.TAGLINE, 17, Config.COLOR_ACCENT)
	tagline.add_theme_constant_override("outline_size", 0)
	box.add_child(tagline)

	box.add_child(_spacer(10))

	var desc := UI.make_label(Config.DESCRIPTION, 15, Config.COLOR_MUTED)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(640, 0)
	desc.add_theme_constant_override("line_spacing", 4)
	box.add_child(desc)

	box.add_child(_spacer(22))

	var play_text := "PLAY" if Game.unlocked <= 1 else "CONTINUE  •  LEVEL %d" % (Game.continue_level() + 1)
	_play_button = UI.make_button(play_text, true, 300)
	_play_button.add_theme_font_size_override("font_size", 24)
	_play_button.custom_minimum_size.y = 56
	_play_button.pressed.connect(func(): Game.start_level(Game.continue_level()))
	box.add_child(_centered(_play_button))

	box.add_child(_spacer(6))

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	var levels := UI.make_button("LEVELS", false, 150)
	levels.pressed.connect(Game.goto_level_select)
	row.add_child(levels)
	var help := UI.make_button("HOW TO PLAY", false, 170)
	help.pressed.connect(_show_help.bind(true))
	row.add_child(help)
	if OS.get_name() != "Web":
		var quit := UI.make_button("QUIT", false, 150)
		quit.pressed.connect(get_tree().quit)
		row.add_child(quit)

	var footer := UI.make_label(Config.VERSION_TEXT, 12, Color(Config.COLOR_MUTED, 0.6))
	footer.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	footer.offset_top = -28
	footer.offset_bottom = -10
	footer.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(footer)

	_build_help()
	_play_button.grab_focus()


func _process(delta: float) -> void:
	_time += delta
	# gentle pulse on the title
	var pulse := 0.5 + 0.5 * sin(_time * 2.0)
	_title.add_theme_color_override("font_shadow_color", Config.COLOR_ACCENT_DARK.lerp(Config.COLOR_ACCENT, pulse * 0.6))
	_title.add_theme_constant_override("shadow_offset_y", int(5 + pulse * 3))


func _unhandled_input(event: InputEvent) -> void:
	if _help_layer.visible and (event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")):
		_show_help(false)
		get_viewport().set_input_as_handled()


func _build_help() -> void:
	_help_layer = ColorRect.new()
	(_help_layer as ColorRect).color = Color(0, 0, 0, 0.7)
	_help_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_help_layer.visible = false
	add_child(_help_layer)
	var center := UI.make_center()
	_help_layer.add_child(center)
	var panel := UI.make_panel(560)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var heading := UI.make_title("HOW TO PLAY", 46)
	box.add_child(heading)
	var lines := [
		["Move", "A / D  or  Left / Right arrows"],
		["Jump", "SPACE, W or Up arrow  (hold for a higher jump)"],
		["Double jump", "Jump again in mid-air  (from level 2)"],
		["Dash", "SHIFT / X  (from level 3)"],
		["Pause", "ESC / P"],
		["Restart level", "R"],
	]
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 6)
	for l in lines:
		grid.add_child(UI.make_label(l[0], 16, Config.COLOR_ACCENT, HORIZONTAL_ALIGNMENT_RIGHT))
		grid.add_child(UI.make_label(l[1], 16, Config.COLOR_BONE, HORIZONTAL_ALIGNMENT_LEFT))
	box.add_child(grid)
	box.add_child(_spacer(6))
	var tips := UI.make_label("Collect the glowing soul gems, light the lanterns (checkpoints)\nand jump into the swirling portal to finish each level.\nStomp skeletons from above — but never touch a ghost!", 14, Config.COLOR_MUTED)
	box.add_child(tips)
	box.add_child(_spacer(8))
	var back := UI.make_button("GOT IT", true, 180)
	back.pressed.connect(_show_help.bind(false))
	box.add_child(_centered(back))


func _show_help(show: bool) -> void:
	_help_layer.visible = show
	if show:
		(_help_layer.find_children("*", "Button", true, false)[0] as Button).grab_focus()
	else:
		_play_button.grab_focus()


func _spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


func _centered(c: Control) -> CenterContainer:
	var cc := CenterContainer.new()
	cc.add_child(c)
	return cc
