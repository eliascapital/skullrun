extends Area2D
## A circus CANNON. Touch it and it shoots you out of its barrel, much higher
## and further than a double jump can take you. `>` in a level points it
## up-right, `<` up-left. You land with your double jump and dash ready.

const SPEED := 1100.0
const ANGLE := deg_to_rad(55.0)  # how far above flat the barrel points
const BARREL := 30.0

## 1 = fires up and to the right, -1 = up and to the left.
var dir := 1.0

var _t := 0.0
var _kick := 0.0  # recoil after a shot
var _cooldown := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(28, 26)
	shape.shape = rect
	shape.position = Vector2(0, 3)
	add_child(shape)


## The direction the barrel points, as an angle (0 = right).
func aim() -> float:
	return -ANGLE if dir > 0.0 else PI + ANGLE


func _physics_process(delta: float) -> void:
	_t += delta
	_kick = maxf(0.0, _kick - delta * 3.0)
	_cooldown -= delta
	queue_redraw()
	if _cooldown > 0.0:
		return
	for body in get_overlapping_bodies():
		if body.is_in_group("player") and not body.dead and body.has_method("blast"):
			_fire(body)


func _fire(body: Node2D) -> void:
	_cooldown = 0.5
	_kick = 1.0
	var muzzle := global_position + _pivot() + Vector2.RIGHT.rotated(aim()) * BARREL
	body.blast(muzzle, SPEED, aim())
	Sfx.play("cannon")


func _pivot() -> Vector2:
	return Vector2(0, -2)


func _draw() -> void:
	draw_cannon(self, dir, aim(), _kick, _t)


## Also used for the picture on the website.
static func draw_cannon(ci: CanvasItem, dir: float, angle: float, kick: float, t: float) -> void:
	var wood := Color("8a4b2a")
	var iron := Color("2f2a3a")
	var gold := Color("ffd166")
	var red := Color("e63946")
	var pivot := Vector2(0, -2)
	var along := Vector2.RIGHT.rotated(angle)
	var across := along.orthogonal()
	var back := pivot - along * (8.0 + kick * 6.0)
	# barrel: a fat tube, red with gold bands, wider at the back
	var tip := back + along * 38.0
	var poly := PackedVector2Array([back + across * 11.0, tip + across * 8.0, tip - across * 8.0, back - across * 11.0])
	ci.draw_colored_polygon(poly, red.darkened(0.15))
	ci.draw_line(back + across * 6.0, tip + across * 4.5, red.lightened(0.25), 3.0)
	for k in [0.2, 0.62]:
		var c: Vector2 = back + along * 38.0 * k
		ci.draw_line(c + across * (11.0 - 3.0 * k), c - across * (11.0 - 3.0 * k), gold, 4.0)
	ci.draw_line(tip + across * 9.0, tip - across * 9.0, gold, 5.0)
	ci.draw_circle(tip, 5.5, iron)
	ci.draw_circle(back, 9.0, red.darkened(0.3))
	# a little fuse with a spark
	var fuse := back - along * 6.0 + across * 4.0 * dir
	ci.draw_line(back, fuse, Color("3a2a1a"), 2.0)
	ci.draw_circle(fuse, 2.0 + sin(t * 20.0), Color(gold, 0.8))
	# carriage and wheels
	ci.draw_rect(Rect2(-14, 2, 28, 7), wood)
	for x in [-9.0, 9.0]:
		ci.draw_circle(Vector2(x, 9), 7.0, wood.darkened(0.3))
		ci.draw_circle(Vector2(x, 9), 4.0, wood)
		ci.draw_circle(Vector2(x, 9), 1.5, iron)
	# puff of smoke right after a shot
	if kick > 0.0:
		for i in 4:
			var p := tip + along * (8.0 + (1.0 - kick) * 28.0 + i * 7.0) + across * sin(i * 2.0) * 6.0
			ci.draw_circle(p, (6.0 + i * 2.0) * kick, Color(1, 1, 1, 0.5 * kick))
