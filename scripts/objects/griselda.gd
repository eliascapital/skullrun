extends Node2D
## GRISELDA, the scruffy witch who's been putting up all the hint signs
## (`&` in a level, standing just right of a sign). The skull catches her
## hammering in a sign. She jumps, tells her story, then flies off on her
## broom. She can't go any deeper into the Reaper's lands, so after level 33
## there are no more signs.
## The skull stands still while she talks; JUMP skips to her next line.

const TRIGGER := 6.0 * 32.0
const SCALE := 1.3
const LINE_TIME := 3.6
const LINES := [
	"Eek! You caught me!",
	"I'm Griselda. I'm the one who's been\nputting up all those signs for you.",
	"I wanted to help you get away\nfrom the Reaper.",
	"But past here are the Reaper's darkest lands.\nIf I go any further, he'll catch me!",
	"So this is my very last sign.\nFrom now on, you're on your own.",
	"Be brave, little skull. Goodbye!",
]

enum State { HAMMER, STARTLED, TALK, LEAVE, GONE }

## Set by the level.
var player: Node2D
var level: Node2D

var state := State.HAMMER
var facing := -1.0
var _state_time := 0.0
var _t := 0.0
var _line := 0
var _knocks := 0
var _bubble: PanelContainer
var _label: Label


func _ready() -> void:
	z_index = 4
	_build_bubble()


func _set_state(s: State) -> void:
	state = s
	_state_time = 0.0


func _physics_process(delta: float) -> void:
	_t += delta
	_state_time += delta
	queue_redraw()
	if player == null:
		return
	match state:
		State.HAMMER:
			# tap, tap, tap... (you can hear it as you come closer)
			var knocks := int(_t * 2.5)
			if knocks != _knocks:
				_knocks = knocks
				if absf(player.global_position.x - global_position.x) < 14 * 32:
					Sfx.play("click", 0.5)
			var d: Vector2 = player.global_position - global_position
			if not player.dead and absf(d.x) < TRIGGER and absf(d.y) < 3 * 32:
				_set_state(State.STARTLED)
				facing = signf(d.x + 0.01)
				player.frozen = true
				level.cutscene = true
				Sfx.play("jump", 1.6)
				_say(0)
		State.STARTLED:
			if _state_time > 1.4:
				_set_state(State.TALK)
				_say(1)
		State.TALK:
			if _state_time > LINE_TIME or (_state_time > 0.4 and Input.is_action_just_pressed("jump")):
				if _line + 1 < LINES.size():
					_say(_line + 1)
					_state_time = 0.0
				else:
					_bubble.visible = false
					_set_state(State.LEAVE)
					Sfx.play("vanish", 1.3)
					player.frozen = false
					level.cutscene = false
		State.LEAVE:
			# up on her broom and away
			var k := _state_time
			position += Vector2(facing * -140.0 * k, -220.0 * k) * delta
			modulate.a = 1.0 - clampf((_state_time - 1.2) / 0.8, 0.0, 1.0)
			if _state_time > 2.0:
				_set_state(State.GONE)
				hide()


func _say(i: int) -> void:
	_line = i
	_label.text = LINES[i]
	_bubble.visible = true
	_bubble.reset_size()
	var s := _bubble.get_combined_minimum_size()
	_bubble.size = s
	_bubble.position = Vector2(-s.x * 0.5, -96.0 - s.y)
	if i > 0:
		Sfx.play("click", 1.4)


func _build_bubble() -> void:
	_bubble = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.05, 0.03, 0.94)
	sb.border_color = Color("8cff5a")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(12)
	_bubble.add_theme_stylebox_override("panel", sb)
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 16)
	_label.add_theme_color_override("font_color", Config.COLOR_BONE)
	_bubble.add_child(_label)
	_bubble.z_index = 50
	_bubble.visible = false
	add_child(_bubble)


func _draw() -> void:
	if state == State.GONE:
		return
	var hammer := 0.0
	var hop := 0.0
	if state == State.HAMMER:
		hammer = absf(sin(_t * PI * 2.5))
	elif state == State.STARTLED:
		hop = maxf(0.0, sin(clampf(_state_time / 0.45, 0.0, 1.0) * PI)) * 18.0
	var flying := state == State.LEAVE
	var talking := state in [State.STARTLED, State.TALK]
	# a bit bigger than her drawing, feet still on the ground
	draw_set_transform(Vector2(0, -hop - 16.0 * (SCALE - 1.0)), 0.0, Vector2(SCALE, SCALE))
	draw_griselda(self, facing, _t, hammer, talking, flying)
	draw_set_transform(Vector2.ZERO)


## Also used for the picture on the website. Her feet are at y = 16 (the
## bottom of her map cell). `hammer` 0 … 1 swings the hammer down.
static func draw_griselda(ci: CanvasItem, facing: float, t: float, hammer: float, talking: bool,
		flying: bool) -> void:
	var f := facing
	var skin := Color("a8b88a")  # pale and a bit grubby
	var skin_dark := Color("7a8a62")
	var dress := Color("5a5048")
	var patch := Color("8a6a4a")
	var mud := Color("4a3a28")
	var hat := Color("3a342e")
	var hair := Color("b8b4a8")
	var dark := Color("1a1610")
	var wood := Color("7a5236")
	var straw := Color("c9a85a")

	# her rickety broom: leaning by her feet, or under her when she flies
	if flying:
		ci.draw_line(Vector2(-f * 26, 10), Vector2(f * 24, 6), wood, 3.0)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(-f * 24, 6), Vector2(-f * 40, 2),
			Vector2(-f * 42, 14), Vector2(-f * 24, 14)]), straw)
	else:
		ci.draw_line(Vector2(-f * 16, 16), Vector2(-f * 4, -30), wood, 3.0)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(-f * 13, 6), Vector2(-f * 22, 16),
			Vector2(-f * 8, 16)]), straw)

	# skinny legs with saggy socks and big old boots
	if not flying:
		for s in [-1.0, 1.0]:
			var leg := Vector2(s * 3.0, 2)
			ci.draw_line(leg, leg + Vector2(0, 11), skin_dark, 2.0)
			ci.draw_line(leg + Vector2(0, 7), leg + Vector2(0, 11), Color("9a9080"), 3.0)
			ci.draw_rect(Rect2(leg.x - 3 + f * 2.0, 12, 8, 4), dark)

	# a long, thin, ragged dress with patches and mud stains
	var dy := -4.0 if flying else 0.0
	var body := PackedVector2Array([Vector2(-5, -24 + dy), Vector2(5, -24 + dy), Vector2(8, 4 + dy),
		Vector2(6, 2 + dy), Vector2(4, 6 + dy), Vector2(1, 3 + dy), Vector2(-2, 6 + dy), Vector2(-5, 3 + dy),
		Vector2(-8, 5 + dy)])
	ci.draw_colored_polygon(body, dress)
	ci.draw_rect(Rect2(-4, -12 + dy, 5, 5), patch)
	ci.draw_line(Vector2(-4, -12 + dy), Vector2(1, -7 + dy), patch.darkened(0.4), 1.0)
	ci.draw_circle(Vector2(3, -2 + dy), 2.5, mud)
	ci.draw_circle(Vector2(-4, 1 + dy), 2.0, mud)

	# a sack of signs on her back
	ci.draw_rect(Rect2(-f * 12 - 4, -24 + dy, 8, 16), Color("8a7a5a"))
	ci.draw_rect(Rect2(-f * 12 - 6, -28 + dy, 12, 5), wood)

	# bony arms: one with a hammer
	var shoulder := Vector2(f * 4.0, -20 + dy)
	var hand := shoulder + Vector2(f * 10.0, lerpf(-10.0, 8.0, hammer))
	if talking:
		hand = shoulder + Vector2(f * 9.0, -6.0 + sin(t * 6.0) * 3.0)
	ci.draw_line(shoulder, hand, skin_dark, 2.0)
	if not flying:
		var head_dir := Vector2(f, -0.3 + hammer * 0.9).normalized()
		ci.draw_line(hand, hand + Vector2(0, -2) + head_dir.orthogonal() * -f * 8.0, wood, 2.0)
		var hh := hand + head_dir.orthogonal() * -f * 8.0
		ci.draw_rect(Rect2(hh.x - 3, hh.y - 3, 6, 6), Color("8a8a90"))
	ci.draw_line(Vector2(-f * 4.0, -20 + dy), Vector2(-f * 8.0, -6 + dy), skin_dark, 2.0)

	# head: thin face, long crooked nose, a smudge of dirt
	var head := Vector2(f * 1.0, -31 + dy)
	for k in 5:
		var hx := -f * (3.0 + k * 1.5)
		ci.draw_line(head + Vector2(hx, -4), head + Vector2(hx - f * 2.0, 8.0 + k * 1.5), hair, 2.0)
	ci.draw_circle(head, 6.5, skin)
	ci.draw_colored_polygon(PackedVector2Array([head + Vector2(f * 4.0, -2), head + Vector2(f * 13.0, 3),
		head + Vector2(f * 9.0, 4), head + Vector2(f * 4.0, 3)]), skin_dark)
	ci.draw_circle(head + Vector2(-f * 2.5, 2.5), 1.8, Color(mud, 0.8))
	var eye := head + Vector2(f * 2.5, -1.5)
	ci.draw_circle(eye, 1.8 if talking else 1.3, Color.WHITE)
	ci.draw_circle(eye + Vector2(f * 0.5, 0), 0.9, dark)
	if talking:
		ci.draw_circle(head + Vector2(f * 3.0, 4.0), 1.5 + absf(sin(t * 12.0)), dark)
	else:
		ci.draw_line(head + Vector2(f * 1.0, 4.0), head + Vector2(f * 4.0, 4.0), dark, 1.2)

	# a battered, patched hat, bent over at the top
	var brim := head + Vector2(0, -5)
	ci.draw_colored_polygon(PackedVector2Array([brim + Vector2(-12, 1), brim + Vector2(12, 1),
		brim + Vector2(10, -2), brim + Vector2(-10, -2)]), hat)
	ci.draw_colored_polygon(PackedVector2Array([brim + Vector2(-7, -1), brim + Vector2(7, -1),
		brim + Vector2(-f * 1.0, -14)]), hat)
	ci.draw_colored_polygon(PackedVector2Array([brim + Vector2(-f * 1.0 - 2.5, -12), brim + Vector2(-f * 1.0 + 2.5, -12),
		brim + Vector2(-f * 9.0, -19)]), hat)
	ci.draw_rect(Rect2(brim + Vector2(-2, -9), Vector2(4, 4)), patch)
	ci.draw_circle(brim + Vector2(f * 3.0, -5), 1.0, Color("8cff5a"))  # a hole the light peeks through

	# flies buzzing round her (she really needs a bath)
	for k in 3:
		var a := t * (5.0 + k) + k * 2.1
		var fp := head + Vector2(cos(a) * (14.0 + k * 3.0), -6.0 + sin(a * 1.3) * 8.0)
		ci.draw_circle(fp, 1.2, dark)
		ci.draw_line(fp + Vector2(-2, -1.5), fp + Vector2(2, -1.5), Color(1, 1, 1, 0.5), 1.0)
