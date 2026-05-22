class_name EnemyAI
extends RefCounted

const ACTION_DELAY: float = 0.4
const CARD_DELAY: float = 0.35
const MAX_CARDS_PER_TURN: int = 4

func take_turn(gs: GameState) -> void:
	var board: Board = gs.board
	if board == null:
		return
	# Phase 1: play cards from enemy hand while energy + targets permit.
	await _play_cards_phase(gs, board)
	if gs.winner != -1:
		return
	# Phase 2: move and attack with units.
	var leader: Unit = _find_leader(board, GameState.PLAYER)
	var enemies: Array[Unit] = []
	for u: Unit in board.all_units():
		if u.owner_id == GameState.ENEMY:
			enemies.append(u)

	for unit: Unit in enemies:
		if gs.winner != -1:
			return
		if not is_instance_valid(unit):
			continue
		if unit.has_moved:
			continue
		await gs.get_tree().create_timer(ACTION_DELAY).timeout

		var target: Unit = _find_attack_target(gs, unit)
		if target != null:
			gs.attempt_attack(unit, target)
			continue

		if leader == null or not is_instance_valid(leader):
			continue
		var move_to := _best_move_toward(board, unit, leader.tile)
		if move_to.x >= 0:
			gs.attempt_move(unit, move_to)

# --- Card-play phase -------------------------------------------------------

func _play_cards_phase(gs: GameState, board: Board) -> void:
	var my_leader: Unit = _find_leader(board, GameState.ENEMY)
	var their_leader: Unit = _find_leader(board, GameState.PLAYER)
	for i in range(MAX_CARDS_PER_TURN):
		var pick := _pick_card_play(gs, board, my_leader, their_leader)
		if pick.is_empty():
			return
		await gs.get_tree().create_timer(CARD_DELAY).timeout
		if gs.winner != -1:
			return
		gs.enemy_play_card(pick.get("card"), pick.get("tile"))

func _pick_card_play(gs: GameState, board: Board,
		my_leader: Unit, their_leader: Unit) -> Dictionary:
	# Prefer weapons → summons → terrain.
	var candidates := gs.enemy_hand.duplicate()
	var ordered: Array[CardData] = []
	for c: CardData in candidates:
		if c.effect is WeaponEffect:
			ordered.append(c)
	for c: CardData in candidates:
		if c.effect is SpawnUnitEffect:
			ordered.append(c)
	for c: CardData in candidates:
		if c.effect is PlaceTerrainEffect or c.effect is AreaTerrainEffect:
			ordered.append(c)
	for c: CardData in candidates:
		if c.effect is DamageEffect:
			ordered.append(c)
	for card: CardData in ordered:
		if card.cost > gs.enemy_energy:
			continue
		var tile := _find_target_for_card(gs, board, card, my_leader, their_leader)
		if tile.x < 0:
			continue
		return {"card": card, "tile": tile}
	return {}

func _find_target_for_card(gs: GameState, board: Board, card: CardData,
		my_leader: Unit, their_leader: Unit) -> Vector2i:
	var effect := card.effect
	if effect == null:
		return Vector2i(-1, -1)
	if effect is WeaponEffect:
		return _find_weapon_target(board, effect as WeaponEffect, my_leader)
	if effect is SpawnUnitEffect:
		return _find_summon_target(gs, board, my_leader, their_leader)
	if effect is PlaceTerrainEffect:
		return _find_terrain_target(board, (effect as PlaceTerrainEffect).terrain_id, my_leader)
	if effect is AreaTerrainEffect:
		return _find_terrain_target(board, (effect as AreaTerrainEffect).terrain_id, my_leader)
	if effect is DamageEffect:
		return _find_damage_target(board, effect as DamageEffect)
	return Vector2i(-1, -1)

func _find_weapon_target(board: Board, weapon: WeaponEffect, my_leader: Unit) -> Vector2i:
	if my_leader == null:
		return Vector2i(-1, -1)
	var best := Vector2i(-1, -1)
	var best_score: int = -1
	for t: Vector2i in board.tiles_within_range(my_leader.tile, weapon.range_):
		var u: Unit = board.get_unit(t)
		if u == null or u.owner_id == GameState.ENEMY:
			continue
		var score: int = 100 - u.current_hp  # prefer low-HP targets
		if u.data.is_deck_leader:
			score += 1000
		if score > best_score:
			best_score = score
			best = t
	return best

func _find_summon_target(gs: GameState, board: Board, my_leader: Unit, their_leader: Unit) -> Vector2i:
	if my_leader == null or their_leader == null:
		return Vector2i(-1, -1)
	if board.count_units(GameState.ENEMY) >= gs.enemy_max_units:
		return Vector2i(-1, -1)
	# Empty tile adjacent to any enemy unit, closest to the player's leader.
	var best := Vector2i(-1, -1)
	var best_dist: int = 9999
	for u: Unit in board.all_units():
		if u.owner_id != GameState.ENEMY:
			continue
		for n: Vector2i in board.neighbors(u.tile):
			if board.get_unit(n) != null:
				continue
			var dist: int = board.hex_distance(n, their_leader.tile)
			if dist < best_dist:
				best_dist = dist
				best = n
	return best

func _find_terrain_target(board: Board, terrain_id: int, my_leader: Unit) -> Vector2i:
	# Convert leader's own tile to favoured terrain if not already.
	if my_leader == null:
		return Vector2i(-1, -1)
	if my_leader.data.terrain_affinity == terrain_id and board.get_terrain(my_leader.tile) != terrain_id:
		return my_leader.tile
	return Vector2i(-1, -1)

func _find_damage_target(board: Board, dmg: DamageEffect) -> Vector2i:
	# Pick the player unit that would die (or take most damage relative to HP).
	var best := Vector2i(-1, -1)
	var best_score: float = -1.0
	for u: Unit in board.all_units():
		if u.owner_id == GameState.ENEMY:
			continue
		var score: float = float(mini(dmg.damage, u.current_hp)) / float(maxi(1, u.get_max_hp()))
		if u.data.is_deck_leader:
			score += 10.0
		if score > best_score:
			best_score = score
			best = u.tile
	return best

# --- Existing unit AI ------------------------------------------------------

func _find_leader(board: Board, owner_id: int) -> Unit:
	for u: Unit in board.all_units():
		if u.owner_id == owner_id and u.data.is_deck_leader:
			return u
	return null

# Only picks attacks expected to deal at least some damage; prefers safe ones.
func _find_attack_target(gs: GameState, unit: Unit) -> Unit:
	var board: Board = gs.board
	var best: Unit = null
	var best_score: int = -1
	for t: Vector2i in board.tiles_within_range(unit.tile, unit.data.attack_range):
		var other: Unit = board.get_unit(t)
		if other == null or other.owner_id == unit.owner_id:
			continue
		var my_atk: int = gs.effective_atk(unit)
		if my_atk <= 0:
			continue
		var distance: int = board.hex_distance(unit.tile, other.tile)
		var attacker_safe: bool = distance > other.data.attack_range
		# If the trade would kill us without killing them, skip it.
		var their_atk: int = gs.effective_atk(other)
		if not attacker_safe and their_atk >= unit.current_hp and my_atk < other.current_hp:
			continue
		var score: int = my_atk
		if other.data.is_deck_leader:
			score += 1000
		if attacker_safe:
			score += 50
		# Killing blows are great.
		if my_atk >= other.current_hp:
			score += 200
		if score > best_score:
			best_score = score
			best = other
	return best

func _best_move_toward(board: Board, unit: Unit, goal: Vector2i) -> Vector2i:
	var goal_pos := board.tile_map_layer.map_to_local(goal)
	var best := Vector2i(-1, -1)
	var best_dist: float = INF
	for t: Vector2i in board.reachable_tiles(unit.tile, unit.data.speed):
		var d := board.tile_map_layer.map_to_local(t).distance_squared_to(goal_pos)
		if d < best_dist:
			best_dist = d
			best = t
	return best
