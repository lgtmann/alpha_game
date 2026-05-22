class_name HighlightLayer
extends Node2D

const MOVE_COLOR := Color(0.40, 0.95, 0.45, 0.45)
const ATTACK_COLOR := Color(1.00, 0.30, 0.30, 0.50)
const SELECT_COLOR := Color(1.00, 0.90, 0.20, 0.30)

var tile_map_layer_ref: TileMapLayer = null
var move_tiles: Array[Vector2i] = []
var attack_tiles: Array[Vector2i] = []
var select_tile: Vector2i = Vector2i(-1, -1)

func setup(layer: TileMapLayer) -> void:
	tile_map_layer_ref = layer

func set_highlights(moves: Array[Vector2i], attacks: Array[Vector2i], selected: Vector2i) -> void:
	move_tiles = moves
	attack_tiles = attacks
	select_tile = selected
	queue_redraw()

func clear() -> void:
	set_highlights([], [], Vector2i(-1, -1))

func _draw() -> void:
	if tile_map_layer_ref == null or tile_map_layer_ref.tile_set == null:
		return
	var radius: float = tile_map_layer_ref.tile_set.tile_size.y / 2.0
	if select_tile.x >= 0:
		_draw_hex(select_tile, radius, SELECT_COLOR)
	for t: Vector2i in move_tiles:
		_draw_hex(t, radius, MOVE_COLOR)
	for t: Vector2i in attack_tiles:
		_draw_hex(t, radius, ATTACK_COLOR)

func _draw_hex(tile: Vector2i, radius: float, color: Color) -> void:
	var center := tile_map_layer_ref.map_to_local(tile)
	var poly := PackedVector2Array()
	for i in range(6):
		var angle := -PI / 2.0 + i * PI / 3.0
		poly.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(poly, color)
