extends Area2D
## THE REAPER himself, chasing you through the last stretch before a boss.
## Put `Y` in a level where the chase starts and `Z` where it ends.
##
## Once you pass `Y` he appears behind you and drifts after you, straight
## through walls. He's a bit slower than you, so keep moving: dawdle and he
## catches you. When you reach `Z` he teleports right next to you, says his
## piece about the boss, and vanishes. If you die during the chase he comes
## back behind your checkpoint after a moment.

const SPEED := 150.0
const CATCH_UP_SPEED := 320.0  # never falls further behind than MAX_GAP
const MAX_GAP := 14.0 * 32.0
const START_GAP := 11.0 * 32.0
const GRACE := 1.4  # seconds he waits after you respawn
const SPEECH_TIME := 4.5

enum State { WAITING, ARRIVING, CHASE, SPEECH, LEAVING, GONE }

## Set by the level.
var player: Node2D
var level: Node2D
var start_x := 0.0
var end_x := 0.0
var boss_name := "the boss"

var state := State.WAITING
var _state_time := 0.0
var _grace := 0.0
var _t := 0.0
var _facing := 1.0
var _bubble: PanelContainer


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(30, 54)
	shape.shape = rect
	shape.position = Vector2(0, 2)
	add_child(shape)
	z_index = 6
	visible = false
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
		State.WAITING:
			if not player.dead and player.global_position.x >= start_x:
				_appear()
		State.ARRIVING:
			modulate.a = clampf(_state_time / 0.8, 0.0, 1.0)
			_drift(delta, SPEED * 0.4)
			if _state_time > 0.8:
				_set_state(State.CHASE)
		State.CHASE:
			if player.global_position.x >= end_x and not player.dead:
				_start_speech()
				return
			_grace -= delta
			if _grace <= 0.0 and not player.dead:
				var gap := player.global_position.x - global_position.x
				_drift(delta, CATCH_UP_SPEED if gap > MAX_GAP else SPEED)
			for body in get_overlapping_bodies():
				if body == player:
					player.hurt()
		State.SPEECH:
			_facing = signf(player.global_position.x - global_position.x + 0.01)
			if _state_time > SPEECH_TIME:
				_bubble.visible = false
				_set_state(State.LEAVING)
				Sfx.play("vanish")
				_puff()
				player.frozen = false
		State.LEAVING:
			modulate.a = 1.0 - clampf(_state_time / 0.6, 0.0, 1.0)
			if _state_time > 0.6:
				_set_state(State.GONE)
				visible = false


## Moves right at `speed`, and up or down towards the player.
func _drift(delta: float, speed: float) -> void:
	_facing = 1.0
	position.x += speed * delta
	var dy := player.global_position.y - 8.0 - global_position.y
	position.y += clampf(dy, -130.0 * delta, 130.0 * delta)


func _appear() -> void:
	visible = true
	modulate.a = 0.0
	global_position = player.global_position + Vector2(-START_GAP, -24.0)
	reset_physics_interpolation()
	_set_state(State.ARRIVING)
	Sfx.play("laugh")
	level.shake(6.0, 0.5)
	level.hud.show_banner("THE REAPER HAS FOUND YOU!\nRUN! Don't let him catch you!", 3.0, 24)


func _start_speech() -> void:
	_puff()
	Sfx.play("vanish", 0.7)
	_set_state(State.SPEECH)
	global_position = player.global_position + Vector2(-78.0, -26.0)
	reset_physics_interpolation()
	modulate.a = 1.0
	player.frozen = true
	(_bubble.get_child(0) as Label).text = "So... the little skull escaped my crypt.\nNo matter. I will let %s\ndeal with you." % boss_name
	_bubble.visible = true
	_bubble.reset_size()
	var s := _bubble.get_combined_minimum_size()
	_bubble.position = Vector2(-s.x * 0.3, -96.0 - s.y)
	Sfx.play("laugh", 0.8)


## Back behind your checkpoint (the level calls this when you respawn).
func reset() -> void:
	if state in [State.SPEECH, State.LEAVING, State.GONE]:
		return
	if player.respawn_point.x < start_x:
		visible = false
		_set_state(State.WAITING)
		return
	visible = true
	modulate.a = 1.0
	global_position = player.respawn_point + Vector2(-START_GAP * 0.8, -24.0)
	reset_physics_interpolation()
	_grace = GRACE
	_set_state(State.CHASE)


func _puff() -> void:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.amount = 24
	p.lifetime = 0.7
	p.explosiveness = 1.0
	p.spread = 180.0
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 200.0
	p.gravity = Vector2(0, -60)
	p.scale_amount_min = 3.0
	p.scale_amount_max = 7.0
	p.color = Color(Config.COLOR_PURPLE, 0.8)
	p.global_position = global_position
	p.emitting = true
	level.add_child(p)
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)


func _build_bubble() -> void:
	_bubble = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.01, 0.05, 0.94)
	sb.border_color = Config.COLOR_ACCENT
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(12)
	_bubble.add_theme_stylebox_override("panel", sb)
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Config.COLOR_BONE)
	_bubble.add_child(label)
	_bubble.z_index = 50
	_bubble.visible = false
	add_child(_bubble)


# ---------------------------------------------------------------------
#  Drawing (the same Reaper as in the story, just smaller)
# ---------------------------------------------------------------------
func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(_facing, 1.0))
	var swing := 0.25 + 0.25 * sin(_t * 3.0)
	if state == State.SPEECH:
		swing = 0.6
	draw_reaper(self, Vector2(0, 0), 0.4, swing, _t)
	draw_set_transform(Vector2.ZERO)


## Also used for the picture on the website.
static func draw_reaper(ci: CanvasItem, p: Vector2, sc: float, swing: float, t: float) -> void:
	var cloak := Color("120c18")
	var edge := Color("3a2550")
	ci.draw_circle(p, 120.0 * sc, Color(Config.COLOR_ACCENT, 0.07))
	# scythe (behind)
	var hand := p + Vector2(46, 10) * sc
	var ang := 0.15 + swing * 0.7  # the scythe leans forward over his shoulder
	var top := hand + Vector2(0, -120).rotated(ang) * sc
	var bottom := hand + Vector2(0, 70).rotated(ang) * sc
	ci.draw_line(bottom, top, Color("6b5040"), 6.0 * sc)
	var blade := PackedVector2Array()
	for i in 9:
		var a := float(i) / 8.0
		blade.append(top + Vector2(a * 70.0, sin(a * PI) * 26.0 - a * 10.0).rotated(ang) * sc)
	for i in range(7, 0, -1):
		var a := float(i) / 8.0
		blade.append(top + Vector2(a * 66.0, sin(a * PI) * 12.0 - a * 10.0 + 2.0).rotated(ang) * sc)
	ci.draw_colored_polygon(blade, Color("d8d2c4"))
	# cloak
	var pts := PackedVector2Array([p + Vector2(-34, -40) * sc, p + Vector2(0, -78) * sc, p + Vector2(34, -40) * sc])
	for i in 9:
		var x := 52.0 - i * 13.0
		pts.append(p + Vector2(x, 110.0 + (14.0 if i % 2 == 0 else 0.0) + sin(t * 5.0 + i) * 5.0) * sc)
	ci.draw_colored_polygon(pts, edge)
	for i in pts.size():
		pts[i] = p + (pts[i] - p) * 0.9
	ci.draw_colored_polygon(pts, cloak)
	# hood and eyes
	ci.draw_circle(p + Vector2(0, -40) * sc, 22.0 * sc, Color("05030a"))
	for side in [-1.0, 1.0]:
		ci.draw_circle(p + Vector2(side * 8.0 + 3.0, -42) * sc, 9.0 * sc, Color(Config.COLOR_ACCENT, 0.25))
		ci.draw_circle(p + Vector2(side * 8.0 + 3.0, -42) * sc, 4.0 * sc, Config.COLOR_ACCENT)
	# bony hand on the scythe
	ci.draw_circle(hand, 7.0 * sc, Config.COLOR_BONE)
