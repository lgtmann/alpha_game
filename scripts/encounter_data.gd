class_name EncounterData
extends Resource

@export var encounter_name: String = "Encounter"
@export var leader: UnitPlacement
@export var minions: Array[UnitPlacement] = []
@export var deck: Array[CardData] = []
# Optional terrain overrides applied after clear_battle_state. Keys are tiles.
# Values are terrain ids (0=plains, 1=forest, 2=water).
@export var initial_terrain: Dictionary = {}
