class_name LevelData
extends RefCounted

## Position data for a single overworld level.
## The actual tile layout lives in the TileMapLayer nodes inside overworld.tscn —
## draw it yourself in the Godot editor (TileMapFloor for walkable, TileMapWalls for obstacles).

var level_id: String = ""
var npc_defs: Array = []        # [{pos: Vector2i, name: String, enc_idx: int}]
var door_defs: Array = []       # [{pos: Vector2i, dest: String, label: String}]
var salesman_defs: Array = []   # [{pos: Vector2i, name: String}]
var player_spawn: Vector2i = Vector2i(11, 19)
