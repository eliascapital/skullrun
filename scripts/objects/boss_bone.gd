extends Area2D
## A spinning bone thrown by the Bone King. Falls in an arc.

const GRAVITY := 900.0

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
	velocity.y += GRAVITY * delta
	position += velocity * delta
	rotation += 12.0 * delta
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			body.hurt()
	if _age > 5.0 or (is_solid.is_valid() and is_solid.call(global_position + Vector2(0, 6))):
		queue_free()


func _draw() -> void:
	var bone := Color("e8e0cc")
	draw_line(Vector2(-10, 0), Vector2(10, 0), bone, 5.0)
	for e in [-10.0, 10.0]:
		draw_circle(Vector2(e, -3), 4.0, bone)
		draw_circle(Vector2(e, 3), 4.0, bone)
