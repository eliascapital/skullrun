extends Area2D
## MORTIS THE LICH: a floating sorcerer boss. Put `L` on the floor of a
## walled arena (the arena is the space between the walls left and right of him).
##
## He wakes when you step into his arena, then floats out of reach casting
## spells, which get faster and nastier each time you hurt him:
##   soul bolts (aimed at you) and soul rain (flames fall where the floor glows),
##   and from the second hit on he teleports around the arena.
## After each round of spells his magic runs out and he sinks to the floor,
## DRAINED: that's the time to jump on his head. Three hits and he's done.
## You can also catch him in the air with a well-timed double jump.
## If you die, he goes back to sleep at full health.

signal defeated

const SoulBolt = preload("res://scripts/objects/soul_bolt.gd")
const SoulRain = preload("res://scripts/objects/soul_rain.gd")
const SkullArt = preload("res://scripts/skull_art.gd")

const BOSS_NAME := "MORTIS THE LICH"
const MAX_HP := 3
const HALF_HEIGHT := 36.0
const HOVER := 5.5 * 32.0  # how high above the floor he floats
const BOLT_SPEED := 190.0
const GREEN := Color("59ff8a")

enum State { SLEEP, INTRO, DRIFT, BOLTS, RAIN, TELEPORT, DRAINED, HURT, DEAD }

## The level that owns us (for the player, the map and screen shake).
var level: Node2D

var hp := MAX_HP
var state := State.SLEEP
var facing := -1.0
var _state_time := 0.0
var _pattern: Array = []
var _cast := 0
var _t := 0.0
var _floor_y := 0.0
var _arena_left := 0.0
var _arena_right := 0.0
var _target := Vector2.ZERO
var _home_x := 0.0
var _teleported := false
var _shape: CollisionShape2D
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(40, HALF_HEIGHT * 2.0)
	_shape.shape = rect
	add_child(_shape)
	# we're placed on the tile above the arena floor; find the floor and the walls
	_floor_y = position.y + 16.0
	_home_x = position.x
	var row_y := position.y
	_arena_left = position.x
	while _arena_left > 0.0 and not level.is_solid_at(Vector2(_arena_left - 32.0, row_y)):
		_arena_left -= 32.0
	_arena_right = position.x
	while _arena_right < level.width * 32.0 and not level.is_solid_at(Vector2(_arena_right + 32.0, row_y)):
		_arena_right += 32.0
	_arena_left -= 16.0
	_arena_right += 16.0
	_rng.seed = 20
	position = _sleep_pos()
	_target = position


func phase() -> int:
	return MAX_HP - hp + 1


func _speed_mult() -> float:
	return 1.0 + 0.2 * (phase() - 1)


func _player() -> Node2D:
	return level.player if level else null


func _sleep_pos() -> Vector2:
	return Vector2(_home_x, _floor_y - 70.0)


func _hover_y() -> float:
	return _floor_y - HOVER


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

	match state:
		State.SLEEP:
			var px := p.global_position.x
			if not p.dead and not p.frozen and px > _arena_left + 64.0 and px < _arena_right - 64.0 \
					and absf(p.global_position.y - _floor_y) < 7 * 32:
				_set_state(State.INTRO)
				_target = Vector2(position.x, _hover_y())
				Sfx.play("laugh", 0.7)
				level.shake(8.0, 0.8)
				level.hud.show_boss_bar(BOSS_NAME, MAX_HP)
		State.INTRO:
			_move(delta, 90.0)
			if _state_time > 1.6:
				_next_attack()
		State.DRIFT:
			_move(delta, 150.0 * _speed_mult())
			_face_player()
			if _state_time > 1.3:
				_next_attack()
		State.BOLTS:
			_face_player()
			_move(delta, 40.0)
			var volleys := 3 if phase() < 3 else 4
			var gap := 0.62 / _speed_mult()
			if _state_time > 0.35 + _cast * gap and _cast < volleys:
				_cast_bolts([1, 2, 3][phase() - 1])
				_cast += 1
			if _state_time > 0.5 + volleys * gap:
				_next_attack()
		State.RAIN:
			_face_player()
			if _cast == 0 and _state_time > 0.5:
				_cast = 1
				_cast_rain(3 + phase() * 2)
			if _state_time > 2.2:
				_next_attack()
		State.TELEPORT:
			# fade out, jump to the far side of the arena, fade back in
			if _state_time < 0.35:
				modulate.a = 1.0 - _state_time / 0.35
			elif not _teleported:
				_teleported = true
				var px := p.global_position.x
				var side := -1.0 if px > (_arena_left + _arena_right) * 0.5 else 1.0
				var mid := (_arena_left + _arena_right) * 0.5
				position = Vector2(mid + side * _rng.randf_range(4.0, 9.0) * 32.0, _hover_y())
				position.x = clampf(position.x, _arena_left + 64.0, _arena_right - 64.0)
				reset_physics_interpolation()
				_target = position
				Sfx.play("warp", 0.6)
			else:
				modulate.a = clampf((_state_time - 0.35) / 0.35, 0.0, 1.0)
				if _state_time > 0.75:
					_next_attack()
		State.DRAINED:
			_move(delta, 260.0)
			if _state_time > [3.2, 2.8, 2.4][phase() - 1]:
				_target = Vector2(position.x, _hover_y())
				_next_attack()
		State.HURT:
			if _state_time > 0.9:
				_target = Vector2(position.x, _hover_y())
				_next_attack()  # the next round starts with a teleport
		State.DEAD:
			_target = Vector2(position.x, _floor_y - HALF_HEIGHT)
			_move(delta, 60.0)
			if _state_time > 1.8:
				defeated.emit()
				queue_free()
				return

	_check_player_contact(p)


func _move(delta: float, speed: float) -> void:
	position = position.move_toward(_target, speed * delta)


func _set_state(s: State) -> void:
	state = s
	_state_time = 0.0
	_cast = 0
	_teleported = false
	modulate.a = 1.0
	match s:
		State.DRIFT:
			var p := _player()
			var side := -1.0 if _rng.randf() < 0.5 else 1.0
			var x := clampf(p.global_position.x + side * _rng.randf_range(4.0, 7.0) * 32.0,
				_arena_left + 64.0, _arena_right - 64.0)
			_target = Vector2(x, _hover_y() + _rng.randf_range(-20.0, 10.0))
		State.DRAINED:
			_target = Vector2(_open_x(position.x), _floor_y - HALF_HEIGHT)
			Sfx.play("vanish", 0.5)


## The nearest spot to `x` with nothing overhead (no ledges), so you can
## always jump on his head while he's drained.
func _open_x(x: float) -> float:
	for i in 24:
		var cx := x + (i + 1) / 2 * 32.0 * (1.0 if i % 2 == 1 else -1.0)
		if cx < _arena_left + 48.0 or cx > _arena_right - 48.0:
			continue
		var clear := true
		for dx in [-28.0, 0.0, 28.0]:
			for k in range(2, 8):
				if level.is_solid_at(Vector2(cx + dx, _floor_y - k * 32.0 + 8.0)):
					clear = false
		if clear:
			return cx
	return x


func _next_attack() -> void:
	if _pattern.is_empty():
		match phase():
			1: _pattern = [State.DRIFT, State.BOLTS, State.DRIFT, State.RAIN, State.DRAINED]
			2: _pattern = [State.TELEPORT, State.BOLTS, State.DRIFT, State.RAIN, State.TELEPORT, State.BOLTS, State.DRAINED]
			_: _pattern = [State.TELEPORT, State.BOLTS, State.RAIN, State.TELEPORT, State.BOLTS, State.RAIN, State.DRAINED]
	_set_state(_pattern.pop_front())


func _face_player() -> void:
	var p := _player()
	if p:
		var d := p.global_position.x - global_position.x
		if absf(d) > 4.0:
			facing = signf(d)


func _staff_tip() -> Vector2:
	return position + Vector2(facing * 26.0, -50.0)


func _cast_bolts(count: int) -> void:
	var p := _player()
	var from := _staff_tip()
	var aim := (p.global_position - from).normalized()
	for i in count:
		var b := SoulBolt.new()
		b.is_solid = level.is_solid_at
		b.position = from
		var spread := (i - (count - 1) * 0.5) * 0.32
		b.velocity = aim.rotated(spread) * BOLT_SPEED * _speed_mult()
		get_parent().add_child(b)
	Sfx.play("cast")


## Flames fall on `count` spots spread across the arena (one right on you),
## always leaving gaps to stand in.
func _cast_rain(count: int) -> void:
	var p := _player()
	var spots: Array = [p.global_position.x]
	var width := _arena_right - _arena_left - 64.0
	for i in count - 1:
		var x := _arena_left + 32.0 + (i + _rng.randf_range(0.2, 0.8)) * width / (count - 1)
		if absf(x - p.global_position.x) > 48.0:
			spots.append(x)
	for x in spots:
		var r := SoulRain.new()
		r.position = Vector2(x, _floor_y)
		get_parent().add_child(r)
	Sfx.play("cast", 0.7)


func _check_player_contact(p: Node2D) -> void:
	if p.dead or state in [State.SLEEP, State.INTRO, State.HURT, State.DEAD]:
		return
	if state == State.TELEPORT and modulate.a < 0.5:
		return
	for body in get_overlapping_bodies():
		if body != p:
			continue
		if p.is_falling_onto(global_position.y - HALF_HEIGHT + 20.0):
			_take_hit(p)
		elif state != State.DRAINED:  # drained, he's too weak to hurt you
			p.hurt()


func _take_hit(p: Node2D) -> void:
	hp -= 1
	p.bounce()
	p.knockback(signf(p.global_position.x - global_position.x + 0.01) * 320.0)
	level.hud.set_boss_hp(hp)
	level.shake(8.0, 0.3)
	_pattern.clear()
	for proj in get_tree().get_nodes_in_group("boss_projectile"):
		proj.queue_free()
	if hp <= 0:
		Sfx.play("win", 0.7)
		_set_state(State.DEAD)
		level.hud.hide_boss_bar()
	else:
		Sfx.play("boss_hit")
		_set_state(State.HURT)


## Back to sleep at full health (the level calls this when the player respawns).
func reset() -> void:
	if state == State.DEAD:
		return
	hp = MAX_HP
	_pattern.clear()
	_set_state(State.SLEEP)
	position = _sleep_pos()
	_target = position
	reset_physics_interpolation()
	facing = -1.0
	level.hud.hide_boss_bar()
	for proj in get_tree().get_nodes_in_group("boss_projectile"):
		proj.queue_free()


# ---------------------------------------------------------------------
#  Drawing
# ---------------------------------------------------------------------
func _draw() -> void:
	var drained := state == State.DRAINED and position.y > _floor_y - HALF_HEIGHT - 8.0
	var sleeping := state == State.SLEEP
	if state == State.DEAD:
		var k := clampf(_state_time / 1.6, 0.0, 1.0)
		modulate.a = 1.0 - k
		draw_set_transform(Vector2(0, k * 20.0), 0.0, Vector2(1.0 + k * 0.4, 1.0 - k * 0.6))
	elif state == State.HURT:
		modulate = Color(1, 0.5, 0.5) if int(_t * 16.0) % 2 == 0 else Color.WHITE
	elif state != State.TELEPORT:
		modulate = Color.WHITE
	draw_lich(self, facing, _t, phase(), sleeping, drained,
		state == State.BOLTS or (state == State.RAIN and _state_time < 1.0))
	if sleeping:
		var font := ThemeDB.fallback_font
		for i in 3:
			var k := fmod(_t * 0.6 + i / 3.0, 1.0)
			draw_string(font, Vector2(16 + k * 20.0, -40 - k * 40.0), "z", HORIZONTAL_ALIGNMENT_LEFT,
				-1, int(12 + k * 10), Color(Config.COLOR_BONE, 1.0 - k))
	draw_set_transform(Vector2.ZERO)


## Also used for the picture on the website.
static func draw_lich(ci: CanvasItem, facing: float, t: float, phase_n: int, sleeping: bool,
		drained: bool, casting: bool) -> void:
	var bone := Color("e6dcc4")
	var robe := Color("2a1a3e")
	var robe_light := Color("4a2c6a")
	var iron := Color("1a1424")
	var glow := GREEN
	var eye := glow.lerp(Color.WHITE, 0.1 * phase_n + 0.1 * sin(t * 7.0))
	if sleeping or drained:
		eye = Color(glow, 0.3)
	var bob := 0.0 if drained else sin(t * 2.2) * 4.0
	var slump := 10.0 if drained else 0.0
	var o := Vector2(0, bob)

	# aura
	if not drained:
		ci.draw_circle(o + Vector2(0, -4), 58.0, Color(glow, 0.05 + 0.025 * phase_n))
		ci.draw_circle(o + Vector2(0, -4), 40.0, Color(glow, 0.04))
	# robe: wide shoulders flaring to a ragged hem that fades into wisps
	var hem := PackedVector2Array([o + Vector2(-20, -12 + slump), o + Vector2(20, -12 + slump)])
	for i in 7:
		var x := 28.0 - i * (56.0 / 6.0)
		var y := 34.0 + (6.0 if i % 2 == 0 else 0.0) + sin(t * 6.0 + i * 1.3) * (1.0 if drained else 4.0)
		hem.append(o + Vector2(x, y))
	ci.draw_colored_polygon(hem, robe)
	var inner := PackedVector2Array([o + Vector2(-7, -8 + slump), o + Vector2(7, -8 + slump),
		o + Vector2(10, 34), o + Vector2(-10, 34)])
	ci.draw_colored_polygon(inner, robe_light)
	ci.draw_line(o + Vector2(0, -6 + slump), o + Vector2(0, 32), Color(glow, 0.5), 2.0)
	if not drained:
		for i in 3:
			var k := fmod(t * 0.9 + i / 3.0, 1.0)
			ci.draw_circle(o + Vector2((i - 1) * 14.0, 38.0 + k * 16.0), 4.0 * (1.0 - k), Color(glow, 0.4 * (1.0 - k)))
	# shoulder spikes
	for s in [-1.0, 1.0]:
		ci.draw_colored_polygon(PackedVector2Array([o + Vector2(s * 10, -18 + slump), o + Vector2(s * 31, -30 + slump),
			o + Vector2(s * 24, -9 + slump)]), iron)
	# staff (dropped on the floor when drained)
	var hand := o + Vector2(facing * 24.0, 0.0 + slump)
	if casting:
		hand = o + Vector2(facing * 26.0, -20.0)
	if drained:
		ci.draw_line(Vector2(-34, HALF_HEIGHT - 3), Vector2(30, HALF_HEIGHT - 6), Color("5a4636"), 4.0)
		ci.draw_circle(Vector2(34, HALF_HEIGHT - 7), 5.0, Color(glow, 0.3))
	else:
		var tip := hand + Vector2(0, -30)
		ci.draw_line(hand + Vector2(0, 30), tip, Color("5a4636"), 4.0)
		ci.draw_colored_polygon(PackedVector2Array([tip + Vector2(-7, 2), tip + Vector2(-4, -10),
			tip + Vector2(0, -4), tip + Vector2(4, -10), tip + Vector2(7, 2)]), iron)
		var pulse := 1.0 + 0.2 * sin(t * (12.0 if casting else 4.0))
		ci.draw_circle(tip + Vector2(0, -6), 12.0 * pulse, Color(glow, 0.2))
		ci.draw_circle(tip + Vector2(0, -6), 5.5 * pulse, glow)
	# bony hands
	ci.draw_circle(hand, 4.5, bone)
	ci.draw_circle(o + Vector2(-facing * 20.0, 4.0 + slump), 4.0, bone)
	# hood, skull and an iron crown with a soul gem
	var head := o + Vector2(facing * 2.0, -28.0 + slump * 1.4)
	ci.draw_circle(head + Vector2(0, -3), 20.0, iron)
	ci.draw_colored_polygon(PackedVector2Array([head + Vector2(-18, -6), head + Vector2(0, -34),
		head + Vector2(18, -6)]), iron)
	SkullArt.draw_skull(ci, head, 14.0, bone, eye, facing, Color("0a0610"))
	var cy := head.y - 15.0
	var crown := PackedVector2Array([Vector2(head.x - 13, cy + 3), Vector2(head.x - 15, cy - 12),
		Vector2(head.x - 6, cy - 4), Vector2(head.x, cy - 16), Vector2(head.x + 6, cy - 4),
		Vector2(head.x + 15, cy - 12), Vector2(head.x + 13, cy + 3)])
	if drained:
		for i in crown.size():
			crown[i] = crown[i].rotated(0.2 * facing) + Vector2(facing * 6.0, 4.0)
	ci.draw_colored_polygon(crown, Color("3a3046"))
	ci.draw_circle(Vector2(head.x, cy - 3), 3.0, glow)
	# dazed wisps when drained
	if drained:
		for i in 3:
			var a := t * 3.0 + i * TAU / 3.0
			ci.draw_circle(head + Vector2(cos(a) * 20.0, -24.0 + sin(a) * 5.0), 3.0, Color(glow, 0.7))
