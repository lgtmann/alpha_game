class_name SpawnUnitEffect
extends CardEffect

@export var unit_data: UnitData

func apply(board, tile: Vector2i) -> void:
	if unit_data == null:
		return
	var owner_id := 0
	if board.game_state != null:
		owner_id = board.game_state.current_player
	board.add_unit(unit_data, owner_id, tile)

func can_target(board, tile: Vector2i) -> bool:
	if not board.is_valid_tile(tile):
		return false
	if board.get_unit(tile) != null:
		return false
	var owner_id := 0
	var gs: GameState = board.game_state
	if gs != null:
		owner_id = gs.current_player
		# Communication channels — leader-driven cap on friendly units.
		var cap: int = gs.max_units if owner_id == GameState.PLAYER else gs.enemy_max_units
		if board.count_units(owner_id) >= cap:
			return false
	return board.has_adjacent_friendly(tile, owner_id)

func summary() -> String:
	if unit_data == null:
		return ""
	var parts: Array[String] = []
	parts.append("%d/%d" % [unit_data.atk, unit_data.max_hp])
	var badges: Array[String] = []
	if unit_data.attack_range > 1:
		badges.append("R%d" % unit_data.attack_range)
	if unit_data.speed > 1:
		badges.append("S%d" % unit_data.speed)
	if badges.size() > 0:
		parts.append(" ".join(badges))
	return "  ".join(parts)
