extends CharacterBody2D
## THE BONE KING: a giant skeleton boss. Put `K` in a level to place him.
##
## He sleeps until you come close, then repeats a pattern of attacks that
## gets faster and nastier each time you hurt him:
##   walk towards you -> throw bones -> (slam) -> charge.
## When a charge ends against a wall he is dazed for a moment: that's the
## best time to jump on his head. Three stomps and he's done.
## If you die, he goes back to sleep at full health.

signal defeated

const SkullArt = preload("res://scripts/skull_art.gd")
const BossBone = preload("res://scripts/objects/boss_bone.gd")
const BossShockwave = preload("res://scripts/objects/boss_shockwave.gd")

const MAX_HP := 3
const GRAVITY := 1800.0
const WAKE_DISTANCE := 30.0 * 32.0
const HALF_HEIGHT := 42.0

enum State { SLEEP, INTRO, WALK, THROW, SLAM_JUMP, SLAM_FALL, WINDUP, CHARGE, STUNNED, HURT, DEAD }

## The level that owns us (for the player, the map and screen shake).
var level: Node2D

var hp := MAX_HP
var state := State.SLEEP
var facing := -1.0
var _state_time := 0.0
var _pattern: Array = []
var _thrown := 0
var _t := 0.0
var _home := Vector2.ZERO
var _hitbox: Area2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	_home = position
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(48, HALF_HEIGHT * 2)
	shape.shape = rect
	add_child(shape)

	_hitbox = Area2D.new()
	_hitbox.collision_layer = 0
	_hitbox.collision_mask = 2
	_hitbox.monitorable = false
	var hs := CollisionShape2D.new()
	var hr := RectangleShape2D.new()
	hr.size = Vector2(54, HALF_HEIGHT * 2 + 8)
	hs.shape = hr
	_hitbox.add_child(hs)
	add_child(_hitbox)


func phase() -> int:
	return MAX_HP - hp + 1


func _speed_mult() -> float:
	return 1.0 + 0.25 * (phase() - 1)


func _player() -> Node2D:
	return level.player if level else null


# ---------------------------------------------------------------------
#  Brain
# ---------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	_t += delta
	_state_time += delta
	queue_redraw()
	var p := _player()
	if p == null:
		return

	if not is_on_floor() or state == State.SLAM_JUMP or state == State.SLAM_FALL:
		velocity.y = minf(velocity.y + GRAVITY * delta, 1200.0)

	match state:
		State.SLEEP:
			velocity.x = 0.0
			var d := p.global_position - global_position
			if not p.dead and absf(d.x) < WAKE_DISTANCE and absf(d.y) < 3 * 32:
				_set_state(State.INTRO)
				Sfx.play("roar")
				level.shake(10.0, 0.8)
				level.hud.show_boss_bar("THE BONE KING", MAX_HP)
		State.INTRO:
			if _state_time > 1.4:
				_next_attack()
		State.WALK:
			_face_player()
			velocity.x = facing * 85.0 * _speed_mult()
			if _state_time > 1.8:
				_next_attack()
		State.THROW:
			velocity.x = 0.0
			_face_player()
			var count := 3 if phase() == 1 else 5
			var gap := 0.32 / _speed_mult()
			if _state_time > 0.45 + _thrown * gap and _thrown < count:
				_throw_bone(_thrown, count)
				_thrown += 1
			if _state_time > 0.6 + count * gap:
				_next_attack()
		State.SLAM_JUMP:
			if _state_time < 0.05:
				_face_player()
				var dx := clampf(p.global_position.x - global_position.x, -260.0, 260.0)
				velocity = Vector2(dx / 0.9, -820.0)
			elif velocity.y > 0.0:
				_set_state(State.SLAM_FALL)
		State.SLAM_FALL:
			if is_on_floor():
				velocity.x = 0.0
				_slam_land()
				_next_attack()
		State.WINDUP:
			velocity.x = 0.0
			_face_player()
			if _state_time > 0.7 / _speed_mult():
				_set_state(State.CHARGE)
				Sfx.play("dash", 0.6)
		State.CHARGE:
			velocity.x = facing * 340.0 * _speed_mult()
			if (is_on_wall() and _state_time > 0.1) or _state_time > 3.5:
				velocity.x = 0.0
				_set_state(State.STUNNED)
				Sfx.play("slam")
				level.shake(9.0, 0.4)
		State.STUNNED:
			velocity.x = 0.0
			if _state_time > 2.6:
				_next_attack()
		State.HURT:
			velocity.x = 0.0
			if _state_time > 1.1:
				_next_attack()
		State.DEAD:
			velocity.x = 0.0
			if _state_time > 1.6:
				defeated.emit()
				queue_free()
				return

	move_and_slide()
	_check_player_contact(p)


func _set_state(s: State) -> void:
	state = s
	_state_time = 0.0
	_thrown = 0


func _next_attack() -> void:
	if _pattern.is_empty():
		match phase():
			1: _pattern = [State.WALK, State.THROW, State.WINDUP]
			2: _pattern = [State.WALK, State.THROW, State.SLAM_JUMP, State.WINDUP]
			_: _pattern = [State.THROW, State.SLAM_JUMP, State.WALK, State.SLAM_JUMP, State.WINDUP]
	_set_state(_pattern.pop_front())


func _face_player() -> void:
	var p := _player()
	if p:
		var d := p.global_position.x - global_position.x
		if absf(d) > 4.0:
			facing = signf(d)


func _throw_bone(i: int, count: int) -> void:
	var p := _player()
	var b := BossBone.new()
	b.is_solid = level.is_solid_at
	b.position = position + Vector2(facing * 26.0, -HALF_HEIGHT - 6.0)
	# aim around the player so standing still isn't safe
	var spread := (i - (count - 1) * 0.5) * 70.0
	var target_x := p.global_position.x + spread
	var flight := 1.0
	b.velocity = Vector2((target_x - b.position.x) / flight, -BossBone.GRAVITY * flight * 0.5 - 60.0)
	get_parent().add_child(b)
	Sfx.play("dash", 1.5)


func _slam_land() -> void:
	Sfx.play("slam")
	level.shake(12.0, 0.5)
	for d in [-1.0, 1.0]:
		var w := BossShockwave.new()
		w.dir = d
		w.is_solid = level.is_solid_at
		w.position = position + Vector2(d * 30.0, HALF_HEIGHT)
		get_parent().add_child(w)


func _check_player_contact(p: Node2D) -> void:
	if p.dead or state in [State.SLEEP, State.INTRO, State.HURT, State.DEAD]:
		return
	for body in _hitbox.get_overlapping_bodies():
		if body != p:
			continue
		if p.is_falling_onto(global_position.y - HALF_HEIGHT + 22.0):
			_take_hit(p)
		else:
			p.hurt()


func _take_hit(p: Node2D) -> void:
	hp -= 1
	p.bounce()
	p.knockback(signf(p.global_position.x - global_position.x + 0.01) * 320.0)
	level.hud.set_boss_hp(hp)
	level.shake(8.0, 0.3)
	_pattern.clear()
	if hp <= 0:
		Sfx.play("win", 0.7)
		_set_state(State.DEAD)
		level.hud.hide_boss_bar()
		for proj in get_tree().get_nodes_in_group("boss_projectile"):
			proj.queue_free()
	else:
		Sfx.play("boss_hit")
		_set_state(State.HURT)


## Back to sleep at full health (the level calls this when the player respawns).
func reset() -> void:
	if state == State.DEAD:
		return
	hp = MAX_HP
	position = _home
	velocity = Vector2.ZERO
	facing = -1.0
	_pattern.clear()
	_set_state(State.SLEEP)
	level.hud.hide_boss_bar()
	for proj in get_tree().get_nodes_in_group("boss_projectile"):
		proj.queue_free()


# ---------------------------------------------------------------------
#  Drawing
# ---------------------------------------------------------------------
func _draw() -> void:
	var bone := Color("e6dcc4")
	var dark := Color("120c18")
	var cape := Color("5a1a3a")
	var gold := Config.COLOR_GOLD
	var eye := Config.COLOR_ACCENT.lerp(Color.WHITE, 0.15 * phase() + 0.1 * sin(_t * 8.0))

	if state == State.DEAD:
		# falling apart
		var k := clampf(_state_time / 1.4, 0.0, 1.0)
		modulate.a = 1.0 - k * 0.8
		draw_set_transform(Vector2(0, k * 30.0), k * 0.6 * facing, Vector2(1.0 + k * 0.3, 1.0 - k * 0.5))
	elif state == State.HURT:
		modulate = Color(1, 0.5, 0.5) if int(_t * 16.0) % 2 == 0 else Color.WHITE
	else:
		modulate = Color.WHITE

	var sleeping := state == State.SLEEP
	var stunned := state == State.STUNNED
	var walk := sin(_t * (14.0 if state == State.CHARGE else 7.0))
	if state not in [State.WALK, State.CHARGE]:
		walk = 0.0
	var head := Vector2(facing * 3.0, -26.0)
	if stunned or sleeping:
		head += Vector2(facing * 6.0, 10.0)
	if state == State.WINDUP:
		head += Vector2(-facing * 4.0, 4.0 + sin(_t * 30.0) * 1.5)

	# aura
	draw_circle(Vector2(0, -6), 60.0, Color(Config.COLOR_ACCENT, 0.05 + 0.03 * phase()))
	# cape
	draw_colored_polygon(PackedVector2Array([
		Vector2(-18, -14), Vector2(18, -14), Vector2(26 - facing * 8, 36 + sin(_t * 3.0) * 3.0),
		Vector2(8, 30), Vector2(-4, 38), Vector2(-16, 30), Vector2(-26 - facing * 8, 36)]), cape)
	# legs
	draw_line(Vector2(-9, 16), Vector2(-11 + walk * 8.0, HALF_HEIGHT), bone, 7.0)
	draw_line(Vector2(9, 16), Vector2(11 - walk * 8.0, HALF_HEIGHT), bone, 7.0)
	# pelvis, spine, ribs
	draw_rect(Rect2(-15, 10, 30, 9), bone)
	draw_line(Vector2(0, -14), Vector2(0, 14), bone, 7.0)
	for i in 4:
		var y := -10.0 + i * 5.5
		var w := 19.0 - i * 2.5
		draw_line(Vector2(-w, y), Vector2(w, y), bone, 4.0)
	draw_line(Vector2(-24, -14), Vector2(24, -14), bone, 7.0)
	# arms
	var arm_front := Vector2(facing * 32.0, 10.0 - walk * 6.0)
	if state == State.THROW:
		arm_front = Vector2(facing * 20.0, -52.0) if fmod(_state_time, 0.32) < 0.16 else Vector2(facing * 38.0, -20.0)
	elif state in [State.SLAM_JUMP, State.SLAM_FALL]:
		arm_front = Vector2(facing * 26.0, -50.0)
	elif stunned:
		arm_front = Vector2(facing * 26.0, 26.0)
	draw_line(Vector2(facing * 22.0, -14), arm_front, bone, 6.0)
	draw_line(Vector2(-facing * 22.0, -14), Vector2(-facing * 30.0, 12.0 + walk * 6.0), bone, 6.0)
	# skull
	var eye_col := Color(eye, 0.25) if sleeping else eye
	SkullArt.draw_skull(self, head, 19.0, bone, eye_col, facing, dark)
	# crown
	var cy := head.y - 19.0 * 1.05
	var crown := PackedVector2Array([
		Vector2(head.x - 16, cy + 6), Vector2(head.x - 18, cy - 12), Vector2(head.x - 8, cy - 2),
		Vector2(head.x, cy - 16), Vector2(head.x + 8, cy - 2), Vector2(head.x + 18, cy - 12),
		Vector2(head.x + 16, cy + 6)])
	if stunned:
		for i in crown.size():
			crown[i] = crown[i].rotated(0.25 * facing) + Vector2(facing * 8.0, 4.0)
	draw_colored_polygon(crown, gold)
	draw_circle(Vector2(head.x, cy - 2), 3.0, Config.COLOR_ACCENT)
	# dazed stars / sleepy Zs
	if stunned:
		for i in 3:
			var a := _t * 4.0 + i * TAU / 3.0
			var sp := head + Vector2(cos(a) * 24.0, -30.0 + sin(a) * 6.0)
			draw_circle(sp, 3.5, gold)
	if sleeping:
		var font := ThemeDB.fallback_font
		for i in 3:
			var k := fmod(_t * 0.6 + i / 3.0, 1.0)
			draw_string(font, head + Vector2(18 + k * 20.0, -24 - k * 40.0), "z", HORIZONTAL_ALIGNMENT_LEFT,
				-1, int(12 + k * 10), Color(Config.COLOR_BONE, 1.0 - k))
	draw_set_transform(Vector2.ZERO)
