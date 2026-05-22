class_name DamageEffect
extends CardEffect

@export var damage: int = 3
@export var enemy_only: bool = true

func apply(board, tile: Vector2i) -> void:
	var u: Unit = board.get_unit(tile)
	if u == null:
		return
	var gs: GameState = board.game_state
	var dealt: int = u.take_damage(damage)
	if gs != null:
		gs.log_message.emit("Spell hits %s for %d (%d HP left)." % [
			gs.unit_label(u), dealt, u.current_hp])
		gs.unit_damaged.emit(u)
		if u.is_dead():
			gs.destroy_unit(u)

func can_target(board, tile: Vector2i) -> bool:
	if not board.is_valid_tile(tile):
		return false
	var u: Unit = board.get_unit(tile)
	if u == null:
		return false
	if enemy_only:
		var gs: GameState = board.game_state
		if gs != null and u.owner_id == gs.current_player:
			return false
	return true

func summary() -> String:
	return "Deal %d damage" % damage
