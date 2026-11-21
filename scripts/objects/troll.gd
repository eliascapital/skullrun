extends CharacterBody2D
## A big CAVE TROLL (`t` in a level). He stomps slowly back and forth, turning
## at walls and ledges. When the skull is in front of him he lifts his club and
## pounds the ground, sending a rumble along the floor both ways (jump it!).
## He's far too big to squish: landing on his head just bounces you up high,
## like a trampoline. The only thing that knocks him out is a falling
## stalactite landing on his head... and his pounding shakes loose the
## stalactites right over him. So get him to pound under one!
## Like witches, he comes back (walking again) when the skull respawns.

const BossShockwave = preload("res://scripts/objects/boss_shockwave.gd")

const SPEED := 45.0
const GRAVITY := 1800.0
const SEE := 6.0 * 32.0
const WINDUP := 0.7
const REST := 0.9
const COOLDOWN := 1.6
const HEAD_BOUNCE := -760.0  # higher than a stomp bounce: about 5 tiles
const BOUNCE_GRACE := 0.3  # after a bounce, touching him doesn't hurt for a moment
const SIZE := Vector2(40, 58)
const ROCK_REACH := 52.0  # his thump shakes loose stalactites this close (sideways) to him

enum State { WALK, WINDUP, POUND, KO }

## Set by the level.
var is_solid: Callable
var player: Node2D
var level: Node2D

var state := State.WALK
var _dir := -1.0
var _t := 0.0
var _state_time := 0.0
var _cooldown := 0.0
var _squish := 0.0  # a wobble when the skull bounces off his head
var _grace := 0.0
var _home := Vector2.ZERO
var _tween: Tween
var _hitbox: Area2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = SIZE
	shape.shape = rect
	add_child(shape)

	_hitbox = Area2D.new()
	_hitbox.collision_layer = 0
	_hitbox.collision_mask = 2
	_hitbox.monitorable = false
	var hs := CollisionShape2D.new()
	var hr := RectangleShape2D.new()
	hr.size = SIZE + Vector2(4, 4)
	hs.shape = hr
	_hitbox.add_child(hs)
	add_child(_hitbox)
	_t = fmod(position.x * 0.021, TAU)
	_home = position


func _set_state(s: State) -> void:
	state = s
	_state_time = 0.0


func _physics_process(delta: float) -> void:
	_t += delta
	_state_time += delta
	_cooldown -= delta
	_grace -= delta
	_squish = maxf(0.0, _squish - delta * 3.0)
	queue_redraw()
	velocity.y = minf(velocity.y + GRAVITY * delta, 900.0)
	match state:
		State.WALK:
			velocity.x = _dir * SPEED
			if _cooldown <= 0.0 and _sees_player():
				_set_state(State.WINDUP)
				Sfx.play("roar", 1.6)
		State.WINDUP:
			velocity.x = 0.0
			if _state_time > WINDUP:
				_pound()
				_set_state(State.POUND)
		State.POUND:
			velocity.x = 0.0
			if _state_time > REST:
				_cooldown = COOLDOWN
				_set_state(State.WALK)
		State.KO:
			velocity.x = 0.0
			move_and_slide()
			if _state_time > 1.4 and visible:
				hide()
			return
	move_and_slide()
	if is_on_floor() and state == State.WALK:
		var ahead := global_position + Vector2(_dir * (SIZE.x * 0.5 + 4.0), SIZE.y * 0.5 + 6.0)
		if is_on_wall() or (is_solid.is_valid() and not is_solid.call(ahead)):
			_dir = -_dir
	_check_player()


func _check_player() -> void:
	if not _hitbox.monitoring:
		return  # just got back up (monitoring turns back on next frame)
	for body in _hitbox.get_overlapping_bodies():
		if not body.is_in_group("player") or body.dead:
			continue
		# landing anywhere on his top half counts (he's big, so be generous)
		if body.is_falling_onto(global_position.y - 6.0):
			# boing! his big head is like a trampoline
			body.launch(HEAD_BOUNCE)
			_squish = 1.0
			_grace = BOUNCE_GRACE
			Sfx.play("bounce", 0.7)
		elif _grace <= 0.0:
			body.hurt()


func _sees_player() -> bool:
	if player == null or player.dead:
		return false
	var d := player.global_position - global_position
	return signf(d.x) == _dir and absf(d.x) < SEE and absf(d.y) < 56.0


func _pound() -> void:
	Sfx.play("slam", 0.9)
	if level:
		level.shake(5.0, 0.3)
		# the thump shakes loose any stalactite right over his head
		for st in level.stalactites:
			if is_instance_valid(st) and absf(st.global_position.x + 16.0 - global_position.x) < ROCK_REACH \
					and st.global_position.y < global_position.y:
				st.trigger()
	var floor_y := global_position.y + SIZE.y * 0.5
	for d in [-1.0, 1.0]:
		var w := BossShockwave.new()
		w.dir = d
		w.life = 1.0
		w.tint = Color("b08a5a")
		w.is_solid = is_solid
		w.position = Vector2(global_position.x + d * 30.0, floor_y)
		get_parent().add_child(w)


## Is the troll still standing (so a stalactite can knock him out)?
func can_be_crushed() -> bool:
	return state != State.KO


## True if a falling rock's tip at `p` lands on the troll (his club and
## shoulders count too, so any rock his thump shakes loose hits him).
func covers(p: Vector2) -> bool:
	var d := p - global_position
	return absf(d.x) < ROCK_REACH + 4.0 and absf(d.y) < SIZE.y * 0.5 + 4.0


## Bonk! A stalactite landed on his head.
func crush() -> void:
	_set_state(State.KO)
	Sfx.play("boss_hit", 0.8)
	_hitbox.set_deferred("monitoring", false)
	_tween = create_tween()
	_tween.tween_interval(0.8)
	_tween.tween_property(self, "modulate:a", 0.0, 0.5)


## Called when the skull respawns: a knocked-out troll gets back up, and
## every troll walks again from where he started.
func reset() -> void:
	if _tween:
		_tween.kill()
	position = _home
	reset_physics_interpolation()
	velocity = Vector2.ZERO
	_dir = -1.0
	_cooldown = 0.0
	_grace = 0.0
	modulate.a = 1.0
	show()
	_hitbox.set_deferred("monitoring", true)
	_set_state(State.WALK)


func _draw() -> void:
	var raise := 0.0
	if state == State.WINDUP:
		raise = clampf(_state_time / WINDUP, 0.0, 1.0)
	elif state == State.POUND:
		raise = -1.0
	var walk := _t if state == State.WALK else 0.0
	if state == State.KO:
		var k := clampf(_state_time / 0.3, 0.0, 1.0)
		draw_set_transform(Vector2(0, k * 14.0), -_dir * k * 1.4, Vector2.ONE)
	else:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0 + _squish * 0.15, 1.0 - _squish * 0.15))
	draw_troll(self, _dir, walk, raise, state == State.KO)
	draw_set_transform(Vector2.ZERO)


## Also used for the picture on the website. `raise` 0 … 1 lifts the club,
## -1 is the club smashed down on the ground. The feet are at y = 29.
static func draw_troll(ci: CanvasItem, facing: float, t: float, raise: float, ko: bool) -> void:
	var f := facing
	var skin := Color("7d8f6a")
	var skin_dark := Color("56664a")
	var belly := Color("a3b08a")
	var cloth := Color("6a4a32")
	var hair := Color("3d5a34")
	var dark := Color("161a12")
	var step := sin(t * 5.0)
	var bob := absf(step) * -1.5
	var o := Vector2(0, bob)
	# legs and big feet
	for s in [-1.0, 1.0]:
		var hip := o + Vector2(s * 9.0, 12)
		var foot := Vector2(s * 10.0 + step * s * 3.0, 26)
		ci.draw_line(hip, foot, skin_dark, 10.0)
		ci.draw_circle(foot + Vector2(f * 3.0, 0), 6.0, skin_dark)
		ci.draw_rect(Rect2(foot.x - 5 + f * 2.0, foot.y, 12, 4), skin_dark)
	# back arm
	ci.draw_line(o + Vector2(-f * 14.0, -10), o + Vector2(-f * 18.0, 8 - step * 2.0), skin_dark, 8.0)
	# a big round body with a hairy belly and a rag
	ci.draw_circle(o + Vector2(0, -4), 20.0, skin)
	ci.draw_circle(o + Vector2(f * 3.0, 0), 13.0, belly)
	ci.draw_colored_polygon(PackedVector2Array([o + Vector2(-18, 6), o + Vector2(18, 6), o + Vector2(15, 16),
		o + Vector2(4, 13), o + Vector2(-6, 18), o + Vector2(-16, 14)]), cloth)
	ci.draw_line(o + Vector2(-17, 7), o + Vector2(17, 7), cloth.darkened(0.3), 2.0)
	# the head: low and lumpy, with a big nose, tusks and moss for hair
	var head := o + Vector2(f * 8.0, -22)
	ci.draw_circle(head, 12.0, skin)
	for k in 4:
		ci.draw_circle(head + Vector2(-8.0 + k * 5.0 - f * 2.0, -10.0 + absf(k - 1.5) * 1.5), 4.5, hair)
	ci.draw_circle(head + Vector2(f * 9.0, 1), 5.5, skin_dark)  # the nose
	if ko:
		for s in [-1.0, 1.0]:
			var e := head + Vector2(s * 4.0 + f * 3.0, -4)
			ci.draw_line(e + Vector2(-2, -2), e + Vector2(2, 2), dark, 2.0)
			ci.draw_line(e + Vector2(-2, 2), e + Vector2(2, -2), dark, 2.0)
		for k in 3:
			var a := t * 4.0 + k * TAU / 3.0 + Time.get_ticks_msec() * 0.004
			var sp := head + Vector2(cos(a) * 14.0, -16.0 + sin(a) * 4.0)
			ci.draw_circle(sp, 2.5, Color("ffd166"))
	else:
		for s in [-1.0, 1.0]:
			var e := head + Vector2(s * 4.0 + f * 3.0, -4)
			ci.draw_circle(e, 2.6, Color("fff2a0"))
			ci.draw_circle(e + Vector2(f * 0.8, 0), 1.3, dark)
		# a grumpy brow
		ci.draw_line(head + Vector2(-7 + f * 3.0, -9), head + Vector2(7 + f * 3.0, -8), skin_dark, 3.0)
	ci.draw_line(head + Vector2(-5 + f * 3.0, 6), head + Vector2(5 + f * 3.0, 6), dark, 2.0)
	for s in [-1.0, 1.0]:
		ci.draw_colored_polygon(PackedVector2Array([head + Vector2(s * 4.0 + f * 3.0 - 1.5, 6),
			head + Vector2(s * 4.0 + f * 3.0 + 1.5, 6), head + Vector2(s * 4.0 + f * 3.0, 1)]), Color("f4efe0"))
	# front arm with the club
	var shoulder := o + Vector2(f * 14.0, -10)
	var hand := shoulder + Vector2(f * 10.0, 14.0)
	var club_dir := Vector2(f * 0.6, -1.0).normalized()
	if raise > 0.0:
		hand = shoulder + Vector2(f * 4.0, -16.0 * raise + 14.0 * (1.0 - raise))
		club_dir = Vector2(-f * 0.5 * raise + f * 0.6 * (1.0 - raise), -1.0).normalized()
	elif raise < 0.0:
		hand = shoulder + Vector2(f * 18.0, 16.0)
		club_dir = Vector2(f, 0.25).normalized()
	ci.draw_line(shoulder, hand, skin, 8.0)
	var club_end := hand + club_dir * 26.0
	ci.draw_line(hand - club_dir * 4.0, club_end, Color("7a5236"), 6.0)
	ci.draw_circle(club_end, 8.0, Color("8a8478"))
	ci.draw_circle(club_end + Vector2(-2, -2), 3.0, Color("a8a294"))
	ci.draw_circle(hand, 5.0, skin)
