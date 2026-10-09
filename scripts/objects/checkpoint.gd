extends Area2D
## A soul lantern. Touch it and you'll come back here when you die.

signal activated(checkpoint: Node2D)

var lit := false
var _t := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(30, 64)
	shape.shape = rect
	shape.position = Vector2(0, -16)
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if lit or not body.is_in_group("player") or body.dead:
		return
	lit = true
	Sfx.play("checkpoint")
	activated.emit(self)


func _draw() -> void:
	var wood := Color("3a2c22")
	draw_rect(Rect2(-2, -30, 4, 46), wood)  # pole
	draw_rect(Rect2(-12, 14, 24, 4), wood)  # foot
	draw_rect(Rect2(-2, -34, 14, 3), wood)  # arm
	var lp := Vector2(10, -20)
	var frame := Color("1a1420")
	draw_rect(Rect2(lp.x - 7, lp.y - 9, 14, 18), frame)
	if lit:
		var flick := 0.8 + 0.2 * sin(_t * 13.0) * cos(_t * 7.0)
		draw_circle(lp, 26.0 * flick, Color(Config.COLOR_GEM, 0.12))
		draw_circle(lp, 14.0 * flick, Color(Config.COLOR_GEM, 0.2))
		draw_rect(Rect2(lp.x - 5, lp.y - 7, 10, 14), Config.COLOR_GEM.lightened(0.3))
		draw_circle(lp + Vector2(0, 1), 3.5 * flick, Color.WHITE)
	else:
		draw_rect(Rect2(lp.x - 5, lp.y - 7, 10, 14), Color("2e2a38"))
	draw_rect(Rect2(lp.x - 8, lp.y - 11, 16, 3), frame)
	draw_line(Vector2(lp.x, -33), Vector2(lp.x, lp.y - 11), frame, 2.0)
