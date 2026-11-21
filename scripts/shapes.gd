extends RefCounted
## Cheap filled circles for things that redraw every frame. In Godot 4.3
## draw_circle() always uses a lot of points, even for a tiny dot; these use
## just enough for their size, which adds up when a boss fight has a dozen
## things moving on screen.

static var _unit := {}  # number of points -> points on a circle of radius 1


static func disc(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	if r < 0.5 or col.a <= 0.0:
		return
	var n := clampi(int(r * 0.6) + 6, 6, 18)
	if not _unit.has(n):
		var u := PackedVector2Array()
		for i in n:
			u.append(Vector2(cos(TAU * i / n), sin(TAU * i / n)))
		_unit[n] = u
	var unit: PackedVector2Array = _unit[n]
	var pts := PackedVector2Array()
	pts.resize(n)
	for i in n:
		pts[i] = c + unit[i] * r
	ci.draw_colored_polygon(pts, col)
