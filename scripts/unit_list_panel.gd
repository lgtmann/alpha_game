class_name UnitListPanel
extends PanelContainer

@onready var label: Label = $V/Scroll/Label

var game_state: GameState = null

func bind(gs: GameState) -> void:
	game_state = gs
	gs.turn_started.connect(_on_state_changed.unbind(2))
	gs.unit_destroyed.connect(_on_state_changed.unbind(1))
	gs.unit_damaged.connect(_on_state_changed.unbind(1))
	gs.game_ended.connect(_on_state_changed.unbind(1))
	if gs.board != null:
		gs.board.units_changed.connect(_refresh)
	_refresh()

func _on_state_changed() -> void:
	_refresh()

func _refresh() -> void:
	if game_state == null or game_state.board == null or label == null:
		return
	var lines: Array[String] = []
	lines.append("[Your]")
	var any_player := false
	for u: Unit in game_state.board.all_units():
		if u.owner_id != GameState.PLAYER:
			continue
		any_player = true
		lines.append(_format_unit(u))
	if not any_player:
		lines.append("  (none)")
	lines.append("")
	lines.append("[Enemy]")
	var any_enemy := false
	for u: Unit in game_state.board.all_units():
		if u.owner_id != GameState.ENEMY:
			continue
		any_enemy = true
		lines.append(_format_unit(u))
	if not any_enemy:
		lines.append("  (none)")
	label.text = "\n".join(lines)

func _format_unit(u: Unit) -> String:
	var name: String = u.data.unit_name if u.data != null else "?"
	var leader_tag := " *" if u.data != null and u.data.is_deck_leader else ""
	return "  %s%s  ATK %d  HP %d/%d" % [
		name, leader_tag, u.get_atk(), u.current_hp, u.get_max_hp()]
