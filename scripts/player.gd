extends CharacterBody2D
## The runaway skull. Handles running, jumping, double jumping, dashing,
## wall jumping, sliding on ice, dying and respawning at the last checkpoint.

signal died
signal respawned
signal first_move  # the first time the player presses a movement key

const SkullArt = preload("res://scripts/skull_art.gd")

# --- movement tuning (1 tile = 32 pixels) -----------------------------
const RUN_SPEED := 250.0
const GROUND_ACCEL := 2200.0
const AIR_ACCEL := 1500.0
const GROUND_FRICTION := 2600.0
const GRAVITY := 1800.0
const MAX_FALL_SPEED := 900.0
const JUMP_VELOCITY := -680.0  # reaches about 4 tiles high
const DOUBLE_JUMP_VELOCITY := -600.0
const JUMP_CUT := 0.45  # letting go of jump early makes a shorter hop
const STOMP_BOUNCE := -520.0
const DASH_SPEED := 640.0
const DASH_TIME := 0.16
const COYOTE_TIME := 0.1  # you can still jump just after running off a ledge
const JUMP_BUFFER := 0.12  # pressing jump just before landing still counts
const WALL_SLIDE_SPEED := 130.0  # how fast you slide down a wall you're holding
const WALL_JUMP_VELOCITY := Vector2(300.0, -640.0)
const WALL_JUMP_LOCK := 0.16  # seconds you can't steer after a wall jump
const WALL_COYOTE := 0.1
const ICE_SPEED := 250.0  # on ice you always slide at this speed
const WIND_LIFT := -340.0  # how fast soul vents carry you upward
const RESPAWN_DELAY := 0.8
const RESPAWN_SAFE_TIME := 1.5  # enemies can't hurt you right after respawning

var can_double_jump := true
var can_dash := true
var can_wall_jump := true

## Set by the level: returns the map character at a world position.
var tile_at: Callable
var has_moved := false

var respawn_point := Vector2.ZERO
var kill_y := 100000.0
var dead := false
var frozen := false  # true when the level is finished

var facing := 1.0
var _air_jumps := 0
var _dash_ready := true
var _dash_time := 0.0
var _dash_dir := 1.0
var _coyote := 0.0
var _buffer := 0.0
var _launched := false
var _was_on_floor := true
var _squash := Vector2.ONE
var _trail: Array = []
var _time := 0.0
var _on_ice := false
var _wall_side := 0.0  # -1 = touching a wall on the left, 1 = on the right
var _wall_coyote := 0.0
var _wall_lock := 0.0
var _wall_sliding := false
var _safe_time := 0.0
var _wind_time := 0.0

var camera: Camera2D
var _particles: CPUParticles2D
var _respawn_timer: Timer


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 6.0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(20, 26)
	shape.shape = rect
	add_child(shape)

	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	camera.drag_vertical_enabled = true
	camera.drag_top_margin = 0.25
	camera.drag_bottom_margin = 0.15
	add_child(camera)

	_particles = CPUParticles2D.new()
	_particles.emitting = false
	_particles.one_shot = true
	_particles.amount = 22
	_particles.lifetime = 0.9
	_particles.explosiveness = 1.0
	_particles.direction = Vector2.UP
	_particles.spread = 80.0
	_particles.initial_velocity_min = 160.0
	_particles.initial_velocity_max = 360.0
	_particles.gravity = Vector2(0, 900)
	_particles.scale_amount_min = 3.0
	_particles.scale_amount_max = 6.0
	_particles.color = Config.COLOR_BONE
	_particles.angular_velocity_min = -360
	_particles.angular_velocity_max = 360
	add_child(_particles)

	_respawn_timer = Timer.new()
	_respawn_timer.one_shot = true
	_respawn_timer.wait_time = RESPAWN_DELAY
	_respawn_timer.timeout.connect(respawn)
	add_child(_respawn_timer)

	respawn_point = global_position


func _physics_process(delta: float) -> void:
	_time += delta
	_squash = _squash.lerp(Vector2.ONE, 12.0 * delta)
	_update_trail()
	queue_redraw()
	if _safe_time > 0.0:
		_safe_time -= delta
		modulate.a = 0.35 if int(_time * 14.0) % 2 == 0 else 1.0
		if _safe_time <= 0.0:
			modulate.a = 1.0

	if dead:
		return
	if frozen:
		velocity.x = move_toward(velocity.x, 0.0, GROUND_FRICTION * delta)
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
		move_and_slide()
		return

	var dir := Input.get_axis("move_left", "move_right")
	if not has_moved and (not is_zero_approx(dir) or Input.is_action_just_pressed("jump")
			or Input.is_action_just_pressed("dash")):
		has_moved = true
		first_move.emit()

	var on_floor := is_on_floor()
	_on_ice = on_floor and _tile_below() == "I"

	if on_floor:
		_coyote = 0.0 if _on_ice else COYOTE_TIME
		_air_jumps = 1 if can_double_jump else 0
		_dash_ready = true
		_launched = false
	else:
		_coyote -= delta

	# walls you can slide down and jump off (but not icy ones)
	var side := 0.0
	if can_wall_jump and not on_floor:
		side = _touching_wall(dir)
	if side != 0.0:
		_wall_side = side
		_wall_coyote = WALL_COYOTE
	else:
		_wall_coyote -= delta

	if Input.is_action_just_pressed("jump"):
		_buffer = JUMP_BUFFER
	else:
		_buffer -= delta

	_wall_sliding = false
	if _dash_time > 0.0:
		_dash_time -= delta
		velocity = Vector2(_dash_dir * DASH_SPEED, 0.0)
		if _dash_time <= 0.0:
			velocity.x = _dash_dir * RUN_SPEED
	else:
		# run
		if _wall_lock > 0.0:
			_wall_lock -= delta
		elif _on_ice:
			# Ice: no steering. Once you're sliding you keep going until you
			# leave the ice or bump into something.
			if absf(velocity.x) < 20.0:
				velocity.x = dir * ICE_SPEED
			else:
				velocity.x = signf(velocity.x) * ICE_SPEED
		else:
			var accel := GROUND_ACCEL if on_floor else AIR_ACCEL
			if is_zero_approx(dir) and on_floor:
				accel = GROUND_FRICTION
			velocity.x = move_toward(velocity.x, dir * RUN_SPEED, accel * delta)
		# fall (slowly, if you're pressing into a wall) - or float up a soul vent
		if _wind_time > 0.0:
			_wind_time -= delta
			var lift_accel := 7000.0 if velocity.y > 0.0 else 2600.0
			velocity.y = move_toward(velocity.y, WIND_LIFT, lift_accel * delta)
		else:
			velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
		if side != 0.0 and signf(dir) == side and velocity.y > WALL_SLIDE_SPEED:
			velocity.y = WALL_SLIDE_SPEED
			_wall_sliding = true
		# jump (never on ice)
		if _buffer > 0.0 and not _on_ice:
			if _coyote > 0.0:
				_jump(JUMP_VELOCITY)
				Sfx.play("jump")
			elif can_wall_jump and _wall_coyote > 0.0:
				_wall_jump()
			elif _air_jumps > 0:
				_air_jumps -= 1
				_jump(DOUBLE_JUMP_VELOCITY)
				Sfx.play("double_jump")
				_burst(Config.COLOR_PURPLE, 8)
		if Input.is_action_just_released("jump") and velocity.y < 0.0 and not _launched:
			velocity.y *= JUMP_CUT
		# dash (never on ice)
		if can_dash and _dash_ready and not _on_ice and Input.is_action_just_pressed("dash"):
			_dash_ready = false
			_dash_time = DASH_TIME
			_wall_lock = 0.0
			_dash_dir = signf(dir) if not is_zero_approx(dir) else facing
			_squash = Vector2(1.4, 0.7)
			Sfx.play("dash")

	if _on_ice and absf(velocity.x) > 1.0:
		facing = signf(velocity.x)
	elif _wall_lock > 0.0:
		facing = signf(velocity.x)
	elif not is_zero_approx(dir):
		facing = signf(dir)

	move_and_slide()

	if is_on_floor() and not _was_on_floor:
		_squash = Vector2(1.25, 0.78)
	_was_on_floor = is_on_floor()

	camera.position.x = lerpf(camera.position.x, facing * 70.0, 2.5 * delta)

	if global_position.y > kill_y:
		die()


func _tile_below() -> String:
	if not tile_at.is_valid():
		return ""
	return tile_at.call(global_position + Vector2(0, 20))


## Returns -1 or 1 if a (non-icy) wall is right next to us, preferring the
## side the player is pushing towards, else 0.
func _touching_wall(dir: float) -> float:
	var sides := [signf(dir), -signf(dir)] if not is_zero_approx(dir) else [facing, -facing]
	for s in sides:
		if test_move(global_transform, Vector2(s * 3.0, 0.0)):
			if tile_at.is_valid() and tile_at.call(global_position + Vector2(s * 18.0, 0)) == "I":
				continue
			return s
	return 0.0


func _wall_jump() -> void:
	velocity = Vector2(-_wall_side * WALL_JUMP_VELOCITY.x, WALL_JUMP_VELOCITY.y)
	_wall_lock = WALL_JUMP_LOCK
	_wall_coyote = 0.0
	_coyote = 0.0
	_buffer = 0.0
	_launched = false
	_air_jumps = 1 if can_double_jump else 0
	_dash_ready = true
	facing = -_wall_side
	_squash = Vector2(0.75, 1.3)
	Sfx.play("wall_jump")
	_burst(Config.COLOR_BONE, 6)


func _jump(v: float) -> void:
	velocity.y = v
	_coyote = 0.0
	_buffer = 0.0
	_launched = false
	_squash = Vector2(0.75, 1.3)


## Called by jump pads.
func launch(v: float) -> void:
	velocity.y = v
	_launched = true
	_air_jumps = 1 if can_double_jump else 0
	_dash_ready = true
	_dash_time = 0.0
	_squash = Vector2(0.7, 1.35)


## Called when the skull lands on an enemy's head.
func bounce() -> void:
	velocity.y = STOMP_BOUNCE * (1.3 if Input.is_action_pressed("jump") else 1.0)
	_launched = true
	_air_jumps = 1 if can_double_jump else 0
	_dash_ready = true
	_dash_time = 0.0
	_squash = Vector2(0.8, 1.25)


## Called every frame by a soul vent the skull is inside.
func ride_wind() -> void:
	if dead or frozen:
		return
	_wind_time = 0.05
	_air_jumps = 1 if can_double_jump else 0
	_dash_ready = true
	_launched = true


## Pushes the skull sideways (e.g. off the boss after a stomp).
func knockback(vx: float) -> void:
	velocity.x = vx
	_wall_lock = 0.25


func is_falling_onto(target_y: float) -> bool:
	return velocity.y > -50.0 and global_position.y < target_y


## True for a moment after respawning, while enemies can't hurt you.
func is_safe() -> bool:
	return _safe_time > 0.0


## Called by enemies. Ignored right after a respawn.
func hurt() -> void:
	if is_safe():
		return
	die()


func die() -> void:
	if dead or frozen:
		return
	dead = true
	velocity = Vector2.ZERO
	_dash_time = 0.0
	_trail.clear()
	Sfx.play("death")
	_burst(Config.COLOR_BONE, 22)
	died.emit()
	_respawn_timer.start()


func respawn() -> void:
	global_position = respawn_point
	velocity = Vector2.ZERO
	dead = false
	_squash = Vector2(0.6, 1.4)
	_was_on_floor = false
	_wall_lock = 0.0
	_safe_time = RESPAWN_SAFE_TIME
	camera.reset_smoothing()
	respawned.emit()


func _burst(color: Color, amount: int) -> void:
	_particles.color = color
	_particles.amount = amount
	_particles.restart()
	_particles.emitting = true


func _update_trail() -> void:
	if _dash_time > 0.0 or (absf(velocity.x) > RUN_SPEED * 1.05 and not dead):
		_trail.push_front(global_position)
	elif not _trail.is_empty():
		_trail.pop_back()
	while _trail.size() > 6:
		_trail.pop_back()


func _draw() -> void:
	# dash after-images
	for i in _trail.size():
		var a := 0.25 * (1.0 - float(i) / _trail.size())
		var p: Vector2 = to_local(_trail[i])
		draw_circle(p + Vector2(0, -2), 12.0, Color(Config.COLOR_PURPLE, a))
	if dead:
		return
	# soft glow
	draw_circle(Vector2(0, 0), 18.0, Color(Config.COLOR_ACCENT, 0.08))
	# squash & stretch around the feet, lean into the run
	var lean := clampf(velocity.x / RUN_SPEED, -1.0, 1.0) * 0.12
	var bob := 0.0
	if is_on_floor() and absf(velocity.x) > 20.0:
		bob = absf(sin(_time * 16.0)) * -2.5
	draw_set_transform(Vector2(0, 13.0 * (1.0 - _squash.y) + bob), lean, _squash)
	var eye := Config.COLOR_ACCENT.lerp(Color.WHITE, 0.25 + 0.15 * sin(_time * 6.0))
	if not _dash_ready and can_dash:
		eye = Config.COLOR_PURPLE
	if _wall_sliding:
		draw_set_transform(Vector2(0, 0))
		for i in 3:
			var y := fmod(_time * 90.0 + i * 9.0, 26.0) - 13.0
			draw_circle(Vector2(_wall_side * 11.0, y), 1.5, Color(Config.COLOR_BONE, 0.5))
		draw_set_transform(Vector2(0, 13.0 * (1.0 - _squash.y) + bob), lean, _squash)
	SkullArt.draw_skull(self, Vector2(0, 0.5), 12.5, Config.COLOR_BONE, eye, facing)
	draw_set_transform(Vector2.ZERO)
