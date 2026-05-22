class_name AreaTerrainEffect
extends CardEffect

const TERRAIN_NAMES := {0: "plains", 1: "forest", 2: "water"}

@export var terrain_id: int = 1

func apply(board, tile: Vector2i) -> void:
	if not board.is_valid_tile(tile):
		return
	board.set_terrain(tile, terrain_id)
	for n: Vector2i in board.neighbors(tile):
		board.set_terrain(n, terrain_id)

func can_target(board, tile: Vector2i) -> bool:
	return board.is_valid_tile(tile)

func summary() -> String:
	var name_: String = TERRAIN_NAMES.get(terrain_id, "tile")
	return "Area: %s + neighbors" % name_
