extends Area2D
## A green fireball spat by a Skull Spitter. Flies straight until it hits a wall.

var dir := 1.0
var speed := 190.0
var is_solid: Callable
var _age := 0.0


func _ready() -> void:
	add_to_group("spit")
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 6.0
	shape.shape = circle
	add_child(shape)


func _physics_process(delta: float) -> void:
	_age += delta
	position.x += dir * speed * delta
	queue_redraw()
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			body.hurt()
	if _age > 7.0 or (is_solid.is_valid() and is_solid.call(global_position + Vector2(dir * 6.0, 0))):
		queue_free()


func _draw() -> void:
	var c := Color("8cff5a")
	for i in 4:
		draw_circle(Vector2(-dir * (5.0 + i * 5.0), sin(_age * 20.0 + i) * 1.5), 5.0 - i, Color(c, 0.35 - i * 0.07))
	draw_circle(Vector2.ZERO, 10.0, Color(c, 0.15))
	draw_circle(Vector2.ZERO, 6.0, c)
	draw_circle(Vector2(dir * 1.5, -1.5), 2.5, Color.WHITE)
