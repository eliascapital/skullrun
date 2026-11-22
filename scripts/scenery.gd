extends Node2D
## One parallax layer of background silhouettes. The picture is
## SEGMENT pixels wide and repeats forever.

const Shapes = preload("res://scripts/shapes.gd")

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
		"islands":
			# floating rocks, some of them upside down
			for i in 9:
				var x := rng.randf_range(0, SEGMENT - 140)
				var w := rng.randf_range(60, 150) * (0.7 + depth * 0.4)
				var y := rng.randf_range(h * 0.15, h * 0.7)
				var flip := -1.0 if rng.randf() < 0.4 else 1.0
				var ipts := PackedVector2Array([Vector2(x, y), Vector2(x + w, y)])
				var steps := 5
				for k in steps:
					var t := 1.0 - (k + 0.5) / steps
					ipts.append(Vector2(x + w * t, y + flip * rng.randf_range(15, 45) * (0.3 + 0.7 * sin(PI * t))))
				draw_colored_polygon(ipts, color)
				draw_line(Vector2(x, y), Vector2(x + w, y), Color(Color("4ff0d0"), 0.12 + depth * 0.1), 2.0)
				for k in 3:
					var rx := x + rng.randf_range(10, w - 10)
					draw_line(Vector2(rx, y), Vector2(rx + rng.randf_range(-6, 6), y + flip * rng.randf_range(25, 60)), color, 2.0)
			for i in 30:
				draw_circle(Vector2(rng.randf_range(0, SEGMENT), rng.randf_range(0, h)), rng.randf_range(1, 2.5),
					Color(Color("4ff0d0"), 0.15 + depth * 0.1))
		"bog":
			# twisted trees and crooked witch huts on stilts
			for i in 5:
				_tree(rng.randf_range(0, SEGMENT), ground - 20, rng)
			for i in 2:
				var x := rng.randf_range(0, SEGMENT - 120)
				var hw := rng.randf_range(60, 90) * (0.7 + depth * 0.4)
				var base := ground - 40.0
				for k in 3:
					draw_line(Vector2(x + 8 + k * (hw - 16) * 0.5, base), Vector2(x + 8 + k * (hw - 16) * 0.5, ground), color, 4.0)
				draw_rect(Rect2(x, base - hw * 0.7, hw, hw * 0.7), color)
				draw_colored_polygon(PackedVector2Array([Vector2(x - 10, base - hw * 0.68),
					Vector2(x + hw * 0.4, base - hw * 1.5), Vector2(x + hw + 12, base - hw * 0.62)]), color)
				draw_rect(Rect2(x + hw * 0.6, base - hw * 0.5, 12, 10), Color(Color("c46bff"), 0.22))
			for i in 24:
				draw_circle(Vector2(rng.randf_range(0, SEGMENT), rng.randf_range(h * 0.3, ground)), rng.randf_range(1, 2),
					Color(Color("c6ff6b"), 0.18 + depth * 0.12))
		"cauldrons":
			# jagged rocks with big bubbling pots on top
			for i in 6:
				var x := rng.randf_range(-60, SEGMENT)
				var rh := rng.randf_range(110, 230) * (0.6 + depth * 0.5)
				var rw := rng.randf_range(90, 170)
				draw_colored_polygon(PackedVector2Array([Vector2(x, ground + 20), Vector2(x + rw * 0.3, ground - rh),
					Vector2(x + rw * 0.55, ground - rh * 0.8), Vector2(x + rw * 0.75, ground - rh * 1.05),
					Vector2(x + rw, ground + 20)]), color)
			for i in 3:
				var x := rng.randf_range(40, SEGMENT - 80)
				var r := rng.randf_range(26, 40) * (0.7 + depth * 0.4)
				var cy := ground - r
				var brew := Color("ff4fd8")
				draw_circle(Vector2(x, cy), r, color)
				for s in [-1.0, 1.0]:
					draw_line(Vector2(x + s * r * 0.6, cy + r * 0.6), Vector2(x + s * r * 0.9, ground + 6), color, 6.0)
				draw_rect(Rect2(x - r * 0.95, cy - r * 0.86, r * 1.9, 5), Color(brew, 0.22 + depth * 0.12))
				draw_rect(Rect2(x - r * 1.1, cy - r * 0.8, r * 2.2, r * 0.3), color)
				for k in 3:
					draw_circle(Vector2(x + (k - 1) * r * 0.45, cy - r - 6.0 - k * 10.0), 2.0 + k, Color(brew, 0.1 + depth * 0.08))
		"tents":
			# striped circus tents with flags, and strings of bunting
			for i in 4:
				var x := rng.randf_range(0, SEGMENT - 200)
				var tw := rng.randf_range(150, 230) * (0.7 + depth * 0.4)
				var th := tw * 0.75
				var base := ground + 10.0
				var stripe := Color(Config.COLOR_ACCENT, 0.10 + depth * 0.08)
				draw_rect(Rect2(x, base - th * 0.55, tw, th * 0.55 + 10), color)
				draw_colored_polygon(PackedVector2Array([Vector2(x - 12, base - th * 0.55),
					Vector2(x + tw * 0.5, base - th), Vector2(x + tw + 12, base - th * 0.55)]), color)
				for k in 4:
					var sx := x + tw * (k + 0.5) / 4.0
					draw_colored_polygon(PackedVector2Array([Vector2(x + tw * 0.5, base - th),
						Vector2(sx - tw * 0.06, base - th * 0.55), Vector2(sx + tw * 0.06, base - th * 0.55)]), stripe)
				var pole := Vector2(x + tw * 0.5, base - th)
				draw_line(pole, pole + Vector2(0, -26), color, 3.0)
				draw_colored_polygon(PackedVector2Array([pole + Vector2(0, -26), pole + Vector2(18, -21),
					pole + Vector2(0, -16)]), Color(Config.COLOR_GOLD, 0.15 + depth * 0.1))
			for i in 3:
				var x0 := rng.randf_range(0, SEGMENT - 300)
				var y0 := h * rng.randf_range(0.25, 0.45)
				for k in 10:
					var x := x0 + k * 30.0
					var y := y0 + sin(k / 9.0 * PI) * 30.0
					var flag: Color = [Color("ff5fd2"), Color("ffd166"), Color("6bd7ff")][k % 3]
					draw_colored_polygon(PackedVector2Array([Vector2(x, y), Vector2(x + 14, y), Vector2(x + 7, y + 12)]),
						Color(flag, 0.10 + depth * 0.08))
		"jungle":
			# a crumbling temple with a snake carved on it, and hanging vines
			for i in 3:
				var x := rng.randf_range(0, SEGMENT - 220)
				var tw := rng.randf_range(140, 220) * (0.7 + depth * 0.4)
				var steps := 4
				for k in steps:
					var w := tw * (1.0 - k * 0.2)
					draw_rect(Rect2(x + (tw - w) * 0.5, ground - 40.0 * (k + 1) * (0.7 + depth * 0.4), w, 42), color)
				var top := Vector2(x + tw * 0.5, ground - 40.0 * steps * (0.7 + depth * 0.4))
				for k in 6:
					var a := k * 0.9
					draw_circle(top + Vector2(sin(a) * 18.0, 30 + k * 12.0) * (0.7 + depth * 0.4), 6.0,
						Color(Color("c8a040"), 0.08 + depth * 0.06))
			for i in 12:
				var x := rng.randf_range(0, SEGMENT)
				var vl := rng.randf_range(60, 220) * (0.6 + depth * 0.6)
				var wob := rng.randf_range(0, TAU)
				var vine := PackedVector2Array()
				for k in 8:
					var yy := -10.0 + vl * k / 7.0
					vine.append(Vector2(x + sin(wob + k * 0.8) * 6.0, yy))
				draw_polyline(vine, color, 3.0)
				for k in 3:
					draw_circle(vine[2 + k * 2] + Vector2(4, 0), 4.0, color)
		"olives":
			# giant olives, olive branches and jars of olives
			for i in 6:
				var x := rng.randf_range(0, SEGMENT)
				var r := rng.randf_range(40, 90) * (0.6 + depth * 0.5)
				var y := ground - r * 0.6
				draw_set_transform(Vector2(x, y), rng.randf_range(-0.5, 0.5), Vector2(1.3, 1.0))
				draw_circle(Vector2.ZERO, r, color)
				draw_circle(Vector2(r * 0.65, 0), r * 0.28, Color(Color("c8302a"), 0.10 + depth * 0.08))
				draw_set_transform(Vector2.ZERO)
			for i in 3:
				var x := rng.randf_range(0, SEGMENT - 120)
				var jh := rng.randf_range(110, 180) * (0.7 + depth * 0.4)
				draw_rect(Rect2(x, ground - jh, 90, jh + 20), color)
				draw_rect(Rect2(x + 10, ground - jh - 18, 70, 20), color)
			for i in 3:
				var bx := rng.randf_range(0, SEGMENT - 200)
				var by := h * rng.randf_range(0.15, 0.4)
				draw_line(Vector2(bx, by), Vector2(bx + 200, by + 30), color, 4.0)
				for k in 6:
					var lx := bx + 20 + k * 30
					var ly := by + 3 + k * 4.5
					var s: float = 1.0 if k % 2 == 0 else -1.0
					draw_colored_polygon(PackedVector2Array([Vector2(lx, ly), Vector2(lx + 8, ly + s * 16),
						Vector2(lx + 16, ly)]), color)
		"crystals":
			# a rocky cave roof with stalactites, and glowing crystals and mushrooms below
			_cave_roof(rng)
			for i in 7:
				var x := rng.randf_range(0, SEGMENT - 60)
				var ch := rng.randf_range(30, 80) * (0.6 + depth * 0.6)
				var glow := Color(Color("6ad8e8"), 0.10 + depth * 0.10)
				for k in 3:
					var cx := x + k * 14.0 - 14.0
					var hh := ch * (1.0 - absf(k - 1) * 0.35)
					var tilt := (k - 1) * 10.0
					draw_colored_polygon(PackedVector2Array([Vector2(cx - 7, ground + 10), Vector2(cx + tilt, ground - hh),
						Vector2(cx + 7, ground + 10)]), color)
					draw_line(Vector2(cx, ground + 4), Vector2(cx + tilt * 0.8, ground - hh * 0.8), glow, 3.0)
				Shapes.disc(self, Vector2(x, ground - ch * 0.4), ch * 0.6, Color(Color("6ad8e8"), 0.03 + depth * 0.03))
			for i in 8:
				var x := rng.randf_range(0, SEGMENT)
				var mh := rng.randf_range(10, 22) * (0.7 + depth * 0.5)
				draw_line(Vector2(x, ground + 6), Vector2(x, ground - mh), color, 3.0)
				Shapes.disc(self, Vector2(x, ground - mh), mh * 0.45, color)
				Shapes.disc(self, Vector2(x, ground - mh - 1), mh * 0.3, Color(Color("9cff8a"), 0.10 + depth * 0.10))
		"pumpkins":
			# a cave roof over a pumpkin patch, with scarecrows and hay bales
			_cave_roof(rng)
			for i in 3:
				var x := rng.randf_range(40, SEGMENT - 40)
				var sh := rng.randf_range(90, 140) * (0.7 + depth * 0.4)
				draw_line(Vector2(x, ground + 10), Vector2(x, ground - sh), color, 5.0)
				draw_line(Vector2(x - 34, ground - sh * 0.75), Vector2(x + 34, ground - sh * 0.75), color, 5.0)
				draw_colored_polygon(PackedVector2Array([Vector2(x - 14, ground - sh * 0.78), Vector2(x + 14, ground - sh * 0.78),
					Vector2(x + 12, ground - sh * 0.45), Vector2(x - 12, ground - sh * 0.45)]), color)
				Shapes.disc(self, Vector2(x, ground - sh - 2), 13.0, color)
				draw_colored_polygon(PackedVector2Array([Vector2(x - 22, ground - sh - 10), Vector2(x + 22, ground - sh - 10),
					Vector2(x + 8, ground - sh - 30), Vector2(x - 8, ground - sh - 30)]), color)
			for i in 9:
				var x := rng.randf_range(0, SEGMENT)
				var r := rng.randf_range(12, 24) * (0.7 + depth * 0.5)
				draw_set_transform(Vector2(x, ground - r * 0.7), 0.0, Vector2(1.3, 1.0))
				Shapes.disc(self, Vector2.ZERO, r, color)
				draw_set_transform(Vector2.ZERO)
				var face := Color(Color("ffb23e"), 0.10 + depth * 0.12)
				for s2 in [-1.0, 1.0]:
					draw_colored_polygon(PackedVector2Array([Vector2(x + s2 * r * 0.4, ground - r * 0.95),
						Vector2(x + s2 * r * 0.4 - 3, ground - r * 0.75), Vector2(x + s2 * r * 0.4 + 3, ground - r * 0.75)]), face)
				draw_rect(Rect2(x - r * 0.5, ground - r * 0.55, r, 3), face)
			for i in 3:
				var x := rng.randf_range(0, SEGMENT - 80)
				draw_rect(Rect2(x, ground - 34, 70, 44), color)
		"spires":
			for i in 8:
				var x := rng.randf_range(0, SEGMENT - 60)
				var sh := rng.randf_range(150, 320) * (0.6 + depth * 0.5)
				var sw := rng.randf_range(30, 60)
				draw_rect(Rect2(x, ground - sh, sw, sh + 20), color)
				draw_colored_polygon(PackedVector2Array([Vector2(x - 6, ground - sh), Vector2(x + sw * 0.5, ground - sh - sw * 1.6), Vector2(x + sw + 6, ground - sh)]), color)
				draw_rect(Rect2(x + sw * 0.5 - 4, ground - sh + 30, 8, 14), Color(Config.COLOR_ACCENT, 0.25))


## A rocky cave roof along the top with stalactites hanging from it.
func _cave_roof(rng: RandomNumberGenerator) -> void:
	draw_rect(Rect2(0, -400, SEGMENT, 430 - depth * 10.0), color)
	for i in 16:
		var x := rng.randf_range(0, SEGMENT)
		var w := rng.randf_range(10, 26)
		var slen := rng.randf_range(30, 120) * (0.6 + depth * 0.6)
		draw_colored_polygon(PackedVector2Array([Vector2(x - w, 20), Vector2(x + w, 20), Vector2(x + w * 0.3, 20 + slen * 0.4),
			Vector2(x, 20 + slen)]), color)


func _tree(x: float, base: float, rng: RandomNumberGenerator) -> void:
	var th := 120.0 * (0.7 + depth * 0.5)
	draw_line(Vector2(x, base), Vector2(x + 6, base - th), color, 9.0)
	for i in 5:
		var y := base - th * rng.randf_range(0.4, 1.0)
		var dir := -1.0 if i % 2 == 0 else 1.0
		draw_line(Vector2(x + 4, y), Vector2(x + 4 + dir * rng.randf_range(25, 55), y - rng.randf_range(15, 40)), color, 4.0)
