extends AnimatableBody2D
## A floating platform that slides back and forth (axis "h") or up and
## down (axis "v"). You can jump up through it from below.

@export var width_tiles := 3
@export var axis := "h"
@export var travel := 128.0  # pixels
@export var period := 4.0  # seconds for a full round trip
var color := Color("6e5640")

var _origin := Vector2.ZERO
var _t := 0.0


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	sync_to_physics = true
	var w := width_tiles * 32.0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(w, 12)
	shape.shape = rect
	shape.position = Vector2(w * 0.5, 6)
	shape.one_way_collision = true
	add_child(shape)
	_origin = position


func _physics_process(delta: float) -> void:
	_t += delta
	var k := 0.5 - 0.5 * cos(_t * TAU / period)
	if axis == "v":
		position = _origin + Vector2(0, -travel * k)
	else:
		position = _origin + Vector2(travel * k, 0)


func _draw() -> void:
	var w := width_tiles * 32.0
	draw_rect(Rect2(0, 0, w, 12), color.darkened(0.35))
	draw_rect(Rect2(0, 0, w, 8), color)
	draw_rect(Rect2(0, 0, w, 2), color.lightened(0.3))
	for i in width_tiles:
		draw_circle(Vector2(i * 32 + 16, 5), 2.0, color.darkened(0.5))
	# little ghostly glow underneath so it reads as magic
	draw_rect(Rect2(4, 12, w - 8, 3), Color(Config.COLOR_PURPLE, 0.35))
