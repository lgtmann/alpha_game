class_name Board
extends Control

const GRID_W: int = 10
const GRID_H: int = 10
const CELL_W: int = 68
const CELL_H: int = 78
const DRAG_THRESHOLD: float = 6.0
const MOVE_TWEEN_DUR: float = 0.18

# Terrain id -> color. Index is also the TileSet source id.
const TERRAIN_COLORS := [
	Color("#7ec850"),  # 0: plains
	Color("#2d5a27"),  # 1: forest
	Color("#3a78b5"),  # 2: water
]

const ADJACENT_OFFSETS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
]

# Hex direction offsets for our pointy-top, odd-r offset layout.
# Direction indices: 0=E, 1=SE, 2=SW, 3=W, 4=NW, 5=NE.
const NEIGHBOR_DIRS_EVEN: Array[Vector2i] = [
	Vector2i(1, 0),    # 0: E
	Vector2i(0, 1),    # 1: SE
	Vector2i(-1, 1),   # 2: SW
	Vector2i(-1, 0),   # 3: W
	Vector2i(-1, -1),  # 4: NW
	Vector2i(0, -1),   # 5: NE
]
const NEIGHBOR_DIRS_ODD: Array[Vector2i] = [
	Vector2i(1, 0),    # 0: E
	Vector2i(1, 1),    # 1: SE
	Vector2i(0, 1),    # 2: SW
	Vector2i(-1, 0),   # 3: W
	Vector2i(0, -1),   # 4: NW
	Vector2i(1, -1),   # 5: NE
]

# Selection mode: left-click activates MOVE, right-click activates ATTACK.
enum SelectionMode { NONE, MOVE, ATTACK }

@onready var tile_map_layer: TileMapLayer = $TileMapLayer

signal units_changed

var game_state: GameState
var terrain: Dictionary = {}  # Vector2i -> int
var units: Dictionary = {}    # Vector2i -> Unit
var selected_unit: Unit = null
var selection_mode: int = SelectionMode.NONE
var highlight_layer: HighlightLayer = null
var terrain_layer: TerrainLayer = null

# Drag state for left-button drag of friendly units.
var press_state: Dictionary = {}
var drag_ghost: Unit = null

func _ready() -> void:
	tile_map_layer.tile_set = _build_tile_set()
	tile_map_layer.position = Vector2(CELL_W / 2.0, CELL_H / 2.0)
	custom_minimum_size = Vector2(
		GRID_W * CELL_W + CELL_W / 2.0,
		(GRID_H - 1) * (CELL_H * 0.75) + CELL_H
	)
	_init_terrain(0)
	terrain_layer = TerrainLayer.new()
	tile_map_layer.add_child(terrain_layer)
	terrain_layer.setup(tile_map_layer, terrain)
	terrain_layer.refresh()
	highlight_layer = HighlightLayer.new()
	tile_map_layer.add_child(highlight_layer)
	highlight_layer.setup(tile_map_layer)

func _build_tile_set() -> TileSet:
	var ts := TileSet.new()
	ts.tile_shape = TileSet.TILE_SHAPE_HEXAGON
	ts.tile_layout = TileSet.TILE_LAYOUT_STACKED
	ts.tile_offset_axis = TileSet.TILE_OFFSET_AXIS_HORIZONTAL
	ts.tile_size = Vector2i(CELL_W, CELL_H)
	return ts

# --- Terrain -----------------------------------------------------------------

func _init_terrain(default_id: int) -> void:
	terrain.clear()
	for x in range(GRID_W):
		for y in range(GRID_H):
			terrain[Vector2i(x, y)] = default_id

func set_terrain(tile: Vector2i, terrain_id: int) -> void:
	if not terrain.has(tile):
		return
	terrain[tile] = terrain_id
	if terrain_layer != null:
		terrain_layer.refresh()

func get_terrain(tile: Vector2i) -> int:
	return terrain.get(tile, -1)

func is_valid_tile(tile: Vector2i) -> bool:
	return terrain.has(tile)

func neighbors(tile: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for n: Vector2i in tile_map_layer.get_surrounding_cells(tile):
		if is_valid_tile(n):
			out.append(n)
	return out

func hex_distance(a: Vector2i, b: Vector2i) -> int:
	var aq: int = a.x - (a.y - (a.y & 1)) / 2
	var ar: int = a.y
	var bq: int = b.x - (b.y - (b.y & 1)) / 2
	var br: int = b.y
	var dq: int = aq - bq
	var dr: int = ar - br
	var ds: int = -dq - dr
	return maxi(maxi(absi(dq), absi(dr)), absi(ds))

func tiles_within_range(center: Vector2i, attack_range: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if attack_range <= 0:
		return out
	var visited: Dictionary = {center: true}
	var frontier: Array[Vector2i] = [center]
	for depth in range(attack_range):
		var next_frontier: Array[Vector2i] = []
		for t: Vector2i in frontier:
			for n: Vector2i in neighbors(t):
				if visited.has(n):
					continue
				visited[n] = true
				next_frontier.append(n)
				out.append(n)
		frontier = next_frontier
	return out

func _hex_neighbor_in_dir(tile: Vector2i, dir: int) -> Vector2i:
	if dir < 0 or dir > 5:
		return tile
	var offsets: Array[Vector2i] = NEIGHBOR_DIRS_ODD if (tile.y & 1) == 1 else NEIGHBOR_DIRS_EVEN
	return tile + offsets[dir]

func reachable_tiles_with_accelerators(unit: Unit) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var seen: Dictionary = {}
	var tile: Vector2i = unit.tile
	for dir in range(6):
		var n: Vector2i = _hex_neighbor_in_dir(tile, dir)
		if is_valid_tile(n) and get_unit(n) == null:
			seen[n] = true
			out.append(n)
	for side_idx in range(unit.sides.size()):
		var accel: int = unit.get_accelerator_at_side(side_idx)
		if accel <= 0:
			continue
		var world_dir: int = (unit.facing + side_idx) % 6
		var pos: Vector2i = tile
		for _step in range(accel + 1):
			var next: Vector2i = _hex_neighbor_in_dir(pos, world_dir)
			if not is_valid_tile(next) or get_unit(next) != null:
				break
			if not seen.has(next):
				seen[next] = true
				out.append(next)
			pos = next
	return out

func reachable_forward_tiles(unit: Unit) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if unit == null or unit.data == null:
		return out
	var current: Vector2i = unit.tile
	for step in range(unit.data.speed):
		var next: Vector2i = _hex_neighbor_in_dir(current, unit.facing)
		if not is_valid_tile(next):
			break
		if get_unit(next) != null:
			break
		out.append(next)
		current = next
	return out

func reachable_tiles(start: Vector2i, speed: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if speed <= 0:
		return out
	var visited: Dictionary = {start: true}
	var frontier: Array[Vector2i] = [start]
	for depth in range(speed):
		var next_frontier: Array[Vector2i] = []
		for t: Vector2i in frontier:
			for n: Vector2i in neighbors(t):
				if visited.has(n):
					continue
				if get_unit(n) != null:
					visited[n] = true
					continue
				visited[n] = true
				next_frontier.append(n)
				out.append(n)
		frontier = next_frontier
	return out

func position_to_tile(local_pos: Vector2) -> Vector2i:
	return tile_map_layer.local_to_map(local_pos - tile_map_layer.position)

# Hex direction (0..5) of `to` relative to `from`. Returns -1 if non-adjacent.
func direction_from_to(from: Vector2i, to: Vector2i) -> int:
	var offsets: Array[Vector2i] = NEIGHBOR_DIRS_ODD if (from.y & 1) == 1 else NEIGHBOR_DIRS_EVEN
	var diff := to - from
	for i in range(6):
		if offsets[i] == diff:
			return i
	return -1

# Like direction_from_to but falls back to angle-based mapping for non-adjacent
# tiles (e.g. ranged attacks). Always returns 0..5 unless from == to.
func direction_toward(from: Vector2i, to: Vector2i) -> int:
	if from == to:
		return 0
	var d := direction_from_to(from, to)
	if d >= 0:
		return d
	var from_pos := tile_map_layer.map_to_local(from)
	var to_pos := tile_map_layer.map_to_local(to)
	var angle: float = (to_pos - from_pos).angle()
	# Map angle (atan2 result, +X = 0, +Y = +PI/2) to direction (0=E, 1=SE, ...).
	# Sector boundaries sit at i*PI/3 + PI/6.
	var a: float = fmod(angle + 2.0 * PI, 2.0 * PI)
	var s: float = fmod(a + PI / 6.0, 2.0 * PI)
	return int(s / (PI / 3.0)) % 6

# --- Units -------------------------------------------------------------------

func add_unit(data: UnitData, owner_id: int, tile: Vector2i) -> Unit:
	if not is_valid_tile(tile) or units.has(tile):
		return null
	var u := Unit.new()
	u.tile = tile
	u.position = tile_map_layer.map_to_local(tile)
	tile_map_layer.add_child(u)
	u.setup(data, owner_id)
	units[tile] = u
	if game_state != null and owner_id == GameState.PLAYER:
		var atk_b: int = game_state.player_atk_bonus
		var def_b: int = game_state.player_def_bonus
		if atk_b != 0 or def_b != 0:
			u.add_buff(atk_b, def_b)
	units_changed.emit()
	return u

func get_unit(tile: Vector2i) -> Unit:
	return units.get(tile, null) as Unit

func remove_unit(tile: Vector2i) -> void:
	var u: Unit = units.get(tile, null) as Unit
	if u != null:
		units.erase(tile)
		if selected_unit == u:
			_deselect()
		u.play_destroy()
		units_changed.emit()

func move_unit(unit: Unit, to_tile: Vector2i) -> void:
	var from_tile := unit.tile
	units.erase(unit.tile)
	unit.tile = to_tile
	units[to_tile] = unit
	unit.tween_to(tile_map_layer.map_to_local(to_tile), MOVE_TWEEN_DUR)
	unit.set_facing(direction_toward(from_tile, to_tile))
	if selected_unit == unit:
		_refresh_highlights()

func has_adjacent_friendly(tile: Vector2i, owner_id: int) -> bool:
	for n: Vector2i in neighbors(tile):
		var u: Unit = get_unit(n)
		if u != null and u.owner_id == owner_id:
			return true
	return false

func all_units() -> Array[Unit]:
	var out: Array[Unit] = []
	for k: Vector2i in units.keys():
		out.append(units[k] as Unit)
	return out

func count_units(owner_id: int) -> int:
	var n: int = 0
	for k: Vector2i in units.keys():
		var u: Unit = units[k] as Unit
		if u != null and u.owner_id == owner_id:
			n += 1
	return n

func clear_battle_state() -> void:
	_deselect()
	_cancel_drag_visuals()
	press_state = {}
	for u: Unit in all_units():
		u.queue_free()
	units.clear()
	units_changed.emit()
	_init_terrain(0)
	if terrain_layer != null:
		terrain_layer.refresh()

# --- Projectile visual ------------------------------------------------------

func play_projectile(from_tile: Vector2i, to_tile: Vector2i, color: Color = Color("#ffd070")) -> void:
	var proj := ProjectileAnim.new()
	proj.start_pos = tile_map_layer.map_to_local(from_tile)
	proj.end_pos = tile_map_layer.map_to_local(to_tile)
	proj.color = color
	tile_map_layer.add_child(proj)

# --- Card drop ---------------------------------------------------------------

func _can_drop_data(at_position: Vector2, data) -> bool:
	if typeof(data) != TYPE_DICTIONARY or not data.has("card_data"):
		return false
	var card: CardData = data["card_data"]
	var tile := position_to_tile(at_position)
	if game_state != null and not game_state.can_play_card(card):
		return false
	if card.effect == null:
		return is_valid_tile(tile)
	return card.effect.can_target(self, tile)

func _drop_data(at_position: Vector2, data) -> void:
	if game_state == null:
		return
	var view: CardView = data.get("source")
	var tile := position_to_tile(at_position)
	game_state.try_play_card(view, self, tile)

# --- Mouse input -----------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT and mb.button_index != MOUSE_BUTTON_RIGHT:
		return
	if not mb.pressed:
		return
	if game_state == null or game_state.winner != -1:
		return
	if game_state.current_player != GameState.PLAYER:
		return
	accept_event()
	_on_press(position_to_tile(mb.position), mb.position, mb.button_index)

func _on_press(tile: Vector2i, pos: Vector2, button: int) -> void:
	if button == MOUSE_BUTTON_LEFT:
		_on_left_press(tile, pos)
	else:
		_on_right_press(tile, pos)

func _on_left_press(tile: Vector2i, pos: Vector2) -> void:
	_cancel_drag_visuals()
	press_state = {}
	if not is_valid_tile(tile):
		_deselect()
		return
	var unit: Unit = get_unit(tile)

	# Own unit: select for MOVE highlight and arm press_state for rotate/drag.
	if unit != null and unit.owner_id == GameState.PLAYER:
		_select_move(unit)
		press_state = {"unit": unit, "start": pos, "dragging": false}
		return

	# Click empty tile while a MOVE-mode unit is selected: try forward move there.
	if (selected_unit != null and is_instance_valid(selected_unit)
			and selection_mode == SelectionMode.MOVE and unit == null):
		game_state.attempt_move(selected_unit, tile)
		_deselect()
		return

	_deselect()

func _on_right_press(tile: Vector2i, _pos: Vector2) -> void:
	if not is_valid_tile(tile):
		_deselect()
		return
	var unit: Unit = get_unit(tile)

	if selected_unit != null and is_instance_valid(selected_unit) and unit == selected_unit:
		if selection_mode == SelectionMode.ATTACK:
			_deselect()
		else:
			_select_attack(unit)
		return

	if selected_unit != null and is_instance_valid(selected_unit) and selection_mode == SelectionMode.ATTACK:
		# Execute attack on enemy in range, or switch attacker.
		if unit != null and unit.owner_id != selected_unit.owner_id:
			game_state.attempt_attack(selected_unit, unit)
			_deselect()
			return
		if unit != null and unit.owner_id == GameState.PLAYER and not unit.has_moved:
			_select_attack(unit)
			return
		_deselect()
		return

	# No selection or currently in MOVE mode → switch to ATTACK mode on friendly.
	if unit != null and unit.owner_id == GameState.PLAYER and not unit.has_moved:
		_select_attack(unit)
		return

	_deselect()

func _process(_delta: float) -> void:
	_tick_cursor_facing()
	if press_state.is_empty():
		return
	var mouse_held := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var local_pos := get_local_mouse_position()
	var unit: Unit = press_state.get("unit")
	if unit == null or not is_instance_valid(unit):
		_cancel_drag_visuals()
		press_state = {}
		return
	if not mouse_held:
		if press_state.get("dragging", false):
			_commit_drop(unit, local_pos)
		_cancel_drag_visuals()
		press_state = {}
		return
	if not press_state.get("dragging", false):
		var dist := local_pos.distance_to(press_state["start"] as Vector2)
		if dist > DRAG_THRESHOLD:
			press_state["dragging"] = true
			_start_drag_ghost(unit, local_pos)
	else:
		if drag_ghost != null:
			drag_ghost.position = local_pos - tile_map_layer.position

func _start_drag_ghost(unit: Unit, at_pos: Vector2) -> void:
	drag_ghost = Unit.new()
	tile_map_layer.add_child(drag_ghost)
	drag_ghost.setup(unit.data, unit.owner_id)
	drag_ghost.modulate.a = 0.75
	drag_ghost.scale = Vector2(1.12, 1.12)
	drag_ghost.position = at_pos - tile_map_layer.position
	unit.modulate.a = 0.30

func _cancel_drag_visuals() -> void:
	if not press_state.is_empty():
		var u: Unit = press_state.get("unit")
		if u != null and is_instance_valid(u):
			u.modulate.a = 1.0
	if drag_ghost != null and is_instance_valid(drag_ghost):
		drag_ghost.queue_free()
	drag_ghost = null

func _tick_cursor_facing() -> void:
	if (selected_unit == null or not is_instance_valid(selected_unit)
			or selected_unit.owner_id != GameState.PLAYER
			or game_state == null or game_state.current_player != GameState.PLAYER
			or game_state.winner != -1):
		return
	var unit_pos: Vector2 = tile_map_layer.map_to_local(selected_unit.tile) + tile_map_layer.position
	var diff: Vector2 = get_local_mouse_position() - unit_pos
	if diff.length() < 6.0:
		return
	var a: float = fmod(diff.angle() + 2.0 * PI + PI / 6.0, 2.0 * PI)
	var new_facing: int = int(a / (PI / 3.0)) % 6
	if new_facing != selected_unit.facing:
		selected_unit.set_facing(new_facing)
		if selection_mode == SelectionMode.MOVE:
			_refresh_highlights()

func _commit_drop(unit: Unit, at_pos: Vector2) -> void:
	var tile := position_to_tile(at_pos)
	if not is_valid_tile(tile):
		return
	var other: Unit = get_unit(tile)
	if other != null and other.owner_id != unit.owner_id:
		game_state.attempt_attack(unit, other)
	elif other == null:
		if game_state != null and game_state.valid_move_tiles(unit).has(tile):
			unit.position = at_pos - tile_map_layer.position
			game_state.attempt_move(unit, tile)
	_deselect()

# --- Selection / highlights --------------------------------------------------

func _select_move(u: Unit) -> void:
	_set_selected(u, SelectionMode.MOVE)

func _select_attack(u: Unit) -> void:
	_set_selected(u, SelectionMode.ATTACK)

func _set_selected(u: Unit, mode: int) -> void:
	if selected_unit != null and is_instance_valid(selected_unit) and selected_unit != u:
		selected_unit.set_selected(false)
	selected_unit = u
	selection_mode = mode
	u.set_selected(true)
	_refresh_highlights()

func _deselect() -> void:
	if selected_unit != null and is_instance_valid(selected_unit):
		selected_unit.set_selected(false)
	selected_unit = null
	selection_mode = SelectionMode.NONE
	if highlight_layer != null:
		highlight_layer.clear()

func _refresh_highlights() -> void:
	if highlight_layer == null or selected_unit == null or game_state == null:
		return
	if selection_mode == SelectionMode.MOVE:
		var moves := game_state.valid_move_tiles(selected_unit)
		highlight_layer.set_highlights(moves, [], selected_unit.tile)
	elif selection_mode == SelectionMode.ATTACK:
		var attacks := game_state.valid_attack_tiles(selected_unit)
		highlight_layer.set_highlights([], attacks, selected_unit.tile)

# --- Turn lifecycle hook -----------------------------------------------------

func on_turn_started(_turn: int, active_player: int) -> void:
	if active_player != GameState.PLAYER:
		_cancel_drag_visuals()
		press_state = {}
		_deselect()
