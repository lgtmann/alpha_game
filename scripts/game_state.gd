class_name GameState
extends Node

signal turn_started(turn: int, active_player: int)
signal turn_ended(turn: int, active_player: int)
signal energy_changed(current: int, max_value: int)
signal deck_changed(draw_count: int, discard_count: int)
signal card_played(card: CardData)
signal unit_destroyed(unit: Unit)
signal unit_damaged(unit: Unit)
signal game_ended(winner: int)
signal log_message(text: String)

const PLAYER: int = 0
const ENEMY: int = 1
const STARTING_HAND: int = 3
const ENEMY_STARTING_HAND: int = 3

# Player tech/leader-modifiable settings.
var max_hand_size: int = 7
var draw_per_turn: int = 1
var max_energy: int = 3
var max_energy_cap: int = 99
var max_units: int = 5
var player_atk_bonus: int = 0
var player_def_bonus: int = 0
var affinity_multiplier: int = 1

# Enemy-side settings (driven by enemy leader; no tech).
var enemy_max_energy: int = 3
var enemy_max_energy_cap: int = 99
var enemy_max_units: int = 5

var turn: int = 0
var energy: int = 0
var enemy_energy: int = 0
var deck: Deck
var enemy_deck: Deck = null
var enemy_hand: Array[CardData] = []
var enemy_starter_deck: Array[CardData] = []

var current_player: int = PLAYER
var winner: int = -1
var enemy_acting: bool = false

var hand: Hand
var board: Board
var run_state: RunState = null
var player_leader_data: UnitData = null
var enemy_leader_data: UnitData = null

var shard_card_for_unit: Dictionary = {}

# --- Tech / leader-stat application -----------------------------------------

func apply_tech_state() -> void:
	max_hand_size = 7
	draw_per_turn = 1
	max_energy = 3
	max_energy_cap = 99
	max_units = 5
	player_atk_bonus = 0
	player_def_bonus = 0
	affinity_multiplier = 1
	if player_leader_data != null and player_leader_data.is_deck_leader:
		max_hand_size = player_leader_data.hand_size
		max_energy = player_leader_data.energy_per_turn
		max_energy_cap = player_leader_data.max_energy_cap
		max_units = player_leader_data.max_units
	enemy_max_energy = 3
	enemy_max_energy_cap = 99
	enemy_max_units = 5
	if enemy_leader_data != null and enemy_leader_data.is_deck_leader:
		enemy_max_energy = enemy_leader_data.energy_per_turn
		enemy_max_energy_cap = enemy_leader_data.max_energy_cap
		enemy_max_units = enemy_leader_data.max_units
	if run_state == null:
		return
	max_hand_size += run_state.hand_size_bonus
	max_energy += run_state.energy_bonus
	for tech_id: StringName in run_state.unlocked_techs.keys():
		match tech_id:
			&"extra_draw":
				draw_per_turn = 2
			&"energy_surge":
				max_energy += 1
			&"bigger_hand":
				max_hand_size += 3
			&"sharpened_blades":
				player_atk_bonus += 1
			&"reinforced_armor":
				player_def_bonus += 1
			&"terrain_mastery":
				affinity_multiplier = 2

# --- Game / turn lifecycle ---------------------------------------------------

func start_game(starter_deck: Array[CardData]) -> void:
	deck = Deck.new(starter_deck)
	enemy_deck = Deck.new(enemy_starter_deck)
	enemy_hand.clear()
	turn = 1
	energy = max_energy
	enemy_energy = enemy_max_energy
	current_player = PLAYER
	winner = -1
	enemy_acting = false
	var preplaced: int = _preplace_loadout_in_hand()
	for i in range(maxi(0, STARTING_HAND - preplaced)):
		_draw_to_hand()
	for i in range(ENEMY_STARTING_HAND):
		_enemy_draw()
	_emit_state()
	turn_started.emit(turn, current_player)

func end_turn() -> void:
	if winner != -1 or enemy_acting:
		return
	turn_ended.emit(turn, current_player)
	current_player = ENEMY if current_player == PLAYER else PLAYER
	_begin_next_turn()
	if current_player == ENEMY and winner == -1:
		_run_enemy_turn()

func _begin_next_turn() -> void:
	turn += 1
	if current_player == PLAYER:
		energy = mini(energy + max_energy, max_energy_cap)
		for i in range(draw_per_turn):
			_draw_to_hand()
	else:
		enemy_energy = mini(enemy_energy + enemy_max_energy, enemy_max_energy_cap)
		_enemy_draw()
	_reset_units_for_player(current_player)
	_trigger_turn_start_abilities()
	_emit_state()
	turn_started.emit(turn, current_player)

func _reset_units_for_player(owner_id: int) -> void:
	if board == null:
		return
	for u: Unit in board.all_units():
		if u.owner_id == owner_id:
			u.mark_moved(false)
			u.mark_rotated(false)

func _trigger_turn_start_abilities() -> void:
	if board == null:
		return
	for u: Unit in board.all_units():
		if u.owner_id != current_player or u.data == null:
			continue
		if not u.data.is_deck_leader:
			continue
		for r in u.data.leader_abilities:
			var ability := r as LeaderAbility
			if ability != null:
				ability.on_turn_started(u, board, self)

func _run_enemy_turn() -> void:
	enemy_acting = true
	var ai := EnemyAI.new()
	await ai.take_turn(self)
	enemy_acting = false
	if winner == -1:
		end_turn()

# --- Cards: player ----------------------------------------------------------

func can_play_card(card: CardData) -> bool:
	return (winner == -1
		and current_player == PLAYER
		and card != null
		and energy >= card.cost)

func try_play_card(view: CardView, board_ref: Board, tile: Vector2i) -> bool:
	if view == null or view.card_data == null:
		return false
	var card := view.card_data
	if not can_play_card(card):
		return false
	if card.effect != null and not card.effect.can_target(board_ref, tile):
		return false
	if card.effect != null:
		card.effect.apply(board_ref, tile)
	energy -= card.cost
	if not card.single_use:
		deck.recycle_to_bottom(card)
	view.consume()
	card_played.emit(card)
	log_message.emit("Played %s." % card.card_name)
	_emit_state()
	return true

func _preplace_loadout_in_hand() -> int:
	if hand == null or run_state == null:
		return 0
	var added: int = 0
	for c: CardData in [run_state.first_mate, run_state.priority_cargo]:
		if c == null:
			continue
		if hand.get_child_count() >= max_hand_size:
			break
		hand.add_card(c)
		added += 1
	return added

func _draw_to_hand() -> void:
	if hand == null:
		return
	if hand.get_child_count() >= max_hand_size:
		return
	var card := deck.draw_card()
	if card == null:
		return
	hand.add_card(card)

# --- Cards: AI/enemy --------------------------------------------------------

func _enemy_draw() -> void:
	if enemy_deck == null:
		return
	if enemy_leader_data != null and enemy_hand.size() >= enemy_leader_data.hand_size:
		return
	if enemy_hand.size() >= max_hand_size:
		return
	var c := enemy_deck.draw_card()
	if c != null:
		enemy_hand.append(c)

func can_enemy_play_card(card: CardData) -> bool:
	return (winner == -1
		and current_player == ENEMY
		and card != null
		and enemy_energy >= card.cost)

func enemy_play_card(card: CardData, tile: Vector2i) -> bool:
	if not can_enemy_play_card(card):
		return false
	if card.effect != null and not card.effect.can_target(board, tile):
		return false
	if card.effect != null:
		card.effect.apply(board, tile)
	enemy_energy -= card.cost
	if not card.single_use:
		enemy_deck.recycle_to_bottom(card)
	enemy_hand.erase(card)
	log_message.emit("Enemy played %s." % card.card_name)
	return true

# --- Unit actions ------------------------------------------------------------

func attempt_move(unit: Unit, to_tile: Vector2i) -> bool:
	if winner != -1 or unit == null:
		return false
	if unit.has_moved or unit.owner_id != current_player:
		return false
	if not board.is_valid_tile(to_tile):
		return false
	if board.get_unit(to_tile) != null:
		return false
	var valid: Array[Vector2i] = (board.reachable_tiles_with_accelerators(unit)
		if unit.owner_id == PLAYER
		else board.reachable_tiles(unit.tile, unit.data.speed))
	if not valid.has(to_tile):
		return false
	var from_tile := unit.tile
	board.move_unit(unit, to_tile)
	unit.mark_moved(true)
	log_message.emit("%s moves." % unit_label(unit))
	_trigger_move_abilities(unit, from_tile, to_tile)
	return true

func _trigger_move_abilities(unit: Unit, from_tile: Vector2i, to_tile: Vector2i) -> void:
	if unit == null or unit.data == null:
		return
	for r in unit.data.leader_abilities:
		var ability := r as LeaderAbility
		if ability != null:
			ability.on_unit_moved(unit, board, from_tile, to_tile, self)

func attempt_attack(attacker: Unit, defender: Unit) -> bool:
	if winner != -1 or attacker == null or defender == null:
		return false
	if attacker.has_moved or attacker.owner_id != current_player:
		return false
	if attacker.owner_id == defender.owner_id:
		return false
	var distance: int = board.hex_distance(attacker.tile, defender.tile)
	if distance <= 0 or distance > attacker.data.attack_range:
		return false
	# Attacker pivots to face the target — they always strike with side 0.
	attacker.set_facing(board.direction_toward(attacker.tile, defender.tile))
	_resolve_combat(attacker, defender, distance)
	if is_instance_valid(attacker):
		attacker.mark_moved(true)
	return true

func _resolve_combat(attacker: Unit, defender: Unit, distance: int) -> void:
	var attacker_safe: bool = distance > defender.data.attack_range
	var atk_name := unit_label(attacker)
	var def_name := unit_label(defender)
	if board != null:
		var col: Color = Color("#ffd070") if attacker.owner_id == PLAYER else Color("#ff8050")
		board.play_projectile(attacker.tile, defender.tile, col)

	# Compute damage to defender: attacker is facing the target (side 0).
	var a_atk: int = effective_atk(attacker) + attacker.get_cannon_bonus_at_side(0)
	var def_hit_dir: int = board.direction_toward(defender.tile, attacker.tile)
	var def_hit_side: int = ((def_hit_dir - defender.facing) + 6) % 6
	var def_shield: int = defender.get_shield_at_side(def_hit_side)
	var def_damage: int = maxi(0, a_atk - def_shield)
	var def_dealt: int = defender.take_damage(def_damage)
	unit_damaged.emit(defender)
	var shield_note: String = (" (shield −%d)" % def_shield) if def_shield > 0 else ""
	log_message.emit("%s strikes %s for %d%s (%d/%d HP)." % [
		atk_name, def_name, def_dealt, shield_note, defender.current_hp, defender.get_max_hp()])

	# Counter: defender shoots back from whichever side faces the attacker.
	if not attacker_safe:
		if board != null and is_instance_valid(defender) and not defender.is_dead():
			var col_back: Color = Color("#ffd070") if defender.owner_id == PLAYER else Color("#ff8050")
			board.play_projectile(defender.tile, attacker.tile, col_back)
		var counter_side: int = ((def_hit_dir - defender.facing) + 6) % 6
		var d_atk: int = effective_atk(defender) + defender.get_cannon_bonus_at_side(counter_side)
		var atk_hit_dir: int = board.direction_toward(attacker.tile, defender.tile)
		var atk_hit_side: int = ((atk_hit_dir - attacker.facing) + 6) % 6
		var atk_shield: int = attacker.get_shield_at_side(atk_hit_side)
		var atk_damage: int = maxi(0, d_atk - atk_shield)
		var atk_dealt: int = attacker.take_damage(atk_damage)
		unit_damaged.emit(attacker)
		var atk_shield_note: String = (" (shield −%d)" % atk_shield) if atk_shield > 0 else ""
		log_message.emit("%s counters %s for %d%s (%d/%d HP)." % [
			def_name, atk_name, atk_dealt, atk_shield_note, attacker.current_hp, attacker.get_max_hp()])

	if defender.is_dead():
		destroy_unit(defender)
	if is_instance_valid(attacker) and attacker.is_dead():
		destroy_unit(attacker)

func effective_atk(u: Unit) -> int:
	var bonus: int = 0
	if _on_affinity(u):
		var mult: int = affinity_multiplier if u.owner_id == PLAYER else 1
		bonus = u.data.affinity_bonus * mult
	return u.get_atk() + bonus

func _on_affinity(u: Unit) -> bool:
	return board.get_terrain(u.tile) == u.data.terrain_affinity

func destroy_unit(u: Unit) -> void:
	var was_leader := u.data.is_deck_leader
	var dead_owner := u.owner_id
	if not was_leader and dead_owner == ENEMY and run_state != null:
		_grant_drop(u.data)
	log_message.emit("%s destroyed." % unit_label(u))
	unit_destroyed.emit(u)
	board.remove_unit(u.tile)
	if was_leader and winner == -1:
		winner = 1 - dead_owner
		game_ended.emit(winner)

func _grant_drop(data: UnitData) -> void:
	var roll: int = randi() % 6
	var shard: CardData = shard_card_for_unit.get(data)
	if roll == 0 and shard != null:
		run_state.add_shard(shard)
	else:
		var common: StringName = Resources.COMMON.pick_random()
		run_state.add_resource(common, 1)

# --- Query helpers -----------------------------------------------------------

func valid_move_tiles(unit: Unit) -> Array[Vector2i]:
	if unit == null or board == null:
		return []
	if unit.has_moved or unit.owner_id != current_player:
		return []
	if unit.owner_id == PLAYER:
		return board.reachable_tiles_with_accelerators(unit)
	return board.reachable_tiles(unit.tile, unit.data.speed)

func valid_attack_tiles(unit: Unit) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if unit == null or board == null:
		return out
	if unit.has_moved or unit.owner_id != current_player:
		return out
	for t: Vector2i in board.tiles_within_range(unit.tile, unit.data.attack_range):
		var other: Unit = board.get_unit(t)
		if other != null and other.owner_id != unit.owner_id:
			out.append(t)
	return out

# --- Misc --------------------------------------------------------------------

func _adjacent(a: Vector2i, b: Vector2i) -> bool:
	if board == null:
		return false
	return board.neighbors(a).has(b)

func _emit_state() -> void:
	energy_changed.emit(energy, max_energy)
	deck_changed.emit(deck.draw_count(), deck.discard_count())

func unit_label(u: Unit) -> String:
	var prefix := "Your" if u.owner_id == PLAYER else "Enemy"
	return "%s %s" % [prefix, u.data.unit_name]

# --- Debug -------------------------------------------------------------------

func debug_win() -> void:
	if winner != -1 or board == null:
		return
	var leader: Unit = null
	for u: Unit in board.all_units():
		if u.owner_id != ENEMY:
			continue
		if u.data.is_deck_leader:
			leader = u
		else:
			if run_state != null:
				_grant_drop(u.data)
			board.remove_unit(u.tile)
	winner = PLAYER
	if leader != null:
		unit_destroyed.emit(leader)
		board.remove_unit(leader.tile)
	game_ended.emit(winner)
