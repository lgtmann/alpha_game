class_name PlaceTerrainEffect
extends CardEffect

@export var terrain_id: int = 1

func apply(board, tile: Vector2i) -> void:
	board.set_terrain(tile, terrain_id)
