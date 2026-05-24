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

	d.peer_warrior_defs = [
		{pos = Vector2i(9,  18), name = "Ash"},
		{pos = Vector2i(13, 18), name = "Mira"},
		{pos = Vector2i(11, 18), name = "Cole"},
	]

	# Decorative vats in the spawn chamber — visual only, walk-through.
	# type selects the row (colour variant): 0=blue, 1=orange, 2=red, 3=teal
	# All four columns of that row cycle as the bubble animation.
	d.vat_defs = [
		{pos = Vector2i(8,  16), type = 0},   # blue
		{pos = Vector2i(15, 16), type = 1},   # orange
		{pos = Vector2i(8,  19), type = 3},   # teal
		{pos = Vector2i(15, 19), type = 2},   # red
	]

	# Procedural floor layout — rectangles painted onto TileMapFloor at runtime.
	d.floor_rects = [
		Rect2i( 7, 15, 10,  5),   # spawn chamber (cols 7-16, rows 15-19)
		Rect2i(10,  0,  3, 20),   # main N-S corridor (cols 10-12, full height)
		Rect2i(12,  6, 15,  5),   # east wing toward Sea Witch (cols 12-26, rows 6-10)
		Rect2i(24,  0,  3,  7),   # east door approach (cols 24-26, rows 0-6)
		Rect2i( 2,  5, 10,  5),   # west wing toward Stone Lord (cols 2-11, rows 5-9)
		Rect2i( 3,  0,  3,  6),   # west door approach (cols 3-5, rows 0-5)
		Rect2i( 8,  0,  6,  5),   # top chamber for Champion (cols 8-13, rows 0-4)
	]

	return d
