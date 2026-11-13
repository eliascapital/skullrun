extends Area2D
## Things Alethea the Happy Clown throws at you:
##   "pin"  a juggling pin that flies in an arc,
##   "pie"  a cream pie that slides along the floor (jump it!),
##   "ball" a rubber confetti ball that bounces once before it pops.

const GRAVITY := 900.0

var kind := "pin"
var velocity := Vector2.ZERO
var color := Color("ff5fd2")
var is_solid: Callable
var _age := 0.0
var _bounced := false


func _ready() -> void:
	add_to_group("boss_projectile")
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 9.0 if kind == "pie" else 8.0
	shape.shape = circle
	add_child(shape)


func _physics_process(delta: float) -> void:
	_age += delta
	if kind != "pie":
		velocity.y = minf(velocity.y + GRAVITY * delta, 800.0)
	position += velocity * delta
	if kind == "pin":
		rotation += 14.0 * delta * signf(velocity.x + 0.01)
	queue_redraw()
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			body.hurt()
	if _age > 6.0 or not is_solid.is_valid():
		queue_free()
		return
	var ahead := global_position + Vector2(signf(velocity.x) * 8.0, 0)
	if is_solid.call(ahead):
		queue_free()
		return
	if velocity.y > 0.0 and is_solid.call(global_position + Vector2(0, 8)):
		if kind == "ball" and not _bounced:
			_bounced = true
			velocity.y = -absf(velocity.y) * 0.7
			Sfx.play("bounce", 1.8)
		else:
			queue_free()


func _draw() -> void:
	match kind:
		"pin":
			var white := Color("f4efe6")
			draw_colored_polygon(PackedVector2Array([Vector2(-12, -3), Vector2(2, -6), Vector2(10, -4),
				Vector2(13, 0), Vector2(10, 4), Vector2(2, 6), Vector2(-12, 3)]), white)
			draw_rect(Rect2(-2, -6, 4, 12), color)
			draw_circle(Vector2(-12, 0), 3.0, color)
		"pie":
			var d := signf(velocity.x + 0.01)
			draw_rect(Rect2(-12, 0, 24, 7), Color("c98a4a"))
			draw_rect(Rect2(-12, 5, 24, 2), Color("8a5a2a"))
			draw_circle(Vector2(0, 0), 11.0, Color("fff6e8"))
			draw_rect(Rect2(-12, 0, 24, 3), Color("fff6e8"))
			draw_circle(Vector2(0, -8), 3.0, Color("e63946"))
			# whoosh lines behind it
			for i in 3:
				draw_line(Vector2(-d * (16 + i * 6), -4 + i * 4), Vector2(-d * (24 + i * 6), -4 + i * 4),
					Color(1, 1, 1, 0.4), 2.0)
		"ball":
			draw_circle(Vector2.ZERO, 12.0, Color(color, 0.15))
			draw_circle(Vector2.ZERO, 8.0, color)
			draw_arc(Vector2.ZERO, 8.0, -0.6, 1.4, 8, color.darkened(0.3), 2.0)
			draw_circle(Vector2(-3, -3), 2.5, Color(1, 1, 1, 0.8))
