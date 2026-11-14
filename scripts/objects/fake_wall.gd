extends Node2D
## Fake walls (`%` in a level): they look exactly like ground, but nothing is
## there, so you can walk (or fall) straight through them. Great for secret
## rooms. The blocks right around the skull turn see-through while you're
## inside, so you can see where you are. Drawn above everything else, so a
## gem or a snake hiding inside one stays hidden until you get there.

const TileChunk = preload("res://scripts/tile_chunk.gd")
const T := 32.0

var grid: Array = []
var colors := {}
var player: Node2D

var _cells: Array[Vector2i] = []
var _alpha: Array[float] = []


func _ready() -> void:
	z_index = 5
	for y in grid.size():
		var row: String = grid[y]
		for x in row.length():
			if row[x] == "%":
				_cells.append(Vector2i(x, y))
				_alpha.append(1.0)


func _process(delta: float) -> void:
	if player == null:
		return
	var p := player.global_position
	var changed := false
	for i in _cells.size():
		var centre := (Vector2(_cells[i]) + Vector2(0.5, 0.5)) * T
		var d := p.distance_to(centre)
		# fully see-through when you're right there, back to normal 2 tiles away
		var target := lerpf(0.3, 1.0, clampf((d - 24.0) / 40.0, 0.0, 1.0))
		var a := move_toward(_alpha[i], target, delta * 3.0)
		if a != _alpha[i]:
			_alpha[i] = a
			changed = true
	if changed:
		queue_redraw()


func _draw() -> void:
	for i in _cells.size():
		TileChunk.draw_block(self, grid, _cells[i].x, _cells[i].y, colors, _alpha[i])
