extends Control
## Far background: sky gradient, stars and (sometimes) a big moon.

var colors := {}
var _stars: Array = []
var _t := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in 70:
		_stars.append(Vector3(rng.randf(), rng.randf() * 0.7, rng.randf()))


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var top: Color = colors["sky_top"]
	var bottom: Color = colors["sky_bottom"]
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)]),
		PackedColorArray([top, top, bottom, bottom]))
	for s in _stars:
		var tw := 0.35 + 0.35 * sin(_t * (1.0 + s.z * 2.0) + s.z * 20.0)
		draw_circle(Vector2(s.x * size.x, s.y * size.y), 0.8 + s.z, Color(1, 1, 1, tw * 0.6))
	if colors.get("moon", false):
		var m := Vector2(size.x * 0.78, size.y * 0.2)
		for i in 5:
			draw_circle(m, 70.0 - i * 9.0, Color(Config.COLOR_BONE, 0.02 + i * 0.01))
		draw_circle(m, 34.0, Config.COLOR_BONE.lerp(top, 0.15))
		draw_circle(m + Vector2(-10, -6), 7.0, Config.COLOR_BONE.lerp(top, 0.3))
		draw_circle(m + Vector2(9, 10), 5.0, Config.COLOR_BONE.lerp(top, 0.3))
