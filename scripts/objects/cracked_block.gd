extends StaticBody2D
## A cracked stone block. Solid, but a GROUND SLAM smashes straight through it.

signal smashed

var color := Color("6a5a7a")
var _shape: CollisionShape2D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(32, 32)
	_shape.shape = rect
	_shape.position = Vector2(16, 16)
	add_child(_shape)


func smash() -> void:
	# stop being solid right away so the slam carries on through
	collision_layer = 0
	_shape.disabled = true
	smashed.emit()
	var bits := CPUParticles2D.new()
	bits.position = Vector2(16, 16)
	bits.one_shot = true
	bits.amount = 14
	bits.lifetime = 0.8
	bits.explosiveness = 1.0
	bits.spread = 180.0
	bits.initial_velocity_min = 80.0
	bits.initial_velocity_max = 240.0
	bits.gravity = Vector2(0, 900)
	bits.scale_amount_min = 3.0
	bits.scale_amount_max = 7.0
	bits.color = color.lightened(0.2)
	bits.emitting = true
	get_parent().add_child(bits)
	bits.global_position = global_position + Vector2(16, 16)
	get_tree().create_timer(1.2).timeout.connect(bits.queue_free)
	Sfx.play("crumble", 0.8)
	queue_free()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 32, 32), color.darkened(0.35))
	draw_rect(Rect2(2, 2, 28, 28), color)
	draw_rect(Rect2(2, 2, 28, 4), color.lightened(0.2))
	var crack := color.darkened(0.6)
	draw_polyline(PackedVector2Array([Vector2(16, 2), Vector2(13, 10), Vector2(18, 16), Vector2(12, 24), Vector2(15, 30)]), crack, 2.0)
	draw_polyline(PackedVector2Array([Vector2(18, 16), Vector2(26, 19), Vector2(30, 24)]), crack, 2.0)
	draw_polyline(PackedVector2Array([Vector2(13, 10), Vector2(5, 8)]), crack, 2.0)
	# down arrows hint that a slam breaks it
	draw_colored_polygon(PackedVector2Array([Vector2(22, 6), Vector2(27, 6), Vector2(24.5, 10)]), Color(Config.COLOR_BONE, 0.45))
