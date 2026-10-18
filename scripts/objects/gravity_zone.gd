extends Area2D
## A reverse-gravity zone: inside it the skull falls UP and walks on ceilings.
## The level makes one zone for every patch of `:` in the map.

var size := Vector2(64, 64)
var _t := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	z_index = -1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = size * 0.5
	add_child(shape)


func _physics_process(delta: float) -> void:
	_t += delta
	queue_redraw()
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			body.in_flip_zone()


func _draw() -> void:
	var c := Color("39d0ff")
	draw_rect(Rect2(Vector2.ZERO, size), Color(c, 0.07))
	draw_rect(Rect2(Vector2.ZERO, size), Color(c, 0.35), false, 2.0)
	# little arrows drifting upward
	var cols := int(size.x / 48.0) + 1
	var rows := int(size.y / 48.0) + 1
	for i in cols:
		for j in rows:
			var x := 24.0 + i * 48.0
			var y := fmod(j * 48.0 + 40.0 - _t * 30.0 + i * 17.0, size.y + 1.0)
			if x > size.x - 6.0:
				continue
			var a := 0.35 * sin(PI * y / size.y)
			draw_colored_polygon(PackedVector2Array([Vector2(x, y - 6), Vector2(x + 6, y + 3), Vector2(x - 6, y + 3)]),
				Color(c, a))
