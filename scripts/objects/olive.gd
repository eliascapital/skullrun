extends CharacterBody2D
## A little OLIVE that waddles back and forth (`U` in a level). Get close in
## front of it and it jumps in surprise... then CHARGES at you, and keeps going
## until it bumps into something. Jump on it to squish it.

const WADDLE_SPEED := 35.0
const CHARGE_SPEED := 300.0
const GRAVITY := 1800.0
const SEE := 5.0 * 32.0
const ALERT := 0.45
const DIZZY := 0.8

enum State { WADDLE, ALERT, CHARGE, DIZZY }

## Set by the level.
var is_solid: Callable
var player: Node2D

var state := State.WADDLE
var _dir := -1.0
var _t := 0.0
var _state_time := 0.0
var _dead := false
var _hitbox: Area2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(24, 30)
	shape.shape = rect
	shape.position = Vector2(0, 1)
	add_child(shape)

	_hitbox = Area2D.new()
	_hitbox.collision_layer = 0
	_hitbox.collision_mask = 2
	_hitbox.monitorable = false
	var hs := CollisionShape2D.new()
	var hr := RectangleShape2D.new()
	hr.size = Vector2(28, 32)
	hs.shape = hr
	hs.position = Vector2(0, 0)
	_hitbox.add_child(hs)
	add_child(_hitbox)
	_t = fmod(position.x * 0.017, TAU)


func _set_state(s: State) -> void:
	state = s
	_state_time = 0.0


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_t += delta
	_state_time += delta
	velocity.y = minf(velocity.y + GRAVITY * delta, 900.0)
	match state:
		State.WADDLE:
			velocity.x = _dir * WADDLE_SPEED
			if _sees_player():
				_set_state(State.ALERT)
				velocity.y = -260.0  # a little hop of surprise
				Sfx.play("jump", 1.8)
		State.ALERT:
			velocity.x = 0.0
			if _state_time > ALERT and is_on_floor():
				_set_state(State.CHARGE)
				Sfx.play("dash", 1.3)
		State.CHARGE:
			velocity.x = _dir * CHARGE_SPEED
		State.DIZZY:
			velocity.x = 0.0
			if _state_time > DIZZY:
				_set_state(State.WADDLE)
	move_and_slide()
	if is_on_floor():
		var ahead := global_position + Vector2(_dir * 12.0, 22.0)
		if is_on_wall() or (is_solid.is_valid() and not is_solid.call(ahead)):
			if state == State.CHARGE:
				_set_state(State.DIZZY)
			_dir = -_dir
	queue_redraw()
	for body in _hitbox.get_overlapping_bodies():
		if body.is_in_group("player") and not body.dead:
			if body.is_falling_onto(global_position.y - 8.0):
				body.bounce()
				_defeat()
				return
			body.hurt()


func _sees_player() -> bool:
	if player == null or player.dead:
		return false
	var d := player.global_position - global_position
	return signf(d.x) == _dir and absf(d.x) < SEE and absf(d.y) < 48.0


## Squished by a nearby ground slam.
func slam_hit() -> void:
	if not _dead:
		_defeat()


func _defeat() -> void:
	_dead = true
	Sfx.play("stomp", 1.5)
	set_deferred("collision_mask", 0)
	_hitbox.set_deferred("monitoring", false)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.6, 0.25), 0.1)
	tw.tween_interval(0.3)
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_callback(queue_free)


func _draw() -> void:
	# a bit bigger than its drawing, standing on the ground
	draw_set_transform(Vector2(0, -3.75), 0.0, Vector2(1.25, 1.25))
	draw_olive(self, _dir, _t, state == State.CHARGE or state == State.ALERT, state == State.DIZZY)


## Also used for the picture on the website.
static func draw_olive(ci: CanvasItem, facing: float, t: float, angry: bool, dizzy: bool) -> void:
	var olive := Color("7a8a2a")
	var shade := Color("4e5a18")
	var pimento := Color("c8302a")
	var f := facing
	var speed := 22.0 if angry else 8.0
	var tilt := sin(t * speed) * (0.12 if angry else 0.2)
	var step := sin(t * speed)
	# little feet
	for s in [-1.0, 1.0]:
		var lift := maxf(0.0, step * s) * 3.0
		ci.draw_line(Vector2(s * 5.0, 10), Vector2(s * 5.0 + f * 2.0, 15 - lift), shade, 3.0)
		ci.draw_line(Vector2(s * 5.0 + f * 2.0, 15 - lift), Vector2(s * 5.0 + f * 6.0, 15 - lift), shade, 3.0)
	# the olive itself, rocking side to side as it waddles
	var oval := PackedVector2Array()
	var inner := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		oval.append(Vector2(cos(a) * 11.0, sin(a) * 13.5 + 1.0).rotated(tilt))
		inner.append(Vector2(cos(a) * 9.0, sin(a) * 11.5).rotated(tilt))
	ci.draw_colored_polygon(oval, shade)
	ci.draw_colored_polygon(inner, olive)
	ci.draw_circle(Vector2(-4, -6).rotated(tilt), 2.5, Color(1, 1, 1, 0.35))
	# the pimento on top, like a little red hat
	var top := Vector2(0, -12).rotated(tilt)
	ci.draw_circle(top, 4.5, pimento)
	ci.draw_circle(top + Vector2(-1, -1), 1.8, Color("ff6a50"))
	# face
	var face := Vector2(f * 3.0, -1).rotated(tilt)
	for s in [-1.0, 1.0]:
		var e := face + Vector2(s * 3.5, 0)
		if dizzy:
			ci.draw_line(e + Vector2(-1.5, -1.5), e + Vector2(1.5, 1.5), Color("1a1a08"), 1.5)
			ci.draw_line(e + Vector2(-1.5, 1.5), e + Vector2(1.5, -1.5), Color("1a1a08"), 1.5)
		else:
			ci.draw_circle(e, 2.0, Color.WHITE)
			ci.draw_circle(e + Vector2(f * 0.6, 0.3), 1.1, Color("1a1a08"))
			if angry:
				ci.draw_line(e + Vector2(-s * 2.5, -4.0), e + Vector2(s * 2.0, -2.0), Color("1a1a08"), 1.5)
	if angry:
		ci.draw_line(face + Vector2(-3, 5), face + Vector2(3, 5), Color("1a1a08"), 1.5)
	else:
		ci.draw_arc(face + Vector2(0, 3), 2.5, 0.3, PI - 0.3, 6, Color("1a1a08"), 1.2)
