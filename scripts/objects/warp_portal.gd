extends Area2D
## A warp portal. Portals come in pairs (two `a`s, two `b`s ...): step into
## one and you come out of the other, still moving the way you were going.

## Set by the level: the other portal of the pair, and this pair's colour.
var partner: Area2D
var color := Color("c77dff")

var _t := 0.0
var _cooldown := 0.0  # after you arrive here, this portal won't send you straight back
var _flash := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(22, 46)
	shape.shape = rect
	shape.position = Vector2(0, -8)
	add_child(shape)
	body_entered.connect(_on_body_entered)
	_t = fmod(position.x * 0.013, TAU)


func _physics_process(delta: float) -> void:
	_t += delta
	_cooldown -= delta
	_flash = maxf(0.0, _flash - delta * 2.5)
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if _cooldown > 0.0 or partner == null or not body.is_in_group("player") or body.dead:
		return
	partner.arrive()
	_flash = 1.0
	body.warp_to(partner.global_position)
	Sfx.play("warp")


## The player is about to pop out of this portal.
func arrive() -> void:
	_cooldown = 0.5
	_flash = 1.0


func _draw() -> void:
	var c := Vector2(0, -10)
	var k := 1.0 + _flash * 0.35
	for i in 5:
		draw_circle(c, (40.0 - i * 6.0) * k, Color(color, 0.04 + i * 0.015 + _flash * 0.05))
	# a tall oval: dark centre, swirling rings in the pair's colour
	draw_set_transform(c, 0.0, Vector2(0.55, 1.0) * k)
	draw_circle(Vector2.ZERO, 26.0, Color(color.darkened(0.8), 0.95))
	for i in 4:
		var r := 25.0 - i * 5.5
		var start := -_t * (3.0 + i) + i * 1.7
		draw_arc(Vector2.ZERO, r, start, start + PI * 1.4, 24, color.lerp(Color.WHITE, i * 0.18), 3.5)
	draw_arc(Vector2.ZERO, 27.0, 0.0, TAU, 40, Color(color, 0.9), 2.0)
	draw_set_transform(Vector2.ZERO)
	# sparkles drifting up and out
	for i in 4:
		var f := fmod(_t * 0.8 + i * 0.25, 1.0)
		var side := -1.0 if i % 2 == 0 else 1.0
		draw_circle(c + Vector2(side * (10.0 + f * 10.0), 18.0 - f * 50.0), 2.0 * (1.0 - f), Color(color.lightened(0.4), 1.0 - f))
