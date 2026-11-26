extends Node
## Global game state: which level you're on, saved progress and scene changes.

const LevelData = preload("res://scripts/level_data.gd")
const Skins = preload("res://scripts/skins.gd")
const SAVE_PATH := "user://skullrun_save.cfg"

const TITLE_SCENE := "res://scenes/title.tscn"
const LEVEL_SELECT_SCENE := "res://scenes/level_select.tscn"
const LEVEL_SCENE := "res://scenes/level.tscn"
const INTRO_SCENE := "res://scenes/intro.tscn"
const SHOP_SCENE := "res://scenes/shop.tscn"

## Phones held sideways are wide but short, so the whole level looks tiny.
## On touch screens shorter than this (in CSS pixels) the level camera zooms in.
const PHONE_ZOOM_HEIGHT := 520.0
const PHONE_ZOOM_MAX := 1.45

var level_paths: PackedStringArray = []
var level_headers: Array = []
var current_level := 0

# Progress (saved to disk)
var unlocked := 1  # number of levels you can play
var best_times := {}  # level index (String) -> seconds (real runs only)
var code_best := -1.0  # the time a secret code gives on every level (-1 = no code entered)
var show_code_scores := false  # the level menu shows the code score instead of the real one
var best_gems := {}  # level index (String) -> gems
var seen_intro := false
## Where the player has moved the touch buttons (see scripts/ui/touch_controls.gd).
## Empty = the standard layout.
var touch_layout := {}

# Skins (scripts/skins.gd). Gems you carry through a level's exit portal go in
# the gem bag; the shop spends them.
var gem_bag := 0
var owned_skins: Array = ["classic"]
var skin_id := "classic"
var custom_skin := Skins.DEFAULT_CUSTOM.duplicate()
var used_gem_codes: Array = []  # hashes of the gem codes this save has used
## Infinite gems: after a gem code, the CODE box lets the player pick their own
## number. Typing that number as a code turns infinite gems on. Only its hash is saved.
var infinite_code := ""
var infinite_gems := false
var gems_added := 0  # gems the last finished level put in the bag (for the HUD)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	level_paths = LevelData.list_level_files()
	for p in level_paths:
		level_headers.append(LevelData.read_header(p))
	load_progress()
	get_tree().root.size_changed.connect(_fit_to_screen)
	_fit_to_screen()


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


func goto_shop() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(SHOP_SCENE)


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


## Wide screens show a bit more of the level at the sides ("expand"). An upright
## screen (a phone held the tall way) would show a huge, tall slice of the level,
## so it gets the normal widescreen picture with bars above and below instead.
func _fit_to_screen() -> void:
	var win := get_tree().root
	var upright := win.size.y > win.size.x
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP if upright else Window.CONTENT_SCALE_ASPECT_EXPAND


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
	gems_added = gems
	gem_bag += gems
	save_progress()


# ---------------------------------------------------------------------
#  Skins
# ---------------------------------------------------------------------
## The skin the skull is wearing (a Dictionary, see scripts/skins.gd).
func current_skin() -> Dictionary:
	if skin_id == Skins.CUSTOM_ID:
		return custom_skin
	var s := Skins.find(skin_id)
	return s if not s.is_empty() else Skins.SKINS[0]


func owns_skin(id: String) -> bool:
	return id == "classic" or id in owned_skins


## Spends gems from the bag on a skin and puts it on. False if there aren't enough gems.
func buy_skin(id: String) -> bool:
	if owns_skin(id):
		wear_skin(id)
		return true
	var cost := Skins.price(id)
	if cost < 0 or not can_afford(cost):
		return false
	if not infinite_gems:
		gem_bag -= cost
	owned_skins.append(id)
	wear_skin(id)
	return true


func can_afford(cost: int) -> bool:
	return infinite_gems or gem_bag >= cost


## The gem bag as text: "1,250" or "INFINITE".
func gem_text() -> String:
	return "INFINITE" if infinite_gems else Skins.format_gems(gem_bag)


func wear_skin(id: String) -> void:
	if owns_skin(id) and Skins.exists(id):
		skin_id = id
		save_progress()


## Secret codes (title screen → CODE, or just type one there). They're kept
## only as SHA-256 hashes because this code is public: never write a code
## itself in the code, the docs or a commit. Each one unlocks every level and
## sets your best time on every level to the time next to it. Not case
## sensitive, spaces don't matter.
const CODES := {
	"1996e73821c8c4bd2d08cb5d52904b6b8a8c22def3863a6f90827c87cf6ddaa1": 0.1,
	"01949ff4f7c87a98695f74f58737c1776f3101cf4a4da3970105b3a4c67f5b0e": 0.0,
}
const MAX_CODE_LENGTH := 16

## Gem codes (also typed on the title screen, also kept only as SHA-256
## hashes): each one puts gems in the gem bag, once per save file.
const GEM_CODES := {
	"c315d9cc30342e6ecb562cb6ea183e35e0fe508f0d58b07319d69df873d3c8d9": 500000,
}


static func _code_hash(code: String) -> String:
	return code.strip_edges().to_lower().replace(" ", "").sha256_text()


## True if `code` is any secret code (a level code, a gem code or the
## player's own infinite-gems number).
func is_code(code: String) -> bool:
	return code_time(code) >= 0.0 or GEM_CODES.has(_code_hash(code)) or is_infinite_code(code)


func is_infinite_code(code: String) -> bool:
	return infinite_code != "" and _code_hash(code) == infinite_code


## Sets the player's own infinite-gems number. Returns "" if it worked, or
## what's wrong with it.
func set_infinite_code(number: String) -> String:
	number = number.strip_edges()
	if number.length() < 3 or not number.is_valid_int() or "-" in number or "+" in number:
		return "Use at least 3 numbers."
	if code_time(number) >= 0.0 or GEM_CODES.has(_code_hash(number)):
		return "That's already a code. Pick another number!"
	infinite_code = _code_hash(number)
	save_progress()
	return ""


## Turns infinite gems on if `code` is the player's number. Returns 1 if it
## did, 0 if they're already on, or -1 if `code` isn't the number.
func try_infinite_code(code: String) -> int:
	if not is_infinite_code(code):
		return -1
	if infinite_gems:
		return 0
	infinite_gems = true
	save_progress()
	return 1


## Puts a gem code's gems in the bag. Returns the gems added, 0 if this save
## already used the code, or -1 if `code` isn't a gem code.
func try_gem_code(code: String) -> int:
	var h := _code_hash(code)
	if not GEM_CODES.has(h):
		return -1
	if h in used_gem_codes:
		return 0
	used_gem_codes.append(h)
	gem_bag += int(GEM_CODES[h])
	save_progress()
	return int(GEM_CODES[h])


## The best time a code gives (seconds), or -1 if `code` isn't a code.
func code_time(code: String) -> float:
	return CODES.get(_code_hash(code), -1.0)


## Returns true (unlocking every level and setting every best time) if `code`
## is one of the secret codes.
func try_code(code: String) -> bool:
	var t := code_time(code)
	if t < 0.0:
		return false
	unlocked = maxi(level_count(), 1)
	# real best times are kept: the code score is separate (the level menu switches)
	code_best = t if code_best < 0.0 else minf(code_best, t)
	show_code_scores = true
	seen_intro = true
	save_progress()
	return true


func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "unlocked", unlocked)
	cfg.set_value("progress", "best_times", best_times)
	cfg.set_value("progress", "code_best", code_best)
	cfg.set_value("settings", "show_code_scores", show_code_scores)
	cfg.set_value("progress", "best_gems", best_gems)
	cfg.set_value("progress", "seen_intro", seen_intro)
	cfg.set_value("progress", "gem_bag", gem_bag)
	cfg.set_value("progress", "owned_skins", owned_skins)
	cfg.set_value("progress", "used_gem_codes", used_gem_codes)
	cfg.set_value("progress", "infinite_code", infinite_code)
	cfg.set_value("progress", "infinite_gems", infinite_gems)
	cfg.set_value("settings", "skin", skin_id)
	cfg.set_value("settings", "custom_skin", custom_skin)
	cfg.set_value("settings", "touch_layout", touch_layout)
	cfg.save(SAVE_PATH)


func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	unlocked = clampi(int(cfg.get_value("progress", "unlocked", 1)), 1, maxi(level_count(), 1))
	best_times = cfg.get_value("progress", "best_times", {})
	code_best = cfg.get_value("progress", "code_best", -1.0)
	show_code_scores = cfg.get_value("settings", "show_code_scores", false)
	# older saves wrote code times straight into the best times: no real run
	# is that fast, so move them over to the code score
	for key in best_times.keys():
		if best_times[key] <= 0.1001:
			code_best = best_times[key] if code_best < 0.0 else minf(code_best, best_times[key])
			best_times.erase(key)
	best_gems = cfg.get_value("progress", "best_gems", {})
	seen_intro = cfg.get_value("progress", "seen_intro", unlocked > 1)
	touch_layout = cfg.get_value("settings", "touch_layout", {})
	gem_bag = maxi(int(cfg.get_value("progress", "gem_bag", 0)), 0)
	owned_skins = ["classic"]
	var owned = cfg.get_value("progress", "owned_skins", [])
	if typeof(owned) == TYPE_ARRAY:
		for id in owned:
			if Skins.exists(str(id)) and not str(id) in owned_skins:
				owned_skins.append(str(id))
	var used = cfg.get_value("progress", "used_gem_codes", [])
	used_gem_codes = used if typeof(used) == TYPE_ARRAY else []
	infinite_code = str(cfg.get_value("progress", "infinite_code", ""))
	infinite_gems = bool(cfg.get_value("progress", "infinite_gems", false))
	custom_skin = Skins.clean_custom(cfg.get_value("settings", "custom_skin", {}))
	skin_id = str(cfg.get_value("settings", "skin", "classic"))
	if not owns_skin(skin_id) or not Skins.exists(skin_id):
		skin_id = "classic"


func reset_progress() -> void:
	unlocked = 1
	best_times = {}
	best_gems = {}
	code_best = -1.0
	show_code_scores = false
	save_progress()


## The best time the level menu shows for a level: the real one, or the code
## score when the menu is switched to code scores. -1 if there isn't one.
func shown_best(index: int) -> float:
	if show_code_scores and code_best >= 0.0:
		return code_best
	return best_times.get(str(index), -1.0)


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
