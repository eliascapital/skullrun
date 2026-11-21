extends CharacterBody2D
## JETT THE SCARECROW: the cave boss (`O`, for his pumpkin head). Put him on
## the floor of an arena with a wall at each end and a ceiling about 11 tiles
## up (he leaps high, and in a cave-in the rocks fall from that ceiling).
##
## He stands still like an ordinary scarecrow until you come in. Then he
## throws his sickle (it flies out low and comes back high), summons witches
## around him, hops at you on his pole, and finally leaps high and plunges
## his pole into the ground... where it gets STUCK. That's the only time a
## stomp hurts him (landing on his hat any other time just bounces you off).
## Five hits. At 3 he goes CRAZY: his head catches fire, he gets faster,
## throws two sickles, summons more witches, leaps twice, and stamps so hard
## that stalactites fall from the ceiling.
## If you die, he goes back to standing still at full health.

signal defeated

const Sickle = preload("res://scripts/objects/sickle.gd")
const Witch = preload("res://scripts/objects/witch.gd")
const FallingStalactite = preload("res://scripts/objects/falling_stalactite.gd")
const BossShockwave = preload("res://scripts/objects/boss_shockwave.gd")

const BOSS_NAME := "JETT THE SCARECROW"
const MAX_HP := 5
const CRAZY_AT := 3  # hit points left when he goes crazy
const GRAVITY := 1800.0
const HALF_HEIGHT := 44.0
const WITCH_HEIGHT := 3.5 * 32.0  # summoned witches float this high above the floor

enum State { SLEEP, INTRO, SCYTHE, SUMMON, HOP_CROUCH, HOP, LEAP_WINDUP, LEAP, STUCK, CAVE_IN, HURT, RAGE,
	DEAD }

## The level that owns us (for the player, the map and screen shake).
var level: Node2D

var hp := MAX_HP
var state := State.SLEEP
var facing := -1.0
var _state_time := 0.0
var _pattern: Array = []
var _count := 0  # sickles thrown, hops done, leaps done...
var _t := 0.0
var _home := Vector2.ZERO
var _floor_y := 0.0
var _arena_left := 0.0
var _arena_right := 0.0
var _sickles: Array = []
var _witches: Array = []
var _hitbox: Area2D
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	_home = position
	_floor_y = position.y + HALF_HEIGHT
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(36, HALF_HEIGHT * 2)
	shape.shape = rect
	add_child(shape)

	_hitbox = Area2D.new()
	_hitbox.collision_layer = 0
	_hitbox.collision_mask = 2
	_hitbox.monitorable = false
	var hs := CollisionShape2D.new()
	var hr := RectangleShape2D.new()
	hr.size = Vector2(44, HALF_HEIGHT * 2 + 6)
	hs.shape = hr
	_hitbox.add_child(hs)
	add_child(_hitbox)

	# the arena: between the walls left and right of him, on his row
	var row_y := _floor_y - 16.0
	_arena_left = position.x
	while _arena_left > 0.0 and not level.is_solid_at(Vector2(_arena_left - 32.0, row_y)):
		_arena_left -= 32.0
	_arena_right = position.x
	while _arena_right < level.width * 32.0 and not level.is_solid_at(Vector2(_arena_right + 32.0, row_y)):
		_arena_right += 32.0
	_arena_left -= 16.0
	_arena_right += 16.0
	_rng.seed = 40


func is_crazy() -> bool:
	return hp <= CRAZY_AT


func _speed_mult() -> float:
	return [1.0, 1.1, 1.3, 1.4, 1.5][clampi(MAX_HP - hp, 0, 4)]


func _player() -> Node2D:
	return level.player if level else null


## Where the Reaper's throw drops the skull: high over the left of the arena.
func drop_point() -> Vector2:
	var x := _arena_left + 4.0 * 32.0
	var y := _floor_y - 16.0
	var up := 0
	while up < 8 and not level.is_solid_at(Vector2(x, y - 32.0)):
		y -= 32.0
		up += 1
	return Vector2(x, y + 8.0)


# ---------------------------------------------------------------------
#  Brain
# ---------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	_t += delta
	_state_time += delta
	queue_redraw()
	var p := _player()
	if p == null:
		return

	velocity.y = minf(velocity.y + GRAVITY * delta, 1200.0)
	var m := _speed_mult()

	match state:
		State.SLEEP:
			velocity.x = 0.0
			var px := p.global_position.x
			if not p.dead and not p.frozen and not p.held and px > _arena_left + 64.0 \
					and px < _arena_right - 64.0 and absf(p.global_position.y - _floor_y) < 6 * 32:
				_set_state(State.INTRO)
				_face_player()
				Sfx.play("laugh", 0.6)
				level.shake(8.0, 0.6)
				level.hud.show_boss_bar(BOSS_NAME, MAX_HP)
				level.hud.show_banner("JETT: Boo! Did I scare you?\nNo? Then meet my friends!", 2.4, 22)
		State.INTRO:
			velocity.x = 0.0
			if _state_time > 2.0:
				_next_attack()
		State.SCYTHE:
			velocity.x = 0.0
			var count := 2 if is_crazy() else 1
			var gap := 0.75 / m
			if _count < count:
				_face_player()
				if _state_time > 0.45 + _count * gap:
					_throw_sickle()
					_count += 1
			_sickles = _sickles.filter(func(s): return is_instance_valid(s))
			if (_count >= count and _sickles.is_empty()) or _state_time > 6.0:
				_next_attack()
		State.SUMMON:
			velocity.x = 0.0
			_face_player()
			if _count == 0 and _state_time > 0.7:
				_count = 1
				_summon_witches()
			if _state_time > 1.3:
				_next_attack()
		State.HOP_CROUCH:
			velocity.x = 0.0
			if _state_time > 0.25 / m:
				_face_player()
				var flight := 0.75
				var dx := clampf(p.global_position.x - global_position.x, -200.0, 200.0)
				velocity = Vector2(dx / flight, -0.5 * GRAVITY * flight)
				var done := _count
				_set_state(State.HOP)
				_count = done
				Sfx.play("bounce", 0.5)
		State.HOP:
			if _state_time > 0.1 and is_on_floor():
				velocity.x = 0.0
				_land(false)
				_count += 1
				if _count < (3 if is_crazy() else 2):
					var done := _count
					_set_state(State.HOP_CROUCH)
					_count = done
				else:
					_next_attack()
		State.LEAP_WINDUP:
			velocity.x = 0.0
			_face_player()
			if _state_time < 0.05 and _count == 0:
				Sfx.play("roar", 1.5)
			if _state_time > (0.7 if _count == 0 else 0.3) / m:
				# aim for where the skull is now (so keep moving!)
				var flight := 0.9
				var tx := clampf(p.global_position.x, _arena_left + 48.0, _arena_right - 48.0)
				velocity = Vector2((tx - global_position.x) / flight, -0.5 * GRAVITY * flight)
				var done := _count
				_set_state(State.LEAP)
				_count = done
				Sfx.play("dash", 0.5)
		State.LEAP:
			if _state_time > 0.1 and is_on_floor():
				velocity.x = 0.0
				_count += 1
				if is_crazy() and _count < 2:
					# crazy: a second leap straight away
					_land(false)
					var done := _count
					_set_state(State.LEAP_WINDUP)
					_count = done
				else:
					_land(true)
					_set_state(State.STUCK)
		State.STUCK:
			velocity.x = 0.0
			if _state_time > (1.9 if is_crazy() else 2.4):
				# yank the pole out with a little hop
				velocity.y = -300.0
				Sfx.play("jump", 0.5)
				_next_attack()
		State.CAVE_IN:
			velocity.x = 0.0
			if _count == 0 and _state_time > 0.5:
				_count = 1
				_cave_in()
			if _state_time > 2.4:
				_next_attack()
		State.HURT:
			velocity.x = 0.0
			if _state_time > 1.0:
				if hp == CRAZY_AT:
					_go_crazy()
				else:
					_next_attack()
		State.RAGE:
			velocity.x = 0.0
			if int(_state_time * 10.0) % 3 == 0:
				level.shake(5.0, 0.1)
			if _state_time > 1.8:
				_next_attack()
		State.DEAD:
			velocity.x = 0.0
			if _state_time > 1.8:
				defeated.emit()
				queue_free()
				return

	move_and_slide()
	_check_player_contact(p)


func _set_state(s: State) -> void:
	state = s
	_state_time = 0.0
	_count = 0


func _next_attack() -> void:
	if _pattern.is_empty():
		if is_crazy():
			_pattern = [State.CAVE_IN, State.SCYTHE, State.HOP_CROUCH, State.SUMMON, State.CAVE_IN,
				State.LEAP_WINDUP]
		else:
			_pattern = [State.SCYTHE, State.SUMMON, State.HOP_CROUCH, State.LEAP_WINDUP]
	var s: State = _pattern.pop_front()
	if s == State.SUMMON and _alive_witches() >= _max_witches():
		# enough witches about already: do something else
		var nxt: int = _pattern[0] if not _pattern.is_empty() else -1
		s = State.HOP_CROUCH if nxt != State.HOP_CROUCH else State.SCYTHE
	_set_state(s)


func _go_crazy() -> void:
	_pattern.clear()
	_set_state(State.RAGE)
	Sfx.play("roar", 1.2)
	Sfx.play("laugh", 0.7)
	level.hud.show_banner("JETT IS GOING CRAZY!\nHis head is on fire! Watch the ceiling!", 2.6, 24)


func _face_player() -> void:
	var p := _player()
	if p:
		var d := p.global_position.x - global_position.x
		if absf(d) > 4.0:
			facing = signf(d)


func _throw_sickle() -> void:
	var s := Sickle.new()
	s.dir = facing
	s.speed = 380.0 * _speed_mult()
	s.floor_y = _floor_y
	s.home_x = position.x
	s.max_x = _arena_right - 20.0 if facing > 0.0 else _arena_left + 20.0
	s.is_solid = level.is_solid_at
	s.position = Vector2(position.x + facing * 26.0, 0)
	get_parent().add_child(s)
	_sickles.append(s)
	Sfx.play("dash", 1.4)


func _max_witches() -> int:
	return 3 if is_crazy() else 2


func _alive_witches() -> int:
	_witches = _witches.filter(func(w): return is_instance_valid(w) and not w.is_defeated())
	return _witches.size()


## Witches pop out of puffs of straw around him.
func _summon_witches() -> void:
	var p := _player()
	var want := _max_witches() - _alive_witches()
	var offsets := [-4.5, 4.5, -9.0, 9.0]
	var placed := 0
	for o in offsets:
		if placed >= want:
			break
		var x := clampf(position.x + o * 32.0, _arena_left + 48.0, _arena_right - 48.0)
		var spot := Vector2(x, _floor_y - WITCH_HEIGHT)
		var taken := false
		for w in _witches:
			if absf(w.position.x - spot.x) < 64.0:
				taken = true
		if taken or (p and p.global_position.distance_to(spot) < 56.0):
			continue
		var w := Witch.new()
		w.position = spot
		w.is_solid = level.is_solid_at
		w.player = p
		w.summoned = true
		get_parent().add_child(w)
		_witches.append(w)
		placed += 1
	Sfx.play("vanish", 0.8)
	Sfx.play("laugh", 1.5)


func _land(stuck: bool) -> void:
	Sfx.play("slam")
	level.shake(13.0 if stuck else 9.0, 0.45)
	for d in [-1.0, 1.0]:
		var w := BossShockwave.new()
		w.dir = d
		w.tint = Color("ffb23e")
		w.is_solid = level.is_solid_at
		w.position = Vector2(position.x + d * 30.0, _floor_y)
		get_parent().add_child(w)


## Crazy Jett stamps so hard that stalactites fall from the ceiling: one over
## the skull, the rest spread out, always with gaps to stand in.
func _cave_in() -> void:
	Sfx.play("slam", 0.7)
	level.shake(14.0, 0.7)
	var p := _player()
	var spots: Array = [clampf(p.global_position.x, _arena_left + 24.0, _arena_right - 24.0)]
	var count := 6
	var width := _arena_right - _arena_left - 48.0
	for i in count - 1:
		var x := _arena_left + 24.0 + (i + _rng.randf_range(0.2, 0.8)) * width / (count - 1)
		if absf(x - spots[0]) > 72.0:
			spots.append(x)
	for x in spots:
		# from the ceiling over that spot
		var cell_x := floorf(x / 32.0) * 32.0
		var y := _floor_y - 48.0
		var up := 0
		while up < 16 and not level.is_solid_at(Vector2(cell_x + 16.0, y - 32.0)):
			y -= 32.0
			up += 1
		var st := FallingStalactite.new()
		st.once = true
		st.shake_time = 0.8
		st.level = level
		st.player = p
		st.color = level.colors["tile_light"]
		st.position = Vector2(cell_x, y - 16.0)
		get_parent().add_child(st)


func _check_player_contact(p: Node2D) -> void:
	if p.dead or state in [State.SLEEP, State.INTRO, State.HURT, State.RAGE, State.DEAD]:
		return
	for body in _hitbox.get_overlapping_bodies():
		if body != p:
			continue
		var on_top: bool = p.is_falling_onto(global_position.y - HALF_HEIGHT + 22.0)
		if state == State.STUCK:
			if on_top:
				_take_hit(p)
		elif on_top and state not in [State.HOP, State.LEAP]:
			# his springy straw hat bounces you off, but it doesn't hurt him
			p.bounce()
			p.knockback(signf(p.global_position.x - global_position.x + 0.01) * 300.0)
			Sfx.play("bounce", 1.4)
		else:
			p.hurt()


func _take_hit(p: Node2D) -> void:
	hp -= 1
	p.bounce()
	p.knockback(signf(p.global_position.x - global_position.x + 0.01) * 320.0)
	level.hud.set_boss_hp(hp)
	level.shake(8.0, 0.3)
	_pattern.clear()
	_clear_projectiles()
	if hp <= 0:
		Sfx.play("win", 0.7)
		_set_state(State.DEAD)
		level.hud.hide_boss_bar()
	else:
		Sfx.play("boss_hit")
		_set_state(State.HURT)


## Sickles, shockwaves, falling rocks and his witches all go away.
func _clear_projectiles() -> void:
	for proj in get_tree().get_nodes_in_group("boss_projectile"):
		proj.queue_free()
	_witches.clear()
	_sickles.clear()


## Back to standing still at full health (the level calls this when the player respawns).
func reset() -> void:
	if state == State.DEAD:
		return
	hp = MAX_HP
	position = _home
	reset_physics_interpolation()
	velocity = Vector2.ZERO
	facing = -1.0
	_pattern.clear()
	_set_state(State.SLEEP)
	if level.hud:
		level.hud.hide_boss_bar()
	_clear_projectiles()


# ---------------------------------------------------------------------
#  Drawing
# ---------------------------------------------------------------------
func _draw() -> void:
	if state == State.DEAD:
		var k := clampf(_state_time / 1.6, 0.0, 1.0)
		modulate.a = 1.0 - k
		draw_set_transform(Vector2(0, k * 30.0), k * 0.8 * facing, Vector2(1.0 + k * 0.3, 1.0 - k * 0.5))
	elif state == State.HURT:
		modulate = Color(1, 0.5, 0.5) if int(_t * 16.0) % 2 == 0 else Color.WHITE
	else:
		modulate = Color.WHITE
	var pose := 0  # 0 arms out, 1 arms up, 2 crouching, 3 throwing
	if state in [State.SUMMON, State.INTRO, State.CAVE_IN, State.RAGE]:
		pose = 1
	elif state in [State.HOP_CROUCH, State.LEAP_WINDUP]:
		pose = 2
	elif state == State.SCYTHE:
		pose = 3
	var crazy := 1.0 if is_crazy() and state != State.HURT else 0.0
	if state == State.RAGE:
		crazy = clampf(_state_time / 1.2, 0.0, 1.0)
	var shake := Vector2.ZERO
	if state == State.RAGE or state == State.STUCK:
		shake = Vector2(sin(_t * 70.0), cos(_t * 63.0)) * (2.0 if state == State.RAGE else 1.2)
	if state != State.DEAD:
		var tilt := 0.0
		if state == State.STUCK:
			tilt = 0.22 * facing + sin(_t * 9.0) * 0.06
		draw_set_transform(shake, tilt)
	draw_jett(self, facing, _t, crazy, state == State.STUCK, pose, state != State.SLEEP)
	draw_set_transform(Vector2.ZERO)


## Also used for the picture on the website. The pole's end is at y = 44.
## `crazy` 0 … 1 sets his head on fire, `stuck` makes him dizzy, `lit` lights
## up his pumpkin face (it's dark while he pretends to be a normal scarecrow).
## `pose`: 0 arms out, 1 arms up, 2 crouching, 3 throwing.
static func draw_jett(ci: CanvasItem, facing: float, t: float, crazy: float, stuck: bool, pose: int,
		lit: bool) -> void:
	var f := facing
	var shirt := Color("b0442e").lerp(Color("5a1a2a"), crazy)
	var check := Color("6a2418").lerp(Color("2a0a14"), crazy)
	var straw := Color("e0be62")
	var straw_dark := Color("a8862e")
	var wood := Color("7a5236")
	var pumpkin := Color("f08a24")
	var pumpkin_dark := Color("b85a10")
	var hat := Color("8a6a3a")
	var dark := Color("1a1008")
	var glow := Color("ffd166").lerp(Color("ff3b1f"), crazy)
	var crouch := 8.0 if pose == 2 else 0.0
	var bob := sin(t * (8.0 if crazy > 0.5 else 3.0)) * 1.5 if lit else 0.0
	var o := Vector2(0, crouch + bob)

	# the pole he hops on, with a little foot peg
	ci.draw_line(Vector2(0, 44), o + Vector2(0, 2), wood, 6.0)
	ci.draw_line(Vector2(-7, 34), Vector2(7, 34), wood.darkened(0.2), 4.0)
	if stuck:
		# dirt heaped round the pole where it's stuck in the ground
		ci.draw_colored_polygon(PackedVector2Array([Vector2(-16, 46), Vector2(-6, 38), Vector2(6, 37),
			Vector2(16, 46)]), Color("5a4630"))

	# a patched plaid shirt, straw poking out the bottom
	for k in 5:
		var sx := -12.0 + k * 6.0
		ci.draw_line(o + Vector2(sx, 6), o + Vector2(sx + sin(t * 3.0 + k) * 2.0 - 1.0, 14), straw, 2.0)
	var body := PackedVector2Array([o + Vector2(-14, -26), o + Vector2(14, -26), o + Vector2(16, 8),
		o + Vector2(-16, 8)])
	ci.draw_colored_polygon(body, shirt)
	for k in 3:
		ci.draw_line(o + Vector2(-14 + k * 10, -26), o + Vector2(-14 + k * 10, 8), check, 2.0)
		ci.draw_line(o + Vector2(-15, -18 + k * 10), o + Vector2(15, -18 + k * 10), check, 2.0)
	ci.draw_rect(Rect2(o + Vector2(2, -14), Vector2(8, 7)), Color("4a6a8a"))  # a patch
	ci.draw_line(o + Vector2(2, -14), o + Vector2(10, -7), Color("2a3a4a"), 1.0)
	ci.draw_rect(Rect2(o + Vector2(-16, 2), Vector2(32, 3)), Color("8a6a3a"))  # rope belt

	# arms: a stick through the sleeves, straw hands
	var shoulder_y := -20.0
	for s in [-1.0, 1.0]:
		var sh := o + Vector2(s * 12.0, shoulder_y)
		var hand := sh + Vector2(s * 20.0, 2.0 + sin(t * 2.0 + s) * 1.5)
		if pose == 1:
			hand = sh + Vector2(s * 12.0, -22.0 + sin(t * 9.0 + s) * 3.0)
		elif pose == 2:
			hand = sh + Vector2(s * 18.0, 10.0)
		elif pose == 3 and s == f:
			hand = sh + Vector2(s * 8.0, -20.0)
		ci.draw_line(sh, hand, shirt, 8.0)
		ci.draw_line(sh + (hand - sh) * 0.5, sh + (hand - sh) * 0.5 + Vector2(0, 3), check, 2.0)
		for k in 4:
			var a := (hand - sh).angle() + (k - 1.5) * 0.35
			ci.draw_line(hand, hand + Vector2(cos(a), sin(a)) * 8.0, straw, 2.0)
		if pose == 3 and s == f:
			# the sickle, ready to throw
			ci.draw_set_transform(hand + Vector2(0, -4), -0.6 * f, Vector2(f, 1.0))
			ci.draw_line(Vector2(-12, 4), Vector2(-2, 0), wood, 4.0)
			ci.draw_arc(Vector2(2, -2), 10.0, -0.3, 2.85, 8, Color("d8d8dc"), 4.0)
			ci.draw_set_transform(Vector2.ZERO)

	# straw sticking out at the neck
	for k in 5:
		ci.draw_line(o + Vector2(-8 + k * 4, -26), o + Vector2(-10 + k * 5, -31), straw_dark, 2.0)

	# the pumpkin head
	var head := o + Vector2(f * 1.0, -40)
	if crazy > 0.0:
		# flames on top
		for k in 5:
			var fx := -10.0 + k * 5.0
			var fh := (12.0 + 6.0 * sin(t * 20.0 + k * 1.7)) * crazy
			ci.draw_colored_polygon(PackedVector2Array([head + Vector2(fx - 4, -10), head + Vector2(fx + 4, -10),
				head + Vector2(fx + sin(t * 15.0 + k) * 2.0, -12 - fh - 8.0)]),
				Color("ff7a1f").lerp(Color("ffd166"), 0.5 + 0.5 * sin(t * 18.0 + k)))
	ci.draw_set_transform(head, 0.0, Vector2(1.15, 1.0))
	ci.draw_circle(Vector2.ZERO, 14.0, pumpkin_dark)
	ci.draw_circle(Vector2(0, -1), 12.5, pumpkin)
	for k in [-6.0, 0.0, 6.0]:
		ci.draw_line(Vector2(k, -12), Vector2(k * 1.2, 11), pumpkin_dark, 1.5)
	ci.draw_set_transform(Vector2.ZERO)
	# carved face: glowing when he's awake
	var face_col := glow if lit else dark
	if stuck:
		for s in [-1.0, 1.0]:
			var e := head + Vector2(s * 5.5 + f * 2.0, -3)
			for k in 5:
				var a := t * 9.0 + k * 1.2
				ci.draw_circle(e + Vector2(cos(a), sin(a)) * (0.6 * k), 1.3, face_col)
	else:
		for s in [-1.0, 1.0]:
			var e := head + Vector2(s * 5.5 + f * 2.0, -3)
			if crazy > 0.5:
				ci.draw_colored_polygon(PackedVector2Array([e + Vector2(-s * 4.0, -5), e + Vector2(s * 4.0, -1),
					e + Vector2(-s * 2.0, 3)]), face_col)
			else:
				ci.draw_colored_polygon(PackedVector2Array([e + Vector2(0, -4), e + Vector2(3.5, 3),
					e + Vector2(-3.5, 3)]), face_col)
	var mouth := head + Vector2(f * 2.0, 6)
	var pts := PackedVector2Array([mouth + Vector2(-9, -2), mouth + Vector2(-5, 0), mouth + Vector2(-3, -2),
		mouth + Vector2(0, 1), mouth + Vector2(3, -2), mouth + Vector2(5, 0), mouth + Vector2(9, -2),
		mouth + Vector2(6, 4), mouth + Vector2(0, 5), mouth + Vector2(-6, 4)])
	ci.draw_colored_polygon(pts, face_col)
	if lit:
		ci.draw_circle(head, 22.0, Color(glow, 0.08))
	# a floppy straw hat (it burns away a bit when he's crazy)
	var brim := head + Vector2(-f * 1.0, -11)
	ci.draw_colored_polygon(PackedVector2Array([brim + Vector2(-22, 3), brim + Vector2(22, 3),
		brim + Vector2(18, -1), brim + Vector2(-18, -1)]), hat)
	var crown := PackedVector2Array([brim + Vector2(-10, 0), brim + Vector2(10, 0), brim + Vector2(8, -12),
		brim + Vector2(f * 4.0, -15), brim + Vector2(-8, -12)])
	ci.draw_colored_polygon(crown, hat.lerp(Color("3a2a1a"), crazy))
	ci.draw_rect(Rect2(brim + Vector2(-10, -4), Vector2(20, 3)), Color("b0442e"))
	for k in 3:
		ci.draw_line(brim + Vector2(-20 + k * 3.0, 3), brim + Vector2(-24 + k * 2.0, 7), straw, 1.5)
	if stuck:
		# sweat drops: he's trying to pull his pole out
		for k in 2:
			var d := fmod(t * 1.6 + k * 0.5, 1.0)
			ci.draw_circle(head + Vector2(-f * (16.0 + k * 4.0), -6.0 + d * 12.0), 2.0, Color(Color("8fd8f0"), 1.0 - d))
