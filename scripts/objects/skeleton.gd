extends CharacterBody2D
## A walking skeleton. Jump on its head to defeat it; touching it from
## the side hurts. It turns around at walls and ledges.

const SPEED := 55.0
const GRAVITY := 1800.0

## Set by the level: returns true if a world position is inside solid ground.
var is_solid: Callable

var _dir := -1.0
var _t := 0.0
var _dead := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(18, 28)
	shape.shape = rect
	add_child(shape)

	var hitbox := Area2D.new()
	hitbox.collision_layer = 0
	hitbox.collision_mask = 2
	hitbox.monitorable = false
	var hs := CollisionShape2D.new()
	var hr := RectangleShape2D.new()
	hr.size = Vector2(22, 30)
	hs.shape = hr
	hitbox.add_child(hs)
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	add_child(hitbox)


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_t += delta
	velocity.y = minf(velocity.y + GRAVITY * delta, 900.0)
	velocity.x = _dir * SPEED
	move_and_slide()
	if is_on_floor():
		var ahead := global_position + Vector2(_dir * 14.0, 22.0)
		if is_on_wall() or (is_solid.is_valid() and not is_solid.call(ahead)):
			_dir = -_dir
	queue_redraw()


func _on_hitbox_body_entered(body: Node2D) -> void:
	if _dead or not body.is_in_group("player") or body.dead:
		return
	if body.is_falling_onto(global_position.y - 8.0):
		body.bounce()
		_defeat()
	else:
		body.die()


func _defeat() -> void:
	_dead = true
	Sfx.play("stomp")
	set_deferred("collision_mask", 0)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.4, 0.3), 0.12)
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_callback(queue_free)


func _draw() -> void:
	var bone := Color("d9d2bf")
	var dark := Color("17121f")
	var step := sin(_t * 10.0)
	# legs
	draw_line(Vector2(-3, 6), Vector2(-4 + step * 4, 14), bone, 3.0)
	draw_line(Vector2(3, 6), Vector2(4 - step * 4, 14), bone, 3.0)
	# spine and ribs
	draw_line(Vector2(0, -5), Vector2(0, 6), bone, 3.0)
	for i in 3:
		var y := -3.0 + i * 3.0
		draw_line(Vector2(-6, y), Vector2(6, y), bone, 2.0)
	# arms
	draw_line(Vector2(-6, -4), Vector2(-9 + _dir * 3, 4 + step * 2), bone, 2.0)
	draw_line(Vector2(6, -4), Vector2(9 + _dir * 3, 4 - step * 2), bone, 2.0)
	# head
	var h := Vector2(_dir * 1.5, -11)
	draw_circle(h, 7.5, bone)
	draw_rect(Rect2(h.x - 4.5, h.y + 3, 9, 4), bone)
	draw_circle(h + Vector2(-2.6 + _dir * 1.5, 0), 2.2, dark)
	draw_circle(h + Vector2(2.6 + _dir * 1.5, 0), 2.2, dark)
	draw_circle(h + Vector2(-2.6 + _dir * 1.8, 0), 0.9, Config.COLOR_GOLD)
	draw_circle(h + Vector2(2.6 + _dir * 1.8, 0), 0.9, Config.COLOR_GOLD)
