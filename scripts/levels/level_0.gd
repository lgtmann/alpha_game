class_name Level0
extends RefCounted

## Factory for Level 0 — the starting cave.
## Call Level0.create() to get a fully populated LevelData.

static func create() -> LevelData:
	var d := LevelData.new()
	d.level_id = "0"
	d.map_w = 30
	d.map_h = 22
	d.player_spawn = Vector2i(11, 19)

	_build_tiles(d)

	# NPCs — same encounter positions as the original overworld.
	d.npc_defs = [
		{pos = Vector2i(11, 17), name = "Dark Lord",     enc_idx = 0},
		{pos = Vector2i(11, 14), name = "Forest Warden", enc_idx = 1},
		{pos = Vector2i(25, 8),  name = "Sea Witch",     enc_idx = 2},
		{pos = Vector2i(4,  6),  name = "Stone Lord",    enc_idx = 3},
		{pos = Vector2i(11, 3),  name = "Champion",      enc_idx = 4},
	]

	# Doors cut into the north wall, above the three main corridors.
	# dest matches the level_id of the destination level.
	d.door_defs = [
		{pos = Vector2i(11, 0), dest = "1.1", label = "1.1"},
		{pos = Vector2i(25, 0), dest = "1.2", label = "1.2"},
		{pos = Vector2i(4,  0), dest = "1.3", label = "1.3"},
	]

	return d


static func _build_tiles(d: LevelData) -> void:
	# Step 1 — fill everything with cave floor.
	d.tiles.clear()
	for y in range(d.map_h):
		var row: Array = []
		for x in range(d.map_w):
			row.append(LevelData.T_FLOOR)
		d.tiles.append(row)

	# Step 2 — outer border = stone wall.
	for x in range(d.map_w):
		_put(d, x, 0,           LevelData.T_WALL)
		_put(d, x, d.map_h - 1, LevelData.T_WALL)
	for y in range(d.map_h):
		_put(d, 0,           y, LevelData.T_WALL)
		_put(d, d.map_w - 1, y, LevelData.T_WALL)

	# Step 3 — rock clusters that define the cave shape.
	_fill(d,  5,  1, 5, 5, LevelData.T_WALL)   # NW cluster (guards Champion approach)
	_fill(d, 14,  1, 7, 4, LevelData.T_WALL)   # NE cluster
	_fill(d, 15, 14, 8, 5, LevelData.T_WALL)   # SE cluster

	# Step 4 — underground pool.
	_fill(d, 1, 12, 3, 6, LevelData.T_WATER)

	# Step 5 — door openings cut into the north wall (override T_WALL).
	_put(d, 11, 0, LevelData.T_DOOR)   # → level 1.1
	_put(d, 25, 0, LevelData.T_DOOR)   # → level 1.2
	_put(d,  4, 0, LevelData.T_DOOR)   # → level 1.3

	# Step 6 — corridors (re-open any tiles closed by clusters above).
	for y in range(1, d.map_h - 1):
		_put(d, 11, y, LevelData.T_FLOOR)      # main N–S corridor
	for x in range(1, d.map_w - 1):
		_put(d, x, 10, LevelData.T_FLOOR)      # E–W crossroads
	for y in range(8, 11):
		_put(d, 25, y, LevelData.T_FLOOR)      # east spur → Sea Witch
	for y in range(6, 11):
		_put(d,  4, y, LevelData.T_FLOOR)      # west spur → Stone Lord


static func _fill(d: LevelData, x: int, y: int, w: int, h: int, t: int) -> void:
	for dy in range(h):
		for dx in range(w):
			_put(d, x + dx, y + dy, t)


static func _put(d: LevelData, x: int, y: int, t: int) -> void:
	if y < 0 or y >= d.tiles.size():
		return
	var row: Array = d.tiles[y]
	if x < 0 or x >= row.size():
		return
	row[x] = t
