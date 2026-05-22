class_name RunState
extends Node

signal player_deck_changed
signal inventory_changed
signal shards_changed
signal tech_changed
signal hero_sides_changed
signal leader_loadout_changed

const HAND_SIZE_BONUS_MAX: int = 5
const ENERGY_BONUS_MAX: int = 3

var encounters: Array[EncounterData] = []
var recipes: Array[CraftingRecipe] = []
var tech_nodes: Array[TechNode] = []
var player_deck: Array[CardData] = []
var encounter_index: int = 0

var inventory: Dictionary = {}    # StringName -> int
var shards: Dictionary = {}       # CardData -> int (0-2)
var tech_points: int = 0
var unlocked_techs: Dictionary = {}  # StringName -> true

# Hero's per-side upgrade configuration (length 6).
var hero_sides: Array[SideUpgrade] = []

# Leader loadout: cards that start in hand each round, plus stat bonuses.
var first_mate: CardData = null
var priority_cargo: CardData = null
var hand_size_bonus: int = 0
var energy_bonus: int = 0

var last_battle_resources: Dictionary = {}
var last_battle_shards: Dictionary = {}
var last_battle_cards_unlocked: Array[CardData] = []

func start_run(starter_deck: Array[CardData]) -> void:
	player_deck = starter_deck.duplicate()
	encounter_index = 0
	inventory.clear()
	shards.clear()
	tech_points = 0
	unlocked_techs.clear()
	hero_sides = _default_hero_sides()
	first_mate = _default_first_mate()
	priority_cargo = _default_priority_cargo()
	hand_size_bonus = 0
	energy_bonus = 0
	clear_battle_log()
	player_deck_changed.emit()
	inventory_changed.emit()
	shards_changed.emit()
	tech_changed.emit()
	hero_sides_changed.emit()
	leader_loadout_changed.emit()

func _default_first_mate() -> CardData:
	for c: CardData in player_deck:
		if is_unit_card(c):
			return c
	return null

func _default_priority_cargo() -> CardData:
	for c: CardData in player_deck:
		if c != null and not is_unit_card(c):
			return c
	return null

static func is_unit_card(c: CardData) -> bool:
	return c != null and c.effect != null and c.effect is SpawnUnitEffect

func _default_hero_sides() -> Array[SideUpgrade]:
	var out: Array[SideUpgrade] = []
	for i in range(6):
		out.append(SideUpgrade.new())
	out[0].type = SideUpgrade.Type.CANNON
	out[0].strength = 1
	out[3].type = SideUpgrade.Type.SHIELD
	out[3].strength = 1
	return out

func set_first_mate(card: CardData) -> void:
	first_mate = card
	leader_loadout_changed.emit()

func set_priority_cargo(card: CardData) -> void:
	priority_cargo = card
	leader_loadout_changed.emit()

func set_hand_size_bonus(n: int) -> void:
	hand_size_bonus = clampi(n, 0, HAND_SIZE_BONUS_MAX)
	leader_loadout_changed.emit()

func set_energy_bonus(n: int) -> void:
	energy_bonus = clampi(n, 0, ENERGY_BONUS_MAX)
	leader_loadout_changed.emit()

func set_hero_side(index: int, type_: int, strength: int) -> void:
	while hero_sides.size() <= index:
		hero_sides.append(SideUpgrade.new())
	if hero_sides[index] == null:
		hero_sides[index] = SideUpgrade.new()
	hero_sides[index].type = type_
	hero_sides[index].strength = strength
	hero_sides_changed.emit()

func clear_battle_log() -> void:
	last_battle_resources.clear()
	last_battle_shards.clear()
	last_battle_cards_unlocked.clear()

func current_encounter() -> EncounterData:
	if encounter_index < 0 or encounter_index >= encounters.size():
		return null
	return encounters[encounter_index]

func advance_encounter() -> bool:
	encounter_index += 1
	return encounter_index < encounters.size()

func is_final_encounter() -> bool:
	return encounter_index + 1 >= encounters.size()

func add_card(card: CardData) -> void:
	if card == null:
		return
	player_deck.append(card)
	player_deck_changed.emit()

func add_resource(name: StringName, amount: int) -> void:
	if amount <= 0:
		return
	inventory[name] = inventory.get(name, 0) + amount
	last_battle_resources[name] = last_battle_resources.get(name, 0) + amount
	inventory_changed.emit()

func add_shard(card: CardData) -> void:
	if card == null:
		return
	shards[card] = shards.get(card, 0) + 1
	last_battle_shards[card] = last_battle_shards.get(card, 0) + 1
	if shards[card] >= 3:
		shards[card] = 0
		player_deck.append(card)
		last_battle_cards_unlocked.append(card)
		player_deck_changed.emit()
	shards_changed.emit()

func get_resource_count(name: StringName) -> int:
	return inventory.get(name, 0)

func get_shard_count(card: CardData) -> int:
	if card == null:
		return 0
	return shards.get(card, 0)

func craft(recipe: CraftingRecipe) -> bool:
	if recipe == null or recipe.output_card == null:
		return false
	if not recipe.can_afford(inventory):
		return false
	recipe.spend(inventory)
	inventory_changed.emit()
	add_card(recipe.output_card)
	return true

# --- Tech --------------------------------------------------------------------

func is_tech_unlocked(id: StringName) -> bool:
	return unlocked_techs.get(id, false)

func tech_prereqs_met(node: TechNode) -> bool:
	if node == null:
		return false
	for prereq: StringName in node.prerequisites:
		if not is_tech_unlocked(prereq):
			return false
	return true

func unlock_tech(node: TechNode) -> bool:
	if node == null:
		return false
	if is_tech_unlocked(node.id):
		return false
	if tech_points < node.cost:
		return false
	if not tech_prereqs_met(node):
		return false
	tech_points -= node.cost
	unlocked_techs[node.id] = true
	tech_changed.emit()
	return true

func add_tech_points(n: int) -> void:
	if n <= 0:
		return
	tech_points += n
	tech_changed.emit()

func find_tech_node(id: StringName) -> TechNode:
	for n: TechNode in tech_nodes:
		if n.id == id:
			return n
	return null
