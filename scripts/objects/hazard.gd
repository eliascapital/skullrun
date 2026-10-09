extends Area2D
## A row of spikes ("spikes") or a pool of bubbling liquid ("liquid").
## Touching it sends you back to the last checkpoint.

@export var kind := "spikes"
@export var width_tiles := 1
var color := Color.WHITE

var _t := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var w := width_tiles * 32.0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	if kind == "spikes":
		rect.size = Vector2(w - 10, 12)
		shape.position = Vector2(w * 0.5, 25)
	else:
		rect.size = Vector2(w - 4, 18)
		shape.position = Vector2(w * 0.5, 22)
	shape.shape = rect
	add_child(shape)
	body_entered.connect(_on_body_entered)
	set_process(kind != "spikes")


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.die()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var w := width_tiles * 32.0
	if kind == "spikes":
		for i in width_tiles * 2:
			var x := i * 16.0
			draw_colored_polygon(PackedVector2Array([Vector2(x + 1, 32), Vector2(x + 8, 14), Vector2(x + 15, 32)]), color.darkened(0.35))
			draw_colored_polygon(PackedVector2Array([Vector2(x + 4, 32), Vector2(x + 8, 14), Vector2(x + 12, 32)]), color)
		return
	# liquid: glow, wavy surface, bubbles
	draw_rect(Rect2(0, -6, w, 38), Color(color, 0.08))
	var pts := PackedVector2Array()
	var steps := width_tiles * 4
	for i in steps + 1:
		var x := w * i / steps
		pts.append(Vector2(x, 12.0 + sin(_t * 3.0 + x * 0.08) * 2.5))
	pts.append(Vector2(w, 32))
	pts.append(Vector2(0, 32))
	draw_colored_polygon(pts, color.darkened(0.25))
	for i in steps + 1:
		var x := w * i / steps
		if i > 0:
			draw_line(pts[i - 1], pts[i], color.lightened(0.4), 2.0)
	for i in width_tiles:
		var phase := fmod(_t * 0.7 + i * 0.37, 1.0)
		draw_circle(Vector2(i * 32 + 10 + (i * 7) % 14, 30 - phase * 18), 2.5 * (1.0 - phase), color.lightened(0.5))
