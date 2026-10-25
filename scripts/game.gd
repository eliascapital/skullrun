extends Node
## Global game state: which level you're on, saved progress and scene changes.

const LevelData = preload("res://scripts/level_data.gd")
const SAVE_PATH := "user://skullrun_save.cfg"

const TITLE_SCENE := "res://scenes/title.tscn"
const LEVEL_SELECT_SCENE := "res://scenes/level_select.tscn"
const LEVEL_SCENE := "res://scenes/level.tscn"
const INTRO_SCENE := "res://scenes/intro.tscn"

## Phones held sideways are wide but short, so the whole level looks tiny.
## On touch screens shorter than this (in CSS pixels) the level camera zooms in.
const PHONE_ZOOM_HEIGHT := 520.0
const PHONE_ZOOM_MAX := 1.45

var level_paths: PackedStringArray = []
var level_headers: Array = []
var current_level := 0

# Progress (saved to disk)
var unlocked := 1  # number of levels you can play
var best_times := {}  # level index (String) -> seconds
var best_gems := {}  # level index (String) -> gems
var seen_intro := false
## Where the player has moved the touch buttons (see scripts/ui/touch_controls.gd).
## Empty = the standard layout.
var touch_layout := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	level_paths = LevelData.list_level_files()
	for p in level_paths:
		level_headers.append(LevelData.read_header(p))
	load_progress()


func level_count() -> int:
	return level_paths.size()


func level_name(index: int) -> String:
	if index < 0 or index >= level_headers.size():
		return "?"
	return level_headers[index].get("name", "Level %d" % (index + 1))


func is_last_level(index: int) -> bool:
	return index >= level_count() - 1


# ---------------------------------------------------------------------
#  Scene changes
# ---------------------------------------------------------------------
func start_level(index: int) -> void:
	current_level = clampi(index, 0, maxi(level_count() - 1, 0))
	get_tree().paused = false
	get_tree().change_scene_to_file(LEVEL_SCENE)


func restart_level() -> void:
	start_level(current_level)


func next_level() -> void:
	if is_last_level(current_level):
		goto_title()
	else:
		start_level(current_level + 1)


## The opening story. It ends by starting level 1.
func play_story() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(INTRO_SCENE)


func finish_intro() -> void:
	if not seen_intro:
		seen_intro = true
		save_progress()
	start_level(0)


## What the PLAY button does: the story first on a brand-new game.
func play() -> void:
	if not seen_intro and continue_level() == 0:
		play_story()
	else:
		start_level(continue_level())


func goto_title() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(TITLE_SCENE)


func goto_level_select() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(LEVEL_SELECT_SCENE)


## The level the PLAY button starts: the furthest one you've unlocked.
func continue_level() -> int:
	return clampi(unlocked - 1, 0, maxi(level_count() - 1, 0))


# ---------------------------------------------------------------------
#  Phone zoom
# ---------------------------------------------------------------------
## How much the level camera zooms in: about 1.33 on a phone held sideways,
## 1.0 on tablets, computers, and phones held upright.
func phone_zoom() -> float:
	if not DisplayServer.is_touchscreen_available():
		return 1.0
	var css_height := 0.0
	if OS.has_feature("web"):
		css_height = float(str(JavaScriptBridge.eval("window.innerHeight", true)))
	else:
		css_height = DisplayServer.window_get_size().y / maxf(DisplayServer.screen_get_scale(), 1.0)
	return zoom_for_height(css_height)


static func zoom_for_height(css_height: float) -> float:
	if css_height <= 0.0:
		return 1.0
	return clampf(PHONE_ZOOM_HEIGHT / css_height, 1.0, PHONE_ZOOM_MAX)


# ---------------------------------------------------------------------
#  Progress
# ---------------------------------------------------------------------
func complete_level(index: int, time: float, gems: int) -> void:
	var key := str(index)
	if not best_times.has(key) or time < best_times[key]:
		best_times[key] = time
	if not best_gems.has(key) or gems > best_gems[key]:
		best_gems[key] = gems
	unlocked = maxi(unlocked, mini(index + 2, level_count()))
	save_progress()


func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "unlocked", unlocked)
	cfg.set_value("progress", "best_times", best_times)
	cfg.set_value("progress", "best_gems", best_gems)
	cfg.set_value("progress", "seen_intro", seen_intro)
	cfg.set_value("settings", "touch_layout", touch_layout)
	cfg.save(SAVE_PATH)


func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	unlocked = clampi(int(cfg.get_value("progress", "unlocked", 1)), 1, maxi(level_count(), 1))
	best_times = cfg.get_value("progress", "best_times", {})
	best_gems = cfg.get_value("progress", "best_gems", {})
	seen_intro = cfg.get_value("progress", "seen_intro", unlocked > 1)
	touch_layout = cfg.get_value("settings", "touch_layout", {})


func reset_progress() -> void:
	unlocked = 1
	best_times = {}
	best_gems = {}
	save_progress()


static func format_time(seconds: float) -> String:
	var m := int(seconds) / 60
	var s := fmod(seconds, 60.0)
	return "%d:%04.1f" % [m, s]


# ---------------------------------------------------------------------
#  Controls (set up in code so they're easy to find and change)
# ---------------------------------------------------------------------
func _setup_input() -> void:
	_add_action("move_left", [KEY_A, KEY_LEFT], [JOY_BUTTON_DPAD_LEFT], [[JOY_AXIS_LEFT_X, -1.0]])
	_add_action("move_right", [KEY_D, KEY_RIGHT], [JOY_BUTTON_DPAD_RIGHT], [[JOY_AXIS_LEFT_X, 1.0]])
	_add_action("move_down", [KEY_S, KEY_DOWN], [JOY_BUTTON_DPAD_DOWN], [[JOY_AXIS_LEFT_Y, 1.0]])
	_add_action("jump", [KEY_SPACE, KEY_W, KEY_UP, KEY_Z], [JOY_BUTTON_A])
	_add_action("dash", [KEY_SHIFT, KEY_X, KEY_K], [JOY_BUTTON_X, JOY_BUTTON_RIGHT_SHOULDER])
	_add_action("pause", [KEY_ESCAPE, KEY_P], [JOY_BUTTON_START])
	_add_action("restart", [KEY_R], [JOY_BUTTON_BACK])


func _add_action(action: String, keys: Array, buttons: Array = [], axes: Array = []) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.3)
	for k in keys:
		var e := InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(action, e)
	for b in buttons:
		var e := InputEventJoypadButton.new()
		e.button_index = b
		InputMap.action_add_event(action, e)
	for a in axes:
		var e := InputEventJoypadMotion.new()
		e.axis = a[0]
		e.axis_value = a[1]
		InputMap.action_add_event(action, e)
