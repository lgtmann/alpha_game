class_name Level0
extends RefCounted

## Position data for Level 0 — the starting cave.
## The actual tile map is drawn in Godot editor on the TileMapFloor / TileMapWalls
## layers inside scenes/overworld.tscn.  This file only stores where entities live.

static func create() -> LevelData:
	var d := LevelData.new()
	d.level_id       = "0"
	d.player_spawn   = Vector2i(11, 19)

	d.npc_defs = [
		{pos = Vector2i(11, 17), name = "Dark Lord",     enc_idx = 0},
		{pos = Vector2i(11, 14), name = "Forest Warden", enc_idx = 1},
		{pos = Vector2i(25, 8),  name = "Sea Witch",     enc_idx = 2},
		{pos = Vector2i(4,  6),  name = "Stone Lord",    enc_idx = 3},
		{pos = Vector2i(11, 3),  name = "Champion",      enc_idx = 4},
	]

	d.door_defs = [
		{pos = Vector2i(11, 0), dest = "1.1", label = "1.1"},
		{pos = Vector2i(25, 0), dest = "1.2", label = "1.2"},
		{pos = Vector2i(4,  0), dest = "1.3", label = "1.3"},
	]

	d.salesman_defs = [
		{pos = Vector2i(14, 17), name = "Merchant"},
	]

	return d
