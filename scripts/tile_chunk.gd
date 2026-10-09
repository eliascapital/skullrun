extends Node2D
## Draws the solid ground tiles for a slice of the level. The level is
## split into slices so Godot only draws what's on screen.

const T := 32

var grid: Array = []  # rows of characters
var x_from := 0
var x_to := 0
var colors := {}


func _is_solid(x: int, y: int) -> bool:
	if y < 0:
		return false
	if y >= grid.size():
		return true
	var row: String = grid[y]
	if x < 0 or x >= row.length():
		return true
	return row[x] == "#" or row[x] == "I"


func _hash(x: int, y: int) -> int:
	return absi((x * 73856093) ^ (y * 19349663)) % 1000


func _draw() -> void:
	var tile: Color = colors["tile"]
	var dark: Color = colors["tile_dark"]
	var light: Color = colors["tile_light"]
	var top: Color = colors["tile_top"]
	var plank: Color = colors["platform"]
	for y in grid.size():
		var row: String = grid[y]
		for x in range(x_from, mini(x_to, row.length())):
			var c := row[x]
			var p := Vector2(x * T, y * T)
			if c == "#":
				_draw_block(x, y, p, tile, dark, light, top)
			elif c == "I":
				_draw_ice(x, y, p)
			elif c == "-":
				draw_rect(Rect2(p, Vector2(T, 10)), plank.darkened(0.3))
				draw_rect(Rect2(p, Vector2(T, 7)), plank)
				draw_rect(Rect2(p, Vector2(T, 2)), plank.lightened(0.25))
				if (x + y) % 2 == 0:
					draw_line(p + Vector2(8, 10), p + Vector2(4, 20), plank.darkened(0.45), 2.0)


func _draw_block(x: int, y: int, p: Vector2, tile: Color, dark: Color, light: Color, top: Color) -> void:
	var exposed_top := not _is_solid(x, y - 1)
	var deep := _is_solid(x, y - 1) and _is_solid(x, y - 2) and _is_solid(x - 1, y) and _is_solid(x + 1, y)
	var base := dark if deep else tile
	draw_rect(Rect2(p, Vector2(T, T)), dark.darkened(0.2))
	draw_rect(Rect2(p + Vector2(1, 1), Vector2(T - 2, T - 2)), base)
	# brick seams
	var seam := dark.darkened(0.25)
	draw_line(p + Vector2(0, 16), p + Vector2(T, 16), seam, 2.0)
	var off := 10 if y % 2 == 0 else 22
	draw_line(p + Vector2(off, 0), p + Vector2(off, 16), seam, 2.0)
	draw_line(p + Vector2((off + 16) % T, 16), p + Vector2((off + 16) % T, T), seam, 2.0)
	# speckles
	var h := _hash(x, y)
	if h % 3 == 0:
		draw_rect(Rect2(p + Vector2(4 + h % 20, 4 + (h / 7) % 8), Vector2(3, 2)), light)
	if not deep and h % 5 == 0:
		draw_rect(Rect2(p + Vector2(6 + (h / 3) % 18, 20 + h % 6), Vector2(4, 2)), light)
	# edges
	if not _is_solid(x - 1, y):
		draw_rect(Rect2(p, Vector2(3, T)), light)
	if not _is_solid(x + 1, y):
		draw_rect(Rect2(p + Vector2(T - 3, 0), Vector2(3, T)), dark.darkened(0.3))
	if not _is_solid(x, y + 1):
		draw_rect(Rect2(p + Vector2(0, T - 3), Vector2(T, 3)), dark.darkened(0.3))
	# moss / bone crust on top with little drips
	if exposed_top:
		draw_rect(Rect2(p, Vector2(T, 6)), top)
		draw_rect(Rect2(p, Vector2(T, 2)), top.lightened(0.3))
		var d := _hash(x + 11, y)
		draw_rect(Rect2(p + Vector2(4 + d % 10, 6), Vector2(3, 3 + d % 5)), top)
		if d % 2 == 0:
			draw_rect(Rect2(p + Vector2(18 + d % 9, 6), Vector2(3, 2 + d % 4)), top)


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
