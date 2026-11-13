extends CharacterBody2D
## ALETHEA THE HAPPY CLOWN: the circus boss. Put `A` on the floor of an arena
## with a wall at each end (the arena is the space between those walls).
##
## She juggles pins at you, slides cream pies along the floor, hops over and
## lands with shockwaves, then honks her horn and charges on her unicycle.
## When a charge ends against a wall she's DIZZY: that's the only time a stomp
## hurts her (landing on her head any other time just bounces you off).
## Five hits and she's done. Once she's down to 3 she goes CRAZY: she gets
## faster and adds confetti blasts, jack-in-the-box springs from the floor and
## a double charge (she bounces off the first wall and comes straight back).
## If you die, she goes back to waiting at full health.

signal defeated

const ClownProp = preload("res://scripts/objects/clown_prop.gd")
const JackBox = preload("res://scripts/objects/jack_box.gd")
const BossShockwave = preload("res://scripts/objects/boss_shockwave.gd")

const BOSS_NAME := "ALETHEA THE HAPPY CLOWN"
const MAX_HP := 5
const CRAZY_AT := 3  # hit points left when she goes crazy
const GRAVITY := 1800.0
const HALF_HEIGHT := 44.0
const PROP_COLORS := [Color("ff5fd2"), Color("ffd166"), Color("6bd7ff"), Color("8cff5a")]

enum State { SLEEP, INTRO, JUGGLE, PIES, HOP_JUMP, HOP_FALL, WINDUP, CHARGE, TURN, DIZZY, HURT, RAGE,
	CONFETTI, SPRINGS, DEAD }

## The level that owns us (for the player, the map and screen shake).
var level: Node2D

var hp := MAX_HP
var state := State.SLEEP
var facing := -1.0
var _state_time := 0.0
var _pattern: Array = []
var _thrown := 0
var _charges_left := 0
var _t := 0.0
var _home := Vector2.ZERO
var _floor_y := 0.0
var _arena_left := 0.0
var _arena_right := 0.0
var _hitbox: Area2D
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	_home = position
	_floor_y = position.y + HALF_HEIGHT
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(44, HALF_HEIGHT * 2)
	shape.shape = rect
	add_child(shape)

	_hitbox = Area2D.new()
	_hitbox.collision_layer = 0
	_hitbox.collision_mask = 2
	_hitbox.monitorable = false
	var hs := CollisionShape2D.new()
	var hr := RectangleShape2D.new()
	hr.size = Vector2(50, HALF_HEIGHT * 2 + 6)
	hs.shape = hr
	_hitbox.add_child(hs)
	add_child(_hitbox)

	# the arena: between the walls left and right of her, on her row
	var row_y := _floor_y - 16.0
	_arena_left = position.x
	while _arena_left > 0.0 and not level.is_solid_at(Vector2(_arena_left - 32.0, row_y)):
		_arena_left -= 32.0
	_arena_right = position.x
	while _arena_right < level.width * 32.0 and not level.is_solid_at(Vector2(_arena_right + 32.0, row_y)):
		_arena_right += 32.0
	_arena_left -= 16.0
	_arena_right += 16.0
	_rng.seed = 30


func is_crazy() -> bool:
	return hp <= CRAZY_AT


func _speed_mult() -> float:
	return [1.0, 1.1, 1.3, 1.4, 1.5][clampi(MAX_HP - hp, 0, 4)]


func _player() -> Node2D:
	return level.player if level else null


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

	if not is_on_floor() or state in [State.HOP_JUMP, State.HOP_FALL]:
		velocity.y = minf(velocity.y + GRAVITY * delta, 1200.0)
	var m := _speed_mult()

	match state:
		State.SLEEP:
			velocity.x = 0.0
			var px := p.global_position.x
			if not p.dead and not p.frozen and px > _arena_left + 64.0 and px < _arena_right - 64.0 \
					and absf(p.global_position.y - _floor_y) < 6 * 32:
				_set_state(State.INTRO)
				_face_player()
				Sfx.play("honk")
				level.shake(8.0, 0.6)
				level.hud.show_boss_bar(BOSS_NAME, MAX_HP)
				level.hud.show_banner("ALETHEA: Hee hee! Want to see a trick?", 2.2, 22)
		State.INTRO:
			velocity.x = 0.0
			if _state_time > 1.8:
				_next_attack()
		State.JUGGLE:
			velocity.x = 0.0
			_face_player()
			var count := 6 if is_crazy() else 4
			var gap := 0.34 / m
			if _state_time > 0.4 + _thrown * gap and _thrown < count:
				_throw_pin(_thrown, count)
				_thrown += 1
			if _state_time > 0.7 + count * gap:
				_next_attack()
		State.PIES:
			velocity.x = 0.0
			_face_player()
			var count := 4 if is_crazy() else 3
			var gap := 0.8 / m
			if _state_time > 0.35 + _thrown * gap and _thrown < count:
				_throw_pie()
				_thrown += 1
			if _state_time > 0.5 + count * gap:
				_next_attack()
		State.HOP_JUMP:
			if _state_time < 0.05:
				_face_player()
				var dx := clampf(p.global_position.x - global_position.x, -300.0, 300.0)
				velocity = Vector2(dx / 0.95, -860.0)
				Sfx.play("bounce", 0.6)
			elif velocity.y > 0.0:
				_set_state(State.HOP_FALL)
		State.HOP_FALL:
			if is_on_floor():
				velocity.x = 0.0
				_hop_land()
				_next_attack()
		State.WINDUP:
			velocity.x = 0.0
			_face_player()
			if _state_time < 0.05:
				Sfx.play("honk", 1.2)
			if _state_time > 0.75 / m:
				_set_state(State.CHARGE)
				Sfx.play("dash", 0.6)
		State.CHARGE:
			velocity.x = facing * 360.0 * m
			# only a wall in front counts (not the one she just bounced off)
			var blocked := is_on_wall() and get_wall_normal().x * facing < -0.5
			if blocked and _state_time < 0.5:
				# she started right next to a wall: turn round, it doesn't count
				velocity.x = 0.0
				_set_state(State.TURN)
			elif blocked or _state_time > 4.0:
				velocity.x = 0.0
				level.shake(9.0, 0.4)
				Sfx.play("slam")
				_charges_left -= 1
				if _charges_left > 0:
					_set_state(State.TURN)
				else:
					_set_state(State.DIZZY)
		State.TURN:
			# bonk... and straight back the other way
			velocity.x = 0.0
			if _state_time > 0.3:
				facing = -facing
				Sfx.play("honk", 1.4)
				_set_state(State.CHARGE)
		State.DIZZY:
			velocity.x = 0.0
			if _state_time > (1.9 if is_crazy() else 2.4):
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
		State.CONFETTI:
			velocity.x = 0.0
			_face_player()
			var volleys := 2
			if _state_time > 0.45 + _thrown * 0.9 / m and _thrown < volleys:
				_fire_confetti(_thrown)
				_thrown += 1
			if _state_time > 0.8 + volleys * 0.9 / m:
				_next_attack()
		State.SPRINGS:
			velocity.x = 0.0
			_face_player()
			if _thrown == 0 and _state_time > 0.35:
				_thrown = 1
				_pop_springs(5)
			if _state_time > 2.0:
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
	_thrown = 0
	if s == State.WINDUP:
		_charges_left = 2 if is_crazy() else 1


func _next_attack() -> void:
	if _pattern.is_empty():
		if is_crazy():
			_pattern = [State.CONFETTI, State.HOP_JUMP, State.SPRINGS, State.PIES, State.HOP_JUMP,
				State.JUGGLE, State.WINDUP]
		else:
			_pattern = [State.JUGGLE, State.PIES, State.HOP_JUMP, State.WINDUP]
	_set_state(_pattern.pop_front())


func _go_crazy() -> void:
	_pattern.clear()
	_set_state(State.RAGE)
	Sfx.play("roar", 1.3)
	Sfx.play("laugh", 0.8)
	level.hud.show_banner("ALETHEA IS GOING CRAZY!\nShe's angry now. Watch out for new tricks!", 2.6, 24)


func _face_player() -> void:
	var p := _player()
	if p:
		var d := p.global_position.x - global_position.x
		if absf(d) > 4.0:
			facing = signf(d)


func _hand() -> Vector2:
	return position + Vector2(facing * 22.0, -HALF_HEIGHT - 4.0)


func _throw_pin(i: int, count: int) -> void:
	var p := _player()
	var pin := ClownProp.new()
	pin.kind = "pin"
	pin.color = PROP_COLORS[i % PROP_COLORS.size()]
	pin.is_solid = level.is_solid_at
	pin.position = _hand()
	# spread around the skull, so standing still isn't safe
	var spread := (i - (count - 1) * 0.5) * 64.0
	var target_x := p.global_position.x + spread
	var flight := 1.0
	pin.velocity = Vector2((target_x - pin.position.x) / flight, -ClownProp.GRAVITY * flight * 0.5 - 40.0)
	get_parent().add_child(pin)
	Sfx.play("dash", 1.7)


func _throw_pie() -> void:
	var pie := ClownProp.new()
	pie.kind = "pie"
	pie.is_solid = level.is_solid_at
	pie.position = Vector2(position.x + facing * 30.0, _floor_y - 14.0)
	pie.velocity = Vector2(facing * 280.0 * _speed_mult(), 0.0)
	get_parent().add_child(pie)
	Sfx.play("dash", 1.2)


func _hop_land() -> void:
	Sfx.play("slam")
	level.shake(11.0, 0.45)
	for d in [-1.0, 1.0]:
		var w := BossShockwave.new()
		w.dir = d
		w.is_solid = level.is_solid_at
		w.position = Vector2(position.x + d * 30.0, _floor_y)
		get_parent().add_child(w)


## A fan of bouncy confetti balls, aimed up and over towards you.
func _fire_confetti(volley: int) -> void:
	var p := _player()
	var from := _hand()
	var dx := p.global_position.x - from.x
	for i in 5:
		var b := ClownProp.new()
		b.kind = "ball"
		b.color = PROP_COLORS[(i + volley) % PROP_COLORS.size()]
		b.is_solid = level.is_solid_at
		b.position = from
		# land spread out around the skull: some short, some long
		var land_x := from.x + dx + (i - 2) * 72.0 + (36.0 if volley == 1 else 0.0)
		var flight := 1.1
		b.velocity = Vector2((land_x - from.x) / flight, -ClownProp.GRAVITY * flight * 0.5)
		get_parent().add_child(b)
	Sfx.play("cannon", 1.4)


## Jack-in-the-boxes pop out of the floor: one under you, the rest spread out,
## always with gaps to stand in.
func _pop_springs(count: int) -> void:
	var p := _player()
	var spots: Array = [clampf(p.global_position.x, _arena_left + 32.0, _arena_right - 32.0)]
	var width := _arena_right - _arena_left - 64.0
	for i in count - 1:
		var x := _arena_left + 32.0 + (i + _rng.randf_range(0.25, 0.75)) * width / (count - 1)
		var clear := absf(x - spots[0]) > 64.0 and absf(x - position.x) > 48.0
		if clear:
			spots.append(x)
	for x in spots:
		var j := JackBox.new()
		j.position = Vector2(x, _floor_y)
		get_parent().add_child(j)
	Sfx.play("honk", 0.8)


func _check_player_contact(p: Node2D) -> void:
	if p.dead or state in [State.SLEEP, State.INTRO, State.HURT, State.RAGE, State.DEAD]:
		return
	for body in _hitbox.get_overlapping_bodies():
		if body != p:
			continue
		var on_top: bool = p.is_falling_onto(global_position.y - HALF_HEIGHT + 22.0)
		if state == State.DIZZY:
			if on_top:
				_take_hit(p)
		elif on_top and state not in [State.HOP_JUMP, State.HOP_FALL]:
			# her springy hair bounces you off, but it doesn't hurt her
			p.bounce()
			p.knockback(signf(p.global_position.x - global_position.x + 0.01) * 300.0)
			Sfx.play("honk", 1.6)
		else:
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


## Back to waiting at full health (the level calls this when the player respawns).
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
	level.hud.hide_boss_bar()
	for proj in get_tree().get_nodes_in_group("boss_projectile"):
		proj.queue_free()


# ---------------------------------------------------------------------
#  Drawing
# ---------------------------------------------------------------------
func _draw() -> void:
	if state == State.DEAD:
		var k := clampf(_state_time / 1.6, 0.0, 1.0)
		modulate.a = 1.0 - k
		draw_set_transform(Vector2(0, k * 30.0), k * 0.6 * facing, Vector2(1.0, 1.0 - k * 0.5))
	elif state == State.HURT:
		modulate = Color(1, 0.5, 0.5) if int(_t * 16.0) % 2 == 0 else Color.WHITE
	else:
		modulate = Color.WHITE
	var pose := 0  # 0 standing, 1 arms up (throwing), 2 on the unicycle
	if state in [State.JUGGLE, State.CONFETTI, State.PIES, State.SPRINGS, State.INTRO]:
		pose = 1
	elif state in [State.WINDUP, State.CHARGE, State.TURN]:
		pose = 2
	var crazy := 1.0 if is_crazy() and state != State.HURT else 0.0
	if state == State.RAGE:
		crazy = clampf(_state_time / 1.2, 0.0, 1.0)
	var shake := Vector2.ZERO
	if state == State.RAGE or (crazy > 0.0 and state == State.WINDUP):
		shake = Vector2(sin(_t * 70.0), cos(_t * 63.0)) * 2.0
	if state != State.DEAD:
		draw_set_transform(shake)
	draw_alethea(self, facing, _t, crazy, state == State.DIZZY, pose)
	draw_set_transform(Vector2.ZERO)


## Also used for the picture on the website. `crazy` 0 … 1 turns her angry,
## `pose`: 0 standing, 1 arms up, 2 riding her unicycle.
static func draw_alethea(ci: CanvasItem, facing: float, t: float, crazy: float, dizzy: bool, pose: int) -> void:
	var f := facing
	var happy_suit := Color("ff7ac8")
	var mad_suit := Color("7a2a8a")
	var suit := happy_suit.lerp(mad_suit, crazy)
	var dot := Color("ffd166").lerp(Color("ff3b3b"), crazy)
	var face := Color("fff6ee").lerp(Color("ffb0a0"), crazy)
	var white := Color("fff6ee")
	var red := Color("e63946")
	var dark := Color("1a1020")
	var bob := sin(t * (9.0 if crazy > 0.5 else 4.0)) * 2.0
	var o := Vector2(0, bob)

	# legs: a unicycle, or big floppy shoes
	if pose == 2:
		var wheel := Vector2(0, 30)
		var spin := t * 18.0
		ci.draw_circle(wheel, 13.0, dark)
		ci.draw_circle(wheel, 10.0, Color("ffd166"))
		ci.draw_circle(wheel, 3.0, dark)
		for k in 3:
			var a := spin + k * TAU / 3.0
			ci.draw_line(wheel, wheel + Vector2(cos(a), sin(a)) * 10.0, dark, 2.0)
		ci.draw_line(o + Vector2(0, 14), wheel, Color("c0c8d8"), 3.0)
		ci.draw_rect(Rect2(-9, 12 + bob, 18, 4), dark)
		for s in [-1.0, 1.0]:
			ci.draw_line(o + Vector2(s * 6.0, 14), wheel + Vector2(s * 4.0, 0), suit.darkened(0.2), 5.0)
	else:
		for s in [-1.0, 1.0]:
			ci.draw_line(o + Vector2(s * 8.0, 14), Vector2(s * 9.0, 36), suit.darkened(0.15), 7.0)
			var shoe := Vector2(s * 9.0 + f * 5.0, 39)
			ci.draw_circle(shoe, 6.0, red)
			ci.draw_rect(Rect2(shoe.x - 9, shoe.y - 1, 18, 6), red)
			ci.draw_circle(shoe + Vector2(f * 7.0, -1), 4.0, red.lightened(0.2))

	# body: a baggy polka-dot suit with pompom buttons
	var body := PackedVector2Array([o + Vector2(-14, -20), o + Vector2(14, -20), o + Vector2(20, 6),
		o + Vector2(16, 18), o + Vector2(-16, 18), o + Vector2(-20, 6)])
	ci.draw_colored_polygon(body, suit)
	for d in [Vector2(-10, -12), Vector2(9, -8), Vector2(-12, 6), Vector2(12, 10), Vector2(-2, 14)]:
		ci.draw_circle(o + d, 2.5, dot)
	for k in 3:
		ci.draw_circle(o + Vector2(f * 1.0, -12 + k * 9), 3.0, white)

	# arms (up when throwing, out to the sides otherwise)
	for s in [-1.0, 1.0]:
		var shoulder := o + Vector2(s * 13.0, -16)
		var hand := shoulder + Vector2(s * 12.0, 14.0)
		if pose == 1:
			hand = shoulder + Vector2(s * 8.0, -20.0 + sin(t * 8.0 + s) * 3.0)
		elif pose == 2:
			hand = shoulder + Vector2(s * 16.0, -6.0 + sin(t * 20.0 + s) * 4.0)
		ci.draw_line(shoulder, hand, suit, 6.0)
		ci.draw_circle(hand, 5.0, white)

	# a frilly collar
	for k in 7:
		var cx := -15.0 + k * 5.0
		ci.draw_circle(o + Vector2(cx, -21), 4.5, white if k % 2 == 0 else Color("6bd7ff").lerp(Color("ff7a3d"), crazy))

	# the head
	var head := o + Vector2(f * 2.0, -36)
	# hair: rainbow curls, which turn to flickering flames when she's crazy
	var curl_colors := [Color("ff5fd2"), Color("ffd166"), Color("6bd7ff"), Color("8cff5a")]
	for k in 6:
		var s := -1.0 if k < 3 else 1.0
		var i := k % 3
		var p := head + Vector2(s * (14.0 + i * 3.0), -6.0 + i * 7.0)
		var c: Color = curl_colors[k % 4]
		if crazy > 0.0:
			var fire := Color("ff7a3d").lerp(Color("ffd166"), 0.5 + 0.5 * sin(t * 25.0 + k))
			c = c.lerp(fire, crazy)
			p += Vector2(0, -crazy * (3.0 + 3.0 * sin(t * 30.0 + k)))
		ci.draw_circle(p, 7.0, c)
	ci.draw_circle(head, 15.0, face)
	# a tiny hat with a flower
	var hat := head + Vector2(-f * 3.0, -15)
	ci.draw_rect(Rect2(hat.x - 7, hat.y - 9, 14, 9), dark)
	ci.draw_rect(Rect2(hat.x - 10, hat.y - 1, 20, 3), dark)
	ci.draw_circle(hat + Vector2(f * 5.0, -6), 3.0, Color("ff5fd2").lerp(Color("ff3b3b"), crazy))

	# eyes
	for s in [-1.0, 1.0]:
		var e := head + Vector2(s * 6.0 + f * 1.5, -3)
		if dizzy:
			# swirly eyes
			for k in 5:
				var a := t * 9.0 + k * 1.2
				ci.draw_circle(e + Vector2(cos(a), sin(a)) * (0.6 * k), 1.2, dark)
		elif crazy > 0.5:
			ci.draw_circle(e, 3.6, white)
			ci.draw_circle(e + Vector2(f * 0.8, 0), 2.0, Color("ff2a2a"))
			# angry eyebrows
			ci.draw_line(e + Vector2(-s * 5.0, -7.0), e + Vector2(s * 3.0, -4.0), dark, 2.5)
		else:
			# happy diamond make-up and closed smiling eyes
			ci.draw_colored_polygon(PackedVector2Array([e + Vector2(0, -7), e + Vector2(3.5, -1),
				e + Vector2(0, 5), e + Vector2(-3.5, -1)]), Color("6bd7ff"))
			ci.draw_arc(e + Vector2(0, 1), 3.0, PI + 0.3, TAU - 0.3, 6, dark, 2.0)
	# the big red nose
	ci.draw_circle(head + Vector2(f * 2.5, 3), 4.5, red)
	ci.draw_circle(head + Vector2(f * 3.5, 1.5), 1.4, Color(1, 1, 1, 0.8))
	# mouth: a huge smile, or a wild toothy grin
	var mouth := head + Vector2(f * 1.0, 8)
	if crazy > 0.5:
		var pts := PackedVector2Array()
		for k in 9:
			var x := -11.0 + k * 2.75
			pts.append(mouth + Vector2(x, (2.0 if k % 2 == 0 else -1.0) - absf(x) * 0.15))
		ci.draw_colored_polygon(PackedVector2Array([mouth + Vector2(-12, -2), mouth + Vector2(12, -2),
			mouth + Vector2(7, 5), mouth + Vector2(-7, 5)]), dark)
		ci.draw_polyline(pts, white, 2.0)
	else:
		ci.draw_arc(mouth + Vector2(0, -4), 9.0, 0.35, PI - 0.35, 10, red, 4.0)
	# dizzy stars
	if dizzy:
		for k in 3:
			var a := t * 4.0 + k * TAU / 3.0
			var sp := head + Vector2(cos(a) * 20.0, -24.0 + sin(a) * 5.0)
			ci.draw_colored_polygon(PackedVector2Array([sp + Vector2(0, -4), sp + Vector2(1.2, -1.2),
				sp + Vector2(4, 0), sp + Vector2(1.2, 1.2), sp + Vector2(0, 4), sp + Vector2(-1.2, 1.2),
				sp + Vector2(-4, 0), sp + Vector2(-1.2, -1.2)]), Color("ffd166"))
