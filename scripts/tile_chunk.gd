extends Node2D
## Draws the solid ground tiles for a slice of the level. The level is
## split into slices so Godot only draws what's on screen.

const T := 32

var grid: Array = []  # rows of characters
var x_from := 0
var x_to := 0
var colors := {}


func _is_solid(x: int, y: int) -> bool:
	return is_solid_cell(grid, x, y)


func _hash(x: int, y: int) -> int:
	return cell_hash(x, y)


## True for any cell that's drawn as ground (fake walls `%` look solid too).
static func is_solid_cell(g: Array, x: int, y: int) -> bool:
	if y < 0:
		return false
	if y >= g.size():
		return true
	var row: String = g[y]
	if x < 0 or x >= row.length():
		return true
	var c := row[x]
	return c == "#" or c == "I" or c == "m" or c == "%"


static func cell_hash(x: int, y: int) -> int:
	return absi((x * 73856093) ^ (y * 19349663)) % 1000


func _draw() -> void:
	var plank: Color = colors["platform"]
	for y in grid.size():
		var row: String = grid[y]
		for x in range(x_from, mini(x_to, row.length())):
			var c := row[x]
			var p := Vector2(x * T, y * T)
			if c == "#" or c == "m":  # hidden magma looks just like ground (see magma_block.gd)
				draw_block(self, grid, x, y, colors)
			elif c == "I":
				_draw_ice(x, y, p)
			elif c == "-":
				draw_rect(Rect2(p, Vector2(T, 10)), plank.darkened(0.3))
				draw_rect(Rect2(p, Vector2(T, 7)), plank)
				draw_rect(Rect2(p, Vector2(T, 2)), plank.lightened(0.25))
				if (x + y) % 2 == 0:
					draw_line(p + Vector2(8, 10), p + Vector2(4, 20), plank.darkened(0.45), 2.0)
			# fake walls `%` are drawn by fake_wall.gd, so they can fade as you walk in


## Draws one ground block at cell (x, y). Also used for fake walls, which pass
## an `alpha` below 1 when the skull is inside them.
static func draw_block(ci: CanvasItem, g: Array, x: int, y: int, colors: Dictionary, alpha: float = 1.0) -> void:
	var tile: Color = colors["tile"]
	var dark: Color = colors["tile_dark"]
	var light: Color = colors["tile_light"]
	var top: Color = colors["tile_top"]
	var p := Vector2(x * T, y * T)
	var exposed_top := not is_solid_cell(g, x, y - 1)
	if colors.get("style", "") == "olive":
		_draw_olive_block(ci, x, y, p, colors, exposed_top, alpha)
		return
	if colors.get("style", "") == "stone":
		_draw_stone_block(ci, g, x, y, p, colors, exposed_top, alpha)
		return
	var deep := is_solid_cell(g, x, y - 1) and is_solid_cell(g, x, y - 2) and is_solid_cell(g, x - 1, y) \
		and is_solid_cell(g, x + 1, y)
	var base := dark if deep else tile
	ci.draw_rect(Rect2(p, Vector2(T, T)), Color(dark.darkened(0.2), alpha))
	ci.draw_rect(Rect2(p + Vector2(1, 1), Vector2(T - 2, T - 2)), Color(base, alpha))
	# brick seams
	var seam := Color(dark.darkened(0.25), alpha)
	ci.draw_line(p + Vector2(0, 16), p + Vector2(T, 16), seam, 2.0)
	var off := 10 if y % 2 == 0 else 22
	ci.draw_line(p + Vector2(off, 0), p + Vector2(off, 16), seam, 2.0)
	ci.draw_line(p + Vector2((off + 16) % T, 16), p + Vector2((off + 16) % T, T), seam, 2.0)
	# speckles
	var h := cell_hash(x, y)
	if h % 3 == 0:
		ci.draw_rect(Rect2(p + Vector2(4 + h % 20, 4 + (h / 7) % 8), Vector2(3, 2)), Color(light, alpha))
	if not deep and h % 5 == 0:
		ci.draw_rect(Rect2(p + Vector2(6 + (h / 3) % 18, 20 + h % 6), Vector2(4, 2)), Color(light, alpha))
	# edges
	if not is_solid_cell(g, x - 1, y):
		ci.draw_rect(Rect2(p, Vector2(3, T)), Color(light, alpha))
	if not is_solid_cell(g, x + 1, y):
		ci.draw_rect(Rect2(p + Vector2(T - 3, 0), Vector2(3, T)), Color(dark.darkened(0.3), alpha))
	if not is_solid_cell(g, x, y + 1):
		ci.draw_rect(Rect2(p + Vector2(0, T - 3), Vector2(T, 3)), Color(dark.darkened(0.3), alpha))
	# moss / bone crust on top with little drips
	if exposed_top:
		ci.draw_rect(Rect2(p, Vector2(T, 6)), Color(top, alpha))
		ci.draw_rect(Rect2(p, Vector2(T, 2)), Color(top.lightened(0.3), alpha))
		var d := cell_hash(x + 11, y)
		ci.draw_rect(Rect2(p + Vector2(4 + d % 10, 6), Vector2(3, 3 + d % 5)), Color(top, alpha))
		if d % 2 == 0:
			ci.draw_rect(Rect2(p + Vector2(18 + d % 9, 6), Vector2(3, 2 + d % 4)), Color(top, alpha))


## The olive world: every block is a big green olive with a red pimento.
static func _draw_olive_block(ci: CanvasItem, x: int, y: int, p: Vector2, colors: Dictionary, exposed_top: bool,
		alpha: float) -> void:
	var dark: Color = colors["tile_dark"]
	var olive: Color = colors["tile"]
	var top: Color = colors["tile_top"]
	var h := cell_hash(x, y)
	ci.draw_rect(Rect2(p, Vector2(T, T)), Color(dark, alpha))
	var c := p + Vector2(16, 16)
	var tilt := 0.35 if (x + y) % 2 == 0 else -0.35
	var oval := PackedVector2Array()
	var inner := PackedVector2Array()
	for i in 14:
		var a := TAU * i / 14.0
		oval.append(c + Vector2(cos(a) * 15.5, sin(a) * 12.0).rotated(tilt))
		inner.append(c + Vector2(cos(a) * 13.0, sin(a) * 9.5).rotated(tilt) + Vector2(-1, -1))
	ci.draw_colored_polygon(oval, Color(olive.darkened(0.3), alpha))
	ci.draw_colored_polygon(inner, Color(olive, alpha))
	# the pimento at one end, and a shine
	var end := c + Vector2(10.0 if h % 2 == 0 else -10.0, 0).rotated(tilt)
	ci.draw_circle(end, 4.5, Color("c8302a", alpha))
	ci.draw_circle(end + Vector2(-1, -1), 2.0, Color("ff6a50", alpha))
	ci.draw_circle(c + Vector2(-5, -5).rotated(tilt), 2.5, Color(1, 1, 1, 0.35 * alpha))
	if exposed_top:
		# a shiny drizzle of olive oil on top
		ci.draw_rect(Rect2(p, Vector2(T, 4)), Color(top, alpha))
		var d := cell_hash(x + 11, y)
		ci.draw_rect(Rect2(p + Vector2(4 + d % 18, 4), Vector2(3, 2 + d % 5)), Color(top, alpha))


## Caves: rough natural rock instead of bricks. Lumpy stone with cracks and
## pebbles, moss (or crystals) along the top and little drips underneath.
static func _draw_stone_block(ci: CanvasItem, g: Array, x: int, y: int, p: Vector2, colors: Dictionary,
		exposed_top: bool, alpha: float) -> void:
	var tile: Color = colors["tile"]
	var dark: Color = colors["tile_dark"]
	var light: Color = colors["tile_light"]
	var top: Color = colors["tile_top"]
	var h := cell_hash(x, y)
	var h2 := cell_hash(x + 37, y * 3 + 5)
	var open_l := not is_solid_cell(g, x - 1, y)
	var open_r := not is_solid_cell(g, x + 1, y)
	var open_b := not is_solid_cell(g, x, y + 1)
	# how far this cell is from open air (deep rock is darker)
	var near := exposed_top or open_l or open_r or open_b or not is_solid_cell(g, x, y - 2) \
		or not is_solid_cell(g, x, y + 2) or not is_solid_cell(g, x - 2, y) or not is_solid_cell(g, x + 2, y)
	var base := tile.lerp(dark, 0.2 + (h % 3) * 0.015) if near else dark.lerp(tile, (h % 3) * 0.015)
	ci.draw_rect(Rect2(p, Vector2(T, T)), Color(base, alpha))
	# soft lumps of lighter and darker rock (kept inside the cell)
	var c1 := p + Vector2(8 + h % 16, 8 + (h / 16) % 16)
	ci.draw_circle(c1, 5.0 + h % 3, Color(base.lightened(0.06), alpha))
	var c2 := p + Vector2(8 + h2 % 16, 8 + (h2 / 16) % 16)
	ci.draw_circle(c2, 4.0 + h2 % 4, Color(base.darkened(0.12), alpha))
	# pebbles and specks
	if h % 3 == 0:
		ci.draw_circle(p + Vector2(5 + (h / 3) % 22, 6 + (h / 7) % 20), 2.0, Color(light, 0.8 * alpha))
	if h2 % 4 == 0:
		ci.draw_rect(Rect2(p + Vector2(4 + h2 % 22, 4 + (h2 / 5) % 22), Vector2(2, 2)), Color(light.lightened(0.2), alpha))
	# a crack here and there
	if h % 6 == 1:
		var a := p + Vector2(4 + h2 % 10, 3 + h % 8)
		var b := a + Vector2(6 + h % 6, 8 + h2 % 6)
		var c := b + Vector2(-3 + h2 % 8, 7 + h % 5)
		ci.draw_polyline(PackedVector2Array([a, b, c]), Color(dark.darkened(0.35), alpha), 1.5)
	# rough edges where the rock meets the air
	if open_l:
		ci.draw_rect(Rect2(p, Vector2(3, T)), Color(light, alpha))
		ci.draw_rect(Rect2(p + Vector2(0, 6 + h % 14), Vector2(5, 5)), Color(light, alpha))
	if open_r:
		ci.draw_rect(Rect2(p + Vector2(T - 3, 0), Vector2(3, T)), Color(dark.darkened(0.3), alpha))
		ci.draw_rect(Rect2(p + Vector2(T - 5, 10 + h2 % 12), Vector2(5, 4)), Color(dark.darkened(0.3), alpha))
	if open_b:
		ci.draw_rect(Rect2(p + Vector2(0, T - 3), Vector2(T, 3)), Color(dark.darkened(0.3), alpha))
		# little rock drips under a ceiling
		var dx := 3 + h % 12
		ci.draw_colored_polygon(PackedVector2Array([p + Vector2(dx, T), p + Vector2(dx + 7, T),
			p + Vector2(dx + 3, T + 4 + h2 % 5)]), Color(dark.darkened(0.2), alpha))
		if h2 % 2 == 0:
			var dx2 := 18 + h2 % 10
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(dx2, T), p + Vector2(dx2 + 5, T),
				p + Vector2(dx2 + 2, T + 3 + h % 4)]), Color(dark.darkened(0.2), alpha))
	# a bumpy top with moss (or glowing crystals) growing on it
	if exposed_top:
		ci.draw_rect(Rect2(p, Vector2(T, 4)), Color(light, alpha))
		for k in 4:
			var bx := 2.0 + k * 8.0 + (cell_hash(x + k, y) % 3)
			ci.draw_circle(p + Vector2(bx + 2.0, 3), 3.0, Color(light, alpha))
		ci.draw_rect(Rect2(p + Vector2(0, -1), Vector2(T, 3)), Color(top.darkened(0.25), alpha))
		var d := cell_hash(x + 11, y)
		for k in 3:
			var mx := 3.0 + k * 10.0 + d % 4
			ci.draw_circle(p + Vector2(mx, 0), 2.0 + (d + k) % 2, Color(top, alpha))
		if d % 5 == 0:
			# a little crystal
			var cx := 8.0 + d % 16
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(cx - 3, 0), p + Vector2(cx + 3, 0),
				p + Vector2(cx + 1, -8), p + Vector2(cx - 1, -9)]), Color(top.lightened(0.3), alpha))


func _draw_ice(x: int, y: int, p: Vector2) -> void:
	var ice := Color("8fd8f0")
	var deep := Color("4a8fb8")
	draw_rect(Rect2(p, Vector2(T, T)), deep)
	draw_rect(Rect2(p + Vector2(1, 1), Vector2(T - 2, T - 2)), ice.lerp(deep, 0.35 if _is_solid(x, y - 1) else 0.0))
	# shiny streaks
	var h := _hash(x, y)
	var sx := 4.0 + h % 14
	draw_line(p + Vector2(sx, 26), p + Vector2(sx + 9, 8), Color(1, 1, 1, 0.45), 2.0)
	draw_line(p + Vector2(sx + 7, 28), p + Vector2(sx + 12, 18), Color(1, 1, 1, 0.3), 2.0)
	if not _is_solid(x, y - 1):
		draw_rect(Rect2(p, Vector2(T, 5)), Color("eafaff"))
		draw_rect(Rect2(p + Vector2(0, 5), Vector2(T, 2)), Color(1, 1, 1, 0.5))
	if not _is_solid(x, y + 1):
		# icicles
		var i0 := p + Vector2(T, T)
		for k in 3:
			var ix := p.x + 5 + k * 10 + (h / (k + 3)) % 4
			var il := 5.0 + (h / (k + 1)) % 8
			draw_colored_polygon(PackedVector2Array([Vector2(ix - 3, i0.y), Vector2(ix + 3, i0.y), Vector2(ix, i0.y + il)]), ice)
