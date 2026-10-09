extends Area2D
## The swirling exit portal at the end of each level.

signal reached

var _t := 0.0
var _used := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(36, 60)
	shape.shape = rect
	shape.position = Vector2(0, -14)
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if _used or not body.is_in_group("player") or body.dead:
		return
	_used = true
	Sfx.play("win")
	reached.emit()


func _draw() -> void:
	var c := Vector2(0, -14)
	for i in 7:
		draw_circle(c, 58.0 - i * 6.0, Color(Config.COLOR_PURPLE, 0.03 + i * 0.012))
	# stone arch
	var stone := Color("2a2236")
	draw_rect(Rect2(-30, -52, 8, 70), stone)
	draw_rect(Rect2(22, -52, 8, 70), stone)
	draw_rect(Rect2(-34, -60, 68, 10), stone)
	draw_rect(Rect2(-6, -66, 12, 8), Config.COLOR_ACCENT)
	# swirl
	draw_set_transform(c, 0.0, Vector2(0.75, 1.15))
	draw_circle(Vector2.ZERO, 26.0, Color("1a0b2a"))
	for i in 4:
		var r := 24.0 - i * 5.5
		var start := _t * (2.5 + i) + i
		draw_arc(Vector2.ZERO, r, start, start + PI * 1.3, 24,
			Config.COLOR_PURPLE.lerp(Config.COLOR_ACCENT, i / 4.0), 3.0)
	draw_circle(Vector2.ZERO, 4.0 + sin(_t * 4.0), Config.COLOR_BONE)
	draw_set_transform(Vector2.ZERO)
