extends Control

signal returned_to_overworld
signal run_restarted

const FOREST_CARD := preload("res://cards/data/forest.tres")
const WATER_CARD := preload("res://cards/data/water.tres")
const PLAIN_CARD := preload("res://cards/data/plain.tres")
const SUMMON_KNIGHT_CARD := preload("res://cards/data/summon_knight.tres")
const SUMMON_DRAGON_CARD := preload("res://cards/data/summon_dragon.tres")
const FIREBALL_CARD := preload("res://cards/data/fireball.tres")
const WILDFIRE_CARD := preload("res://cards/data/wildfire.tres")
const BLESS_CARD := preload("res://cards/data/bless.tres")
const QUICK_STRIKE_CARD := preload("res://cards/data/quick_strike.tres")
const ARROW_CARD := preload("res://cards/data/arrow.tres")
const BOLT_CARD := preload("res://cards/data/bolt.tres")

const HERO_DATA := preload("res://units/data/hero.tres")
const DARK_LORD_DATA := preload("res://units/data/dark_lord.tres")
const DRAGON_DATA := preload("res://units/data/dragon.tres")
const KNIGHT_DATA := preload("res://units/data/knight.tres")
const FOREST_WARDEN_DATA := preload("res://units/data/forest_warden.tres")
const SEA_WITCH_DATA := preload("res://units/data/sea_witch.tres")
const STONE_LORD_DATA := preload("res://units/data/stone_lord.tres")
const CHAMPION_DATA := preload("res://units/data/champion.tres")

var is_peer_battle: bool      = false
var last_battle_winner: int   = -1

@onready var board: Board = $VBox/TopRow/BoardContainer/Board
@onready var hand: Hand = $VBox/HBoxBottom/Hand
@onready var turn_panel: TurnPanel = $VBox/HBoxBottom/TurnPanel
@onready var leader_info_panel: LeaderInfoPanel = $VBox/TopRow/RightStack/LeaderInfoPanel
@onready var inventory_panel: InventoryPanel = $VBox/TopRow/RightStack/InventoryPanel
@onready var battle_log: BattleLogPanel = $VBox/TopRow/RightStack/BattleLog
@onready var deck_view: DeckView = $VBox/HBoxBottom/DeckView
@onready var unit_list_panel: UnitListPanel = $VBox/TopRow/LeftStack/UnitListPanel
@onready var game_state: GameState = $GameState
@onready var run_state: RunState = $RunState
@onready var reward_screen: RewardScreen = $RewardScreen

func _ready() -> void:
	game_state.hand = hand
	game_state.board = board
	game_state.run_state = run_state
	game_state.player_leader_data = HERO_DATA
	game_state.shard_card_for_unit[KNIGHT_DATA] = SUMMON_KNIGHT_CARD
	game_state.shard_card_for_unit[DRAGON_DATA] = SUMMON_DRAGON_CARD
	board.game_state = game_state
	game_state.turn_started.connect(board.on_turn_started)
	game_state.game_ended.connect(_on_game_ended)
	turn_panel.bind(game_state)
	inventory_panel.bind(run_state)
	battle_log.bind(game_state)
	leader_info_panel.bind(game_state)
	deck_view.bind(game_state)
	unit_list_panel.bind(game_state)
	reward_screen.next_battle_requested.connect(_on_next_battle)
	reward_screen.restart_run_requested.connect(_on_restart_run)

func setup_run() -> void:
	var encs: Array[EncounterData] = []
	encs.append(_build_encounter_one())
	encs.append(_build_encounter_two())
	encs.append(_build_encounter_three())
	encs.append(_build_encounter_four())
	encs.append(_build_encounter_five())
	run_state.encounters = encs
	run_state.recipes = _build_recipes()
	run_state.tech_nodes = _build_tech_nodes()
	run_state.start_run(_starter_deck())

func begin_battle(enc: EncounterData) -> void:
	_start_encounter(enc)

# Starter is mostly weapons (recycle), a few summons (single-use), and a
# couple of terrain cards for board shaping.
func _starter_deck() -> Array[CardData]:
	var d: Array[CardData] = []
	for i in range(3):
		d.append(QUICK_STRIKE_CARD)
	for i in range(2):
		d.append(ARROW_CARD)
	d.append(BOLT_CARD)
	for i in range(2):
		d.append(SUMMON_KNIGHT_CARD)
	d.append(FOREST_CARD)
	d.append(WATER_CARD)
	return d

func _build_recipes() -> Array[CraftingRecipe]:
	var out: Array[CraftingRecipe] = []
	out.append(_make_recipe(QUICK_STRIKE_CARD, {Resources.WOOD: 1}))
	out.append(_make_recipe(ARROW_CARD, {Resources.WOOD: 1, Resources.IRON: 1}))
	out.append(_make_recipe(BOLT_CARD, {Resources.IRON: 2, Resources.CRYSTAL: 1}))
	out.append(_make_recipe(SUMMON_KNIGHT_CARD, {Resources.IRON: 1, Resources.STONE: 1}))
	out.append(_make_recipe(SUMMON_DRAGON_CARD, {Resources.IRON: 2, Resources.CRYSTAL: 1}))
	out.append(_make_recipe(FIREBALL_CARD, {Resources.IRON: 1, Resources.CRYSTAL: 1}))
	out.append(_make_recipe(WILDFIRE_CARD, {Resources.WOOD: 3, Resources.SOUL: 1}))
	out.append(_make_recipe(BLESS_CARD, {Resources.STONE: 2}))
	return out

func _make_recipe(card: CardData, costs: Dictionary) -> CraftingRecipe:
	var r := CraftingRecipe.new()
	r.output_card = card
	r.costs = costs
	return r

func _build_tech_nodes() -> Array[TechNode]:
	var out: Array[TechNode] = []
	out.append(_make_tech(&"extra_draw", "Extra Draw",
		"Draw 2 cards per turn instead of 1.", 1, &"economy", []))
	out.append(_make_tech(&"energy_surge", "Energy Surge",
		"Max energy +1 (4 per turn).", 2, &"economy", [&"extra_draw"]))
	out.append(_make_tech(&"bigger_hand", "Bigger Hand",
		"Max hand size 10 (was 7).", 3, &"economy", [&"energy_surge"]))
	out.append(_make_tech(&"sharpened_blades", "Sharpened Blades",
		"All your units enter play with +1 ATK.", 1, &"combat", []))
	out.append(_make_tech(&"reinforced_armor", "Reinforced Armor",
		"All your units enter play with +1 DEF.", 2, &"combat", [&"sharpened_blades"]))
	out.append(_make_tech(&"terrain_mastery", "Terrain Mastery",
		"Affinity bonus doubled for your units.", 3, &"combat", [&"reinforced_armor"]))
	return out

func _make_tech(id: StringName, name_: String, desc: String, cost: int,
		branch: StringName, prereqs: Array[StringName]) -> TechNode:
	var n := TechNode.new()
	n.id = id
	n.node_name = name_
	n.description = desc
	n.cost = cost
	n.branch = branch
	n.prerequisites = prereqs
	return n

# --- Encounters --------------------------------------------------------------

func _build_encounter_one() -> EncounterData:
	var enc := EncounterData.new()
	enc.encounter_name = "Dark Lord"
	enc.leader = _place(DARK_LORD_DATA, Vector2i(4, 1))
	enc.minions.append(_place(DRAGON_DATA, Vector2i(6, 2)))
	enc.deck = _mix({
		WATER_CARD: 2, FOREST_CARD: 1, PLAIN_CARD: 1,
		QUICK_STRIKE_CARD: 2, ARROW_CARD: 1,
		SUMMON_KNIGHT_CARD: 2,
	})
	return enc

func _build_encounter_two() -> EncounterData:
	var enc := EncounterData.new()
	enc.encounter_name = "Forest Warden"
	enc.leader = _place(FOREST_WARDEN_DATA, Vector2i(5, 1))
	enc.minions.append(_place(KNIGHT_DATA, Vector2i(3, 2)))
	enc.minions.append(_place(DRAGON_DATA, Vector2i(7, 2)))
	enc.deck = _mix({
		FOREST_CARD: 2, PLAIN_CARD: 1,
		ARROW_CARD: 2, QUICK_STRIKE_CARD: 1,
		SUMMON_DRAGON_CARD: 2,
	})
	return enc

func _build_encounter_three() -> EncounterData:
	var enc := EncounterData.new()
	enc.encounter_name = "Sea Witch"
	enc.leader = _place(SEA_WITCH_DATA, Vector2i(5, 1))
	enc.minions.append(_place(KNIGHT_DATA, Vector2i(2, 2)))
	enc.minions.append(_place(KNIGHT_DATA, Vector2i(8, 2)))
	enc.initial_terrain = {
		Vector2i(4, 0): 2,
		Vector2i(5, 0): 2,
		Vector2i(6, 0): 2,
		Vector2i(4, 1): 2,
		Vector2i(5, 1): 2,
		Vector2i(6, 1): 2,
		Vector2i(4, 2): 2,
		Vector2i(5, 2): 2,
		Vector2i(6, 2): 2,
	}
	enc.deck = _mix({
		WATER_CARD: 2, PLAIN_CARD: 1,
		ARROW_CARD: 2, BOLT_CARD: 1,
		FIREBALL_CARD: 1, SUMMON_DRAGON_CARD: 1,
	})
	return enc

func _build_encounter_four() -> EncounterData:
	var enc := EncounterData.new()
	enc.encounter_name = "Stone Lord"
	enc.leader = _place(STONE_LORD_DATA, Vector2i(4, 1))
	enc.minions.append(_place(KNIGHT_DATA, Vector2i(5, 2)))
	enc.minions.append(_place(DRAGON_DATA, Vector2i(6, 2)))
	enc.deck = _mix({
		PLAIN_CARD: 2, FOREST_CARD: 1,
		ARROW_CARD: 2, BOLT_CARD: 1,
		SUMMON_KNIGHT_CARD: 1, BLESS_CARD: 2,
	})
	return enc

func _build_encounter_five() -> EncounterData:
	var enc := EncounterData.new()
	enc.encounter_name = "Champion"
	enc.leader = _place(CHAMPION_DATA, Vector2i(5, 1))
	enc.minions.append(_place(DRAGON_DATA, Vector2i(3, 2)))
	enc.minions.append(_place(DRAGON_DATA, Vector2i(7, 2)))
	enc.minions.append(_place(KNIGHT_DATA, Vector2i(5, 3)))
	enc.initial_terrain = {
		Vector2i(3, 2): 1,
		Vector2i(7, 2): 1,
	}
	enc.deck = _mix({
		FOREST_CARD: 1, PLAIN_CARD: 1,
		BOLT_CARD: 2, WILDFIRE_CARD: 1, FIREBALL_CARD: 1,
		BLESS_CARD: 1, SUMMON_DRAGON_CARD: 1,
	})
	return enc

func _place(data: UnitData, tile: Vector2i) -> UnitPlacement:
	var p := UnitPlacement.new()
	p.unit_data = data
	p.tile = tile
	p.owner_id = GameState.ENEMY
	return p

func _mix(counts: Dictionary) -> Array[CardData]:
	var out: Array[CardData] = []
	for card: CardData in counts.keys():
		var n: int = counts[card]
		for i in range(n):
			out.append(card)
	return out

# --- Battle start ------------------------------------------------------------

func _start_encounter(enc: EncounterData) -> void:
	if enc == null:
		return
	board.clear_battle_state()
	for tile_key in enc.initial_terrain.keys():
		if tile_key is Vector2i:
			board.set_terrain(tile_key, enc.initial_terrain[tile_key])
	for child in hand.get_children():
		child.queue_free()
	game_state.winner = -1
	game_state.enemy_acting = false
	run_state.clear_battle_log()
	battle_log.clear()
	game_state.enemy_leader_data = enc.leader.unit_data if enc.leader != null else null
	game_state.enemy_starter_deck = enc.deck.duplicate()
	game_state.apply_tech_state()
	var hero_unit: Unit = board.add_unit(HERO_DATA, GameState.PLAYER, Vector2i(5, 7))
	if hero_unit != null and run_state.hero_sides.size() > 0:
		hero_unit.sides = _duplicate_sides(run_state.hero_sides)
		hero_unit.queue_redraw()
	if enc.leader != null and enc.leader.unit_data != null:
		board.add_unit(enc.leader.unit_data, enc.leader.owner_id, enc.leader.tile)
	for placement: UnitPlacement in enc.minions:
		if placement != null and placement.unit_data != null:
			board.add_unit(placement.unit_data, placement.owner_id, placement.tile)
	game_state.start_game(run_state.player_deck.duplicate())

func _on_game_ended(winner: int) -> void:
	last_battle_winner = winner
	if winner == GameState.PLAYER:
		var enc := run_state.current_encounter()
		var enemy_deck: Array[CardData] = []
		if enc != null:
			enemy_deck = enc.deck.duplicate()
		reward_screen.show_victory(enemy_deck, run_state, run_state.is_final_encounter())
	else:
		reward_screen.show_defeat()

func _on_next_battle() -> void:
	if not is_peer_battle:
		run_state.advance_encounter()
	is_peer_battle = false
	returned_to_overworld.emit()

func _on_restart_run() -> void:
	is_peer_battle = false
	last_battle_winner = -1
	setup_run()
	run_restarted.emit()
	returned_to_overworld.emit()

func build_peer_encounter() -> EncounterData:
	var enc := EncounterData.new()
	enc.encounter_name = "Peer Warrior"
	enc.leader = _place(KNIGHT_DATA, Vector2i(5, 1))
	enc.deck = _mix({
		QUICK_STRIKE_CARD: 3,
		ARROW_CARD: 2,
	})
	return enc


func _duplicate_sides(sides: Array[SideUpgrade]) -> Array[SideUpgrade]:
	var out: Array[SideUpgrade] = []
	for s: SideUpgrade in sides:
		if s == null:
			out.append(SideUpgrade.new())
			continue
		var copy := SideUpgrade.new()
		copy.type = s.type
		copy.strength = s.strength
		out.append(copy)
	return out
