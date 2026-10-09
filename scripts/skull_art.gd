extends RefCounted
## Shared drawing code for skulls (the player, menu decorations, icons).


## Draws a skull centred on `c`. `r` is roughly the radius of the head.
## `look` (-1 … 1) shifts the eyes left/right to show where it is facing.
static func draw_skull(ci: CanvasItem, c: Vector2, r: float, bone: Color, eye: Color,
		look: float = 0.0, dark: Color = Color("0b0a10")) -> void:
	var shade := bone.darkened(0.25)
	# jaw + cheeks
	ci.draw_rect(Rect2(c.x - r * 0.62, c.y + r * 0.2, r * 1.24, r * 0.72), shade)
	ci.draw_rect(Rect2(c.x - r * 0.56, c.y + r * 0.2, r * 1.12, r * 0.66), bone)
	# cranium
	ci.draw_circle(c + Vector2(0, -r * 0.12), r * 1.02, shade)
	ci.draw_circle(c + Vector2(0, -r * 0.15), r, bone)
	ci.draw_circle(c + Vector2(-r * 0.35 + look * r * 0.1, -r * 0.55), r * 0.22, bone.lightened(0.35))
	# eye sockets
	var ex := look * r * 0.14
	for side in [-1.0, 1.0]:
		var p := c + Vector2(side * r * 0.4 + ex, r * 0.08)
		ci.draw_circle(p, r * 0.29, dark)
		ci.draw_circle(p + Vector2(look * r * 0.06, r * 0.02), r * 0.11, eye)
	# nose
	var n := c + Vector2(ex * 0.6, r * 0.42)
	ci.draw_colored_polygon(PackedVector2Array([
		n + Vector2(0, -r * 0.14), n + Vector2(r * 0.1, r * 0.08), n + Vector2(-r * 0.1, r * 0.08)]), dark)
	# teeth
	for i in 3:
		var tx := c.x + (i - 1) * r * 0.28 + ex * 0.4
		ci.draw_line(Vector2(tx, c.y + r * 0.6), Vector2(tx, c.y + r * 0.86), dark, maxf(1.0, r * 0.07))
