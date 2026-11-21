extends Area2D
## A bony hand the Reaper makes burst out of the floor. The floor cracks and
## glows first (that's your warning), then the hand grabs upward, about
## 2.5 tiles high. Don't be standing there!

const Shapes = preload("res://scripts/shapes.gd")

const WARN := 0.8
const UP := 0.65
const HEIGHT := 2.5 * 32.0

var _age := 0.0
var _shape: CollisionShape2D


func _ready() -> void:
	add_to_group("boss_projectile")
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(20, HEIGHT - 6.0)
	_shape.shape = rect
	_shape.position = Vector2(0, -HEIGHT * 0.5 - 3.0)
	_shape.disabled = true
	add_child(_shape)


func _physics_process(delta: float) -> void:
	_age += delta
	queue_redraw()
	if _age >= WARN and _shape.disabled:
		_shape.disabled = false
		Sfx.play("crumble", 0.7)
	if _age >= WARN + UP + 0.2:
		queue_free()
		return
	if not _shape.disabled and _age < WARN + UP:
		for body in get_overlapping_bodies():
			if body.is_in_group("player"):
				body.hurt()


func _draw() -> void:
	# position is on the floor
	var glow := Color(Config.COLOR_PURPLE, 0.35 + 0.3 * sin(_age * 20.0))
	if _age < WARN:
		draw_rect(Rect2(-16, -4, 32, 4), glow)
		draw_line(Vector2(-10, 0), Vector2(-3, -3), Color(0, 0, 0, 0.7), 2.0)
		draw_line(Vector2(-3, -3), Vector2(5, 0), Color(0, 0, 0, 0.7), 2.0)
		draw_line(Vector2(5, 0), Vector2(11, -2), Color(0, 0, 0, 0.7), 2.0)
		return
	var k := minf(1.0, (_age - WARN) / 0.08)
	if _age > WARN + UP:
		k = 1.0 - (_age - WARN - UP) / 0.2
	var top := -HEIGHT * k
	var bone := Config.COLOR_BONE
	Shapes.disc(self, Vector2(0, -2), 14.0, Color(Config.COLOR_PURPLE, 0.25))
	# the arm
	draw_line(Vector2(-3, 0), Vector2(-3, top + 16), bone, 4.0)
	draw_line(Vector2(3, 0), Vector2(3, top + 16), bone.darkened(0.15), 4.0)
	# the palm and grabbing fingers
	Shapes.disc(self, Vector2(0, top + 14), 7.0, bone)
	for i in 4:
		var x := -7.0 + i * 4.7
		var curl := sin(_age * 18.0 + i) * 2.0
		draw_line(Vector2(x, top + 10), Vector2(x + curl, top - 2), bone, 3.0)
		Shapes.disc(self, Vector2(x + curl, top - 2), 1.6, bone)
	draw_line(Vector2(7, top + 14), Vector2(12, top + 6), bone, 3.0)
