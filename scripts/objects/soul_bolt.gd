extends Area2D
## A soul bolt cast by Mortis the Lich. Flies in a straight line.

var velocity := Vector2.ZERO
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
	position += velocity * delta
	queue_redraw()
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			body.hurt()
	if _age > 7.0 or (_age > 0.3 and is_solid.is_valid() and is_solid.call(global_position)):
		queue_free()


func _draw() -> void:
	var green := Color("59ff8a")
	var back := -velocity.normalized()
	for i in 5:
		draw_circle(back * (6.0 + i * 5.0), 7.0 - i * 1.2, Color(green, 0.35 - i * 0.06))
	draw_circle(Vector2.ZERO, 14.0, Color(green, 0.15))
	draw_circle(Vector2.ZERO, 8.0, green)
	draw_circle(Vector2.ZERO, 4.0 + sin(_age * 30.0), Color("e8fff0"))
