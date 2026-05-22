class_name LeaderAbility
extends Resource

@export var ability_name: String = ""
@export var description: String = ""

# Subclasses override the hooks they care about. `unit` is the leader the
# ability is attached to. `gs` is the GameState.

func on_unit_moved(_unit, _board, _from_tile: Vector2i, _to_tile: Vector2i, _gs) -> void:
	pass

func on_turn_started(_unit, _board, _gs) -> void:
	pass
