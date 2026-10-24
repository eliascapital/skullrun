extends Control
## The opening story, drawn entirely in code. It plays before level 1 the first
## time you press PLAY (and from the STORY button). SPACE / ENTER / ESC skips.
##
## Timeline (seconds):
##   0-6.5    a man walks to work on a normal morning
##   6.5-14   the sky turns red, the Reaper and his army arrive, scythe swing
##   14-16    darkness
##   16-22    a tomb: the Reaper leaves and slams the stone door shut
##   22-31    the skull's eyes light up... "I'm DEAD?!"
##   31-37    the skull pushes the door open, light floods in -> level 1

const SkullArt = preload("res://scripts/skull_art.gd")

const W := 960.0
const H := 540.0
const END_TIME := 37.0
const GROUND := 440.0  # street level
const FLOOR := 430.0  # tomb floor

const CAPTIONS := [
	[0.5, 6.2, "It was just a normal morning. A man was walking to work..."],
	[6.8, 10.0, "...when the sky turned red. The Reaper had come,\nand he brought his whole army of the dead."],
	[10.2, 13.6, "In a single day, they took over the world."],
	[14.6, 16.2, "Everything went dark."],
	[16.8, 21.0, "Deep underground, the Reaper locked away his newest prisoner..."],
]
const BUBBLES := [
	[23.4, 25.9, "Wait... I'm DEAD?!"],
	[26.1, 28.6, "Then how am I still thinking?"],
	[28.8, 31.0, "I have to get out of here!"],
	[32.4, 35.0, "Hnnnnngh!!"],
]

var t := 0.0
var _fired := {}
var _ending := false
var _shake := 0.0
var _rng := RandomNumberGenerator.new()
var _base := Transform2D.IDENTITY  # scales the 960x540 story canvas to the screen


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rng.seed = 7


func _process(delta: float) -> void:
	t += delta
	_shake = maxf(0.0, _shake - delta * 2.5)
	_cue(7.4, func(): Sfx.play("roar"))
	_cue(14.1, func(): Sfx.play("death", 0.7))
	_cue(20.6, func():
		Sfx.play("slam")
		_shake = 1.0)
	_cue(22.6, func(): Sfx.play("checkpoint", 0.6))
	for i in 6:
		_cue(32.5 + i * 0.4, func(): Sfx.play("crumble", 0.6 + i * 0.05))
	_cue(34.0, func():
		Sfx.play("slam", 0.8)
		_shake = 0.6)
	_cue(35.2, func(): Sfx.play("win"))
	if t >= END_TIME:
		_finish()
	queue_redraw()


func _cue(at: float, what: Callable) -> void:
	if t >= at and not _fired.has(at):
		_fired[at] = true
		what.call()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump") or event.is_action_pressed("pause") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_finish()
	elif event is InputEventMouseButton and event.pressed:
		_finish()


func _finish() -> void:
	if _ending:
		return
	_ending = true
	Game.finish_intro()


# ---------------------------------------------------------------------
#  Drawing
# ---------------------------------------------------------------------
func _k(a: float, b: float) -> float:
	return smoothstep(a, b, t)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color.BLACK)
	var s := minf(size.x / W, size.y / H)
	var origin := (size - Vector2(W, H) * s) * 0.5
	var jiggle := Vector2(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1)) * 10.0 * _shake
	_base = Transform2D(0.0, Vector2(s, s), 0.0, origin + jiggle * s)
	draw_set_transform_matrix(_base)

	if t < 14.3:
		_draw_street()
	elif t >= 16.3:
		_draw_tomb()
	# fade in/out between the scenes
	var black := maxf(1.0 - _k(0.0, 0.8), 0.0)
	if t >= 14.1:
		black = 1.0 - _k(16.3, 17.4)
	draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, black))
	# scythe flash
	var flash := _k(13.85, 14.1) * (1.0 - _k(14.1, 14.4))
	draw_rect(Rect2(0, 0, W, H), Color(1, 1, 1, flash))
	# final fade to white
	draw_rect(Rect2(0, 0, W, H), Color(1, 1, 1, _k(35.4, 36.8)))

	_draw_captions()
	var font := get_theme_default_font()
	draw_string(font, Vector2(W - 190, 26), "SPACE to skip", HORIZONTAL_ALIGNMENT_RIGHT, 170, 14,
		Color(Config.COLOR_MUTED, 0.8))
	draw_set_transform(Vector2.ZERO)


# ----- scene 1: the street ---------------------------------------------
func _draw_street() -> void:
	var dark := _k(6.5, 8.2)
	var sky_top := Color("7ec8f0").lerp(Color("1a0408"), dark)
	var sky_bottom := Color("ffe0b0").lerp(Color("7a1424"), dark)
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(W, 0), Vector2(W, GROUND), Vector2(0, GROUND)]),
		PackedColorArray([sky_top, sky_top, sky_bottom, sky_bottom]))
	# sun -> blood moon
	var sun := Color("fff3a0").lerp(Color("e63946"), dark)
	for i in 4:
		draw_circle(Vector2(800, 110), 70.0 - i * 10.0, Color(sun, 0.08))
	draw_circle(Vector2(800, 110), 38.0, sun)
	# far buildings, then houses
	var far := Color("9fb7c9").lerp(Color("2a0c16"), dark)
	var near := Color("d9b38c").lerp(Color("1c0a10"), dark)
	var xs := [0, 70, 150, 205, 290, 360, 450, 520, 600, 680, 760, 850, 900]
	for i in xs.size():
		var bh := 120.0 + (i * 37) % 90
		draw_rect(Rect2(xs[i], GROUND - bh - 40, 64, bh + 40), far)
	for i in 7:
		var hx := 20.0 + i * 140.0
		var hh := 90.0 + (i * 23) % 40
		draw_rect(Rect2(hx, GROUND - hh, 110, hh), near)
		draw_colored_polygon(PackedVector2Array([Vector2(hx - 8, GROUND - hh), Vector2(hx + 55, GROUND - hh - 40),
			Vector2(hx + 118, GROUND - hh)]), near.darkened(0.15))
		var lit := Color("fff1b0") if dark < 0.5 else Color("ff5a3c")
		for w in 2:
			draw_rect(Rect2(hx + 18 + w * 50, GROUND - hh + 20, 22, 22), Color(lit, 0.85 - dark * 0.4))
		draw_rect(Rect2(hx + 44, GROUND - 40, 22, 40), near.darkened(0.35))
	# pavement and road
	draw_rect(Rect2(0, GROUND, W, 22), Color("b8b2a8").lerp(Color("3a2a30"), dark))
	draw_rect(Rect2(0, GROUND + 22, W, H - GROUND), Color("4a4a52").lerp(Color("140a0e"), dark))
	for i in 10:
		draw_rect(Rect2(i * 110 + 20, GROUND + 66, 60, 6), Color(1, 1, 1, 0.5 - dark * 0.35))
	# red haze
	draw_rect(Rect2(0, 0, W, H), Color(0.5, 0, 0.05, dark * 0.18))

	# the army of the dead
	_draw_army(dark)
	# the man
	var man_x := lerpf(110.0, 470.0, clampf(t / 6.5, 0.0, 1.0))
	var walking := t < 6.5
	var scared := t > 7.0
	_draw_man(Vector2(man_x, GROUND), walking, scared)
	# the Reaper
	var rp := Vector2(720, lerpf(-260.0, 230.0, _k(7.0, 9.5)))
	rp.x = lerpf(720.0, 590.0, _k(12.6, 13.6))
	rp.y += sin(t * 2.0) * 6.0
	var swing := _k(13.0, 13.7) - _k(13.75, 14.0) * 2.0
	_draw_reaper(rp, 1.0, swing)


func _draw_man(feet: Vector2, walking: bool, scared: bool) -> void:
	var step := sin(t * 9.0) if walking else 0.0
	var shiver := sin(t * 60.0) * 1.5 if scared else 0.0
	var p := feet + Vector2(shiver, 0)
	var skin := Color("f2c9a0")
	var shirt := Color("3d6fb6")
	var pants := Color("2b2f3a")
	# legs
	draw_line(p + Vector2(-4, -34), p + Vector2(-4 + step * 9.0, 0), pants, 6.0)
	draw_line(p + Vector2(4, -34), p + Vector2(4 - step * 9.0, 0), pants, 6.0)
	# body + tie
	draw_rect(Rect2(p.x - 11, p.y - 70, 22, 38), shirt)
	draw_colored_polygon(PackedVector2Array([p + Vector2(-2, -68), p + Vector2(2, -68), p + Vector2(3, -48),
		p + Vector2(0, -44), p + Vector2(-3, -48)]), Color("c0392b"))
	# arms: briefcase in the back hand, or both hands up when scared
	if scared:
		draw_line(p + Vector2(-9, -66), p + Vector2(-20, -86), skin, 5.0)
		draw_line(p + Vector2(9, -66), p + Vector2(20, -86), skin, 5.0)
		draw_rect(Rect2(p.x - 26, p.y - 18, 20, 14), Color("6b4a2e"))  # dropped briefcase
	else:
		draw_line(p + Vector2(-9, -66), p + Vector2(-12 - step * 6.0, -40), skin, 5.0)
		draw_line(p + Vector2(9, -66), p + Vector2(13 + step * 6.0, -40), skin, 5.0)
		draw_rect(Rect2(p.x + 6 + step * 6.0, p.y - 40, 18, 14), Color("6b4a2e"))
	# head
	draw_circle(p + Vector2(0, -82), 11.0, skin)
	draw_rect(Rect2(p.x - 11, p.y - 95, 22, 7), Color("4a2f1e"))
	var look := 3.0 if not scared else 4.0
	draw_circle(p + Vector2(look, -83), 1.6, Color.BLACK)
	if scared:
		draw_circle(p + Vector2(look + 1, -76), 2.5, Color.BLACK)  # gasp
		var font := get_theme_default_font()
		draw_string(font, p + Vector2(-6, -104), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Config.COLOR_ACCENT)


func _draw_reaper(p: Vector2, scale_k: float, swing: float) -> void:
	var cloak := Color("120c18")
	var edge := Color("3a2550")
	var sc := 1.4 * scale_k
	# glow
	draw_circle(p, 120.0 * sc, Color(Config.COLOR_ACCENT, 0.06))
	# scythe (behind)
	var hand := p + Vector2(-46, 10) * sc
	var ang := -0.5 - swing * 1.4
	var top := hand + Vector2(0, -120).rotated(ang) * sc
	var bottom := hand + Vector2(0, 70).rotated(ang) * sc
	draw_line(bottom, top, Color("6b5040"), 6.0 * sc)
	# curved blade: outer edge out to the tip, inner edge back (no repeated points)
	var blade := PackedVector2Array()
	for i in 9:
		var a := float(i) / 8.0
		blade.append(top + Vector2(-a * 70.0, sin(a * PI) * 26.0 - a * 10.0).rotated(ang) * sc)
	for i in range(7, 0, -1):
		var a := float(i) / 8.0
		blade.append(top + Vector2(-a * 66.0, sin(a * PI) * 12.0 - a * 10.0 + 2.0).rotated(ang) * sc)
	draw_colored_polygon(blade, Color("d8d2c4"))
	# cloak
	var pts := PackedVector2Array([p + Vector2(-34, -40) * sc, p + Vector2(0, -78) * sc, p + Vector2(34, -40) * sc])
	for i in 9:
		var x := 52.0 - i * 13.0
		pts.append(p + Vector2(x, 110.0 + (14.0 if i % 2 == 0 else 0.0) + sin(t * 5.0 + i) * 5.0) * sc)
	draw_colored_polygon(pts, edge)
	for i in pts.size():
		pts[i] = p + (pts[i] - p) * 0.9
	draw_colored_polygon(pts, cloak)
	# hood and eyes
	draw_circle(p + Vector2(0, -40) * sc, 22.0 * sc, Color("05030a"))
	for side in [-1.0, 1.0]:
		draw_circle(p + Vector2(side * 8.0, -42) * sc, 4.0 * sc, Config.COLOR_ACCENT)
		draw_circle(p + Vector2(side * 8.0, -42) * sc, 9.0 * sc, Color(Config.COLOR_ACCENT, 0.25))
	# bony hand on the scythe
	draw_circle(hand, 7.0 * sc, Config.COLOR_BONE)


func _draw_army(dark: float) -> void:
	if t < 7.8:
		return
	# skeletons marching in from the right
	for i in 6:
		var start := 7.8 + i * 0.55
		if t < start:
			continue
		var stop := 600.0 + i * 55.0
		var x := maxf(stop, 1000.0 - (t - start) * 140.0)
		_draw_skeleton(Vector2(x, GROUND), x > stop)
	# ghosts and bats in the sky
	for i in 5:
		var start := 8.3 + i * 0.6
		if t < start:
			continue
		var k := clampf((t - start) / 2.5, 0.0, 1.0)
		var gx := lerpf(1000.0, 300.0 + i * 120.0, k) + sin(t * 1.5 + i) * 20.0
		var gy := 150.0 + (i * 53) % 140 + sin(t * 2.5 + i * 2.0) * 10.0
		if i % 2 == 0:
			_draw_ghost(Vector2(gx, gy))
		else:
			_draw_bat(Vector2(gx, gy - 40.0))
	# wraiths creeping across the houses
	for i in 3:
		var start := 9.6 + i * 0.9
		if t < start:
			continue
		var wx := lerpf(1000.0, 200.0 + i * 160.0, clampf((t - start) / 3.0, 0.0, 1.0))
		_draw_wraith(Vector2(wx, 330.0 + i * 18.0 + sin(t * 3.0 + i) * 6.0))


func _draw_skeleton(feet: Vector2, walking: bool) -> void:
	var bone := Color("e6dcc4")
	var dark := Color("120c18")
	var st := sin(t * 10.0 + feet.x) if walking else 0.0
	var p := feet + Vector2(0, -2)
	draw_line(p + Vector2(-4, -18), p + Vector2(-5 + st * 6, 0), bone, 4.0)
	draw_line(p + Vector2(4, -18), p + Vector2(5 - st * 6, 0), bone, 4.0)
	draw_line(p + Vector2(0, -36), p + Vector2(0, -18), bone, 4.0)
	for i in 3:
		draw_line(p + Vector2(-8, -33 + i * 4), p + Vector2(8, -33 + i * 4), bone, 2.5)
	draw_line(p + Vector2(-8, -34), p + Vector2(-14, -22 + st * 3), bone, 3.0)
	draw_line(p + Vector2(8, -34), p + Vector2(-4, -26), bone, 3.0)
	draw_circle(p + Vector2(-1, -46), 10.0, bone)
	draw_circle(p + Vector2(-5, -46), 2.8, dark)
	draw_circle(p + Vector2(2, -46), 2.8, dark)
	draw_circle(p + Vector2(-5, -46), 1.1, Config.COLOR_GOLD)
	draw_circle(p + Vector2(2, -46), 1.1, Config.COLOR_GOLD)


func _draw_ghost(p: Vector2) -> void:
	var body := Color(0.88, 0.92, 1.0, 0.8)
	draw_circle(p, 26.0, Color(0.7, 0.8, 1.0, 0.08))
	draw_circle(p + Vector2(0, -4), 15.0, body)
	var pts := PackedVector2Array([p + Vector2(-15, -4), p + Vector2(15, -4)])
	for i in 7:
		pts.append(p + Vector2(15.0 - i * 5.0, 15.0 + (4.0 if i % 2 == 0 else -1.0) + sin(t * 8.0 + i) * 1.5))
	draw_colored_polygon(pts, body)
	draw_circle(p + Vector2(-6, -5), 3.2, Color("1a1030"))
	draw_circle(p + Vector2(4, -5), 3.2, Color("1a1030"))
	draw_circle(p + Vector2(-1, 4), 3.0, Color("1a1030"))


func _draw_bat(p: Vector2) -> void:
	var flap := sin(t * 16.0 + p.x)
	var c := Color("4b2a63")
	for side in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([p + Vector2(side * 6, -2), p + Vector2(side * 26, -10 - flap * 10),
			p + Vector2(side * 20, 3 + flap * 2), p + Vector2(side * 9, 6)]), c)
	draw_circle(p, 10.0, c.lightened(0.1))
	draw_circle(p + Vector2(-3, -1), 2.0, Config.COLOR_ACCENT)
	draw_circle(p + Vector2(3, -1), 2.0, Config.COLOR_ACCENT)


func _draw_wraith(p: Vector2) -> void:
	var pts := PackedVector2Array([p + Vector2(-14, -8), p + Vector2(0, -24), p + Vector2(14, -8)])
	for i in 6:
		pts.append(p + Vector2(15.0 - i * 6.0, 18.0 + (5.0 if i % 2 == 0 else 0.0) + sin(t * 7.0 + i) * 2.0))
	draw_colored_polygon(pts, Color("6a4590"))
	for i in pts.size():
		pts[i] = p + (pts[i] - p) * 0.85
	draw_colored_polygon(pts, Color("1c1226"))
	draw_circle(p + Vector2(0, -8), 8.0, Color("07040a"))
	draw_circle(p + Vector2(-3, -8), 2.0, Config.COLOR_ACCENT)
	draw_circle(p + Vector2(3, -8), 2.0, Config.COLOR_ACCENT)


# ----- scene 2: the tomb -----------------------------------------------
func _draw_tomb() -> void:
	var stone := Color("2a2236")
	var stone_dark := Color("1a1424")
	draw_rect(Rect2(0, 0, W, H), stone_dark)
	# brick wall
	for row in 14:
		var off := 0.0 if row % 2 == 0 else 30.0
		for col in 18:
			var r := Rect2(col * 60.0 - off, row * 32.0, 58.0, 30.0)
			draw_rect(r, stone.darkened(0.15 + ((row * 7 + col * 3) % 5) * 0.04))
	# floor
	draw_rect(Rect2(0, FLOOR, W, H - FLOOR), Color("3a3048"))
	draw_rect(Rect2(0, FLOOR, W, 5), Color("5a4c6e"))
	# a few bones lying around
	for b in [[120.0, 0.3], [220.0, -0.4], [560.0, 0.2]]:
		var c := Vector2(b[0], FLOOR - 4)
		var d := Vector2(16, 0).rotated(b[1])
		draw_line(c - d, c + d, Color("cfc6b0"), 4.0)
		draw_circle(c - d, 4.0, Color("cfc6b0"))
		draw_circle(c + d, 4.0, Color("cfc6b0"))

	# the doorway on the right
	var door_open := 1.0 - _k(19.6, 20.6)  # the Reaper shuts it
	door_open = maxf(door_open, _k(33.9, 35.3))  # the skull pushes it open
	var nudge := 0.0
	if t > 32.4 and t < 33.9:
		nudge = 4.0 + sin(t * 40.0) * 3.0  # it budges a little while he pushes
	var light := Color("cfe6ff")
	var gap := Rect2(720, 250, 110, FLOOR - 250)
	draw_rect(gap, light.darkened(0.15))
	# light spilling in through the gap
	if door_open > 0.08:
		var beam := door_open
		draw_colored_polygon(PackedVector2Array([Vector2(720, 252), Vector2(720, FLOOR),
			Vector2(720 - 420 * beam, FLOOR + 40)]), Color(light, 0.12 * beam))
	# the Reaper walks out through the doorway (and disappears behind the wall)
	if t < 19.8:
		_draw_reaper(Vector2(lerpf(770.0, 990.0, _k(18.0, 19.8)), 300), 0.75, 0.0)
	# the stone door slides to the right, into the wall
	var slab_x := 720.0 + nudge + door_open * 120.0
	draw_rect(Rect2(slab_x, 246, 114, FLOOR - 246), Color("4a3e5c"))
	draw_rect(Rect2(slab_x + 6, 252, 102, FLOOR - 258), Color("574a6c"))
	for i in 3:
		draw_line(Vector2(slab_x + 20 + i * 30, 270), Vector2(slab_x + 34 + i * 26, FLOOR - 20), Color("3a3048"), 2.0)
	# wall to the right of the doorway hides the open door
	draw_rect(Rect2(834, 0, W - 834, FLOOR), stone)
	draw_rect(Rect2(700, 230, 154, 20), Color("3e3350"))
	draw_rect(Rect2(700, 230, 20, FLOOR - 230), Color("3e3350"))

	# darkness: lighter while the door is open
	var dark := lerpf(0.88, 0.35, door_open)
	dark = lerpf(dark, 0.0, _k(34.5, 35.6))
	draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, dark))

	_draw_hero_skull()
	_draw_bubbles()


func _draw_hero_skull() -> void:
	var awake := _k(22.0, 23.0)
	var x := 380.0
	x = lerpf(x, 692.0, _k(30.6, 32.2))  # hops over to the door
	var hop := absf(sin(t * 9.0)) * 18.0 if t > 30.6 and t < 32.2 else 0.0
	var push := 0.0
	if t > 32.3 and t < 34.2:
		push = sin(t * 30.0) * 2.0
	if t > 34.2:
		x = lerpf(692.0, 760.0, _k(34.2, 35.4))  # rolls out into the light
	var c := Vector2(x + push, FLOOR - 24.0 - hop)
	# red glow from the eyes lights up the tomb
	var glow := _k(22.0, 23.2)
	for i in 6:
		draw_circle(c, 150.0 - i * 22.0, Color(Config.COLOR_ACCENT, 0.035 * glow))
	var tilt := lerpf(-0.5, 0.0, awake)
	draw_set_transform_matrix(_base * Transform2D(tilt, c))
	var eye := Color("05030a").lerp(Config.COLOR_ACCENT.lerp(Color.WHITE, 0.2), glow)
	SkullArt.draw_skull(self, Vector2.ZERO, 22.0, Config.COLOR_BONE.darkened(0.15 * (1.0 - glow)), eye, 0.6)
	draw_set_transform_matrix(_base)
	# effort lines while pushing
	if t > 32.4 and t < 34.0:
		for i in 3:
			var a := -0.6 + i * 0.6
			var p := c + Vector2(-34, -10).rotated(a)
			draw_line(p, p + Vector2(-12, 0).rotated(a), Color(Config.COLOR_BONE, 0.8), 3.0)


func _draw_bubbles() -> void:
	var font := get_theme_default_font()
	for b in BUBBLES:
		if t < b[0] or t > b[1]:
			continue
		var text: String = b[2]
		var shown := text.substr(0, int((t - b[0]) * 30.0))
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x + 36.0
		var x := 380.0
		if t > 30.6:
			x = 600.0
		var r := Rect2(clampf(x - w * 0.5, 10.0, W - w - 10.0), 300.0, w, 50.0)
		draw_rect(r, Color(Config.COLOR_BONE, 0.95))
		draw_colored_polygon(PackedVector2Array([Vector2(x - 10, 350), Vector2(x + 10, 350), Vector2(x, 368)]),
			Color(Config.COLOR_BONE, 0.95))
		draw_string(font, r.position + Vector2(18, 33), shown, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("1a1020"))


func _draw_captions() -> void:
	var font := get_theme_default_font()
	for c in CAPTIONS:
		if t < c[0] or t > c[1]:
			continue
		var text: String = c[2]
		var shown := text.substr(0, int((t - c[0]) * 45.0))
		var a := minf(1.0, (c[1] - t) * 3.0)
		draw_rect(Rect2(0, H - 96, W, 96), Color(0, 0, 0, 0.6 * a))
		draw_multiline_string(font, Vector2(40, H - 58), shown, HORIZONTAL_ALIGNMENT_CENTER, W - 80, 22, -1,
			Color(Config.COLOR_BONE, a))
