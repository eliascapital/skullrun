extends Area2D
## A SKELETON GUARD: a big armoured skeleton with a spear. He stands in one
## spot and turns to face you. Come within about 3 tiles and he pulls his
## spear back (it glints), then stabs. The stab is at skull height, so jump
## over it and land on his head. It takes two stomps: the first knocks his
## helmet off and he holds his spear straight up for a moment, so wait for
## it to come down before you stomp again. A ground slam close by counts too.

const REACH := 3.0 * 32.0  # he starts a stab when you're this close (sideways)
const WINDUP := 0.45
const STAB := 0.3
const RECOVER := 0.8
const GUARD_UP := 1.3  # spear held up after the first hit
const SPEAR_LEN := 78.0
const HALF_HEIGHT := 26.0

enum State { READY, WINDUP, STAB, RECOVER, GUARD_UP, DEAD }

var player: Node2D

var hp := 2
var facing := -1.0
var state := State.READY
var _state_time := 0.0
var _turn_time := 0.0
var _grace := 0.0  # right after a stomp, while you bounce clear, touching him is fine
var _t := 0.0
var _spear: Area2D
var _spear_shape: CollisionShape2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(26, HALF_HEIGHT * 2.0)
	shape.shape = rect
	# placed on the tile above the ground: stand on the ground
	shape.position = Vector2(0, 16.0 - HALF_HEIGHT)
	add_child(shape)

	_spear = Area2D.new()
	_spear.collision_layer = 0
	_spear.collision_mask = 2
	_spear.monitorable = false
	_spear_shape = CollisionShape2D.new()
	_spear_shape.shape = RectangleShape2D.new()
	_spear.add_child(_spear_shape)
	add_child(_spear)
	_t = fmod(position.x * 0.01, TAU)


func _set_state(s: State) -> void:
	state = s
	_state_time = 0.0


## How far the spear tip pokes out in front of him right now (pixels from his middle).
func _spear_out() -> float:
	match state:
		State.WINDUP:
			return 26.0 - 10.0 * minf(1.0, _state_time / 0.15)
		State.STAB:
			return 16.0 + SPEAR_LEN * minf(1.0, _state_time / 0.07)
		State.RECOVER:
			return lerpf(16.0 + SPEAR_LEN, 26.0, minf(1.0, _state_time / 0.4))
	return 26.0


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	_t += delta
	_state_time += delta
	_grace -= delta
	queue_redraw()
	if player == null:
		return
	var d := player.global_position - (global_position + Vector2(0, 16.0 - HALF_HEIGHT))
	var near: bool = absf(d.x) < REACH + 16.0 and d.y > -40.0 and d.y < 40.0 and not player.dead

	# turn to face you (a moment after you get behind him)
	if state == State.READY and absf(d.x) < 8.0 * 32.0 and signf(d.x) != facing and absf(d.x) > 6.0:
		_turn_time += delta
		if _turn_time > 0.35:
			facing = -facing
			_turn_time = 0.0
	else:
		_turn_time = 0.0

	match state:
		State.READY:
			if near and signf(d.x) == facing:
				_set_state(State.WINDUP)
		State.WINDUP:
			if _state_time > WINDUP:
				_set_state(State.STAB)
				Sfx.play("dash", 1.6)
		State.STAB:
			if _state_time > STAB:
				_set_state(State.RECOVER)
		State.RECOVER:
			if _state_time > RECOVER:
				_set_state(State.READY)
		State.GUARD_UP:
			if _state_time > GUARD_UP:
				_set_state(State.READY)

	_update_spear()
	if player.dead or _grace > 0.0:
		return
	# the spear
	if state in [State.STAB, State.GUARD_UP]:
		for body in _spear.get_overlapping_bodies():
			if body.is_in_group("player"):
				body.hurt()
				return
	# his body: stomp him, or get hurt
	for body in get_overlapping_bodies():
		if body.is_in_group("player") and not body.dead:
			if state != State.GUARD_UP and body.is_falling_onto(global_position.y + 16.0 - HALF_HEIGHT * 2.0 + 10.0):
				body.bounce()
				body.knockback(signf(body.global_position.x - global_position.x + 0.01) * 300.0)
				_hit()
			else:
				body.hurt()


func _update_spear() -> void:
	var rect := _spear_shape.shape as RectangleShape2D
	if state == State.GUARD_UP:
		# straight up over his head
		rect.size = Vector2(10, 46)
		_spear_shape.position = Vector2(facing * 4.0, 16.0 - HALF_HEIGHT * 2.0 - 20.0)
	else:
		var out := _spear_out()
		rect.size = Vector2(maxf(4.0, out - 12.0), 8)
		_spear_shape.position = Vector2(facing * (12.0 + out) * 0.5, 2.0)


func _hit() -> void:
	hp -= 1
	_grace = 0.35
	Sfx.play("stomp", 0.7)
	if hp <= 0:
		_defeat()
	else:
		Sfx.play("boss_hit", 1.6)
		_set_state(State.GUARD_UP)


## Flattened by a nearby ground slam (counts as one hit).
func slam_hit() -> void:
	if state != State.DEAD:
		_hit()


func _defeat() -> void:
	_set_state(State.DEAD)
	set_deferred("monitoring", false)
	_spear.set_deferred("monitoring", false)
	queue_redraw()
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.3, 0.2), 0.18)
	tw.parallel().tween_property(self, "position:y", position.y + 14.0, 0.18)
	tw.tween_property(self, "modulate:a", 0.0, 0.35)
	tw.tween_callback(queue_free)


func _draw() -> void:
	var pose := 0  # 0 normal, 1 pulling back, 2 stabbing, 3 spear up
	match state:
		State.WINDUP:
			pose = 1
		State.STAB, State.RECOVER:
			pose = 2
		State.GUARD_UP:
			pose = 3
	var flash := state == State.GUARD_UP and int(_t * 12.0) % 2 == 0
	draw_guard(self, facing, _t, _spear_out(), pose, hp >= 2, flash)


## Also used for the picture on the website. `spear_out` is how far the spear tip
## reaches in front of him; `pose`: 0 standing, 1 pulling back, 2 stabbing, 3 spear up.
static func draw_guard(ci: CanvasItem, facing: float, t: float, spear_out: float, pose: int,
		helmet: bool, flash: bool) -> void:
	var bone := Color("e6dcc4") if not flash else Color("ffb0b0")
	var shade := bone.darkened(0.25)
	var dark := Color("14101c")
	var iron := Color("6e6a82")
	var iron_dark := Color("44405a")
	var red := Color("c0303a")
	var f := facing
	var feet := 16.0
	var breathe := sin(t * 2.0) * 1.0
	# legs and big boots
	for s in [-1.0, 1.0]:
		ci.draw_line(Vector2(s * 6.0, feet - 16), Vector2(s * 7.0, feet - 4), bone, 4.0)
		ci.draw_rect(Rect2(s * 7.0 - 6.0, feet - 6, 12, 6), iron_dark)
	# hips and ribcage under a breastplate
	ci.draw_rect(Rect2(-9, feet - 20, 18, 5), shade)
	var chest := Vector2(0, feet - 32 + breathe)
	ci.draw_colored_polygon(PackedVector2Array([chest + Vector2(-13, -10), chest + Vector2(13, -10),
		chest + Vector2(10, 10), chest + Vector2(-10, 10)]), iron)
	ci.draw_line(chest + Vector2(-11, -6), chest + Vector2(11, -6), iron.lightened(0.3), 2.0)
	ci.draw_circle(chest + Vector2(0, 2), 3.0, red)
	# shoulder plates
	for s in [-1.0, 1.0]:
		ci.draw_circle(chest + Vector2(s * 13.0, -9), 6.0, iron_dark)
	# the spear arm
	var hand := chest + Vector2(f * 10.0, 8.0)
	if pose == 1:
		hand = chest + Vector2(-f * 2.0, 8.0)
	if pose == 3:
		hand = chest + Vector2(f * 6.0, -6.0)
	ci.draw_line(chest + Vector2(f * 12.0, -8), hand, bone, 4.0)
	ci.draw_circle(hand, 3.5, bone)
	# the spear (along the skull's height, or straight up)
	var gleam := pose == 1 and int(t * 20.0) % 2 == 0
	if pose == 3:
		var bottom := Vector2(f * 4.0, feet - 6)
		var top := Vector2(f * 4.0, feet - HALF_HEIGHT * 2.0 - 40.0)
		ci.draw_line(bottom, top, Color("7a5236"), 3.0)
		ci.draw_colored_polygon(PackedVector2Array([top + Vector2(-5, 2), top + Vector2(0, -14), top + Vector2(5, 2)]),
			Color("dfe6ee"))
	else:
		var y := 2.0
		var tip := Vector2(f * spear_out, y)
		var butt := tip - Vector2(f * 70.0, 0)
		ci.draw_line(butt, tip - Vector2(f * 8.0, 0), Color("7a5236"), 3.0)
		ci.draw_colored_polygon(PackedVector2Array([tip - Vector2(f * 10.0, 5), tip,
			tip - Vector2(f * 10.0, -5)]), Color("ffffff") if gleam else Color("dfe6ee"))
		ci.draw_rect(Rect2(tip.x - f * 13.0 - 1.5, y - 4, 3, 8), red)
	# head: a skull, with a helmet and red plume
	var head := chest + Vector2(f * 1.0, -20)
	ci.draw_circle(head, 10.0, bone)
	ci.draw_rect(Rect2(head.x - 6, head.y + 4, 12, 6), bone)
	for s in [-1.0, 1.0]:
		ci.draw_circle(head + Vector2(s * 4.0 + f * 1.5, 1), 3.0, dark)
		ci.draw_circle(head + Vector2(s * 4.0 + f * 1.5, 1), 1.2, red)
	for i in 3:
		ci.draw_line(head + Vector2(-4 + i * 4, 6), head + Vector2(-4 + i * 4, 9), dark, 1.0)
	if helmet:
		ci.draw_colored_polygon(PackedVector2Array([head + Vector2(-12, -1), head + Vector2(-11, -9),
			head + Vector2(0, -14), head + Vector2(11, -9), head + Vector2(12, -1)]), iron)
		ci.draw_rect(Rect2(head.x - 12, head.y - 3, 24, 3), iron_dark)
		ci.draw_colored_polygon(PackedVector2Array([head + Vector2(-2, -13), head + Vector2(-f * 14.0, -22),
			head + Vector2(-f * 16.0, -12), head + Vector2(2, -12)]), red)
	else:
		# the crack where the helmet was
		ci.draw_line(head + Vector2(-3, -9), head + Vector2(1, -4), dark, 1.5)
