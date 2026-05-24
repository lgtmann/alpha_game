class_name DeathRegistry
extends RefCounted

## Thin wrapper around SaveData scoped to the active save slot.
## Set active_slot (done by game_root when the player picks a slot on the title screen)
## before calling any method.  All callers in game_root / overworld keep working
## without change — they never need to know which slot is active.

static var active_slot: int = 1


static func record_death(level_id: String, tile_pos: Vector2i) -> void:
	SaveData.record_death(active_slot, level_id, tile_pos)


static func get_deaths_for_level(level_id: String) -> Array[Vector2i]:
	return SaveData.get_deaths(active_slot, level_id)


## Increments warriors_escaped + runs_completed. Returns new escape count.
static func record_escape() -> int:
	return SaveData.record_escape(active_slot)


static func warriors_escaped() -> int:
	return SaveData.warriors_escaped(active_slot)
