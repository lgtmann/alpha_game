class_name UnitData
extends Resource

@export var unit_name: String = "Unnamed"
@export var atk: int = 1
@export var max_hp: int = 1
@export var terrain_affinity: int = -1
@export var affinity_bonus: int = 0
@export var is_deck_leader: bool = false
@export var attack_range: int = 1
@export var speed: int = 1

# ── Leader-only stats (used when is_deck_leader == true) ─────────────────────
@export var hand_size: int = 7
@export var energy_per_turn: int = 3
@export var max_energy_cap: int = 99
@export var max_units: int = 5
@export var leader_abilities: Array[LeaderAbility] = []

# Per-side upgrades. If empty, this unit has no directional upgrades and
# behaves like a vanilla unit (no shields, no bonus cannons, no accelerators).
# Hero's sides come from RunState.hero_sides (configurable via the editor);
# other units stay empty by default.
@export var sides: Array[SideUpgrade] = []
