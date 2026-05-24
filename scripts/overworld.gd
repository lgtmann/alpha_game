class_name Overworld
extends Node2D

signal battle_requested(enc_idx: int)
signal door_requested(dest_level_id: String)
signal shop_requested
signal dialogue_requested(pw: OverworldPeerWarrior)

# ── Two-layer tilemap ──────────────────────────────────────────────────────
# TileMapFloor  (z=-2): paint ANY tile here  → the cell is walkable floor.
# TileMapWalls  (z=-1): paint ANY tile here  → the cell is impassable.
# A cell without a floor tile is also impassable (e.g. the empty edge).
# Door tiles must NOT have a floor tile (or must have a wall tile on top)
# so that bumping into them triggers _try_interact() instead of walking through.
# ──────────────────────────────────────────────────────────────────────────

const TILE_SIZE: int = 48
const MOVE_COOLDOWN: float = 0.15

@onready var _floor_map: TileMapLayer = $TileMapFloor
@onready var _wall_map:  TileMapLayer = $TileMapWalls

var _level_data: LevelData = null
var _player: OverworldPlayer = null
var _npcs: Array[OverworldNpc] = []
var _salesmen: Array[OverworldSalesman] = []
var _peer_warriors: Array[OverworldPeerWarrior] = []
var _run_state: RunState = null
var _move_timer: float = 0.0
var _bones: Array[OverworldBones] = []
var _vats:  Array[OverworldVat]   = []

var current_level_id: String:
	get:
		return _level_data.level_id if _level_data != null else ""

var player_tile_pos: Vector2i:
	get:
		return _player.tile_pos if _player != null else Vector2i.ZERO


func _ready() -> void:
	_level_data = Level0.create()
	_paint_level()
	_player = OverworldPlayer.new()
	_player.tile_pos = _level_data.player_spawn
	add_child(_player)
	_spawn_vats()
	_spawn_salesmen()
	_spawn_peer_warriors()


func _paint_level() -> void:
	if _floor_map == null or _level_data == null:
		return
	_floor_map.clear()
	for rect: Rect2i in _level_data.floor_rects:
		for row in range(rect.position.y, rect.position.y + rect.size.y):
			for col in range(rect.position.x, rect.position.x + rect.size.x):
				_floor_map.set_cell(Vector2i(col, row), 0, Vector2i(0, 0))


func _spawn_vats() -> void:
	if _level_data == null:
		return
	for def: Dictionary in _level_data.vat_defs:
		var vat := OverworldVat.new()
		add_child(vat)
		vat.setup(def["pos"], def.get("type", 0))
		_vats.append(vat)


func _spawn_salesmen() -> void:
	if _level_data == null:
		return
	for def: Dictionary in _level_data.salesman_defs:
		var s := OverworldSalesman.new()
		add_child(s)
		s.setup(def["pos"], def["name"])
		_salesmen.append(s)


func _spawn_peer_warriors() -> void:
	if _level_data == null:
		return
	for def: Dictionary in _level_data.peer_warrior_defs:
		var pw := OverworldPeerWarrior.new()
		add_child(pw)
		pw.setup(def["pos"], def["name"])
		_peer_warriors.append(pw)


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


func spawn_death_markers(death_positions: Array[Vector2i]) -> void:
	for b: OverworldBones in _bones:
		if is_instance_valid(b):
			b.queue_free()
	_bones.clear()
	for tp: Vector2i in death_positions:
		var bone := OverworldBones.new()
		add_child(bone)
		bone.setup(tp)
		_bones.append(bone)


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
	# Peer warrior check — opens dialogue instead of jumping straight to battle.
	for pw: OverworldPeerWarrior in _peer_warriors:
		if not is_instance_valid(pw) or pw.defeated:
			continue
		if pw.tile_pos == tile:
			dialogue_requested.emit(pw)
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
	# No floor tile → empty space, out of bounds, or unpainted.
	if _floor_map == null or _floor_map.get_cell_source_id(tile) == -1:
		return false
	# Wall tile overrides floor → impassable rock/obstacle.
	if _wall_map != null and _wall_map.get_cell_source_id(tile) != -1:
		return false
	# Door positions are always impassable (player bumps to trigger them).
	if _level_data != null:
		for door: Dictionary in _level_data.door_defs:
			if door["pos"] == tile:
				return false
	# Entity blocking.
	for npc: OverworldNpc in _npcs:
		if is_instance_valid(npc) and not npc.defeated and npc.tile_pos == tile:
			return false
	for s: OverworldSalesman in _salesmen:
		if is_instance_valid(s) and s.tile_pos == tile:
			return false
	for pw: OverworldPeerWarrior in _peer_warriors:
		if is_instance_valid(pw) and not pw.defeated and pw.tile_pos == tile:
			return false
	return true
