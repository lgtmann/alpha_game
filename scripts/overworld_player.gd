class_name OverworldPlayer
extends Node2D

const TILE_SIZE: int = 48
const MOVE_DURATION: float = 0.12

var tile_pos: Vector2i = Vector2i(11, 19)
var _moving: bool = false
var _facing: Vector2i = Vector2i(0, -1)

func _ready() -> void:
	position = Vector2(tile_pos.x * TILE_SIZE + TILE_SIZE / 2.0,
					   tile_pos.y * TILE_SIZE + TILE_SIZE / 2.0)
	var cam := Camera2D.new()
	cam.zoom = Vector2(2.0, 2.0)
	add_child(cam)
	z_index = 1

func move_to(target: Vector2i) -> void:
	if _moving:
		return
	var delta := target - tile_pos
	if delta != Vector2i.ZERO:
		_facing = delta
	tile_pos = target
	_moving = true
	var world_pos := Vector2(target.x * TILE_SIZE + TILE_SIZE / 2.0,
							 target.y * TILE_SIZE + TILE_SIZE / 2.0)
	var tween := create_tween()
	tween.tween_property(self, "position", world_pos, MOVE_DURATION)
	tween.tween_callback(func() -> void: _moving = false)
	queue_redraw()

func is_moving() -> bool:
	return _moving

func _draw() -> void:
	var r: float = TILE_SIZE * 0.35
	draw_circle(Vector2.ZERO, r, Color("#3a8fd4"))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 24, Color("#2060a0"), 2.0)
	var facing_f := Vector2(_facing.x, _facing.y).normalized()
	var eye_pos := facing_f * (r * 0.55)
	draw_circle(eye_pos, r * 0.25, Color("#ffffff"))
