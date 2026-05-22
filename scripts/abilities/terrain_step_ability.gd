class_name TerrainStepAbility
extends LeaderAbility

# The terrain id (0 plains, 1 forest, 2 water) the tile under the leader
# becomes when they move.
@export var terrain_id: int = 2

func on_unit_moved(unit, board, _from_tile: Vector2i, to_tile: Vector2i, _gs) -> void:
	if unit == null or unit.data == null or not unit.data.is_deck_leader:
		return
	board.set_terrain(to_tile, terrain_id)
