class_name LevelData
extends RefCounted

## Position data for a single overworld level.
## floor_rects is painted onto TileMapFloor at runtime — each Rect2i fills that
## rectangle with walkable floor tiles.  Leave it empty to paint manually in the editor.

var level_id: String = ""
var npc_defs: Array = []            # [{pos: Vector2i, name: String, enc_idx: int}]
var door_defs: Array = []           # [{pos: Vector2i, dest: String, label: String}]
var salesman_defs: Array = []       # [{pos: Vector2i, name: String}]
var peer_warrior_defs: Array = []   # [{pos: Vector2i, name: String}]
var floor_rects: Array[Rect2i] = [] # painted procedurally onto TileMapFloor
var vat_defs: Array = []            # [{pos: Vector2i, frame: int}]  decorative vats
var player_spawn: Vector2i = Vector2i(11, 19)
