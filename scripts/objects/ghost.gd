extends Area2D
## A floating enemy you must avoid. `kind` is "ghost" (moves left/right)
## or "bat" (moves up/down). Touching either one hurts!

@export var kind := "ghost"
@export var travel := 96.0  # pixels each way
@export var speed := 1.4

var _origin := Vector2.ZERO
var _t := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 10.0
	shape.shape = circle
	add_child(shape)
	_origin = position
	_t = fmod(position.x * 0.021 + position.y * 0.017, TAU)


func _physics_process(delta: float) -> void:
	_t += delta
	if kind == "bat":
		position = _origin + Vector2(sin(_t * 2.3) * 6.0, sin(_t * speed) * travel)
	else:
		position = _origin + Vector2(sin(_t * speed) * travel, sin(_t * 3.0) * 5.0)
	queue_redraw()
	# checked every frame so it still counts after the respawn grace period
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			body.hurt()


func _draw() -> void:
	if kind == "bat":
		_draw_bat()
	else:
		_draw_ghost()


func _draw_ghost() -> void:
	var dir := signf(cos(_t * speed))
	var body := Color(0.88, 0.92, 1.0, 0.75)
	draw_circle(Vector2.ZERO, 22.0, Color(0.7, 0.8, 1.0, 0.07))
	draw_circle(Vector2(0, -3), 12.0, body)
	var pts := PackedVector2Array([Vector2(-12, -3), Vector2(12, -3)])
	for i in 7:
		var x := 12.0 - i * 4.0
		pts.append(Vector2(x, 12.0 + (3.0 if i % 2 == 0 else -1.0) + sin(_t * 8.0 + i) * 1.5))
	draw_colored_polygon(pts, body)
	var eye := Color("1a1030")
	draw_circle(Vector2(-4 + dir * 2.5, -4), 2.6, eye)
	draw_circle(Vector2(4 + dir * 2.5, -4), 2.6, eye)
	draw_circle(Vector2(dir * 2.5, 3), 2.0 + absf(sin(_t * 2.0)), eye)


func _draw_bat() -> void:
	var flap := sin(_t * 18.0)
	var c := Color("4b2a63")
	draw_circle(Vector2.ZERO, 18.0, Color(Config.COLOR_PURPLE, 0.08))
	for side in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([
			Vector2(side * 5, -2), Vector2(side * 20, -8 - flap * 8), Vector2(side * 16, 2 + flap * 2),
			Vector2(side * 11, -1), Vector2(side * 7, 5)]), c)
	draw_circle(Vector2.ZERO, 8.0, c.lightened(0.1))
	draw_colored_polygon(PackedVector2Array([Vector2(-6, -5), Vector2(-3, -12), Vector2(-1, -6)]), c)
	draw_colored_polygon(PackedVector2Array([Vector2(6, -5), Vector2(3, -12), Vector2(1, -6)]), c)
	draw_circle(Vector2(-3, -1), 1.8, Config.COLOR_ACCENT)
	draw_circle(Vector2(3, -1), 1.8, Config.COLOR_ACCENT)
