extends Area2D
## A wraith: a little hooded reaper that wakes up when you come close and
## drifts after you, straight through walls. It's slower than you, so keep
## moving! It can't be stomped. If you get far enough away it gives up and
## floats home, and it returns home whenever you respawn.

const WAKE_RANGE := 7.0 * 32.0
const GIVE_UP_RANGE := 12.0 * 32.0
const CHASE_SPEED := 92.0
const RETURN_SPEED := 60.0

## Set by the level.
var player: Node2D

var _home := Vector2.ZERO
var _chasing := false
var _t := 0.0
var _vel := Vector2.ZERO


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 10.0
	shape.shape = circle
	add_child(shape)
	_home = position
	_t = fmod(position.x * 0.017, TAU)
	z_index = 5


func reset() -> void:
	position = _home
	_vel = Vector2.ZERO
	_chasing = false


func _physics_process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if player == null:
		return
	var to_player := player.global_position - global_position
	var dist := to_player.length()
	if player.dead:
		_chasing = false
	elif not _chasing and dist < WAKE_RANGE:
		_chasing = true
		Sfx.play("roar", 2.2)
	elif _chasing and dist > GIVE_UP_RANGE:
		_chasing = false

	var target_vel := Vector2.ZERO
	if _chasing:
		target_vel = to_player.normalized() * CHASE_SPEED
	elif position.distance_to(_home) > 4.0:
		target_vel = (_home - position).normalized() * RETURN_SPEED
	_vel = _vel.move_toward(target_vel, 260.0 * delta)
	position += _vel * delta + Vector2(0, sin(_t * 2.5) * 0.25)

	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			body.hurt()


func _draw() -> void:
	var cloak := Color("1c1226")
	var edge := Color("6a4590")
	var glow := Config.COLOR_GEM if not _chasing else Config.COLOR_ACCENT
	var look := clampf(_vel.x / CHASE_SPEED, -1.0, 1.0)
	# aura
	draw_circle(Vector2(0, 0), 24.0, Color(glow, 0.06 + (0.06 if _chasing else 0.0)))
	# tattered cloak
	var pts := PackedVector2Array([Vector2(-11, -6), Vector2(0, -18), Vector2(11, -6)])
	for i in 6:
		var x := 12.0 - i * 4.8
		var y := 13.0 + (4.0 if i % 2 == 0 else 0.0) + sin(_t * 7.0 + i) * 2.0
		pts.append(Vector2(x, y))
	draw_colored_polygon(pts, edge)
	for i in pts.size():
		pts[i] = pts[i] * 0.86 + Vector2(0, -1)
	draw_colored_polygon(pts, cloak)
	# hood opening and eyes
	draw_circle(Vector2(look * 2.0, -6), 6.5, Color("07040a"))
	draw_circle(Vector2(-2.4 + look * 2.5, -6), 1.6, glow)
	draw_circle(Vector2(2.4 + look * 2.5, -6), 1.6, glow)
	# little scythe
	var side := -1.0 if look > 0.1 else 1.0
	var hand := Vector2(side * 10.0, 2.0)
	draw_line(hand + Vector2(0, 10), hand + Vector2(0, -16), Color("6b5040"), 2.0)
	draw_arc(hand + Vector2(-side * 6.0, -16), 7.0, PI if side > 0 else 0.0, (PI if side > 0 else 0.0) + PI * 0.75 * side, 8,
		Color("d8d2c4"), 2.5)
