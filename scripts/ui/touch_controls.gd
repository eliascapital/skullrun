extends CanvasLayer
## On-screen controls for phones and tablets: a joystick (push it down in
## mid-air for a ground slam), jump and dash buttons and a pause button. They
## press the same input actions as the keyboard, so the player doesn't know the
## difference. Only shown on touch screens, and hidden again as soon as a
## keyboard or gamepad is used.
##
## The buttons can be moved: "MOVE TOUCH BUTTONS" in the pause menu calls
## start_editing(), the player drags them around, and the layout is saved.

signal pause_pressed
signal editing_finished

const UI = preload("res://scripts/ui/ui.gd")

const STICK_RADIUS := 64.0
const STICK_DEADZONE := 0.3  # how far (0-1) to push sideways before you start running
const STICK_DOWN := 0.55  # how far (0-1) to push down for a ground slam
const KNOB_RADIUS := 28.0
const JUMP_RADIUS := 62.0
const DASH_RADIUS := 46.0
const PAUSE_RADIUS := 22.0

## Each control's place, measured from the screen corner it's anchored to
## (so the layout still fits when the screen turns or changes size).
const CORNERS := {"stick": Vector2(0, 1), "jump": Vector2(1, 1), "dash": Vector2(1, 1), "pause": Vector2(1, 0)}
const DEFAULT_LAYOUT := {
	"stick": Vector2(130, 120), "jump": Vector2(100, 100), "dash": Vector2(232, 78), "pause": Vector2(44, 80),
}
const RADII := {"stick": STICK_RADIUS + 8.0, "jump": JUMP_RADIUS, "dash": DASH_RADIUS, "pause": PAUSE_RADIUS}

## Set by the level. Used to hide the dash button until you have the power
## and to hide everything once the level is finished.
var player: Node
## Set by the level: returns true for screen points that belong to other
## buttons (the HUD's EXIT button), which the touch controls leave alone.
var is_blocked: Callable

var _pad: Control
var _stick_touch := -1  # index of the finger on the joystick, -1 if none
var _stick_center := Vector2.ZERO
var _stick_knob := Vector2.ZERO  # knob offset from the centre
var _button_touches := {}  # finger index -> "jump" or "dash"
var _held := {}  # actions we are currently holding down

var _editing := false
var _dim: ColorRect
var _drag := {}  # finger index -> [control name, grab offset]
var _edit_box: Control
var _edit_buttons: Array[Button] = []
var _t := 0.0


func _ready() -> void:
	layer = 9  # under the HUD, so the pause menu covers it
	process_mode = Node.PROCESS_MODE_ALWAYS
	_dim = ColorRect.new()  # darkens the level while the buttons are being moved
	_dim.color = Color(0, 0, 0, 0.55)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim.visible = false
	add_child(_dim)
	_pad = Control.new()
	_pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pad.draw.connect(_draw_pad)
	add_child(_pad)
	_build_edit_box()
	get_viewport().size_changed.connect(_pad.queue_redraw)
	visible = DisplayServer.is_touchscreen_available()


func _process(delta: float) -> void:
	_t += delta
	var playing := _is_playing()
	if not playing and not _held.is_empty():
		_release_all()
	_pad.visible = playing or _editing
	if _editing:
		_pad.queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_release_all()


func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventJoypadButton:
		# a real keyboard or gamepad: get the buttons out of the way
		if event.is_pressed() and visible and not _editing:
			visible = false
			_release_all()
		return
	if not (event is InputEventScreenTouch or event is InputEventScreenDrag):
		return
	visible = true
	if _editing:
		_edit_input(event)
		return
	if not _is_playing():
		return  # let the touch reach the pause / level-complete menus
	if event is InputEventScreenTouch:
		if event.pressed:
			if is_blocked.is_valid() and is_blocked.call(event.position):
				return  # it's for the EXIT button
			_touch_down(event.index, event.position)
		else:
			_touch_up(event.index)
	elif event.index == _stick_touch:
		_move_stick(event.position)
	get_viewport().set_input_as_handled()


func _is_playing() -> bool:
	return visible and not _editing and not get_tree().paused and not (player != null and player.frozen)


# ---------------------------------------------------------------------
#  Fingers
# ---------------------------------------------------------------------
func _touch_down(index: int, pos: Vector2) -> void:
	if pos.distance_to(_pos("pause")) < PAUSE_RADIUS * 1.8:
		_release_all()
		pause_pressed.emit()
		return
	if _dash_shown() and pos.distance_to(_pos("dash")) < DASH_RADIUS * 1.5:
		_press_button(index, "dash")
		return
	# everywhere else belongs to the joystick or the jump button, whichever is
	# nearer; the joystick appears under your thumb
	if pos.distance_to(_pos("stick")) < pos.distance_to(_pos("jump")):
		if _stick_touch == -1:
			_stick_touch = index
			_stick_center = _clamp_on_screen(pos, STICK_RADIUS + 12.0)
			_move_stick(pos)
		return
	_press_button(index, "jump")


func _press_button(index: int, action: String) -> void:
	_button_touches[index] = action
	_set_action(action, true)
	_pad.queue_redraw()


func _touch_up(index: int) -> void:
	if index == _stick_touch:
		_stick_touch = -1
		_stick_knob = Vector2.ZERO
		_update_stick_actions()
	elif _button_touches.has(index):
		var action: String = _button_touches[index]
		_button_touches.erase(index)
		if not _button_touches.values().has(action):
			_set_action(action, false)
		_pad.queue_redraw()


func _move_stick(pos: Vector2) -> void:
	var offset := pos - _stick_center
	if offset.length() > STICK_RADIUS:
		# drag the joystick along behind your thumb, so turning around is quick
		_stick_center += offset - offset.limit_length(STICK_RADIUS)
		offset = offset.limit_length(STICK_RADIUS)
	_stick_knob = offset
	_update_stick_actions()


func _update_stick_actions() -> void:
	var v := _stick_knob / STICK_RADIUS
	_set_action("move_left", v.x < -STICK_DEADZONE)
	_set_action("move_right", v.x > STICK_DEADZONE)
	_set_action("move_down", v.y > STICK_DOWN)
	_pad.queue_redraw()


func _set_action(action: String, on: bool) -> void:
	if on == _held.has(action):
		return
	if on:
		_held[action] = true
		Input.action_press(action)
	else:
		_held.erase(action)
		Input.action_release(action)


func _release_all() -> void:
	for action in _held.keys():
		Input.action_release(action)
	_held.clear()
	_button_touches.clear()
	_stick_touch = -1
	_stick_knob = Vector2.ZERO
	_pad.queue_redraw()


# ---------------------------------------------------------------------
#  Moving the buttons
# ---------------------------------------------------------------------
## Shows the controls with DONE / RESET so the player can drag them around.
## The game should already be paused.
func start_editing() -> void:
	_release_all()
	visible = true
	_editing = true
	_drag.clear()
	layer = 11  # above the HUD while moving
	_dim.visible = true
	_edit_box.visible = true
	_pad.queue_redraw()


func _stop_editing() -> void:
	_editing = false
	_drag.clear()
	layer = 9
	_dim.visible = false
	_edit_box.visible = false
	Game.save_progress()
	editing_finished.emit()


func _reset_layout() -> void:
	Game.touch_layout = {}
	_pad.queue_redraw()


func _edit_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			for b in _edit_buttons:
				if b.get_global_rect().grow(8.0).has_point(event.position):
					return  # DONE / RESET handle this tap themselves
			# grab the nearest control under the finger
			var best := ""
			var best_d := INF
			for key in CORNERS:
				if key == "dash" and not _dash_shown():
					continue
				var d: float = event.position.distance_to(_pos(key))
				if d < RADII[key] * 1.4 and d < best_d:
					best = key
					best_d = d
			if best != "":
				_drag[event.index] = [best, _pos(best) - event.position]
		else:
			_drag.erase(event.index)
	elif _drag.has(event.index):
		_set_pos(_drag[event.index][0], event.position + _drag[event.index][1])
	get_viewport().set_input_as_handled()
	_pad.queue_redraw()


func _build_edit_box() -> void:
	_edit_box = VBoxContainer.new()
	_edit_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_edit_box.offset_top = 56
	_edit_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_edit_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_edit_box.add_theme_constant_override("separation", 10)
	_edit_box.visible = false
	add_child(_edit_box)
	var label := UI.make_label("Drag the buttons to where they feel comfortable.", 18, Config.COLOR_BONE)
	label.add_theme_color_override("font_outline_color", Config.COLOR_BG)
	label.add_theme_constant_override("outline_size", 6)
	_edit_box.add_child(label)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	_edit_box.add_child(row)
	var done := UI.make_button("DONE", true, 150)
	done.pressed.connect(_stop_editing)
	var reset := UI.make_button("RESET", false, 150)
	reset.pressed.connect(_reset_layout)
	for b in [done, reset]:
		b.focus_mode = Control.FOCUS_NONE
		row.add_child(b)
		_edit_buttons.append(b)


# ---------------------------------------------------------------------
#  Layout and drawing
# ---------------------------------------------------------------------

func _screen() -> Vector2:
	return get_viewport().get_visible_rect().size


## Where a control is on screen right now (the joystick: where it rests).
func _pos(key: String) -> Vector2:
	var off: Vector2 = Game.touch_layout.get(key, DEFAULT_LAYOUT[key])
	var c: Vector2 = CORNERS[key]
	var s := _screen()
	var p := Vector2(s.x - off.x if c.x > 0.0 else off.x, s.y - off.y if c.y > 0.0 else off.y)
	return _clamp_on_screen(p, RADII[key] + 4.0)


func _set_pos(key: String, p: Vector2) -> void:
	p = _clamp_on_screen(p, RADII[key] + 4.0)
	var c: Vector2 = CORNERS[key]
	var s := _screen()
	Game.touch_layout[key] = Vector2(s.x - p.x if c.x > 0.0 else p.x, s.y - p.y if c.y > 0.0 else p.y)


func _dash_shown() -> bool:
	return player == null or player.can_dash


func _clamp_on_screen(pos: Vector2, margin: float) -> Vector2:
	var s := _screen()
	return Vector2(clampf(pos.x, margin, maxf(margin, s.x - margin)), clampf(pos.y, margin, maxf(margin, s.y - margin)))


func _draw_pad() -> void:
	var bone := Config.COLOR_BONE
	var touching := _stick_touch != -1
	var center := _stick_center if touching else _pos("stick")
	var ring := STICK_RADIUS + 8.0
	_pad.draw_circle(center, ring, Color(0, 0, 0, 0.25))
	_pad.draw_arc(center, ring, 0.0, TAU, 48, Color(bone, 0.5 if touching else 0.3), 3.0, true)
	_pad.draw_circle(center + _stick_knob, KNOB_RADIUS, Color(bone, 0.55 if touching else 0.3))

	_draw_button(_pos("jump"), JUMP_RADIUS, _held.has("jump"), "jump")
	if _dash_shown():
		_draw_button(_pos("dash"), DASH_RADIUS, _held.has("dash"), "dash")
	_draw_button(_pos("pause"), PAUSE_RADIUS, false, "pause")

	if _editing:
		# pulsing outlines show what can be dragged
		var glow := Color(Config.COLOR_GOLD, 0.55 + 0.35 * sin(_t * 5.0))
		for key in CORNERS:
			if key == "dash" and not _dash_shown():
				continue
			_pad.draw_arc(_pos(key), RADII[key] + 6.0, 0.0, TAU, 48, glow, 3.0, true)


func _draw_button(c: Vector2, r: float, pressed: bool, icon: String) -> void:
	var bone := Config.COLOR_BONE
	_pad.draw_circle(c, r, Color(Config.COLOR_ACCENT, 0.6) if pressed else Color(0, 0, 0, 0.3))
	_pad.draw_arc(c, r, 0.0, TAU, 48, Color(bone, 0.45), 3.0, true)
	var ink := Color(bone, 0.85 if pressed else 0.6)
	match icon:
		"jump":  # two chevrons pointing up
			for dy in [-8.0, 10.0]:
				_pad.draw_polyline(PackedVector2Array([c + Vector2(-17, dy + 8), c + Vector2(0, dy - 9),
					c + Vector2(17, dy + 8)]), ink, 5.0, true)
		"dash":  # speed lines and an arrow head
			for dy in [-9.0, 0.0, 9.0]:
				_pad.draw_line(c + Vector2(-20, dy), c + Vector2(-4, dy), ink, 4.0, true)
			_pad.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -14), c + Vector2(20, 0),
				c + Vector2(0, 14)]), ink)
		"pause":
			_pad.draw_rect(Rect2(c + Vector2(-8, -9), Vector2(5, 18)), ink)
			_pad.draw_rect(Rect2(c + Vector2(3, -9), Vector2(5, 18)), ink)
