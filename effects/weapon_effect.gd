class_name WeaponEffect
extends CardEffect

@export var attack: int = 3
@export var range_: int = 2

func can_target(board, tile: Vector2i) -> bool:
	if not board.is_valid_tile(tile):
		return false
	var target: Unit = board.get_unit(tile)
	if target == null:
		return false
	var gs: GameState = board.game_state
	if gs == null:
		return false
	if target.owner_id == gs.current_player:
		return false
	var leader := _find_leader(board, gs.current_player)
	if leader == null:
		return false
	var distance: int = board.hex_distance(leader.tile, tile)
	return distance > 0 and distance <= range_

func apply(board, tile: Vector2i) -> void:
	var target: Unit = board.get_unit(tile)
	if target == null:
		return
	var gs: GameState = board.game_state
	if gs == null:
		return
	var leader := _find_leader(board, gs.current_player)
	if leader == null:
		return
	board.play_projectile(leader.tile, tile, Color("#ffe080"))
	var dealt: int = target.take_damage(attack)
	gs.log_message.emit("%s strikes %s for %d (%d HP left)." % [
		gs.unit_label(leader), gs.unit_label(target), dealt, target.current_hp])
	gs.unit_damaged.emit(target)
	if target.is_dead():
		gs.destroy_unit(target)

func summary() -> String:
	return "ATK %d  RNG %d" % [attack, range_]

func _find_leader(board, owner_id: int) -> Unit:
	for u: Unit in board.all_units():
		if u.owner_id == owner_id and u.data.is_deck_leader:
			return u
	return null
