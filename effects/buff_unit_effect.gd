class_name BuffUnitEffect
extends CardEffect

@export var atk_delta: int = 1
@export var hp_delta: int = 1
@export var friendly_only: bool = true

func apply(board, tile: Vector2i) -> void:
	var u: Unit = board.get_unit(tile)
	if u == null:
		return
	u.add_buff(atk_delta, hp_delta)

func can_target(board, tile: Vector2i) -> bool:
	if not board.is_valid_tile(tile):
		return false
	var u: Unit = board.get_unit(tile)
	if u == null:
		return false
	if friendly_only:
		var gs: GameState = board.game_state
		if gs != null and u.owner_id != gs.current_player:
			return false
	return true

func summary() -> String:
	var parts: Array[String] = []
	if atk_delta != 0:
		parts.append("%+d ATK" % atk_delta)
	if hp_delta != 0:
		parts.append("%+d HP" % hp_delta)
	return " / ".join(parts)
