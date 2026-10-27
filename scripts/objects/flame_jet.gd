extends Area2D
## A flame jet: a grate in the floor (or ceiling) that blasts a tall column of
## fire every few seconds, up to a ceiling (or down to the floor). It's taller
## than a double jump, so you can't hop over it: wait for it to stop, then run.
## The grate glows just before it fires. Every jet in a level fires at the
## same time, so you can learn the rhythm.

const PERIOD := 3.0
const WARN_AT := 1.6  # the grate starts glowing
const FIRE_AT := 2.0  # flames on until the end of the cycle
## Tallest a jet can be (a double jump reaches about 7.5 tiles).
const MAX_TILES := 9

var width_tiles := 1
## Set by the level: how many tiles the fire reaches before it hits something solid.
var length_tiles := MAX_TILES
## 1 = flames shoot up from the floor, -1 = down from a ceiling.
var dir := 1.0
var color := Color("ff7b2e")
## Set by the level, so only jets near the player make a sound.
var player: Node2D

var _clock := 0.0
var _shape: CollisionShape2D
var _was_on := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var w := width_tiles * 32.0
	var length := _length()
	_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	# a little short of the flame tips, so a near miss isn't a hit
	rect.size = Vector2(w - 8.0, length - 16.0)
	_shape.shape = rect
	# position is the top-left of the tile the jet sits in
	var base_y := 32.0 if dir > 0.0 else 0.0
	_shape.position = Vector2(w * 0.5, base_y - dir * (length * 0.5 - 4.0))
	add_child(_shape)


func _length() -> float:
	return length_tiles * 32.0


func is_on() -> bool:
	return _clock >= FIRE_AT


func _physics_process(delta: float) -> void:
	_clock = fmod(_clock + delta, PERIOD)
	queue_redraw()
	var on := is_on()
	if on and not _was_on and player and player.global_position.distance_to(global_position) < 360.0:
		Sfx.play("flame")
	_was_on = on
	if on:
		for body in get_overlapping_bodies():
			if body.is_in_group("player"):
				body.hurt()


func _draw() -> void:
	var w := width_tiles * 32.0
	var base_y := 32.0 if dir > 0.0 else 0.0
	# the grate
	var grate := Rect2(2, base_y - 6 if dir > 0.0 else 0, w - 4, 6)
	draw_rect(grate, Color("2a2430"))
	var glow := 0.0
	if _clock >= WARN_AT:
		glow = 1.0 if is_on() else 0.5 + 0.5 * sin(_clock * 40.0)
	for i in width_tiles * 3:
		var x := 6.0 + i * (w - 12.0) / maxf(1.0, width_tiles * 3 - 1)
		draw_rect(Rect2(x - 1.5, grate.position.y + 1, 3, 4), Color(color, 0.25 + glow * 0.75))
	if glow > 0.0 and not is_on():
		draw_rect(Rect2(0, base_y - dir * 14.0 - 7.0, w, 14), Color(color, 0.12 * glow))
	if not is_on():
		return
	# the fire: flickering tongues, hot core
	var k := clampf((_clock - FIRE_AT) / 0.12, 0.15, 1.0)
	var length := _length() * k
	var t := _clock * 30.0
	for layer in 3:
		var shrink := layer * 5.0
		var col: Color = [Color(color, 0.55), color.lightened(0.25), Color("fff3c8")][layer]
		var pts := PackedVector2Array()
		var steps := width_tiles * 4
		for i in steps + 1:
			var x := shrink + i * (w - shrink * 2.0) / steps
			var tip := length * (0.92 + 0.08 * sin(t + i * 2.1 + layer)) * (1.0 - layer * 0.18)
			pts.append(Vector2(x, base_y - dir * (tip if i % 2 == 1 else tip - minf(18.0, tip * 0.2))))
		pts.append(Vector2(w - shrink, base_y))
		pts.append(Vector2(shrink, base_y))
		draw_colored_polygon(pts, col)
