class_name Overworld
extends Node2D

signal battle_requested(enc_idx: int)

const TILE_SIZE: int = 48
const MAP_W: int = 30
const MAP_H: int = 22
const MOVE_COOLDOWN: float = 0.15

const T_GRASS: int = 0
const T_PATH: int = 1
const T_TREE: int = 2
const T_WATER: int = 3

const TILE_COLORS: Array[Color] = [
	Color("#5a8c3c"),
	Color("#c8a860"),
	Color("#2a5418"),
	Color("#3a78b5"),
]

# NPC positions paired with encounter names, indexed by encounter order.
const NPC_DEFS: Array[Dictionary] = [
	{pos = Vector2i(11, 17), name = "Dark Lord"},
	{pos = Vector2i(11, 14), name = "Forest Warden"},
	{pos = Vector2i(25, 8),  name = "Sea Witch"},
	{pos = Vector2i(4, 6),   name = "Stone Lord"},
	{pos = Vector2i(11, 3),  name = "Champion"},
]

var _map: Array = []
var _player: OverworldPlayer = null
var _npcs: Array[OverworldNpc] = []
var _run_state: RunState = null
var _move_timer: float = 0.0

func _ready() -> void:
	_build_map()
	_player = OverworldPlayer.new()
	add_child(_player)

func initialize(rs: RunState) -> void:
	_run_state = rs
	refresh_npcs()

func refresh_npcs() -> void:
	for n: OverworldNpc in _npcs:
		if is_instance_valid(n):
			n.queue_free()
	_npcs.clear()
	if _run_state == null:
		return
	var enc_count: int = mini(NPC_DEFS.size(), _run_state.encounters.size())
	for i in range(enc_count):
		var def: Dictionary = NPC_DEFS[i]
		var npc := OverworldNpc.new()
		add_child(npc)
		npc.setup(def["pos"], def["name"], i)
		if i < _run_state.encounter_index:
			npc.mark_defeated()
		_npcs.append(npc)

func _process(delta: float) -> void:
	if not is_visible_in_tree() or _player == null or _player.is_moving():
		_move_timer = 0.0
		return
	_move_timer -= delta
	if _move_timer > 0.0:
		return
	var dir := _get_input_dir()
	if dir == Vector2i.ZERO:
		return
	var target := _player.tile_pos + dir
	_move_timer = MOVE_COOLDOWN
	if _is_walkable(target):
		_player.move_to(target)
	else:
		_try_interact(target)

func _get_input_dir() -> Vector2i:
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		return Vector2i(-1, 0)
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		return Vector2i(1, 0)
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		return Vector2i(0, -1)
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		return Vector2i(0, 1)
	return Vector2i.ZERO

func _try_interact(tile: Vector2i) -> void:
	if _run_state == null:
		return
	for npc: OverworldNpc in _npcs:
		if not is_instance_valid(npc) or npc.defeated:
			continue
		if npc.tile_pos == tile:
			battle_requested.emit(npc.encounter_index)
			return

func _is_walkable(tile: Vector2i) -> bool:
	if tile.x < 0 or tile.x >= MAP_W or tile.y < 0 or tile.y >= MAP_H:
		return false
	var t: int = _get_tile(tile)
	if t == T_TREE or t == T_WATER:
		return false
	for npc: OverworldNpc in _npcs:
		if is_instance_valid(npc) and not npc.defeated and npc.tile_pos == tile:
			return false
	return true

func _get_tile(tile: Vector2i) -> int:
	if tile.y < 0 or tile.y >= _map.size():
		return T_TREE
	var row: Array = _map[tile.y]
	if tile.x < 0 or tile.x >= row.size():
		return T_TREE
	return row[tile.x]

func _draw() -> void:
	for y in range(MAP_H):
		for x in range(MAP_W):
			var t: int = _get_tile(Vector2i(x, y))
			draw_rect(Rect2(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE), TILE_COLORS[t])
			draw_rect(Rect2(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE),
					  Color(0.0, 0.0, 0.0, 0.12), false, 1.0)

func _build_map() -> void:
	_map.clear()
	for y in range(MAP_H):
		var row: Array = []
		for x in range(MAP_W):
			row.append(T_GRASS)
		_map.append(row)
	# Border trees
	for x in range(MAP_W):
		_set_tile(x, 0, T_TREE)
		_set_tile(x, MAP_H - 1, T_TREE)
	for y in range(MAP_H):
		_set_tile(0, y, T_TREE)
		_set_tile(MAP_W - 1, y, T_TREE)
	# Main vertical path x=11
	for y in range(1, MAP_H - 1):
		_set_tile(11, y, T_PATH)
	# Horizontal crossroads y=10
	for x in range(1, MAP_W - 1):
		_set_tile(x, 10, T_PATH)
	# East branch to Sea Witch: x=25, y=8-10
	for y in range(8, 11):
		_set_tile(25, y, T_PATH)
	# West branch to Stone Lord: x=4, y=6-10
	for y in range(6, 11):
		_set_tile(4, y, T_PATH)
	# Water feature: x=1-3, y=12-17
	_fill_rect(1, 12, 3, 6, T_WATER)
	# NW forest: x=5-9, y=1-5
	_fill_rect(5, 1, 5, 5, T_TREE)
	# NE forest: x=14-20, y=1-4
	_fill_rect(14, 1, 7, 4, T_TREE)
	# SE forest: x=15-22, y=14-18
	_fill_rect(15, 14, 8, 5, T_TREE)

func _fill_rect(x: int, y: int, w: int, h: int, tile_type: int) -> void:
	for dy in range(h):
		for dx in range(w):
			_set_tile(x + dx, y + dy, tile_type)

func _set_tile(x: int, y: int, t: int) -> void:
	if y < 0 or y >= _map.size() or x < 0 or x >= MAP_W:
		return
	_map[y][x] = t
