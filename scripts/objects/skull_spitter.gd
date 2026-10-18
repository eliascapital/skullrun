extends Area2D
## SKULL SPITTER: a stone totem with a skull on top. When you're in line with
## it, it turns to face you and spits green fireballs along the ground.
## Jump over the fireballs, then stomp or slam the totem to smash it.

const Fireball = preload("res://scripts/objects/fireball.gd")

const RANGE := 14.0 * 32.0
const COOLDOWN := 2.4
const WINDUP := 0.6

var player: Node2D
var is_solid: Callable

var facing := -1.0
var _cooldown := 1.0
var _windup := 0.0
var _t := 0.0
var _dead := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(24, 30)
	shape.shape = rect
	shape.position = Vector2(0, 1)
	add_child(shape)
	_cooldown = 0.8 + fmod(position.x * 0.01, 1.2)


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_t += delta
	queue_redraw()
	if player == null:
		return
	var d := player.global_position - global_position
	var in_line: bool = absf(d.x) < RANGE and absf(d.y) < 2.5 * 32.0 and not player.dead
	if _windup > 0.0:
		_windup -= delta
		if _windup <= 0.0:
			_spit()
	else:
		_cooldown -= delta
		if in_line:
			facing = signf(d.x) if absf(d.x) > 2.0 else facing
			if _cooldown <= 0.0:
				_windup = WINDUP
	for body in get_overlapping_bodies():
		if body.is_in_group("player") and not body.dead:
			if body.is_slamming() or body.is_falling_onto(global_position.y - 6.0):
				body.bounce()
				smash()
				return
			body.hurt()


func _spit() -> void:
	_cooldown = COOLDOWN
	var f := Fireball.new()
	f.dir = facing
	f.is_solid = is_solid
	f.position = position + Vector2(facing * 14.0, -4.0)
	get_parent().add_child(f)
	Sfx.play("dash", 1.8)


## Smashed by a stomp or a nearby ground slam.
func smash() -> void:
	if _dead:
		return
	_dead = true
	Sfx.play("stomp", 0.8)
	set_deferred("monitoring", false)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.4, 0.2), 0.15)
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	tw.tween_callback(queue_free)


func slam_hit() -> void:
	smash()


func _draw() -> void:
	var stone := Color("5b5470")
	var dark := Color("2a2436")
	# pillar
	draw_rect(Rect2(-10, 0, 20, 16), stone.darkened(0.2))
	draw_rect(Rect2(-12, 12, 24, 4), dark)
	for i in 2:
		draw_line(Vector2(-10, 4 + i * 5), Vector2(10, 4 + i * 5), dark, 1.0)
	# stone skull
	var glow := 0.0
	if _windup > 0.0:
		glow = 1.0 - _windup / WINDUP
	var head := Vector2(facing * 1.0, -6.0)
	draw_circle(head, 11.0, stone.lightened(0.15))
	draw_rect(Rect2(head.x - 7, head.y + 3, 14, 7), stone.lightened(0.15))
	var eye := Color("8cff5a").lerp(Color.WHITE, glow * 0.6)
	for side in [-1.0, 1.0]:
		var p := head + Vector2(side * 4.5 + facing * 2.0, -1.0)
		draw_circle(p, 3.2, dark)
		draw_circle(p, 1.4 + glow * 1.2, Color(eye, 0.5 + glow * 0.5))
	# mouth
	var m := head + Vector2(facing * 6.0, 6.0)
	draw_circle(m, 3.0 + glow * 2.0, dark)
	if glow > 0.0:
		draw_circle(m, 2.0 + glow * 3.0, Color(Color("8cff5a"), glow))
		draw_circle(m, 12.0 * glow, Color(Color("8cff5a"), 0.12 * glow))
