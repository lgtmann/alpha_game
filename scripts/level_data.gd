class_name LevelData
extends RefCounted

## Lightweight data container for a single overworld level.
## Created by a factory script (e.g. Level0.create()) and consumed by Overworld.

# Tile type constants shared by all levels and the Overworld renderer.
const T_FLOOR: int = 0   # Walkable cave floor
const T_WALL:  int = 1   # Impassable rock / log wall
const T_DOOR:  int = 2   # Exit door — impassable but triggers door_requested signal
const T_WATER: int = 3   # Impassable underground pool (rendered with blue tint)

var level_id: String = ""
var map_w: int = 30
var map_h: int = 22
var tiles: Array = []       # tiles[y][x] -> int  (populated by the factory)
var npc_defs: Array = []    # Array of {pos: Vector2i, name: String, enc_idx: int}
var door_defs: Array = []   # Array of {pos: Vector2i, dest: String, label: String}
var player_spawn: Vector2i = Vector2i(11, 19)
