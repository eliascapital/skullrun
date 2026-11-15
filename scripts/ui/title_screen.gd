extends Control
## The opening screen: title, description and the main menu buttons.
## To change the words, edit scripts/config.gd.

const UI = preload("res://scripts/ui/ui.gd")
const MenuBackground = preload("res://scripts/ui/menu_background.gd")

var _title: Label
var _help_layer: Control
var _code_layer: Control
var _code_edit: LineEdit
var _code_message: Label
var _play_button: Button
var _typed := ""  # letters typed on the title screen, to catch the secret code
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
	_play_button.pressed.connect(Game.play)
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
	var story := UI.make_button("STORY", false, 130)
	story.pressed.connect(Game.play_story)
	row.add_child(story)
	var code := UI.make_button("CODE", false, 110)
	code.pressed.connect(_show_code.bind(true))
	row.add_child(code)
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
	_build_code()
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
	elif _code_layer.visible and (event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")):
		_show_code(false)
		get_viewport().set_input_as_handled()
	elif not _code_layer.visible and event is InputEventKey and event.pressed and not event.echo \
			and event.unicode > 0:
		# typing the secret code straight onto the title screen works too
		_typed = (_typed + char(event.unicode).to_lower()).right(Game.UNLOCK_CODE.length())
		if _typed == Game.UNLOCK_CODE:
			_typed = ""
			_show_code(true)
			_submit_code(Game.UNLOCK_CODE)


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
		["Wall jump", "Jump at a wall, then jump again  (from level 7)"],
		["Ground slam", "S / Down arrow in mid-air  (from level 12)"],
		["Pause", "ESC / P"],
		["Restart level", "R"],
		["Touch screen", "Joystick to move (down in mid-air to slam), buttons to\njump and dash. Move them: pause, MOVE TOUCH BUTTONS"],
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
	var tips := UI.make_label("Collect the glowing soul gems, light the lanterns (checkpoints)\nand jump into the swirling portal to finish each level.\nStomp skeletons, but never touch ghosts! Ice: no jumping or turning.\nVents lift you, blue zones flip gravity, coloured portals warp you.", 14, Config.COLOR_MUTED)
	box.add_child(tips)
	box.add_child(_spacer(8))
	var back := UI.make_button("GOT IT", true, 180)
	back.pressed.connect(_show_help.bind(false))
	box.add_child(_centered(back))


func _build_code() -> void:
	_code_layer = ColorRect.new()
	(_code_layer as ColorRect).color = Color(0, 0, 0, 0.7)
	_code_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_code_layer.visible = false
	add_child(_code_layer)
	var center := UI.make_center()
	_code_layer.add_child(center)
	var panel := UI.make_panel(440)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	box.add_child(UI.make_title("SECRET CODE", 46))
	box.add_child(UI.make_label("Know a secret code? Type it in!", 16, Config.COLOR_MUTED))
	_code_edit = LineEdit.new()
	_code_edit.custom_minimum_size = Vector2(300, 48)
	_code_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_code_edit.max_length = 24
	_code_edit.placeholder_text = "type the code here"
	_code_edit.add_theme_font_size_override("font_size", 22)
	_code_edit.add_theme_stylebox_override("normal", UI.style_box(Config.COLOR_BG_LIGHT, Config.COLOR_MUTED))
	_code_edit.add_theme_stylebox_override("focus", UI.style_box(Config.COLOR_BG_LIGHT, Config.COLOR_ACCENT))
	_code_edit.text_submitted.connect(_submit_code)
	box.add_child(_centered(_code_edit))
	_code_message = UI.make_label(" ", 18, Config.COLOR_BONE)
	box.add_child(_code_message)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	var ok := UI.make_button("OK", true, 140)
	ok.pressed.connect(func(): _submit_code(_code_edit.text))
	row.add_child(ok)
	var back := UI.make_button("BACK", false, 140)
	back.pressed.connect(_show_code.bind(false))
	row.add_child(back)


func _show_code(show: bool) -> void:
	_code_layer.visible = show
	if show:
		_code_edit.text = ""
		_code_message.text = " "
		_code_edit.grab_focus()
	else:
		_play_button.grab_focus()


func _submit_code(code: String) -> void:
	if Game.try_code(code):
		_code_message.text = "ALL LEVELS UNLOCKED!"
		_code_message.add_theme_color_override("font_color", Config.COLOR_GOLD)
		_play_button.text = "CONTINUE  •  LEVEL %d" % (Game.continue_level() + 1)
		Sfx.play("win")
	else:
		_code_message.text = "Hmm, that's not a code."
		_code_message.add_theme_color_override("font_color", Config.COLOR_ACCENT)
		Sfx.play("click", 0.6)
		_code_edit.select_all()
		_code_edit.grab_focus()


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
