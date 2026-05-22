class_name TerrainLayer
extends Node2D

const TERRAIN_COLORS := [
	Color("#7ec850"),  # 0: plains
	Color("#2d5a27"),  # 1: forest
	Color("#3a78b5"),  # 2: water
]
const BORDER_COLOR := Color(0, 0, 0, 0.55)

var tile_map_layer_ref: TileMapLayer = null
var terrain_ref: Dictionary = {}

func setup(layer: TileMapLayer, terrain_dict: Dictionary) -> void:
	tile_map_layer_ref = layer
	terrain_ref = terrain_dict

func refresh() -> void:
	queue_redraw()

func _draw() -> void:
	if tile_map_layer_ref == null or tile_map_layer_ref.tile_set == null:
		return
	var radius: float = tile_map_layer_ref.tile_set.tile_size.y / 2.0
	for tile: Vector2i in terrain_ref.keys():
		var id: int = terrain_ref[tile]
		var color: Color = TERRAIN_COLORS[id] if id >= 0 and id < TERRAIN_COLORS.size() else Color.MAGENTA
		var poly := _hex_points(tile, radius)
		draw_colored_polygon(poly, color)
		var border := poly.duplicate()
		border.append(poly[0])
		draw_polyline(border, BORDER_COLOR, 1.5, true)

func _hex_points(tile: Vector2i, radius: float) -> PackedVector2Array:
	var center := tile_map_layer_ref.map_to_local(tile)
	var poly := PackedVector2Array()
	for i in range(6):
		var angle := -PI / 2.0 + i * PI / 3.0
		poly.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return poly
