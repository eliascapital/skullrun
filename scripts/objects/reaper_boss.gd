extends Area2D
## THE REAPER, fighting you himself (`r` on the floor of an arena with a wall
## at each end, in the same level as Jett the Scarecrow `O`).
##
## He can't be hurt at all. All you can do is SURVIVE: he sends flaming skulls
## after you, makes bony hands grab up out of the floor and swoops across the
## floor with his scythe. After 30 seconds he gets bored, says you're not
## worth his time, grabs the skull and flings it far, far away... right into
## Jett's arena. If you die, the 30 seconds start again.

const Reaper = preload("res://scripts/objects/reaper.gd")
const GraveHand = preload("res://scripts/objects/grave_hand.gd")
const ReaperSkull = preload("res://scripts/objects/reaper_skull.gd")
const UI = preload("res://scripts/ui/ui.gd")

const BOSS_NAME := "THE REAPER"
const SURVIVE := 30.0
const HOVER := 5.0 * 32.0  # how high above the floor he floats
const SCALE := 0.42
const LINES := [
	"Enough! You're not worth my time,\nlittle skull.",
	"I have a whole world to rule.\nGo and bother my scarecrow instead...",
	"JETT! Catch!",
]
const LINE_TIME := 2.6

enum State { WAIT, INTRO, FLOAT, SKULLS, HANDS, SWEEP_GO, SWEEP_WARN, SWEEP, SWEEP_BACK, TALK, GRAB, WIND,
	FLING, TWINKLE, FADE_OUT, FAR_AWAY, DROP, GONE }

## Set by the level.
var level: Node2D
var player: Node2D

var state := State.WAIT
var facing := -1.0
var _state_time := 0.0
var _t := 0.0
var _survived := 0.0
var _pattern: Array = []
var _cast := 0
var _line := 0
var _home := Vector2.ZERO
var _floor_y := 0.0
var _arena_left := 0.0
var _arena_right := 0.0
var _sweep_to := 0.0
var _laughed := false
var _shown_secs := -1
var _fling_from := Vector2.ZERO
var _twinkle_at := Vector2.ZERO
var _drop_at := Vector2.ZERO
var _rng := RandomNumberGenerator.new()
var _bubble: PanelContainer
var _fade: ColorRect
var _far_label: Label


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(28, 56)
	shape.shape = rect
	shape.position = Vector2(0, 4)
	add_child(shape)
	z_index = 6
	_floor_y = position.y + 16.0
	var row_y := _floor_y - 16.0
	_arena_left = position.x
	while _arena_left > 0.0 and not level.is_solid_at(Vector2(_arena_left - 32.0, row_y)):
		_arena_left -= 32.0
	_arena_right = position.x
	while _arena_right < level.width * 32.0 and not level.is_solid_at(Vector2(_arena_right + 32.0, row_y)):
		_arena_right += 32.0
	_arena_left -= 16.0
	_arena_right += 16.0
	_home = Vector2(position.x, _floor_y - HOVER)
	position = _home
	visible = false
	_rng.seed = 40
	_build_bubble()
	_build_fade()


func _set_state(s: State) -> void:
	state = s
	_state_time = 0.0
	_cast = 0


func _physics_process(delta: float) -> void:
	_t += delta
	_state_time += delta
	queue_redraw()
	if player == null:
		return
	if state in [State.FLOAT, State.SKULLS, State.HANDS, State.SWEEP_GO, State.SWEEP_WARN, State.SWEEP,
			State.SWEEP_BACK] and not player.dead:
		_survived += delta
		var secs := ceili(maxf(SURVIVE - _survived, 0.0))
		if secs != _shown_secs:
			_shown_secs = secs
			level.hud.set_boss_name("%s  •  SURVIVE %d" % [BOSS_NAME, secs])
			level.hud.set_boss_hp(secs)

	match state:
		State.WAIT:
			var px: float = player.global_position.x
			if not player.dead and px > _arena_left + 48.0 and px < _arena_right - 48.0 \
					and absf(player.global_position.y - _floor_y) < 4 * 32:
				_appear()
		State.INTRO:
			modulate.a = clampf(_state_time / 0.6, 0.0, 1.0)
			_face_player()
			if _state_time > 2.6:
				_bubble.visible = false
				_set_state(State.FLOAT)
		State.FLOAT:
			_face_player()
			_hover_towards(player.global_position.x, delta, 110.0)
			if _state_time > 0.8:
				if _survived >= SURVIVE:
					_start_talk()
				else:
					_next_attack()
		State.SKULLS:
			_face_player()
			_hover_towards(player.global_position.x, delta, 60.0)
			var count := 4 if _survived > 15.0 else 3
			if _state_time > 0.5 + _cast * 0.25 and _cast < count:
				_send_skull(_cast, count)
				_cast += 1
			if _state_time > 2.6:
				_set_state(State.FLOAT)
		State.HANDS:
			_face_player()
			var waves := 2 if _survived > 15.0 else 1
			if _state_time > 0.3 + _cast * 1.1 and _cast < waves:
				_grab_hands(4 if _survived > 15.0 else 3)
				_cast += 1
			if _state_time > 0.5 + waves * 1.1 + 1.0:
				_set_state(State.FLOAT)
		State.SWEEP_GO:
			# off to the far side from the skull, down near the floor
			var target := Vector2(_sweep_from_x(), _floor_y - 40.0)
			position = position.move_toward(target, 420.0 * delta)
			facing = signf(_sweep_to - position.x + 0.01)
			if position.distance_to(target) < 2.0:
				_set_state(State.SWEEP_WARN)
				Sfx.play("laugh", 1.1)
		State.SWEEP_WARN:
			if _state_time > 0.9:
				_set_state(State.SWEEP)
				Sfx.play("dash", 0.5)
		State.SWEEP:
			position.x = move_toward(position.x, _sweep_to, 520.0 * delta)
			if absf(position.x - _sweep_to) < 1.0:
				_set_state(State.SWEEP_BACK)
		State.SWEEP_BACK:
			position = position.move_toward(Vector2(position.x, _home.y), 260.0 * delta)
			if absf(position.y - _home.y) < 1.0:
				_set_state(State.FLOAT)
		State.TALK:
			_face_player()
			if _state_time > LINE_TIME:
				if _line + 1 < LINES.size():
					_say(_line + 1)
					_state_time = 0.0
				else:
					_bubble.visible = false
					_set_state(State.GRAB)
					player.held = true
					Sfx.play("dash", 0.6)
		State.GRAB:
			# swoop down, pick the skull up and lift it
			var k := clampf(_state_time / 0.7, 0.0, 1.0)
			var hand := _hand()
			position = position.move_toward(player.global_position + Vector2(-facing * 30.0, -14.0), 300.0 * delta)
			if k >= 0.5:
				player.global_position = player.global_position.lerp(hand, 0.3)
			if _state_time > 1.0:
				_set_state(State.WIND)
				Sfx.play("roar", 0.8)
		State.WIND:
			# whirl round once, the skull swinging round him
			var a := _state_time / 0.7 * TAU
			player.global_position = position + Vector2(cos(a + PI * 0.5) * -facing * 34.0, -10.0 + sin(a + PI * 0.5) * 26.0)
			player.tumble = a * 2.0
			if _state_time > 0.7:
				_set_state(State.FLING)
				_fling_from = player.global_position
				Sfx.play("cannon", 0.7)
				level.shake(10.0, 0.5)
		State.FLING:
			# off it goes, up and away into the distance, spinning and shrinking
			var k := clampf(_state_time / 1.1, 0.0, 1.0)
			var dir := Vector2(signf(_drop_at.x - _fling_from.x + 0.01) * 0.75, -1.0).normalized()
			player.global_position = _fling_from + dir * 300.0 * (1.0 - pow(1.0 - k, 2.0))
			player.tumble += delta * 22.0
			player.draw_scale = 1.0 - k
			if k >= 1.0:
				_twinkle_at = player.global_position
				_set_state(State.TWINKLE)
				Sfx.play("gem", 1.6)
		State.TWINKLE:
			if _state_time > 0.7:
				_set_state(State.FADE_OUT)
		State.FADE_OUT:
			_fade.color.a = clampf(_state_time / 0.5, 0.0, 1.0)
			if _state_time > 0.5:
				_set_state(State.FAR_AWAY)
				_far_label.visible = true
				# while the screen is dark, move the skull high over Jett's arena
				player.global_position = _drop_at
				player.reset_physics_interpolation()
				player.camera.reset_smoothing()
				player.tumble = 0.0
				player.draw_scale = 1.0
				visible = false
		State.FAR_AWAY:
			if _state_time > 1.6:
				_far_label.visible = false
				_set_state(State.DROP)
				player.held = false
				player.velocity = Vector2(0, 200)
				Sfx.play("dash", 0.4)
		State.DROP:
			_fade.color.a = 1.0 - clampf(_state_time / 0.4, 0.0, 1.0)
			if player.is_on_floor() and _state_time > 0.1:
				_fade.color.a = 0.0
				player.frozen = false
				player.respawn_point = player.global_position
				level.shake(10.0, 0.4)
				Sfx.play("slam")
				_set_state(State.GONE)
		State.GONE:
			pass

	if state in [State.FLOAT, State.SKULLS, State.HANDS, State.SWEEP_GO, State.SWEEP_WARN, State.SWEEP,
			State.SWEEP_BACK]:
		_check_player()


func _check_player() -> void:
	for body in get_overlapping_bodies():
		if body != player or player.dead:
			continue
		if player.is_falling_onto(global_position.y - 14.0) and state != State.SWEEP:
			# you can't hurt the Reaper. He just laughs.
			player.bounce()
			player.knockback(signf(player.global_position.x - global_position.x + 0.01) * 300.0)
			Sfx.play("laugh", 1.3)
			if not _laughed:
				_laughed = true
				level.hud.show_banner("HA! You can't hurt ME, little skull!", 2.0, 22)
		else:
			player.hurt()


func _face_player() -> void:
	var d: float = player.global_position.x - global_position.x
	if absf(d) > 4.0:
		facing = signf(d)


func _hover_towards(x: float, delta: float, speed: float) -> void:
	var tx := clampf(x, _arena_left + 64.0, _arena_right - 64.0)
	position.x = move_toward(position.x, tx, speed * delta)
	position.y = move_toward(position.y, _home.y + sin(_t * 2.0) * 10.0, 80.0 * delta)


func _hand() -> Vector2:
	return position + Vector2(facing * 20.0, -6.0)


func _next_attack() -> void:
	if _pattern.is_empty():
		_pattern = [State.SKULLS, State.HANDS, State.SWEEP_GO]
	var s: State = _pattern.pop_front()
	_set_state(s)
	if s == State.SWEEP_GO:
		var mid := (_arena_left + _arena_right) * 0.5
		# from the far side, across to the skull's side (and all the way to the wall)
		_sweep_to = _arena_left + 40.0 if player.global_position.x < mid else _arena_right - 40.0
	elif s == State.SKULLS:
		Sfx.play("cast", 0.8)


func _sweep_from_x() -> float:
	return _arena_right - 40.0 if _sweep_to < (_arena_left + _arena_right) * 0.5 else _arena_left + 40.0


func _send_skull(i: int, count: int) -> void:
	var s := ReaperSkull.new()
	s.player = player
	s.is_solid = level.is_solid_at
	var a := -PI * 0.5 + (i - (count - 1) * 0.5) * 0.7
	s.position = position + Vector2(cos(a), sin(a)) * 24.0
	s.velocity = Vector2(cos(a), sin(a)) * ReaperSkull.SPEED
	get_parent().add_child(s)
	Sfx.play("cast", 1.2 + i * 0.1)


## Bony hands grab up out of the floor: one under the skull, the rest spread
## out, always leaving gaps to stand in.
func _grab_hands(count: int) -> void:
	var spots: Array = [clampf(player.global_position.x, _arena_left + 24.0, _arena_right - 24.0)]
	var width := _arena_right - _arena_left - 48.0
	for i in count - 1:
		var x := _arena_left + 24.0 + (i + _rng.randf_range(0.2, 0.8)) * width / (count - 1)
		if absf(x - spots[0]) > 80.0:
			spots.append(x)
	for x in spots:
		var h := GraveHand.new()
		h.position = Vector2(x, _floor_y)
		get_parent().add_child(h)
	Sfx.play("laugh", 0.9)


func _appear() -> void:
	visible = true
	modulate.a = 0.0
	position = _home
	reset_physics_interpolation()
	_survived = 0.0
	_shown_secs = -1
	_pattern.clear()
	_set_state(State.INTRO)
	_face_player()
	Sfx.play("laugh", 0.8)
	level.shake(8.0, 0.6)
	level.hud.show_boss_bar(BOSS_NAME, int(SURVIVE))
	level.hud.show_banner("You can't hurt the Reaper.\nSURVIVE for 30 seconds!", 2.6, 22)
	(_bubble.get_child(0) as Label).text = "You again?! This time\nI'll catch you MYSELF!"
	_show_bubble()


func _start_talk() -> void:
	_set_state(State.TALK)
	for proj in get_tree().get_nodes_in_group("boss_projectile"):
		proj.queue_free()
	level.hud.hide_boss_bar()
	player.frozen = true
	# where the skull lands: high over the left side of Jett's arena
	_drop_at = player.global_position
	if level.boss and level.boss.has_method("drop_point"):
		_drop_at = level.boss.drop_point()
	_say(0)


func _say(i: int) -> void:
	_line = i
	(_bubble.get_child(0) as Label).text = LINES[i]
	_show_bubble()
	Sfx.play("laugh", 0.7 + i * 0.1)


func _show_bubble() -> void:
	_bubble.visible = true
	_bubble.reset_size()
	var s := _bubble.get_combined_minimum_size()
	_bubble.size = s
	_bubble.position = Vector2(-s.x * 0.5, -60.0 - s.y)
	# keep it on screen (he's often near the edge of the view)
	var screen_x := get_global_transform_with_canvas().origin.x
	var view_w := get_viewport_rect().size.x
	var zoom := get_global_transform_with_canvas().get_scale().x
	var left := screen_x + _bubble.position.x * zoom
	var right := left + s.x * zoom
	if left < 12.0:
		_bubble.position.x += (12.0 - left) / zoom
	elif right > view_w - 12.0:
		_bubble.position.x -= (right - view_w + 12.0) / zoom


## Back to waiting, with the full 30 seconds (the level calls this when you respawn).
func reset() -> void:
	if state in [State.TALK, State.GRAB, State.WIND, State.FLING, State.TWINKLE, State.FADE_OUT,
			State.FAR_AWAY, State.DROP, State.GONE]:
		return
	visible = false
	_bubble.visible = false
	position = _home
	reset_physics_interpolation()
	_set_state(State.WAIT)
	level.hud.hide_boss_bar()
	for proj in get_tree().get_nodes_in_group("boss_projectile"):
		proj.queue_free()


func _build_bubble() -> void:
	_bubble = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.01, 0.05, 0.94)
	sb.border_color = Config.COLOR_ACCENT
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(12)
	_bubble.add_theme_stylebox_override("panel", sb)
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Config.COLOR_BONE)
	_bubble.add_child(label)
	_bubble.z_index = 50
	_bubble.visible = false
	add_child(_bubble)


## A black screen with "Far, far away..." for the big throw.
func _build_fade() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 60
	level.add_child.call_deferred(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)
	_far_label = UI.make_title("Far, far away...", 40)
	_far_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_far_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_far_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_far_label.visible = false
	layer.add_child(_far_label)


func _draw() -> void:
	if state == State.TWINKLE:
		# the skull disappears into the distance with a little twinkle
		var p := to_local(_twinkle_at)
		var k := _state_time / 0.7
		var r := 14.0 * sin(k * PI)
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -r), p + Vector2(r * 0.25, -r * 0.25),
			p + Vector2(r, 0), p + Vector2(r * 0.25, r * 0.25), p + Vector2(0, r), p + Vector2(-r * 0.25, r * 0.25),
			p + Vector2(-r, 0), p + Vector2(-r * 0.25, -r * 0.25)]), Color(1, 1, 0.8))
	if state in [State.FADE_OUT, State.FAR_AWAY, State.DROP, State.GONE]:
		return
	var swing := 0.25 + 0.25 * sin(_t * 3.0)
	if state in [State.SWEEP_WARN, State.SWEEP]:
		swing = 0.9
		var glow := 0.3 + 0.25 * sin(_t * 25.0)
		draw_circle(Vector2(facing * 20.0, 10.0), 40.0, Color(Config.COLOR_ACCENT, glow * 0.4))
	elif state in [State.SKULLS, State.HANDS, State.TALK]:
		swing = 0.6
	var spin := 0.0
	if state == State.WIND:
		spin = _state_time / 0.7 * TAU
	draw_set_transform(Vector2.ZERO, spin, Vector2(facing, 1.0))
	Reaper.draw_reaper(self, Vector2.ZERO, SCALE, swing, _t)
	draw_set_transform(Vector2.ZERO)
