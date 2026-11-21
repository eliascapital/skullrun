extends Area2D
## A STALACTITE hanging from a cave ceiling (`!` in a level, in the cell right
## under the ceiling). When the skull walks underneath it shakes for a moment,
## then drops. Getting hit is deadly, so keep running! It smashes on the
## ground and grows back a few seconds later.
## A falling stalactite that lands on a cave troll knocks the troll out, and a
## troll's pounding shakes loose the stalactites right over him.
##
## Jett the Scarecrow makes them fall too (`once`: they drop straight away
## and don't grow back).

const SHAKE_TIME := 0.5
const GRAVITY := 1800.0
const MAX_FALL := 1000.0
const REGROW_TIME := 3.0
const GROW_TIME := 0.6
const LENGTH := 30.0
const TRIGGER_X := 40.0  # how close (sideways) the skull must come
const TRIGGER_DEPTH := 16.0 * 32.0  # how far below it notices the skull

enum State { HANG, SHAKE, FALL, SHATTER, GONE, GROW }

## Set by the level (or by Jett).
var player: Node2D
var level: Node2D
var color := Color("6a7a8a")
## Jett's cave-in: drop right away, and don't grow back.
var once := false
var shake_time := SHAKE_TIME

var state := State.HANG
var _state_time := 0.0
var _home := Vector2.ZERO
var _vy := 0.0
var _t := 0.0
var _shards: Array = []  # [pos, vel] of the broken bits


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(14, 26)
	shape.shape = rect
	shape.position = Vector2(16, 14)
	add_child(shape)
	_home = position
	_t = fmod(position.x * 0.03, TAU)
	if once:
		add_to_group("boss_projectile")
		_set_state(State.SHAKE)
		Sfx.play("crumble", 1.2)


func _set_state(s: State) -> void:
	state = s
	_state_time = 0.0


func _physics_process(delta: float) -> void:
	_t += delta
	_state_time += delta
	if state != State.HANG or _state_time < 0.1:
		queue_redraw()  # a hanging stalactite keeps its last drawing
	match state:
		State.HANG:
			if _skull_below():
				_set_state(State.SHAKE)
				Sfx.play("crumble", 1.5)
		State.SHAKE:
			if _state_time >= shake_time:
				_set_state(State.FALL)
				_vy = 0.0
		State.FALL:
			_vy = minf(_vy + GRAVITY * delta, MAX_FALL)
			position.y += _vy * delta
			for body in get_overlapping_bodies():
				if body.is_in_group("player"):
					body.hurt()
			_hit_trolls()
			var tip := global_position + Vector2(16, LENGTH)
			if (level and level.is_solid_at(tip)) or position.y > _home.y + 40 * 32:
				_shatter()
		State.SHATTER:
			for s in _shards:
				s[1].y += GRAVITY * 0.6 * delta
				s[0] += s[1] * delta
			if _state_time > 0.5:
				if once:
					queue_free()
					return
				_set_state(State.GONE)
		State.GONE:
			if _state_time > REGROW_TIME:
				position = _home
				reset_physics_interpolation()
				_set_state(State.GROW)
		State.GROW:
			if _state_time > GROW_TIME:
				_set_state(State.HANG)


## Starts it shaking (a cave troll's thump does this).
func trigger() -> void:
	if state == State.HANG:
		_set_state(State.SHAKE)
		Sfx.play("crumble", 1.5)


## True if the skull is under us, with nothing solid in between.
func _skull_below() -> bool:
	if player == null or player.dead:
		return false
	var p: Vector2 = player.global_position
	var top := global_position + Vector2(16, 32)
	if absf(p.x - top.x) > TRIGGER_X or p.y < top.y or p.y - top.y > TRIGGER_DEPTH:
		return false
	if level:
		var y := top.y + 16.0
		while y < p.y - 16.0:
			if level.is_solid_at(Vector2(top.x, y)):
				return false
			y += 32.0
	return true


func _hit_trolls() -> void:
	if level == null:
		return
	var tip := global_position + Vector2(16, LENGTH)
	for tr in level.trolls:
		if is_instance_valid(tr) and tr.can_be_crushed() and tr.covers(tip):
			tr.crush()
			_shatter()
			return


func _shatter() -> void:
	_set_state(State.SHATTER)
	Sfx.play("crumble", 0.8)
	_shards.clear()
	var base := Vector2(16, LENGTH * 0.6)
	for i in 6:
		var a := -PI * (0.15 + 0.7 * i / 5.0)
		_shards.append([base, Vector2(cos(a), sin(a)) * randf_range(90.0, 200.0)])


func _draw() -> void:
	match state:
		State.GONE:
			return
		State.SHATTER:
			var fade := 1.0 - clampf(_state_time / 0.5, 0.0, 1.0)
			for s in _shards:
				var p: Vector2 = s[0]
				draw_colored_polygon(PackedVector2Array([p + Vector2(-3, -2), p + Vector2(3, -3),
					p + Vector2(2, 3)]), Color(color, fade))
			draw_circle(Vector2(16, LENGTH * 0.6), 18.0 * (1.0 - fade) + 4.0, Color(color.lightened(0.4), 0.3 * fade))
			return
	var off := Vector2.ZERO
	if state == State.SHAKE:
		off.x = sin(_t * 60.0) * 2.0
	var grow := 1.0
	if state == State.GROW:
		grow = clampf(_state_time / GROW_TIME, 0.0, 1.0)
	draw_set_transform(off + Vector2(16, 0), 0.0, Vector2(1.0, grow))
	draw_stalactite(self, color, state == State.SHAKE)
	draw_set_transform(Vector2.ZERO)
	# a few crumbs trickle down while it shakes
	if state == State.SHAKE:
		for i in 3:
			var k := fmod(_state_time * 3.0 + i / 3.0, 1.0)
			draw_circle(Vector2(10 + i * 6, 4 + k * 40.0), 1.5, Color(color.lightened(0.3), 1.0 - k))


## A pointy rock icicle, hanging down from (0, 0). Also used for the website.
static func draw_stalactite(ci: CanvasItem, col: Color, warning: bool) -> void:
	var dark := col.darkened(0.35)
	var light := col.lightened(0.3)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-14, 0), Vector2(14, 0), Vector2(8, 10),
		Vector2(4, 20), Vector2(0, LENGTH), Vector2(-4, 18), Vector2(-9, 8)]), dark)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-11, 0), Vector2(10, 0), Vector2(5, 10),
		Vector2(1, 22), Vector2(-3, 14), Vector2(-7, 6)]), col)
	ci.draw_line(Vector2(-6, 2), Vector2(-2, 14), light, 2.0)
	# a drip at the tip
	ci.draw_circle(Vector2(0, LENGTH + 2), 1.8, Color(Color("8fd8f0"), 0.7))
	if warning:
		ci.draw_line(Vector2(-3, 5), Vector2(2, 11), Color(0, 0, 0, 0.6), 1.5)
		ci.draw_line(Vector2(2, 11), Vector2(-1, 16), Color(0, 0, 0, 0.6), 1.5)
