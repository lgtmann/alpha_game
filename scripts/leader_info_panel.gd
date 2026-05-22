class_name LeaderInfoPanel
extends PanelContainer

@onready var header_label: Label = $V/HeaderLabel
@onready var stats_label: Label = $V/StatsLabel
@onready var abilities_label: Label = $V/AbilitiesLabel

var game_state: GameState = null

func bind(gs: GameState) -> void:
	game_state = gs
	gs.energy_changed.connect(_on_state_changed.unbind(2))
	gs.turn_started.connect(_on_state_changed.unbind(2))
	gs.unit_destroyed.connect(_on_state_changed.unbind(1))
	gs.game_ended.connect(_on_state_changed.unbind(1))
	if gs.board != null:
		gs.board.units_changed.connect(_on_state_changed)
	_refresh()

func _on_state_changed() -> void:
	_refresh()

func _refresh() -> void:
	if game_state == null or header_label == null:
		return
	var leader_data: UnitData = game_state.player_leader_data
	if leader_data == null:
		header_label.text = "LEADER: —"
		stats_label.text = ""
		abilities_label.text = ""
		abilities_label.visible = false
		return

	header_label.text = "LEADER: %s" % leader_data.unit_name
	var unit_count: int = 0
	if game_state.board != null:
		unit_count = game_state.board.count_units(GameState.PLAYER)
	var stats_lines: Array[String] = []
	stats_lines.append("ATK %d  HP %d  SPD %d  RNG %d" % [
		leader_data.atk, leader_data.max_hp, leader_data.speed, leader_data.attack_range])
	stats_lines.append("Hand %d  Energy +%d/turn" % [
		leader_data.hand_size, leader_data.energy_per_turn])
	stats_lines.append("Units %d / %d  Cap %d" % [
		unit_count, leader_data.max_units, leader_data.max_energy_cap])
	stats_label.text = "\n".join(stats_lines)

	var ab_lines: Array[String] = []
	for r in leader_data.leader_abilities:
		var ability := r as LeaderAbility
		if ability == null:
			continue
		var name_str: String = ability.ability_name if ability.ability_name != "" else "Ability"
		if ability.description != "":
			ab_lines.append("• %s — %s" % [name_str, ability.description])
		else:
			ab_lines.append("• %s" % name_str)
	if ab_lines.size() > 0:
		abilities_label.text = "ABILITIES:\n" + "\n".join(ab_lines)
		abilities_label.visible = true
	else:
		abilities_label.text = ""
		abilities_label.visible = false
