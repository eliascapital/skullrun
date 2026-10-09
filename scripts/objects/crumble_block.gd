extends StaticBody2D
## A cracked block that falls apart shortly after you step on it,
## then grows back a few seconds later.

const SHAKE_TIME := 0.45
const RESPAWN_TIME := 2.6

var color := Color("4a4163")
var _state := "solid"  # solid, shaking, gone
var _timer := 0.0
var _shape: CollisionShape2D
var _inside: Area2D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(32, 32)
	_shape.shape = rect
	_shape.position = Vector2(16, 16)
	add_child(_shape)

	var sensor := Area2D.new()
	sensor.collision_layer = 0
	sensor.collision_mask = 2
	sensor.monitorable = false
	var ss := CollisionShape2D.new()
	var sr := RectangleShape2D.new()
	sr.size = Vector2(30, 8)
	ss.shape = sr
	ss.position = Vector2(16, -3)
	sensor.add_child(ss)
	sensor.body_entered.connect(_on_stepped)
	add_child(sensor)

	_inside = Area2D.new()
	_inside.collision_layer = 0
	_inside.collision_mask = 2
	_inside.monitorable = false
	var is_ := CollisionShape2D.new()
	var ir := RectangleShape2D.new()
	ir.size = Vector2(32, 32)
	is_.shape = ir
	is_.position = Vector2(16, 16)
	_inside.add_child(is_)
	add_child(_inside)


func _on_stepped(body: Node2D) -> void:
	if _state == "solid" and body.is_in_group("player"):
		_state = "shaking"
		_timer = SHAKE_TIME
		Sfx.play("crumble", 1.4)


func _physics_process(delta: float) -> void:
	if _state == "solid":
		return
	_timer -= delta
	if _timer <= 0.0:
		if _state == "shaking":
			_state = "gone"
			_timer = RESPAWN_TIME
			_shape.set_deferred("disabled", true)
			Sfx.play("crumble")
		elif _state == "gone":
			if _inside.has_overlapping_bodies():
				_timer = 0.2
			else:
				_state = "solid"
				_shape.set_deferred("disabled", false)
	queue_redraw()


func _draw() -> void:
	if _state == "gone":
		var a := clampf(1.0 - _timer / RESPAWN_TIME, 0.0, 1.0)
		draw_rect(Rect2(2, 2, 28, 28), Color(color, 0.12 * a), false, 1.0)
		return
	var off := Vector2.ZERO
	if _state == "shaking":
		off = Vector2(randf_range(-2, 2), randf_range(-1, 1))
	draw_rect(Rect2(off, Vector2(32, 32)), color.darkened(0.3))
	draw_rect(Rect2(off + Vector2(2, 2), Vector2(28, 26)), color)
	var crack := color.darkened(0.6)
	draw_polyline(PackedVector2Array([off + Vector2(6, 2), off + Vector2(12, 12), off + Vector2(9, 20), off + Vector2(16, 30)]), crack, 2.0)
	draw_polyline(PackedVector2Array([off + Vector2(26, 4), off + Vector2(20, 14), off + Vector2(25, 24)]), crack, 2.0)
