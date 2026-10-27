extends Area2D
## A smiley-face potion thrown by a witch. It flies in an arc and explodes
## when it hits the ground, a wall or the skull. The blast hurts.

const GRAVITY := 900.0
const BLAST_RADIUS := 46.0
const BLAST_TIME := 0.35

var velocity := Vector2.ZERO
var color := Color("ff5fd2")
var is_solid: Callable

var _age := 0.0
var _spin := 0.0
var _blast := -1.0  # time since the explosion (-1 = still flying)


func _ready() -> void:
	add_to_group("spit")
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 8.0
	shape.shape = circle
	add_child(shape)
	_spin = randf_range(-1.0, 1.0)


func _physics_process(delta: float) -> void:
	_age += delta
	queue_redraw()
	if _blast >= 0.0:
		_blast += delta
		if _blast < BLAST_TIME * 0.6:
			for body in get_overlapping_bodies():
				if body.is_in_group("player"):
					body.hurt()
		if _blast >= BLAST_TIME:
			queue_free()
		return
	velocity.y = minf(velocity.y + GRAVITY * delta, 700.0)
	position += velocity * delta
	_spin += delta * 9.0 * signf(velocity.x + 0.01)
	var hit := _age > 5.0
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			hit = true
	if is_solid.is_valid() and is_solid.call(global_position + velocity.normalized() * 6.0):
		hit = true
	if hit:
		explode()


func explode() -> void:
	if _blast >= 0.0:
		return
	_blast = 0.0
	velocity = Vector2.ZERO
	(get_child(0).shape as CircleShape2D).set_deferred("radius", BLAST_RADIUS)
	Sfx.play("boom", randf_range(0.9, 1.15))


func _draw() -> void:
	if _blast >= 0.0:
		var k := _blast / BLAST_TIME
		var r := BLAST_RADIUS * (0.4 + 0.8 * k)
		draw_circle(Vector2.ZERO, r, Color(color, 0.3 * (1.0 - k)))
		draw_circle(Vector2.ZERO, r * 0.7, Color(color.lightened(0.4), 0.6 * (1.0 - k)))
		draw_circle(Vector2.ZERO, r * 0.35 * (1.0 - k), Color(1, 1, 1, 0.9))
		for i in 8:
			var a := i * TAU / 8.0 + 0.3
			draw_circle(Vector2(cos(a), sin(a)) * r, 5.0 * (1.0 - k), Color(color.lightened(0.2), 1.0 - k))
		return
	draw_circle(Vector2.ZERO, 15.0, Color(color, 0.15))
	draw_set_transform(Vector2.ZERO, _spin)
	draw_potion(self, Vector2.ZERO, 1.0, color)
	draw_set_transform(Vector2.ZERO)


## A round potion bottle with a cork and a big smiley face.
## Also used by the witch while she holds one.
static func draw_potion(ci: CanvasItem, c: Vector2, sc: float, col: Color) -> void:
	var glass := Color("d9f2ff")
	var dark := Color("2a1a2e")
	# neck and cork
	ci.draw_rect(Rect2(c + Vector2(-3, -15) * sc, Vector2(6, 7) * sc), Color(glass, 0.9))
	ci.draw_rect(Rect2(c + Vector2(-4, -19) * sc, Vector2(8, 5) * sc), Color("a0703c"))
	# bottle with the brew inside
	ci.draw_circle(c, 10.0 * sc, Color(glass, 0.9))
	ci.draw_circle(c + Vector2(0, 1) * sc, 8.5 * sc, col)
	ci.draw_circle(c + Vector2(-4, -4) * sc, 2.5 * sc, Color(1, 1, 1, 0.75))
	# the smiley face
	for side in [-1.0, 1.0]:
		ci.draw_circle(c + Vector2(side * 3.2, -1.0) * sc, 1.5 * sc, dark)
	ci.draw_arc(c + Vector2(0, 1.0) * sc, 4.5 * sc, 0.25, PI - 0.25, 8, dark, 1.6 * sc)
