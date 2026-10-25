extends Area2D
## One drop of Mortis the Lich's soul rain: the floor glows where it will
## land, then a ghostly flame falls straight down onto that spot.

const WARN_TIME := 0.9
const FALL_SPEED := 560.0
const DROP_HEIGHT := 9.0 * 32.0

var _age := 0.0
var _y := -DROP_HEIGHT  # the flame's height above the floor (the node sits on the floor)


func _ready() -> void:
	add_to_group("boss_projectile")
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 26)
	shape.shape = rect
	add_child(shape)
	shape.position = Vector2(0, _y)


func _physics_process(delta: float) -> void:
	_age += delta
	queue_redraw()
	if _age < WARN_TIME:
		return
	_y = minf(_y + FALL_SPEED * delta, -12.0)
	(get_child(0) as CollisionShape2D).position.y = _y
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			body.hurt()
	if _y >= -12.0:
		queue_free()


func _draw() -> void:
	var green := Color("59ff8a")
	# the glowing spot on the floor
	var pulse := 0.5 + 0.5 * sin(_age * 18.0)
	draw_set_transform(Vector2(0, -2), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 18.0, Color(green, 0.25 + 0.25 * pulse))
	draw_circle(Vector2.ZERO, 9.0, Color(green, 0.5 + 0.3 * pulse))
	draw_set_transform(Vector2.ZERO)
	if _age < WARN_TIME:
		return
	# the falling flame (point up, round bottom)
	var c := Vector2(0, _y)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-9, 2), c + Vector2(0, -30), c + Vector2(9, 2)]), Color(green, 0.6))
	draw_circle(c + Vector2(0, 4), 10.0, Color(green, 0.85))
	draw_circle(c + Vector2(0, 5), 5.0, Color("e8fff0"))
