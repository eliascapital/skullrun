extends Control
## Animated menu background: dark gradient, drifting fog and falling skulls.

const SkullArt = preload("res://scripts/skull_art.gd")

var _skulls: Array = []
var _rng := RandomNumberGenerator.new()
var _time := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rng.randomize()
	for i in 26:
		_skulls.append(_new_skull(true))


func _new_skull(anywhere: bool) -> Dictionary:
	var s := size if size.x > 0 else Vector2(960, 540)
	var depth := _rng.randf()  # 0 = far away, 1 = close
	return {
		"pos": Vector2(_rng.randf_range(0, s.x), _rng.randf_range(-s.y, s.y) if anywhere else -40.0),
		"r": lerpf(5.0, 16.0, depth),
		"speed": lerpf(18.0, 60.0, depth),
		"spin": _rng.randf_range(-0.8, 0.8),
		"wobble": _rng.randf_range(0, TAU),
		"alpha": lerpf(0.08, 0.3, depth),
	}


func _process(delta: float) -> void:
	_time += delta
	for i in _skulls.size():
		var s: Dictionary = _skulls[i]
		var p: Vector2 = s["pos"]
		p.y += s["speed"] * delta
		p.x += sin(_time * 0.8 + s["wobble"]) * 10.0 * delta
		s["pos"] = p
		if p.y > size.y + 40:
			_skulls[i] = _new_skull(false)
	queue_redraw()


func _draw() -> void:
	# vertical gradient
	var top := Config.COLOR_BG
	var bottom := Config.COLOR_BG_LIGHT
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)]),
		PackedColorArray([top, top, bottom, bottom]))
	# red glow behind the title
	var glow_c := Vector2(size.x * 0.5, size.y * 0.24)
	for i in 24:
		draw_circle(glow_c, 280.0 - i * 11.0, Color(Config.COLOR_ACCENT, 0.012))
	# falling skulls
	for s in _skulls:
		var a: float = s["alpha"]
		SkullArt.draw_skull(self, s["pos"], s["r"], Color(Config.COLOR_BONE, a),
			Color(Config.COLOR_ACCENT, a * 1.5), sin(_time * s["spin"]), Color(Config.COLOR_BG, a))
	# fog along the bottom
	for i in 5:
		var y := size.y - 30.0 - i * 18.0
		var off := sin(_time * 0.3 + i) * 40.0
		for x in range(-100, int(size.x) + 200, 160):
			draw_circle(Vector2(x + off, y), 70.0, Color(Config.COLOR_PURPLE, 0.018))
	# vignette
	var v := Color(0, 0, 0, 0.45)
	var clear := Color(0, 0, 0, 0)
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), Vector2(size.x, 60), Vector2(0, 60)]),
		PackedColorArray([v, v, clear, clear]))
	draw_polygon(PackedVector2Array([Vector2(0, size.y - 60), Vector2(size.x, size.y - 60), size, Vector2(0, size.y)]),
		PackedColorArray([clear, clear, v, v]))
