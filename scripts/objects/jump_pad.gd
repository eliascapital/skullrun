extends Area2D
## A springy bone pad that launches you high into the air.

const LAUNCH_VELOCITY := -1000.0  # about 8 tiles high

var _squish := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(28, 12)
	shape.shape = rect
	shape.position = Vector2(0, 10)
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not body.dead and body.velocity.y >= -10.0:
		body.launch(LAUNCH_VELOCITY)
		_squish = 1.0
		Sfx.play("bounce")


func _process(delta: float) -> void:
	if _squish > 0.0:
		_squish = maxf(0.0, _squish - delta * 4.0)
		queue_redraw()


func _draw() -> void:
	var h := 8.0 - _squish * 5.0 + (sin(_squish * 20.0) * 3.0 if _squish > 0.0 else 0.0)
	var base := Color("2a2236")
	draw_rect(Rect2(-14, 12, 28, 4), base)
	# spring
	draw_line(Vector2(-8, 12), Vector2(8, 12 - h * 0.5), Config.COLOR_BONE, 2.0)
	draw_line(Vector2(8, 12 - h * 0.5), Vector2(-8, 12 - h), Config.COLOR_BONE, 2.0)
	# pad
	draw_rect(Rect2(-14, 8 - h, 28, 5), Config.COLOR_ACCENT)
	draw_rect(Rect2(-14, 8 - h, 28, 2), Config.COLOR_ACCENT.lightened(0.35))
	draw_circle(Vector2(0, 2 - h), 10.0, Color(Config.COLOR_ACCENT, 0.1))
