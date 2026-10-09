extends Area2D
## A glowing soul gem. Collect them all for a perfect level.

signal collected

var _t := 0.0
var _taken := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 11.0
	shape.shape = circle
	add_child(shape)
	_t = fmod(global_position.x * 0.013, TAU)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if _taken or not body.is_in_group("player") or body.dead:
		return
	_taken = true
	Sfx.play("gem", randf_range(0.95, 1.1))
	collected.emit()
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.8, 1.8), 0.15)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.15)
	tw.tween_callback(queue_free)


func _draw() -> void:
	var y := sin(_t * 3.0) * 3.0
	var c := Config.COLOR_GEM
	draw_circle(Vector2(0, y), 14.0, Color(c, 0.12))
	draw_circle(Vector2(0, y), 9.0, Color(c, 0.15))
	var w := 7.0 * (0.75 + 0.25 * cos(_t * 2.0))
	var pts := PackedVector2Array([Vector2(0, y - 10), Vector2(w, y), Vector2(0, y + 10), Vector2(-w, y)])
	draw_colored_polygon(pts, c)
	draw_colored_polygon(PackedVector2Array([Vector2(0, y - 10), Vector2(w, y), Vector2(0, y)]), c.lightened(0.5))
