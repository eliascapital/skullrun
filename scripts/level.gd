extends Node2D
## Builds and runs one level from its text file (see levels/README.md).

const T := 32
const CHUNK_COLUMNS := 16

const LevelData = preload("res://scripts/level_data.gd")
const Player = preload("res://scripts/player.gd")
const TileChunk = preload("res://scripts/tile_chunk.gd")
const SkyBg = preload("res://scripts/sky.gd")
const Scenery = preload("res://scripts/scenery.gd")
const Hud = preload("res://scripts/ui/hud.gd")
const Gem = preload("res://scripts/objects/gem.gd")
const Checkpoint = preload("res://scripts/objects/checkpoint.gd")
const ExitPortal = preload("res://scripts/objects/exit_portal.gd")
const Ghost = preload("res://scripts/objects/ghost.gd")
const Skeleton = preload("res://scripts/objects/skeleton.gd")
const MovingPlatform = preload("res://scripts/objects/moving_platform.gd")
const CrumbleBlock = preload("res://scripts/objects/crumble_block.gd")
const JumpPad = preload("res://scripts/objects/jump_pad.gd")
const Hazard = preload("res://scripts/objects/hazard.gd")
const HintSign = preload("res://scripts/objects/hint_sign.gd")

var data := {}
var colors := {}
var grid: Array = []
var width := 0
var height := 0

var player: Player
var hud: Hud

var total_gems := 0
var gems := 0
var deaths := 0
var time := 0.0
var running := true


func _ready() -> void:
	var index := Game.current_level
	if Game.level_count() == 0:
		push_error("No levels found in " + Config.LEVELS_DIR)
		Game.goto_title()
		return
	data = LevelData.load_level(Game.level_paths[index])
	grid = data["grid"]
	width = data["width"]
	height = data["height"]
	colors = Config.get_theme_colors(data["theme"])

	_build_background()
	_build_tiles()
	var start := _build_objects()
	_build_player(start)

	hud = Hud.new()
	add_child(hud)
	hud.set_level_name("%d  •  %s" % [index + 1, data["name"]])
	hud.restart_requested.connect(Game.restart_level)
	hud.next_requested.connect(Game.next_level)
	hud.menu_requested.connect(Game.goto_title)
	hud.update_stats(gems, total_gems, time, deaths)
	hud.show_banner("LEVEL %d\n%s" % [index + 1, (data["name"] as String).to_upper()], 2.0, 30)
	if not (data["banner"] as String).is_empty():
		create_tween().tween_callback(hud.show_banner.bind(data["banner"], 4.5, 22)).set_delay(3.4)


func _process(delta: float) -> void:
	if running:
		time += delta
		hud.update_stats(gems, total_gems, time, deaths)


## True if the world position is inside a solid ground tile.
func is_solid_at(world_pos: Vector2) -> bool:
	var x := floori(world_pos.x / T)
	var y := floori(world_pos.y / T)
	if x < 0 or x >= width or y < 0:
		return false
	if y >= height:
		return true
	var c: String = (grid[y] as String)[x]
	return c == "#" or c == "-" or c == "X"


# ---------------------------------------------------------------------
#  Building
# ---------------------------------------------------------------------
func _build_background() -> void:
	var sky_layer := CanvasLayer.new()
	sky_layer.layer = -100
	add_child(sky_layer)
	var sky := SkyBg.new()
	sky.colors = colors
	sky_layer.add_child(sky)

	var parallax := ParallaxBackground.new()
	parallax.layer = -99
	add_child(parallax)
	var layers := [[0.15, colors["far"], 0.0, 3], [0.4, colors["near"], 1.0, 9]]
	for l in layers:
		var pl := ParallaxLayer.new()
		pl.motion_scale = Vector2(l[0], 0.0)
		pl.motion_mirroring = Vector2(Scenery.SEGMENT, 0)
		parallax.add_child(pl)
		var s := Scenery.new()
		s.kind = colors["scenery"]
		s.color = l[1]
		s.depth = l[2]
		s.seed_value = l[3]
		pl.add_child(s)


func _build_tiles() -> void:
	# Pictures (split into slices so off-screen slices aren't drawn)
	for x0 in range(0, width, CHUNK_COLUMNS):
		var chunk := TileChunk.new()
		chunk.grid = grid
		chunk.x_from = x0
		chunk.x_to = x0 + CHUNK_COLUMNS
		chunk.colors = colors
		add_child(chunk)

	# Collision: merge tiles into as few rectangles as possible
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	for ch in ["#", "-"]:
		var open := {}  # "x0,x1" -> Rect2i of rows above that can grow down
		var done: Array[Rect2i] = []
		for y in height:
			var row: String = grid[y]
			var runs := {}
			var x := 0
			while x < width:
				if row[x] == ch:
					var x0 := x
					while x < width and row[x] == ch:
						x += 1
					runs["%d,%d" % [x0, x]] = Vector2i(x0, x)
				else:
					x += 1
			var next_open := {}
			for key in runs:
				var r: Vector2i = runs[key]
				if ch == "#" and open.has(key):
					var rect: Rect2i = open[key]
					rect.size.y += 1
					next_open[key] = rect
					open.erase(key)
				else:
					next_open[key] = Rect2i(r.x, y, r.y - r.x, 1)
			for key in open:
				done.append(open[key])
			open = next_open
		for key in open:
			done.append(open[key])
		for rect in done:
			var shape := CollisionShape2D.new()
			var rs := RectangleShape2D.new()
			if ch == "-":
				rs.size = Vector2(rect.size.x * T, 10)
				shape.position = Vector2(rect.position.x * T + rect.size.x * T * 0.5, rect.position.y * T + 5)
				shape.one_way_collision = true
			else:
				rs.size = Vector2(rect.size) * T
				shape.position = Vector2(rect.position) * T + rs.size * 0.5
			shape.shape = rs
			body.add_child(shape)

	# invisible walls at both ends of the level
	for wall_x in [-T * 0.5, width * T + T * 0.5]:
		var shape := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(T, height * T + 4000)
		shape.shape = rs
		shape.position = Vector2(wall_x, height * T * 0.5 - 2000)
		body.add_child(shape)


## Places everything that isn't plain ground. Returns the start position.
func _build_objects() -> Vector2:
	var start := Vector2(2 * T, (height - 3) * T)
	var objects := Node2D.new()
	objects.name = "Objects"
	add_child(objects)
	var signs: Dictionary = data["signs"]

	for y in height:
		var row: String = grid[y]
		var x := 0
		while x < width:
			var c := row[x]
			var center := Vector2(x * T + T * 0.5, y * T + T * 0.5)
			var corner := Vector2(x * T, y * T)
			var run := 1
			if c in ["^", "~", "M", "V"]:
				while x + run < width and row[x + run] == c:
					run += 1
			match c:
				"P":
					start = center
				"o":
					var g := Gem.new()
					g.position = center
					g.collected.connect(_on_gem_collected)
					objects.add_child(g)
					total_gems += 1
				"C":
					var cp := Checkpoint.new()
					cp.position = center
					cp.activated.connect(_on_checkpoint)
					objects.add_child(cp)
				"E":
					var e := ExitPortal.new()
					e.position = center
					e.reached.connect(_on_exit_reached)
					objects.add_child(e)
				"G", "B":
					var gh := Ghost.new()
					gh.kind = "bat" if c == "B" else "ghost"
					gh.travel = 80.0 if c == "B" else 96.0
					gh.position = center
					objects.add_child(gh)
				"S":
					var sk := Skeleton.new()
					sk.position = center
					sk.is_solid = is_solid_at
					objects.add_child(sk)
				"X":
					var cb := CrumbleBlock.new()
					cb.position = corner
					cb.color = colors["tile_light"]
					objects.add_child(cb)
				"J":
					var jp := JumpPad.new()
					jp.position = center
					objects.add_child(jp)
				"^", "~":
					var hz := Hazard.new()
					hz.kind = "spikes" if c == "^" else "liquid"
					hz.width_tiles = run
					hz.color = colors["hazard"] if c == "^" else colors["liquid"]
					hz.position = corner
					objects.add_child(hz)
				"M", "V":
					var mp := MovingPlatform.new()
					mp.axis = "v" if c == "V" else "h"
					mp.width_tiles = run
					mp.travel = 4 * T
					mp.period = 4.0
					mp.color = colors["platform"]
					mp.position = corner
					objects.add_child(mp)
				_:
					if c.is_valid_int() and c != "0":
						var s := HintSign.new()
						s.text = signs.get(c, "")
						s.position = center
						objects.add_child(s)
			x += run
	return start


func _build_player(start: Vector2) -> void:
	player = Player.new()
	player.add_to_group("player")
	player.position = start
	var abilities: String = data["abilities"]
	player.can_double_jump = abilities.contains("double")
	player.can_dash = abilities.contains("dash")
	player.kill_y = height * T + 64
	player.died.connect(func(): deaths += 1)
	add_child(player)
	var cam: Camera2D = player.camera
	cam.limit_left = 0
	cam.limit_right = width * T
	cam.limit_bottom = height * T
	cam.reset_smoothing()


# ---------------------------------------------------------------------
#  Events
# ---------------------------------------------------------------------
func _on_gem_collected() -> void:
	gems += 1


func _on_checkpoint(cp: Node2D) -> void:
	player.respawn_point = cp.global_position


func _on_exit_reached() -> void:
	if not running:
		return
	running = false
	player.frozen = true
	var key := str(Game.current_level)
	var new_best: bool = Game.best_times.has(key) and time < Game.best_times[key]
	Game.complete_level(Game.current_level, time, gems)
	hud.update_stats(gems, total_gems, time, deaths)
	create_tween().tween_callback(hud.show_complete.bind(time, gems, total_gems, deaths, new_best,
		Game.is_last_level(Game.current_level))).set_delay(0.6)
