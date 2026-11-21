extends Area2D
## A little flaming skull the Reaper sends after you. It follows you for a few
## seconds, but it turns slowly, so keep running and it can't catch you.

const SPEED := 165.0
const TURN := 2.0  # radians per second
const LIFE := 3.4

var velocity := Vector2.ZERO
var player: Node2D
var is_solid: Callable
var _age := 0.0


func _ready() -> void:
	add_to_group("boss_projectile")
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 8.0
	shape.shape = circle
	add_child(shape)


func _physics_process(delta: float) -> void:
	_age += delta
	queue_redraw()
	if _age > 0.35 and player and not player.dead:
		# steer towards the skull, but only a little each frame
		var want := (player.global_position - global_position).angle()
		var now := velocity.angle()
		var turn := clampf(wrapf(want - now, -PI, PI), -TURN * delta, TURN * delta)
		velocity = Vector2.RIGHT.rotated(now + turn) * SPEED
	position += velocity * delta
	if _age < LIFE - 0.4:
		for body in get_overlapping_bodies():
			if body.is_in_group("player"):
				body.hurt()
	if _age > LIFE or (is_solid.is_valid() and is_solid.call(global_position)):
		queue_free()


func _draw() -> void:
	var fade := clampf((LIFE - _age) / 0.4, 0.0, 1.0)
	var back := -velocity.normalized()
	for i in 4:
		var k := float(i) / 4.0
		var flick := sin(_age * 30.0 + i * 2.0) * 2.0
		draw_circle(back * (6.0 + i * 5.0) + back.orthogonal() * flick, 7.0 - i * 1.5,
			Color(Config.COLOR_ACCENT.lerp(Color("ffd166"), k), 0.7 * fade * (1.0 - k * 0.6)))
	draw_circle(Vector2.ZERO, 8.0, Color(Config.COLOR_BONE, fade))
	draw_rect(Rect2(-4, 4, 8, 4), Color(Config.COLOR_BONE, fade))
	for s in [-1.0, 1.0]:
		draw_circle(Vector2(s * 3.0, -1), 2.2, Color(Config.COLOR_ACCENT, fade))
