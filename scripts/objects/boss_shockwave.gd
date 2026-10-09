extends Area2D
## A ground shockwave from the Bone King's slam. Jump over it!

const SPEED := 270.0

var dir := 1.0
var is_solid: Callable
var _age := 0.0


func _ready() -> void:
	add_to_group("boss_projectile")
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(22, 20)
	shape.shape = rect
	shape.position = Vector2(0, -10)
	add_child(shape)


func _physics_process(delta: float) -> void:
	_age += delta
	position.x += dir * SPEED * delta
	queue_redraw()
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			body.hurt()
	var blocked: bool = is_solid.is_valid() and (is_solid.call(global_position + Vector2(dir * 12, -10))
		or not is_solid.call(global_position + Vector2(0, 6)))
	if _age > 4.0 or blocked:
		queue_free()


func _draw() -> void:
	var c := Config.COLOR_ACCENT
	var flick := 0.8 + 0.2 * sin(_age * 40.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-14, 0), Vector2(-4, -26 * flick), Vector2(2, -12),
		Vector2(8, -22 * flick), Vector2(14, 0)]), Color(c, 0.85))
	draw_colored_polygon(PackedVector2Array([Vector2(-8, 0), Vector2(-2, -14 * flick), Vector2(6, -10), Vector2(9, 0)]),
		Config.COLOR_GOLD)
	draw_circle(Vector2(0, -6), 18.0, Color(c, 0.12))
