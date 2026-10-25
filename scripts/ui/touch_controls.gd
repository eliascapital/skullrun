extends CanvasLayer
## On-screen controls for phones and tablets: a joystick on the left (push it
## down in mid-air for a ground slam), jump and dash buttons on the right and
## a pause button. They press the same input actions as the keyboard, so the
## player doesn't know the difference. Only shown on touch screens, and hidden
## again as soon as a keyboard or gamepad is used.

signal pause_pressed

const STICK_RADIUS := 64.0
const STICK_DEADZONE := 0.3  # how far (0-1) to push sideways before you start running
const STICK_DOWN := 0.55  # how far (0-1) to push down for a ground slam
const KNOB_RADIUS := 28.0
const JUMP_RADIUS := 62.0
const DASH_RADIUS := 46.0
const PAUSE_RADIUS := 22.0

## Set by the level. Used to hide the dash button until you have the power
## and to hide everything once the level is finished.
var player: Node

var _pad: Control
var _stick_touch := -1  # index of the finger on the joystick, -1 if none
var _stick_center := Vector2.ZERO
var _stick_knob := Vector2.ZERO  # knob offset from the centre
var _button_touches := {}  # finger index -> "jump" or "dash"
var _held := {}  # actions we are currently holding down


func _ready() -> void:
	layer = 9  # under the HUD, so the pause menu covers it
	process_mode = Node.PROCESS_MODE_ALWAYS
	_pad = Control.new()
	_pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pad.draw.connect(_draw_pad)
	add_child(_pad)
	get_viewport().size_changed.connect(_pad.queue_redraw)
	visible = DisplayServer.is_touchscreen_available()


func _process(_delta: float) -> void:
	var playing := _is_playing()
	if not playing and not _held.is_empty():
		_release_all()
	_pad.visible = playing


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_release_all()


func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventJoypadButton:
		# a real keyboard or gamepad: get the buttons out of the way
		if event.is_pressed() and visible:
			visible = false
			_release_all()
		return
	if not (event is InputEventScreenTouch or event is InputEventScreenDrag):
		return
	visible = true
	if not _is_playing():
		return  # let the touch reach the pause / level-complete menus
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_down(event.index, event.position)
		else:
			_touch_up(event.index)
	elif event.index == _stick_touch:
		_move_stick(event.position)
	get_viewport().set_input_as_handled()


func _is_playing() -> bool:
	return visible and not get_tree().paused and not (player != null and player.frozen)


# ---------------------------------------------------------------------
#  Fingers
# ---------------------------------------------------------------------
func _touch_down(index: int, pos: Vector2) -> void:
	if pos.distance_to(_pause_pos()) < PAUSE_RADIUS * 1.8:
		_release_all()
		pause_pressed.emit()
		return
	if pos.x < _screen().x * 0.45:
		# left side: the joystick appears under your thumb
		if _stick_touch == -1:
			_stick_touch = index
			_stick_center = _clamp_stick(pos)
			_move_stick(pos)
		return
	# right side: the dash button, and everywhere else jumps
	var action := "jump"
	if _dash_shown() and pos.distance_to(_dash_pos()) < DASH_RADIUS * 1.5:
		action = "dash"
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
#  Layout and drawing
# ---------------------------------------------------------------------
func _screen() -> Vector2:
	return get_viewport().get_visible_rect().size


func _stick_home() -> Vector2:
	return Vector2(130, _screen().y - 120)


func _jump_pos() -> Vector2:
	return _screen() - Vector2(100, 100)


func _dash_pos() -> Vector2:
	return _screen() - Vector2(232, 78)


func _pause_pos() -> Vector2:
	return Vector2(_screen().x - 44, 80)


func _dash_shown() -> bool:
	return player == null or player.can_dash


## Keeps the whole joystick on screen.
func _clamp_stick(pos: Vector2) -> Vector2:
	var m := STICK_RADIUS + 12.0
	var s := _screen()
	return Vector2(clampf(pos.x, m, s.x - m), clampf(pos.y, m, s.y - m))


func _draw_pad() -> void:
	var bone := Config.COLOR_BONE
	var touching := _stick_touch != -1
	var center := _stick_center if touching else _stick_home()
	var ring := STICK_RADIUS + 8.0
	_pad.draw_circle(center, ring, Color(0, 0, 0, 0.25))
	_pad.draw_arc(center, ring, 0.0, TAU, 48, Color(bone, 0.5 if touching else 0.3), 3.0, true)
	_pad.draw_circle(center + _stick_knob, KNOB_RADIUS, Color(bone, 0.55 if touching else 0.3))

	_draw_button(_jump_pos(), JUMP_RADIUS, _held.has("jump"), "jump")
	if _dash_shown():
		_draw_button(_dash_pos(), DASH_RADIUS, _held.has("dash"), "dash")
	_draw_button(_pause_pos(), PAUSE_RADIUS, false, "pause")


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
