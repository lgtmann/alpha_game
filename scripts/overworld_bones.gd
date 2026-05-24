class_name OverworldBones
extends Node2D

const TILE_SIZE: int = 48

var tile_pos: Vector2i = Vector2i.ZERO

func setup(tp: Vector2i) -> void:
	tile_pos = tp
	position = Vector2(tp.x * TILE_SIZE + TILE_SIZE / 2.0,
					   tp.y * TILE_SIZE + TILE_SIZE / 2.0)
	queue_redraw()

func _draw() -> void:
	var bone_col := Color(0.85, 0.83, 0.72, 0.88)
	var dark_col := Color(0.12, 0.10, 0.10, 1.0)
	# Skull body
	draw_circle(Vector2(0.0, -4.0), 5.0, bone_col)
	# Eye sockets
	draw_circle(Vector2(-1.8, -5.0), 1.4, dark_col)
	draw_circle(Vector2(1.8, -5.0), 1.4, dark_col)
	# Jaw
	draw_line(Vector2(-3.0, -1.5), Vector2(3.0, -1.5), Color(bone_col, 0.6), 1.0)
	# Left crossed bone
	draw_line(Vector2(-7.0, 2.0), Vector2(-2.0, 8.0), bone_col, 2.0)
	draw_circle(Vector2(-7.0, 2.0), 2.2, bone_col)
	draw_circle(Vector2(-2.0, 8.0), 2.2, bone_col)
	# Right crossed bone
	draw_line(Vector2(2.0, 2.0), Vector2(7.0, 8.0), bone_col, 2.0)
	draw_circle(Vector2(2.0, 2.0), 2.2, bone_col)
	draw_circle(Vector2(7.0, 8.0), 2.2, bone_col)
