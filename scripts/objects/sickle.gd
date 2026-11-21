extends Area2D
## Jett the Scarecrow's spinning sickle. It flies out LOW along the floor
## (jump over it!), turns at the wall, and comes back HIGH (so stay down!).

const LOW := 20.0   # height above the floor on the way out
const HIGH := 100.0  # and on the way back
const RISE_TIME := 0.3

enum Phase { OUT, RISE, BACK }

var dir := 1.0
var speed := 380.0
var floor_y := 0.0
var home_x := 0.0
var max_x := 0.0  # how far it may fly out (the arena wall)
var is_solid: Callable

var phase := Phase.OUT
var _age := 0.0
var _phase_time := 0.0


func _ready() -> void:
	add_to_group("boss_projectile")
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 11.0
	shape.shape = circle
	add_child(shape)
	position.y = floor_y - LOW


func _physics_process(delta: float) -> void:
	_age += delta
	_phase_time += delta
	queue_redraw()
	match phase:
		Phase.OUT:
			position.x += dir * speed * delta
			var wall: bool = is_solid.is_valid() and is_solid.call(global_position + Vector2(dir * 14.0, 0))
			if wall or (position.x - max_x) * dir > 0.0:
				phase = Phase.RISE
				_phase_time = 0.0
				Sfx.play("dash", 1.6)
		Phase.RISE:
			position.y = lerpf(floor_y - LOW, floor_y - HIGH, clampf(_phase_time / RISE_TIME, 0.0, 1.0))
			if _phase_time > RISE_TIME:
				phase = Phase.BACK
				_phase_time = 0.0
		Phase.BACK:
			position.x -= dir * speed * 0.9 * delta
			if (position.x - home_x) * dir < 0.0:
				queue_free()
				return
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			body.hurt()
	if _age > 6.0:
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 16.0, Color(Color("ffb23e"), 0.12))
	draw_set_transform(Vector2.ZERO, _age * 16.0 * dir)
	draw_sickle(self)
	draw_set_transform(Vector2.ZERO)


static func draw_sickle(ci: CanvasItem) -> void:
	# a curved blade on a short wooden handle
	ci.draw_line(Vector2(-12, 4), Vector2(-2, 0), Color("7a5236"), 4.0)
	var blade := PackedVector2Array()
	for i in 8:
		var a := -0.3 + i * 0.45
		blade.append(Vector2(cos(a), sin(a)) * 12.0 + Vector2(2, -2))
	for i in range(7, -1, -1):
		var a := -0.3 + i * 0.45
		blade.append(Vector2(cos(a), sin(a)) * 8.0 + Vector2(4, -3))
	ci.draw_colored_polygon(blade, Color("d8d8dc"))
	ci.draw_arc(Vector2(2, -2), 12.0, -0.3, 2.85, 8, Color("f4f4f8"), 1.5)
