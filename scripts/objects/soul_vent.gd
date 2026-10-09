extends Area2D
## A soul vent: a column of rising spirit wind that lifts the skull up.
## Ride it to the top, float across, and it refills your double jump and dash.

var height_tiles := 8
var _t := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	var h := height_tiles * 32.0
	rect.size = Vector2(26, h)
	shape.shape = rect
	shape.position = Vector2(0, 16 - h * 0.5)
	add_child(shape)
	_t = fmod(position.x * 0.013, 10.0)


func _physics_process(delta: float) -> void:
	_t += delta
	queue_redraw()
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			body.ride_wind()


func _draw() -> void:
	var c := Config.COLOR_PURPLE
	var h := height_tiles * 32.0
	# glowing column
	draw_rect(Rect2(-14, 16 - h, 28, h), Color(c, 0.07))
	draw_rect(Rect2(-8, 16 - h, 16, h), Color(c, 0.06))
	# rising wisps
	for i in 10:
		var k := fmod(_t * 0.55 + i * 0.1, 1.0)
		var y := 16.0 - k * h
		var x := sin(_t * 3.0 + i * 1.7) * 8.0
		draw_circle(Vector2(x, y), 3.0 * (1.0 - k) + 1.0, Color(c.lightened(0.4), 0.7 * (1.0 - k)))
	# grate
	draw_rect(Rect2(-16, 10, 32, 6), Color("2a2236"))
	for i in 4:
		draw_rect(Rect2(-13 + i * 7, 11, 3, 4), Color(c, 0.6 + 0.3 * sin(_t * 5.0 + i)))
