extends Area2D
## A jack-in-the-box Alethea the Happy Clown makes pop out of the floor.
## It rattles first (that's your warning), then a spring with a grinning head
## shoots up 3 tiles. Don't be standing on it!

const WARN := 0.95
const UP := 0.7
const HEIGHT := 3.0 * 32.0

var _age := 0.0
var _shape: CollisionShape2D


func _ready() -> void:
	add_to_group("boss_projectile")
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(24, HEIGHT - 8.0)
	_shape.shape = rect
	_shape.position = Vector2(0, -HEIGHT * 0.5 - 4.0)
	_shape.disabled = true
	add_child(_shape)


func _physics_process(delta: float) -> void:
	_age += delta
	queue_redraw()
	if _age >= WARN and _shape.disabled:
		_shape.disabled = false
		Sfx.play("bounce", 0.8)
	if _age >= WARN + UP:
		queue_free()
		return
	if not _shape.disabled:
		for body in get_overlapping_bodies():
			if body.is_in_group("player"):
				body.hurt()


func _draw() -> void:
	# position is on the floor
	var shake := sin(_age * 50.0) * 2.0 if _age < WARN else 0.0
	var box := Rect2(-13 + shake, -20, 26, 20)
	var up := 0.0
	if _age >= WARN:
		up = minf(1.0, (_age - WARN) / 0.08) * (HEIGHT - 20.0)
	# warning glow on the floor
	if _age < WARN:
		draw_rect(Rect2(-16, -4, 32, 4), Color(Color("ff5fd2"), 0.3 + 0.3 * sin(_age * 18.0)))
	# the spring and the grinning head
	if up > 0.0:
		var top := -20.0 - up
		var coils := 7
		for i in coils:
			var y0 := -20.0 - up * i / coils
			var y1 := -20.0 - up * (i + 1) / coils
			draw_line(Vector2(-8, y0), Vector2(8, y1), Color("c0c8d8"), 3.0)
		draw_circle(Vector2(0, top - 4), 11.0, Color("fff6e8"))
		draw_circle(Vector2(0, top - 3), 3.0, Color("e63946"))
		draw_arc(Vector2(0, top - 2), 6.0, 0.3, PI - 0.3, 8, Color("e63946"), 2.0)
		draw_colored_polygon(PackedVector2Array([Vector2(-10, top - 12), Vector2(0, top - 26),
			Vector2(10, top - 12)]), Color("6bd7ff"))
	# the box (with its lid flipped open once it pops)
	draw_rect(box, Color("e63946"))
	draw_rect(Rect2(box.position + Vector2(3, 3), Vector2(20, 14)), Color("ffd166"))
	draw_line(box.position + Vector2(13, 3), box.position + Vector2(13, 17), Color("e63946"), 2.0)
	if up <= 0.0:
		draw_rect(Rect2(-14 + shake, -23, 28, 4), Color("6bd7ff"))
	else:
		draw_rect(Rect2(-18, -24, 4, 16), Color("6bd7ff"))
