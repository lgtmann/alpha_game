class_name SaveData
extends RefCounted

## Per-slot persistent save data.
## Each slot is stored at user://save_slot_N.json (N = 1, 2, or 3).
## Tracks warriors_escaped, runs_completed, and per-level death tile positions.

const SLOT_COUNT: int = 3


static func slot_path(slot: int) -> String:
	return "user://save_slot_%d.json" % slot


static func exists(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))


static func load_slot(slot: int) -> Dictionary:
	if not exists(slot):
		return _empty()
	var f := FileAccess.open(slot_path(slot), FileAccess.READ)
	if f == null:
		return _empty()
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	return _empty()


static func save_slot(slot: int, data: Dictionary) -> void:
	var f := FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if f == null:
		push_error("SaveData: cannot write " + slot_path(slot))
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()


## Lightweight summary for UI — {exists, warriors_escaped, runs_completed}.
static func get_summary(slot: int) -> Dictionary:
	if not exists(slot):
		return {exists = false, warriors_escaped = 0, runs_completed = 0}
	var d := load_slot(slot)
	return {
		exists           = true,
		warriors_escaped = d.get("warriors_escaped", 0),
		runs_completed   = d.get("runs_completed", 0),
	}


## Delete a slot's save file.
static func delete_slot(slot: int) -> void:
	if exists(slot):
		DirAccess.remove_absolute(slot_path(slot))


# ── death tracking ────────────────────────────────────────────────────────────

static func record_death(slot: int, level_id: String, tile_pos: Vector2i) -> void:
	var d := load_slot(slot)
	var deaths: Dictionary = d.get("deaths", {})
	var arr: Array = deaths.get(level_id, [])
	arr.append([tile_pos.x, tile_pos.y])
	deaths[level_id] = arr
	d["deaths"] = deaths
	save_slot(slot, d)


static func get_deaths(slot: int, level_id: String) -> Array[Vector2i]:
	var d := load_slot(slot)
	var raw: Dictionary = d.get("deaths", {})
	var arr: Array = raw.get(level_id, [])
	var out: Array[Vector2i] = []
	for pair in arr:
		if pair is Array and pair.size() >= 2:
			out.append(Vector2i(int(pair[0]), int(pair[1])))
	return out


# ── run tracking ──────────────────────────────────────────────────────────────

## Call when a run ends (warrior died). Increments runs_completed.
static func record_run_end(slot: int) -> void:
	var d := load_slot(slot)
	d["runs_completed"] = d.get("runs_completed", 0) + 1
	save_slot(slot, d)


## Call when a warrior escapes. Increments both counters. Returns new escape total.
static func record_escape(slot: int) -> int:
	var d := load_slot(slot)
	var n: int = d.get("warriors_escaped", 0) + 1
	d["warriors_escaped"] = n
	d["runs_completed"]   = d.get("runs_completed", 0) + 1
	save_slot(slot, d)
	return n


static func warriors_escaped(slot: int) -> int:
	return load_slot(slot).get("warriors_escaped", 0)


# ── internal ──────────────────────────────────────────────────────────────────

static func _empty() -> Dictionary:
	return {warriors_escaped = 0, runs_completed = 0, deaths = {}}
