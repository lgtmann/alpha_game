class_name Overworld
extends Node2D

signal battle_requested(enc_idx: int)
signal door_requested(dest_level_id: String)
signal shop_requested

const TILE_SIZE: int = 48
const MAP_W: int = 30
const MAP_H: int = 22
const MOVE_COOLDOWN: float = 0.15

# Cave tileset: res://art/tiles/cave_tileset.png
# Sheet is 320×224 px — 10 cols × 7 rows of 32×32 tiles.
# Tweak these Rect2s if the visible tiles look wrong in-game.
const _CAVE_TEX := preload("res://art/tiles/cave_tileset.png")
const _R_FLOOR: Rect2 = Rect2(0,  128, 32, 32)   # row 4 col 0 — dark cave floor
const _R_WALL:  Rect2 = Rect2(32,   0, 32, 32)   # row 0 col 1 — log/rock wall
# Water reuses the floor region with a blue modulate (see _draw).

var _level_data: LevelData = null
var _map: Array = []              # alias of _level_data.tiles for fast access
var _player: OverworldPlayer = null
var _npcs: Array[OverworldNpc] = []
var _salesmen: Array[OverworldSalesman] = []
var _run_state: RunState = null
var _move_timer: float = 0.0


func _ready() -> void:
	_level_data = Level0.create()
	_map = _level_data.tiles
	_player = OverworldPlayer.new()
	_player.tile_pos = _level_data.player_spawn
	add_child(_player)
	_spawn_salesmen()


func _spawn_salesmen() -> void:
	if _level_data == null:
		return
	for def: Dictionary in _level_data.salesman_defs:
		var s := OverworldSalesman.new()
		add_child(s)
		s.setup(def["pos"], def["name"])
		_salesmen.append(s)


func initialize(rs: RunState) -> void:
	_run_state = rs
	refresh_npcs()


func refresh_npcs() -> void:
	for n: OverworldNpc in _npcs:
		if is_instance_valid(n):
			n.queue_free()
	_npcs.clear()
	if _run_state == null or _level_data == null:
		return
	var enc_count: int = mini(_level_data.npc_defs.size(), _run_state.encounters.size())
	for i in range(enc_count):
		var def: Dictionary = _level_data.npc_defs[i]
		var npc := OverworldNpc.new()
		add_child(npc)
		npc.setup(def["pos"], def["name"], def["enc_idx"])
		if def["enc_idx"] < _run_state.encounter_index:
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
	if Input.is_action_pressed("ui_left")  or Input.is_key_pressed(KEY_A):
		return Vector2i(-1, 0)
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		return Vector2i(1, 0)
	if Input.is_action_pressed("ui_up")    or Input.is_key_pressed(KEY_W):
		return Vector2i(0, -1)
	if Input.is_action_pressed("ui_down")  or Input.is_key_pressed(KEY_S):
		return Vector2i(0, 1)
	return Vector2i.ZERO


func _try_interact(tile: Vector2i) -> void:
	# Door check.
	if _level_data != null:
		for door: Dictionary in _level_data.door_defs:
			if door["pos"] == tile:
				door_requested.emit(door["dest"])
				return
	# Salesman check.
	for s: OverworldSalesman in _salesmen:
		if is_instance_valid(s) and s.tile_pos == tile:
			shop_requested.emit()
			return
	# Enemy NPC check.
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
	if t == LevelData.T_WALL or t == LevelData.T_WATER or t == LevelData.T_DOOR:
		return false
	for npc: OverworldNpc in _npcs:
		if is_instance_valid(npc) and not npc.defeated and npc.tile_pos == tile:
			return false
	for s: OverworldSalesman in _salesmen:
		if is_instance_valid(s) and s.tile_pos == tile:
			return false
	return true


func _get_tile(tile: Vector2i) -> int:
	if tile.y < 0 or tile.y >= _map.size():
		return LevelData.T_WALL
	var row: Array = _map[tile.y]
	if tile.x < 0 or tile.x >= row.size():
		return LevelData.T_WALL
	return row[tile.x]


func _draw() -> void:
	if _map.is_empty():
		return
	for y in range(MAP_H):
		for x in range(MAP_W):
			var t: int = _get_tile(Vector2i(x, y))
			var dest: Rect2 = Rect2(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
			match t:
				LevelData.T_FLOOR:
					draw_texture_rect_region(_CAVE_TEX, dest, _R_FLOOR)
				LevelData.T_WALL:
					draw_texture_rect_region(_CAVE_TEX, dest, _R_WALL)
				LevelData.T_WATER:
					# Reuse floor texture with a blue tint for the underground pool.
					draw_texture_rect_region(_CAVE_TEX, dest, _R_FLOOR,
							Color(0.28, 0.48, 0.88, 1.0))
				LevelData.T_DOOR:
					draw_texture_rect_region(_CAVE_TEX, dest, _R_FLOOR)
					draw_rect(dest, Color(1.0, 0.82, 0.44, 0.35), true)
					draw_rect(dest, Color("#ffd070"), false, 2.0)
			# Very faint grid lines to help with orientation.
			draw_rect(dest, Color(0.0, 0.0, 0.0, 0.06), false, 1.0)

	# Door destination labels drawn over door tiles.
	if _level_data == null:
		return
	var font: Font = ThemeDB.fallback_font
	if font == null:
		return
	for door: Dictionary in _level_data.door_defs:
		var dp: Vector2i = door["pos"]
		var lx: float = dp.x * TILE_SIZE + 4.0
		var ly: float = dp.y * TILE_SIZE + TILE_SIZE * 0.68
		draw_string(font, Vector2(lx, ly), door["label"],
				HORIZONTAL_ALIGNMENT_LEFT, float(TILE_SIZE - 4), 9, Color("#ffd070"))
