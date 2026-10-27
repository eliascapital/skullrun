extends Area2D
## Hidden magma: a row of blocks that look just like normal ground (the tile
## slice draws them as plain blocks) until the skull comes close. Then they
## start to glow and crack open. Touching magma kills you straight away.

const T := 32.0
## Hidden when the skull is farther away than this (pixels from the block's edge) ...
const HIDE_DIST := 6.0 * 32.0
## ... and fully glowing when it's this close.
const SHOW_DIST := 3.0 * 32.0

var width_tiles := 1
## Set by the level.
var player: Node2D

var _t := 0.0
var _reveal: Array[float] = []  # 0 = hidden … 1 = glowing, one per block


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var w := width_tiles * T
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	# a hair bigger than the blocks, so standing on them or touching a side counts
	rect.size = Vector2(w + 2.0, T + 2.0)
	shape.shape = rect
	shape.position = Vector2(w * 0.5, T * 0.5)
	add_child(shape)
	_reveal.resize(width_tiles)
	_reveal.fill(0.0)


func _physics_process(delta: float) -> void:
	_t += delta
	# each block glows on its own, so a long strip only shows the part near you
	var any := false
	for i in width_tiles:
		var target := 0.0
		if player:
			var box := Rect2(global_position + Vector2(i * T, 0), Vector2(T, T))
			var p := player.global_position
			var nearest := Vector2(clampf(p.x, box.position.x, box.end.x), clampf(p.y, box.position.y, box.end.y))
			var d := p.distance_to(nearest)
			target = clampf((HIDE_DIST - d) / (HIDE_DIST - SHOW_DIST), 0.0, 1.0)
		# fade in quickly, fade out slowly
		var r: float = _reveal[i]
		if r > 0.0 or target > 0.0:
			any = true
		_reveal[i] = move_toward(r, target, delta * (4.0 if target > r else 1.0))
	if any:
		queue_redraw()
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			body.die()


func _hash(i: int) -> int:
	return absi(int(position.x / T + i) * 73856093 ^ int(position.y / T) * 19349663) % 1000


func _draw() -> void:
	var hot := Color("ff5a1f")
	var glow := Color("ffb23e")
	for i in _reveal.size():
		var r: float = _reveal[i]
		if r <= 0.0:
			continue
		var a := r * r * (3.0 - 2.0 * r)  # smooth fade
		var p := Vector2(i * T, 0)
		var h := _hash(i)
		var pulse := 0.5 + 0.5 * sin(_t * 3.0 + i * 1.7)
		# heat shimmer around it
		draw_rect(Rect2(p + Vector2(-2, -10), Vector2(T + 4, 10)), Color(hot, 0.12 * a))
		draw_rect(Rect2(p + Vector2(-3, -3), Vector2(T + 6, T + 6)), Color(glow, 0.08 * a))
		# the stone turns dark red and glows through
		draw_rect(Rect2(p, Vector2(T, T)), Color(Color("3a0c06"), a * 0.85))
		draw_rect(Rect2(p + Vector2(3, 3), Vector2(T - 6, T - 6)), Color(hot.darkened(0.3 - pulse * 0.2), a * 0.9))
		# glowing cracks
		var c := Color(glow.lerp(Color("fff1b0"), pulse * 0.5), a)
		var x0 := 6.0 + h % 12
		draw_polyline(PackedVector2Array([p + Vector2(x0, 2), p + Vector2(x0 + 6, 12),
			p + Vector2(x0 + 2, 20), p + Vector2(x0 + 9, 30)]), c, 2.0)
		draw_polyline(PackedVector2Array([p + Vector2(2, 14 + h % 8), p + Vector2(12, 17),
			p + Vector2(x0 + 6, 12)]), c, 2.0)
		# bubbles
		var k := fmod(_t * 0.8 + (h % 10) * 0.1, 1.0)
		draw_circle(p + Vector2(8 + h % 16, 26 - k * 20.0), 2.5 * (1.0 - k), Color(Color("fff1b0"), a * (1.0 - k)))
