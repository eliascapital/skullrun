extends CharacterBody2D
## An EVIL SNAKE. It slithers back and forth along the ground (turning at walls
## and ledges, but sliding straight through fake walls). When you're in front
## of it and close, it rears up with a hiss... then LUNGES at you, fast.
## Jump over the lunge, or jump on its head while it's slithering.

const SPEED := 60.0
const GRAVITY := 1800.0
const SEE := 4.5 * 32.0  # how far ahead it notices you
const REAR := 0.45  # hiss and rear up (your warning)
const LUNGE := 0.32
const LUNGE_SPEED := 470.0
const REST := 0.7

enum State { SLITHER, REAR, LUNGE, REST }

## Set by the level.
var is_solid: Callable
var player: Node2D

var state := State.SLITHER
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
	rect.size = Vector2(36, 16)
	shape.shape = rect
	shape.position = Vector2(0, 8)
	add_child(shape)

	_hitbox = Area2D.new()
	_hitbox.collision_layer = 0
	_hitbox.collision_mask = 2
	_hitbox.monitorable = false
	var hs := CollisionShape2D.new()
	var hr := RectangleShape2D.new()
	hr.size = Vector2(42, 20)
	hs.shape = hr
	hs.position = Vector2(0, 6)
	_hitbox.add_child(hs)
	add_child(_hitbox)
	_t = fmod(position.x * 0.01, TAU)


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
		State.SLITHER:
			velocity.x = _dir * SPEED
			if _sees_player():
				_set_state(State.REAR)
				Sfx.play("dash", 0.5)
		State.REAR:
			velocity.x = 0.0
			if _state_time > REAR:
				_set_state(State.LUNGE)
				Sfx.play("dash", 1.9)
		State.LUNGE:
			velocity.x = _dir * LUNGE_SPEED
			if _state_time > LUNGE:
				_set_state(State.REST)
		State.REST:
			velocity.x = 0.0
			if _state_time > REST:
				_set_state(State.SLITHER)
	move_and_slide()
	if is_on_floor():
		var ahead := global_position + Vector2(_dir * 16.0, 22.0)
		if is_on_wall() or (is_solid.is_valid() and not is_solid.call(ahead)):
			if state == State.LUNGE:
				velocity.x = 0.0
				_set_state(State.REST)
			_dir = -_dir
	queue_redraw()
	for body in _hitbox.get_overlapping_bodies():
		if body.is_in_group("player") and not body.dead:
			if state != State.REAR and body.is_falling_onto(global_position.y):
				body.bounce()
				_defeat()
				return
			body.hurt()


func _sees_player() -> bool:
	if player == null or player.dead:
		return false
	var d := player.global_position - global_position
	return signf(d.x) == _dir and absf(d.x) < SEE and absf(d.y) < 40.0


## Flattened by a nearby ground slam.
func slam_hit() -> void:
	if not _dead:
		_defeat()


func _defeat() -> void:
	_dead = true
	Sfx.play("stomp", 1.3)
	set_deferred("collision_mask", 0)
	_hitbox.set_deferred("monitoring", false)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.3, 0.2), 0.12)
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_callback(queue_free)


func _draw() -> void:
	var rear := 0.0
	if state == State.REAR:
		rear = minf(1.0, _state_time / 0.15)
	elif state == State.LUNGE:
		rear = 0.4
	# drawn a bit bigger than its picture, standing on the ground
	draw_set_transform(Vector2(0, -4.8), 0.0, Vector2(1.3, 1.3))
	draw_snake(self, _dir, _t, rear, state == State.LUNGE)


## Also used for the picture on the website. `rear` 0 … 1 lifts its head up
## ready to strike; `striking` opens its mouth wide.
static func draw_snake(ci: CanvasItem, facing: float, t: float, rear: float, striking: bool) -> void:
	var body := Color("8a3ac8")
	var stripe := Color("ff3b4e")
	var belly := Color("ffd166")
	var f := facing
	var wiggle := 1.0 - rear * 0.7
	# the body: a wavy line of fat segments from the tail to the neck
	var pts: Array[Vector2] = []
	for i in 9:
		var k := i / 8.0
		var x := -f * (20.0 - k * 30.0)
		var y := 12.0 + sin(t * 9.0 + i * 0.9) * 2.5 * wiggle
		pts.append(Vector2(x, y))
	for i in pts.size():
		var r := 3.0 + 4.0 * sin(PI * (0.15 + 0.85 * i / 8.0))
		ci.draw_circle(pts[i] + Vector2(0, 1.5), r, belly)
		ci.draw_circle(pts[i], r, body)
		if i % 2 == 1:
			ci.draw_circle(pts[i] + Vector2(0, -1), r * 0.45, stripe)
	# the neck rises when it rears up
	var neck := pts[pts.size() - 1]
	var head := neck + Vector2(f * (6.0 - rear * 2.0), -rear * 16.0 - 2.0)
	ci.draw_line(neck, head, body, 9.0)
	# head: wide and flat, with evil eyes
	var hp := PackedVector2Array([head + Vector2(-f * 6.0, -6.0), head + Vector2(f * 6.0, -6.0),
		head + Vector2(f * 11.0, -1.0), head + Vector2(f * 6.0, 5.0), head + Vector2(-f * 6.0, 5.0)])
	ci.draw_colored_polygon(hp, body)
	var eye := head + Vector2(f * 3.0, -3.0)
	ci.draw_circle(eye, 2.6, Color("ffd166"))
	ci.draw_line(eye + Vector2(0, -2), eye + Vector2(0, 2), Color("120a18"), 1.5)
	ci.draw_line(eye + Vector2(-f * 4.0, -4.5), eye + Vector2(f * 2.0, -3.0), Color("120a18"), 1.5)
	# mouth: fangs when it strikes, a flicking forked tongue otherwise
	var snout := head + Vector2(f * 11.0, 0.0)
	if striking or rear > 0.9:
		ci.draw_colored_polygon(PackedVector2Array([snout + Vector2(0, -2), snout + Vector2(f * 3.0, 4.0),
			head + Vector2(f * 4.0, 4.0)]), Color("1a0a10"))
		ci.draw_line(snout + Vector2(-f * 2.0, -1), snout + Vector2(-f * 2.0, 4), Color.WHITE, 1.5)
	elif fmod(t, 1.2) < 0.35:
		var tip := snout + Vector2(f * 6.0, 1.0)
		ci.draw_line(snout, tip, stripe, 1.5)
		ci.draw_line(tip, tip + Vector2(f * 3.0, -2.0), stripe, 1.2)
		ci.draw_line(tip, tip + Vector2(f * 3.0, 2.0), stripe, 1.2)
