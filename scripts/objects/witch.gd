extends Area2D
## A WITCH on a broomstick. She hovers in one spot, and when you come near she
## throws smiley-face potions at you in a high arc. They explode where they
## land, so keep moving! Stomp her (or slam close by) to send her packing.

const Potion = preload("res://scripts/objects/potion.gd")

const RANGE := Vector2(12.0 * 32.0, 8.0 * 32.0)
const COOLDOWN := 2.6
const WINDUP := 0.55
const POTION_COLORS := [Color("ff5fd2"), Color("8cff5a"), Color("ffb23e"), Color("6bd7ff")]

var player: Node2D
var is_solid: Callable

var facing := -1.0
var _cooldown := 1.0
var _windup := 0.0
var _t := 0.0
var _dead := false
var _thrown := 0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(26, 36)
	shape.shape = rect
	shape.position = Vector2(0, -4)
	add_child(shape)
	_cooldown = 0.9 + fmod(position.x * 0.013, 1.0)
	_t = fmod(position.x * 0.01, TAU)


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_t += delta
	queue_redraw()
	if player == null:
		return
	var d := player.global_position - global_position
	var near: bool = absf(d.x) < RANGE.x and absf(d.y) < RANGE.y and not player.dead
	if near and absf(d.x) > 4.0:
		facing = signf(d.x)
	if _windup > 0.0:
		_windup -= delta
		if _windup <= 0.0:
			_throw()
	else:
		_cooldown -= delta
		if near and _cooldown <= 0.0:
			_windup = WINDUP
			if _thrown % 3 == 0:
				Sfx.play("laugh", 1.7)
	for body in get_overlapping_bodies():
		if body.is_in_group("player") and not body.dead:
			if body.is_slamming() or body.is_falling_onto(global_position.y - 10.0):
				body.bounce()
				defeat()
				return
			body.hurt()


func _hand() -> Vector2:
	return position + Vector2(facing * 12.0, -30.0)


## Throws a potion in an arc that lands where the skull is standing right now.
func _throw() -> void:
	_cooldown = COOLDOWN
	var p := Potion.new()
	p.position = _hand()
	p.is_solid = is_solid
	p.color = POTION_COLORS[_thrown % POTION_COLORS.size()]
	_thrown += 1
	var target: Vector2 = player.global_position + Vector2(0, 8)
	var d := target - p.position
	var flight := clampf(absf(d.x) / 260.0, 0.7, 1.3)
	p.velocity = Vector2(d.x / flight, d.y / flight - 0.5 * Potion.GRAVITY * flight)
	get_parent().add_child(p)
	Sfx.play("dash", 1.4)


## Stomped, or flattened by a nearby ground slam.
func defeat() -> void:
	if _dead:
		return
	_dead = true
	Sfx.play("stomp", 1.2)
	Sfx.play("vanish", 1.3)
	set_deferred("monitoring", false)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.3, 0.3), 0.12)
	tw.tween_property(self, "scale", Vector2(0.2, 1.6), 0.15)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_callback(queue_free)


func slam_hit() -> void:
	defeat()


func _draw() -> void:
	var raise := 0.0
	if _windup > 0.0:
		raise = 1.0 - _windup / WINDUP
	var col: Color = POTION_COLORS[_thrown % POTION_COLORS.size()]
	draw_witch(self, facing, _t, raise, col)


## Also used for the picture on the website. `raise` (0 … 1) lifts her arm
## with a potion of colour `potion` in it, ready to throw.
static func draw_witch(ci: CanvasItem, facing: float, t: float, raise: float, potion: Color) -> void:
	var skin := Color("8fd16a")
	var skin_dark := Color("5f9a45")
	var dress := Color("5a2a7a")
	var dress_light := Color("7a3fa0")
	var hat := Color("1e1428")
	var band := Color("ff5fd2")
	var hair := Color("ff8a3d")
	var wood := Color("7a5236")
	var straw := Color("d9b45a")
	var o := Vector2(0, sin(t * 2.4) * 4.0)
	var f := facing

	# broomstick with bristles behind her
	var tail := o + Vector2(-f * 30.0, 12.0)
	var nose := o + Vector2(f * 26.0, 8.0)
	ci.draw_line(tail, nose, wood, 4.0)
	var bristles := PackedVector2Array([tail + Vector2(f * 4.0, -4.0), tail + Vector2(-f * 14.0, -9.0),
		tail + Vector2(-f * 18.0, 2.0), tail + Vector2(-f * 13.0, 11.0), tail + Vector2(f * 4.0, 5.0)])
	ci.draw_colored_polygon(bristles, straw)
	for i in 3:
		ci.draw_line(tail + Vector2(-f * 2.0, -2.0 + i * 3.0), tail + Vector2(-f * 15.0, -5.0 + i * 6.0), straw.darkened(0.3), 1.0)
	ci.draw_line(tail + Vector2(f * 3.0, -4.0), tail + Vector2(f * 3.0, 5.0), Color("a0302a"), 3.0)
	# a little green glow under the broom
	for i in 3:
		var k := fmod(t * 1.2 + i / 3.0, 1.0)
		ci.draw_circle(tail + Vector2(-f * (18.0 + k * 14.0), 4.0 + k * 6.0), 3.0 * (1.0 - k), Color(Color("8cff5a"), 0.5 * (1.0 - k)))

	# dress: sitting side-saddle on the broom
	var body := PackedVector2Array([o + Vector2(-9, -16), o + Vector2(9, -16), o + Vector2(13, 6),
		o + Vector2(15, 14), o + Vector2(5, 11), o + Vector2(-3, 15), o + Vector2(-13, 12), o + Vector2(-12, 4)])
	ci.draw_colored_polygon(body, dress)
	ci.draw_colored_polygon(PackedVector2Array([o + Vector2(-3, -15), o + Vector2(3, -15),
		o + Vector2(5, 8), o + Vector2(-5, 8)]), dress_light)
	# striped stockings and pointy boots dangling below
	for s in [-1.0, 1.0]:
		var leg := o + Vector2(s * 5.0 + f * 2.0, 13.0)
		var foot := leg + Vector2(f * 2.0, 10.0 + sin(t * 3.0 + s) * 1.5)
		ci.draw_line(leg, foot, Color("ece4d0"), 3.0)
		ci.draw_line(leg + (foot - leg) * 0.5, leg + (foot - leg) * 0.5 + Vector2(0, 2), Color("1e1428"), 3.0)
		ci.draw_colored_polygon(PackedVector2Array([foot + Vector2(-f * 3.0, -1), foot + Vector2(f * 3.0, -1),
			foot + Vector2(f * 9.0, 3.0), foot + Vector2(-f * 3.0, 3)]), hat)

	# back arm holds the broom
	ci.draw_line(o + Vector2(-f * 6.0, -10.0), o + Vector2(f * 10.0, 6.0), dress, 4.0)
	ci.draw_circle(o + Vector2(f * 11.0, 7.0), 3.0, skin)

	# head: green face, big nose, a happy grin
	var head := o + Vector2(f * 1.0, -24.0)
	ci.draw_circle(head + Vector2(-f * 7.0, 2.0), 7.0, hair)
	ci.draw_circle(head + Vector2(-f * 9.0, 9.0), 5.0, hair)
	ci.draw_circle(head, 9.0, skin)
	ci.draw_colored_polygon(PackedVector2Array([head + Vector2(f * 6.0, -2.0), head + Vector2(f * 15.0, 4.0),
		head + Vector2(f * 6.0, 4.0)]), skin_dark)
	ci.draw_circle(head + Vector2(f * 3.5, -2.0), 1.8, Color("1a1020"))
	ci.draw_circle(head + Vector2(f * 3.9, -2.4), 0.6, Color.WHITE)
	ci.draw_arc(head + Vector2(f * 2.0, 3.0), 4.0, 0.4, PI - 0.4, 6, Color("2a1030"), 1.5)
	ci.draw_circle(head + Vector2(-f * 2.0, 3.0), 1.0, skin_dark)  # a wart!

	# the pointy hat, a little bent at the tip
	var brim := head + Vector2(0, -6.0)
	ci.draw_colored_polygon(PackedVector2Array([brim + Vector2(-16, 1), brim + Vector2(16, 1),
		brim + Vector2(14, -3), brim + Vector2(-14, -3)]), hat)
	var tip := brim + Vector2(-f * 13.0, -26.0 + sin(t * 2.0) * 1.5)
	ci.draw_colored_polygon(PackedVector2Array([brim + Vector2(-f * 9.0, -2), brim + Vector2(f * 9.0, -2),
		brim + Vector2(-f * 1.0, -18.0), tip]), hat)
	ci.draw_rect(Rect2(brim + Vector2(-9, -6), Vector2(18, 4)), band)

	# throwing arm: raised over her head with a potion when she's about to throw
	var shoulder := o + Vector2(f * 6.0, -12.0)
	var rest := o + Vector2(f * 14.0, -2.0)
	var up := o + Vector2(f * 8.0, -34.0)
	var hand := rest.lerp(up, raise)
	ci.draw_line(shoulder, hand, dress, 4.0)
	ci.draw_circle(hand, 3.0, skin)
	if raise > 0.0:
		var sc := 0.8
		ci.draw_circle(hand + Vector2(0, -8), 14.0 * raise, Color(potion, 0.18))
		Potion.draw_potion(ci, hand + Vector2(0, -8), sc, potion)
