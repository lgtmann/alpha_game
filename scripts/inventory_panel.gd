class_name InventoryPanel
extends PanelContainer

@onready var label: Label = $V/Label

var run_state: RunState = null

func bind(rs: RunState) -> void:
	run_state = rs
	rs.inventory_changed.connect(_refresh)
	rs.shards_changed.connect(_refresh)
	rs.player_deck_changed.connect(_refresh)
	rs.tech_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	if run_state == null or label == null:
		return
	var lines: Array[String] = []
	lines.append("RESOURCES")
	for r: StringName in Resources.ALL:
		var count: int = run_state.inventory.get(r, 0)
		lines.append("  %s: %d" % [r, count])
	var shard_lines: Array[String] = []
	for c: CardData in run_state.shards.keys():
		var count: int = run_state.shards[c]
		if count <= 0:
			continue
		shard_lines.append("  %s: %d/3" % [c.card_name, count])
	if shard_lines.size() > 0:
		lines.append("")
		lines.append("SHARDS")
		for sl: String in shard_lines:
			lines.append(sl)
	lines.append("")
	lines.append("TECH")
	lines.append("  Points: %d" % run_state.tech_points)
	if run_state.unlocked_techs.size() > 0:
		var names: Array[String] = []
		for tech_id: StringName in run_state.unlocked_techs.keys():
			var node := run_state.find_tech_node(tech_id)
			if node != null:
				names.append(node.node_name)
		if names.size() > 0:
			lines.append("  Unlocked: %s" % ", ".join(names))
	label.text = "\n".join(lines)
