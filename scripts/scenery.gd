extends Node2D
## One parallax layer of background silhouettes. The picture is
## SEGMENT pixels wide and repeats forever.

const SEGMENT := 1024.0

var kind := "graves"
var color := Color.BLACK
var depth := 0.0  # 0 = far, 1 = near
var seed_value := 1


func _draw() -> void:
	var h := get_viewport_rect().size.y
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var ground := h - 40.0 + depth * 30.0
	# rolling base
	var pts := PackedVector2Array()
	for i in 17:
		var x := SEGMENT * i / 16.0
		pts.append(Vector2(x, ground - 30.0 - sin(i * 0.9 + seed_value) * 18.0 - depth * 10.0))
	pts.append(Vector2(SEGMENT, h + 400))
	pts.append(Vector2(0, h + 400))
	draw_colored_polygon(pts, color)
	match kind:
		"graves":
			for i in 14:
				var x := rng.randf_range(0, SEGMENT - 40)
				var gh := rng.randf_range(28, 60) * (0.7 + depth * 0.6)
				if rng.randf() < 0.35:
					draw_rect(Rect2(x + 8, ground - gh - 50, 6, gh + 20), color)
					draw_rect(Rect2(x - 2, ground - gh - 32, 26, 6), color)
				else:
					draw_rect(Rect2(x, ground - gh - 20, 24, gh), color)
					draw_circle(Vector2(x + 12, ground - gh - 20), 12, color)
			for i in 2:
				_tree(rng.randf_range(0, SEGMENT), ground - 20, rng)
		"arches":
			for i in 6:
				var x := i * SEGMENT / 6.0 + rng.randf_range(0, 40)
				var ah := rng.randf_range(140, 220) * (0.7 + depth * 0.5)
				draw_rect(Rect2(x, ground - ah, 22, ah + 10), color)
				draw_rect(Rect2(x + 110, ground - ah, 22, ah + 10), color)
				draw_arc(Vector2(x + 66, ground - ah), 66, PI, TAU, 16, color, 22)
		"stalactites":
			for i in 22:
				var x := rng.randf_range(0, SEGMENT)
				var slen := rng.randf_range(40, 160) * (0.6 + depth * 0.6)
				var w := rng.randf_range(14, 34)
				draw_colored_polygon(PackedVector2Array([Vector2(x - w, -200), Vector2(x + w, -200), Vector2(x + w * 0.6, slen * 0.2), Vector2(x, slen)]), color)
				var sx := rng.randf_range(0, SEGMENT)
				var sl := rng.randf_range(30, 110) * (0.6 + depth * 0.6)
				draw_colored_polygon(PackedVector2Array([Vector2(sx - w, ground), Vector2(sx, ground - sl), Vector2(sx + w, ground)]), color)
			draw_rect(Rect2(0, -400, SEGMENT, 400), color)
		"chimneys":
			for i in 7:
				var x := rng.randf_range(0, SEGMENT - 60)
				var ch := rng.randf_range(120, 260) * (0.6 + depth * 0.5)
				var cw := rng.randf_range(26, 48)
				draw_rect(Rect2(x, ground - ch, cw, ch + 20), color)
				draw_rect(Rect2(x - 4, ground - ch, cw + 8, 10), color)
				draw_circle(Vector2(x + cw * 0.5, ground - ch - 12), 22, Color(1.0, 0.35, 0.1, 0.06))
			for i in 4:
				var x := rng.randf_range(0, SEGMENT - 160)
				draw_rect(Rect2(x, ground - 70, 160, 80), color)
		"icepeaks":
			for i in 6:
				var x := rng.randf_range(-100, SEGMENT)
				var ph := rng.randf_range(160, 300) * (0.6 + depth * 0.5)
				var pw := rng.randf_range(120, 220)
				var tip := Vector2(x + pw * 0.5, ground - ph)
				draw_colored_polygon(PackedVector2Array([Vector2(x, ground + 20), tip, Vector2(x + pw, ground + 20)]), color)
				var snow := Color(color.lightened(0.35), 0.8)
				draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(pw * 0.14, ph * 0.22),
					tip + Vector2(0, ph * 0.16), tip + Vector2(-pw * 0.14, ph * 0.22)]), snow)
		"skulls":
			for i in 10:
				var x := rng.randf_range(0, SEGMENT - 120)
				var mh := rng.randf_range(50, 110) * (0.6 + depth * 0.6)
				draw_circle(Vector2(x + 60, ground - 10), mh, color)
				for k in 4:
					var sp := Vector2(x + 60 + rng.randf_range(-mh * 0.6, mh * 0.6), ground - 10 - rng.randf_range(0, mh * 0.8))
					var r := rng.randf_range(6, 11) * (0.7 + depth * 0.5)
					draw_circle(sp, r, color.lightened(0.12))
					draw_circle(sp + Vector2(-r * 0.35, r * 0.1), r * 0.25, color.darkened(0.3))
					draw_circle(sp + Vector2(r * 0.35, r * 0.1), r * 0.25, color.darkened(0.3))
		"pillars":
			for i in 7:
				var x := i * SEGMENT / 7.0 + rng.randf_range(0, 30)
				var ph := rng.randf_range(220, 340) * (0.7 + depth * 0.4)
				draw_rect(Rect2(x, ground - ph, 34, ph + 20), color)
				draw_rect(Rect2(x - 8, ground - ph - 10, 50, 12), color)
				draw_rect(Rect2(x + 6, ground - ph + 24, 22, 60), Color(Config.COLOR_ACCENT, 0.18))
				draw_colored_polygon(PackedVector2Array([Vector2(x + 6, ground - ph + 84),
					Vector2(x + 17, ground - ph + 70), Vector2(x + 28, ground - ph + 84)]), Color(Config.COLOR_ACCENT, 0.18))
		"spires":
			for i in 8:
				var x := rng.randf_range(0, SEGMENT - 60)
				var sh := rng.randf_range(150, 320) * (0.6 + depth * 0.5)
				var sw := rng.randf_range(30, 60)
				draw_rect(Rect2(x, ground - sh, sw, sh + 20), color)
				draw_colored_polygon(PackedVector2Array([Vector2(x - 6, ground - sh), Vector2(x + sw * 0.5, ground - sh - sw * 1.6), Vector2(x + sw + 6, ground - sh)]), color)
				draw_rect(Rect2(x + sw * 0.5 - 4, ground - sh + 30, 8, 14), Color(Config.COLOR_ACCENT, 0.25))


func _tree(x: float, base: float, rng: RandomNumberGenerator) -> void:
	var th := 120.0 * (0.7 + depth * 0.5)
	draw_line(Vector2(x, base), Vector2(x + 6, base - th), color, 9.0)
	for i in 5:
		var y := base - th * rng.randf_range(0.4, 1.0)
		var dir := -1.0 if i % 2 == 0 else 1.0
		draw_line(Vector2(x + 4, y), Vector2(x + 4 + dir * rng.randf_range(25, 55), y - rng.randf_range(15, 40)), color, 4.0)
