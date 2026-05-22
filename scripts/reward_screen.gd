class_name RewardScreen
extends Control

signal next_battle_requested
signal restart_run_requested

const CARD_VIEW_SCENE := preload("res://scenes/card_view.tscn")
const RARE_PICK_AMOUNT: int = 2
const TECH_POINTS_PER_PICK: int = 1

const SIDE_NAMES := ["Front", "Front-R", "Back-R", "Back", "Back-L", "Front-L"]

# Each entry: [type, strength]. The editor cycles through these.
const SIDE_CONFIGS := [
	[SideUpgrade.Type.NONE, 0],
	[SideUpgrade.Type.SHIELD, 1],
	[SideUpgrade.Type.SHIELD, 2],
	[SideUpgrade.Type.SHIELD, 3],
	[SideUpgrade.Type.CANNON, 1],
	[SideUpgrade.Type.CANNON, 2],
	[SideUpgrade.Type.CANNON, 3],
	[SideUpgrade.Type.ACCELERATOR, 1],
	[SideUpgrade.Type.ACCELERATOR, 2],
]

@onready var title_label: Label = $Center/Panel/V/TitleLabel
@onready var drops_label: Label = $Center/Panel/V/DropsLabel
@onready var tool_buttons: HBoxContainer = $Center/Panel/V/ToolButtons
@onready var view_deck_btn: Button = $Center/Panel/V/ToolButtons/ViewDeckButton
@onready var workshop_btn: Button = $Center/Panel/V/ToolButtons/WorkshopButton
@onready var tech_tree_btn: Button = $Center/Panel/V/ToolButtons/TechTreeButton
@onready var leader_editor_btn: Button = $Center/Panel/V/ToolButtons/LeaderEditorButton
@onready var pick_box: VBoxContainer = $Center/Panel/V/PickBox
@onready var cards_btn: Button = $Center/Panel/V/PickBox/ButtonRow/CardsButton
@onready var tech_btn: Button = $Center/Panel/V/PickBox/ButtonRow/TechButton
@onready var resources_btn: Button = $Center/Panel/V/PickBox/ButtonRow/ResourcesButton
@onready var tribute_box: VBoxContainer = $Center/Panel/V/TributeBox
@onready var tribute_cards_row: HBoxContainer = $Center/Panel/V/TributeBox/CardsRow
@onready var resources_box: VBoxContainer = $Center/Panel/V/ResourcesBox
@onready var crystal_btn: Button = $Center/Panel/V/ResourcesBox/ButtonRow/CrystalButton
@onready var soul_btn: Button = $Center/Panel/V/ResourcesBox/ButtonRow/SoulButton
@onready var deck_box: VBoxContainer = $Center/Panel/V/DeckBox
@onready var deck_grid: GridContainer = $Center/Panel/V/DeckBox/Scroll/Grid
@onready var deck_back_btn: Button = $Center/Panel/V/DeckBox/BackButton
@onready var workshop_box: VBoxContainer = $Center/Panel/V/WorkshopBox
@onready var workshop_list: VBoxContainer = $Center/Panel/V/WorkshopBox/Scroll/RecipeList
@onready var workshop_back_btn: Button = $Center/Panel/V/WorkshopBox/BackButton
@onready var tech_tree_box: VBoxContainer = $Center/Panel/V/TechTreeBox
@onready var tech_tree_header: Label = $Center/Panel/V/TechTreeBox/HeaderLabel
@onready var econ_column: VBoxContainer = $Center/Panel/V/TechTreeBox/ColumnsRow/EconomyColumn
@onready var combat_column: VBoxContainer = $Center/Panel/V/TechTreeBox/ColumnsRow/CombatColumn
@onready var tech_tree_back_btn: Button = $Center/Panel/V/TechTreeBox/BackButton
@onready var leader_editor_box: VBoxContainer = $Center/Panel/V/LeaderEditorBox
@onready var leader_picker_host: CenterContainer = $Center/Panel/V/LeaderEditorBox/PickerHost
@onready var leader_selection_label: Label = $Center/Panel/V/LeaderEditorBox/SelectionLabel
@onready var leader_cycle_btn: Button = $Center/Panel/V/LeaderEditorBox/CycleButton
@onready var first_mate_option: OptionButton = $Center/Panel/V/LeaderEditorBox/FirstMateRow/FirstMateOption
@onready var cargo_option: OptionButton = $Center/Panel/V/LeaderEditorBox/CargoRow/CargoOption
@onready var hand_size_label: Label = $Center/Panel/V/LeaderEditorBox/HandSizeRow/HandSizeLabel
@onready var hand_size_minus_btn: Button = $Center/Panel/V/LeaderEditorBox/HandSizeRow/HandSizeMinus
@onready var hand_size_plus_btn: Button = $Center/Panel/V/LeaderEditorBox/HandSizeRow/HandSizePlus
@onready var energy_label: Label = $Center/Panel/V/LeaderEditorBox/EnergyRow/EnergyLabel
@onready var energy_minus_btn: Button = $Center/Panel/V/LeaderEditorBox/EnergyRow/EnergyMinus
@onready var energy_plus_btn: Button = $Center/Panel/V/LeaderEditorBox/EnergyRow/EnergyPlus
@onready var leader_editor_back_btn: Button = $Center/Panel/V/LeaderEditorBox/BackButton
var leader_side_picker: HexSidePicker = null
var _first_mate_choices: Array[CardData] = []
var _cargo_choices: Array[CardData] = []
@onready var done_message: Label = $Center/Panel/V/DoneMessage
@onready var next_battle_btn: Button = $Center/Panel/V/NextBattleButton
@onready var restart_btn: Button = $Center/Panel/V/RestartButton

var defeated_deck: Array[CardData] = []
var run_state: RunState = null
var picked_reward: bool = false

var _vis_stash: Dictionary = {}

func _ready() -> void:
	visible = false
	cards_btn.pressed.connect(_on_cards_pressed)
	tech_btn.pressed.connect(_on_tech_pressed)
	resources_btn.pressed.connect(_on_resources_pressed)
	view_deck_btn.pressed.connect(_on_view_deck_pressed)
	workshop_btn.pressed.connect(_on_workshop_pressed)
	tech_tree_btn.pressed.connect(_on_tech_tree_pressed)
	leader_editor_btn.pressed.connect(_on_leader_editor_pressed)
	deck_back_btn.pressed.connect(_on_deck_back_pressed)
	workshop_back_btn.pressed.connect(_on_workshop_back_pressed)
	tech_tree_back_btn.pressed.connect(_on_tech_tree_back_pressed)
	leader_editor_back_btn.pressed.connect(_on_leader_editor_back_pressed)
	leader_cycle_btn.pressed.connect(_on_leader_cycle_pressed)
	hand_size_minus_btn.pressed.connect(_on_hand_size_delta.bind(-1))
	hand_size_plus_btn.pressed.connect(_on_hand_size_delta.bind(1))
	energy_minus_btn.pressed.connect(_on_energy_delta.bind(-1))
	energy_plus_btn.pressed.connect(_on_energy_delta.bind(1))
	first_mate_option.item_selected.connect(_on_first_mate_selected)
	cargo_option.item_selected.connect(_on_cargo_selected)
	leader_side_picker = HexSidePicker.new()
	leader_picker_host.add_child(leader_side_picker)
	leader_side_picker.side_picked.connect(_on_leader_side_picked)
	next_battle_btn.pressed.connect(_on_next_pressed)
	restart_btn.pressed.connect(_on_restart_pressed)
	crystal_btn.pressed.connect(_on_rare_picked.bind(Resources.CRYSTAL))
	soul_btn.pressed.connect(_on_rare_picked.bind(Resources.SOUL))

func show_victory(enemy_deck: Array[CardData], rs: RunState, is_final: bool) -> void:
	defeated_deck = enemy_deck.duplicate()
	run_state = rs
	picked_reward = false
	_clear_tribute_row()
	_clear_deck_grid()
	_clear_workshop_list()
	_clear_tech_columns()
	_clear_editor_rows()
	_reset_buttons()
	title_label.text = _victory_title(rs, is_final)
	tool_buttons.visible = true
	pick_box.visible = not is_final
	tribute_box.visible = false
	resources_box.visible = false
	deck_box.visible = false
	workshop_box.visible = false
	tech_tree_box.visible = false
	leader_editor_box.visible = false
	done_message.visible = is_final
	done_message.text = "You defeated every opponent." if is_final else ""
	next_battle_btn.visible = false
	restart_btn.visible = is_final
	if is_final:
		restart_btn.text = "Start New Run"
	_populate_drops()
	visible = true

func show_defeat() -> void:
	picked_reward = false
	_clear_tribute_row()
	_clear_deck_grid()
	_clear_workshop_list()
	_clear_tech_columns()
	_clear_editor_rows()
	_reset_buttons()
	title_label.text = "Defeat"
	tool_buttons.visible = false
	pick_box.visible = false
	tribute_box.visible = false
	resources_box.visible = false
	deck_box.visible = false
	workshop_box.visible = false
	tech_tree_box.visible = false
	leader_editor_box.visible = false
	done_message.visible = true
	done_message.text = "Your hero has fallen."
	next_battle_btn.visible = false
	restart_btn.visible = true
	restart_btn.text = "Restart Run"
	drops_label.visible = false
	visible = true

func _victory_title(rs: RunState, is_final: bool) -> String:
	if is_final:
		return "Run Complete!"
	var idx: int = rs.encounter_index + 1
	var total: int = rs.encounters.size()
	return "Victory! — %d / %d" % [idx, total]

func _reset_buttons() -> void:
	crystal_btn.disabled = false
	soul_btn.disabled = false

func _clear_tribute_row() -> void:
	for child in tribute_cards_row.get_children():
		child.queue_free()

func _clear_deck_grid() -> void:
	for child in deck_grid.get_children():
		child.queue_free()

func _clear_workshop_list() -> void:
	for child in workshop_list.get_children():
		child.queue_free()

func _clear_tech_columns() -> void:
	for col: VBoxContainer in [econ_column, combat_column]:
		var children := col.get_children()
		for i in range(children.size() - 1, 0, -1):
			children[i].queue_free()

func _clear_editor_rows() -> void:
	pass

func _populate_drops() -> void:
	if run_state == null:
		drops_label.visible = false
		return
	var lines: Array[String] = []
	if run_state.last_battle_resources.size() > 0:
		lines.append("Resources gained:")
		for r: StringName in run_state.last_battle_resources.keys():
			lines.append("  %s +%d" % [r, run_state.last_battle_resources[r]])
	if run_state.last_battle_shards.size() > 0:
		lines.append("Shards gained:")
		for c: CardData in run_state.last_battle_shards.keys():
			var got: int = run_state.last_battle_shards[c]
			var total: int = run_state.shards.get(c, 0)
			lines.append("  %s shard +%d (now %d/3)" % [c.card_name, got, total])
	if run_state.last_battle_cards_unlocked.size() > 0:
		lines.append("Cards unlocked:")
		for c: CardData in run_state.last_battle_cards_unlocked:
			lines.append("  * %s" % c.card_name)
	if lines.size() == 0:
		drops_label.visible = false
		return
	drops_label.text = "\n".join(lines)
	drops_label.visible = true

# --- Visibility stash for overlay sub-views ---------------------------------

func _stash_main_views() -> void:
	_vis_stash = {
		"tools": tool_buttons.visible,
		"pick": pick_box.visible,
		"tribute": tribute_box.visible,
		"resources": resources_box.visible,
		"done": done_message.visible,
		"next": next_battle_btn.visible,
		"restart": restart_btn.visible,
		"drops": drops_label.visible,
	}
	tool_buttons.visible = false
	pick_box.visible = false
	tribute_box.visible = false
	resources_box.visible = false
	done_message.visible = false
	next_battle_btn.visible = false
	restart_btn.visible = false
	drops_label.visible = false

func _restore_main_views() -> void:
	tool_buttons.visible = _vis_stash.get("tools", true)
	pick_box.visible = _vis_stash.get("pick", false)
	tribute_box.visible = _vis_stash.get("tribute", false)
	resources_box.visible = _vis_stash.get("resources", false)
	done_message.visible = _vis_stash.get("done", false)
	next_battle_btn.visible = _vis_stash.get("next", false)
	restart_btn.visible = _vis_stash.get("restart", false)
	drops_label.visible = _vis_stash.get("drops", false)

# --- View Deck ---------------------------------------------------------------

func _on_view_deck_pressed() -> void:
	_stash_main_views()
	_populate_deck_grid()
	deck_box.visible = true

func _on_deck_back_pressed() -> void:
	deck_box.visible = false
	_restore_main_views()

func _populate_deck_grid() -> void:
	_clear_deck_grid()
	if run_state == null:
		return
	for card: CardData in run_state.player_deck:
		var cv: CardView = CARD_VIEW_SCENE.instantiate()
		deck_grid.add_child(cv)
		cv.set_card(card)
		cv.set_interactive(false)

# --- Workshop ---------------------------------------------------------------

func _on_workshop_pressed() -> void:
	_stash_main_views()
	_populate_workshop()
	workshop_box.visible = true

func _on_workshop_back_pressed() -> void:
	workshop_box.visible = false
	_restore_main_views()

func _populate_workshop() -> void:
	_clear_workshop_list()
	if run_state == null:
		return
	for recipe: CraftingRecipe in run_state.recipes:
		var row := _build_recipe_row(recipe)
		workshop_list.add_child(row)

func _build_recipe_row(recipe: CraftingRecipe) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)

	var cv: CardView = CARD_VIEW_SCENE.instantiate()
	cv.set_card(recipe.output_card)
	cv.set_interactive(false)
	row.add_child(cv)

	var info := Label.new()
	info.text = "Cost: " + recipe.cost_description()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)

	var btn := Button.new()
	btn.text = "Craft"
	btn.custom_minimum_size = Vector2(100, 50)
	btn.disabled = not recipe.can_afford(run_state.inventory)
	btn.pressed.connect(_on_craft_pressed.bind(recipe))
	row.add_child(btn)

	return row

func _on_craft_pressed(recipe: CraftingRecipe) -> void:
	if run_state == null:
		return
	if run_state.craft(recipe):
		_populate_workshop()

# --- Tech Tree --------------------------------------------------------------

func _on_tech_tree_pressed() -> void:
	_stash_main_views()
	_populate_tech_tree()
	tech_tree_box.visible = true

func _on_tech_tree_back_pressed() -> void:
	tech_tree_box.visible = false
	_restore_main_views()

func _populate_tech_tree() -> void:
	_clear_tech_columns()
	if run_state == null:
		return
	tech_tree_header.text = "Tech Tree — Points available: %d" % run_state.tech_points
	for node: TechNode in run_state.tech_nodes:
		var btn := _build_tech_button(node)
		if node.branch == &"economy":
			econ_column.add_child(btn)
		else:
			combat_column.add_child(btn)

func _build_tech_button(node: TechNode) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(220, 56)
	btn.tooltip_text = node.description
	var unlocked: bool = run_state.is_tech_unlocked(node.id)
	var prereqs_met: bool = run_state.tech_prereqs_met(node)
	var affordable: bool = run_state.tech_points >= node.cost
	if unlocked:
		btn.text = "[✓] %s" % node.node_name
		btn.disabled = true
		btn.self_modulate = Color(0.65, 1.0, 0.65, 1.0)
	elif not prereqs_met:
		btn.text = "%s (%d) — locked" % [node.node_name, node.cost]
		btn.disabled = true
		btn.self_modulate = Color(0.55, 0.55, 0.55, 1.0)
	elif not affordable:
		btn.text = "%s (%d tp)" % [node.node_name, node.cost]
		btn.disabled = true
	else:
		btn.text = "%s (%d tp)" % [node.node_name, node.cost]
		btn.disabled = false
		btn.pressed.connect(_on_tech_clicked.bind(node))
	return btn

func _on_tech_clicked(node: TechNode) -> void:
	if run_state == null:
		return
	if run_state.unlock_tech(node):
		_populate_tech_tree()

# --- Leader Editor ---------------------------------------------------------

func _on_leader_editor_pressed() -> void:
	_stash_main_views()
	_populate_leader_editor()
	leader_editor_box.visible = true

func _on_leader_editor_back_pressed() -> void:
	leader_editor_box.visible = false
	_restore_main_views()

func _populate_leader_editor() -> void:
	if run_state == null or leader_side_picker == null:
		return
	leader_side_picker.set_sides(run_state.hero_sides)
	leader_side_picker.select_side(leader_side_picker.selected_idx)
	_refresh_leader_selection_label()
	_populate_first_mate_dropdown()
	_populate_cargo_dropdown()
	_refresh_stat_labels()

func _populate_first_mate_dropdown() -> void:
	first_mate_option.clear()
	_first_mate_choices.clear()
	first_mate_option.add_item("— None —")
	_first_mate_choices.append(null)
	var seen: Dictionary = {}
	for c: CardData in run_state.player_deck:
		if c == null or not RunState.is_unit_card(c) or seen.has(c.card_name):
			continue
		seen[c.card_name] = true
		_first_mate_choices.append(c)
		first_mate_option.add_item(c.card_name)
	var selected_idx: int = 0
	if run_state.first_mate != null:
		for i in range(_first_mate_choices.size()):
			if _first_mate_choices[i] != null and _first_mate_choices[i].card_name == run_state.first_mate.card_name:
				selected_idx = i
				break
	first_mate_option.select(selected_idx)

func _populate_cargo_dropdown() -> void:
	cargo_option.clear()
	_cargo_choices.clear()
	cargo_option.add_item("— None —")
	_cargo_choices.append(null)
	var seen: Dictionary = {}
	for c: CardData in run_state.player_deck:
		if c == null or RunState.is_unit_card(c) or seen.has(c.card_name):
			continue
		seen[c.card_name] = true
		_cargo_choices.append(c)
		cargo_option.add_item(c.card_name)
	var selected_idx: int = 0
	if run_state.priority_cargo != null:
		for i in range(_cargo_choices.size()):
			if _cargo_choices[i] != null and _cargo_choices[i].card_name == run_state.priority_cargo.card_name:
				selected_idx = i
				break
	cargo_option.select(selected_idx)

func _refresh_stat_labels() -> void:
	if run_state == null:
		return
	hand_size_label.text = "Hand Size bonus: +%d  (max +%d)" % [
		run_state.hand_size_bonus, RunState.HAND_SIZE_BONUS_MAX]
	energy_label.text = "Energy/Turn bonus: +%d  (max +%d)" % [
		run_state.energy_bonus, RunState.ENERGY_BONUS_MAX]

func _on_first_mate_selected(idx: int) -> void:
	if run_state == null or idx < 0 or idx >= _first_mate_choices.size():
		return
	run_state.set_first_mate(_first_mate_choices[idx])

func _on_cargo_selected(idx: int) -> void:
	if run_state == null or idx < 0 or idx >= _cargo_choices.size():
		return
	run_state.set_priority_cargo(_cargo_choices[idx])

func _on_hand_size_delta(delta: int) -> void:
	if run_state == null:
		return
	run_state.set_hand_size_bonus(run_state.hand_size_bonus + delta)
	_refresh_stat_labels()

func _on_energy_delta(delta: int) -> void:
	if run_state == null:
		return
	run_state.set_energy_bonus(run_state.energy_bonus + delta)
	_refresh_stat_labels()

func _get_hero_side(idx: int) -> SideUpgrade:
	if run_state == null or idx < 0 or idx >= run_state.hero_sides.size():
		return null
	return run_state.hero_sides[idx]

func _config_index_for(side: SideUpgrade) -> int:
	if side == null:
		return 0
	for i in range(SIDE_CONFIGS.size()):
		if int(SIDE_CONFIGS[i][0]) == side.type and int(SIDE_CONFIGS[i][1]) == side.strength:
			return i
	return 0

func _config_label(cfg_idx: int) -> String:
	var t: int = int(SIDE_CONFIGS[cfg_idx][0])
	var s: int = int(SIDE_CONFIGS[cfg_idx][1])
	if t == SideUpgrade.Type.NONE:
		return "None"
	var nm := "Shield"
	match t:
		SideUpgrade.Type.SHIELD: nm = "Shield"
		SideUpgrade.Type.CANNON: nm = "Cannon"
		SideUpgrade.Type.ACCELERATOR: nm = "Accelerator"
	return "%s %d" % [nm, s]

func _refresh_leader_selection_label() -> void:
	if leader_side_picker == null:
		return
	var idx: int = leader_side_picker.selected_idx
	var cfg_idx: int = _config_index_for(_get_hero_side(idx))
	leader_selection_label.text = "%s: %s" % [SIDE_NAMES[idx], _config_label(cfg_idx)]

func _on_leader_side_picked(idx: int) -> void:
	_refresh_leader_selection_label()

func _on_leader_cycle_pressed() -> void:
	if run_state == null or leader_side_picker == null:
		return
	var idx: int = leader_side_picker.selected_idx
	var cfg_idx: int = _config_index_for(_get_hero_side(idx))
	cfg_idx = (cfg_idx + 1) % SIDE_CONFIGS.size()
	run_state.set_hero_side(idx, int(SIDE_CONFIGS[cfg_idx][0]), int(SIDE_CONFIGS[cfg_idx][1]))
	leader_side_picker.set_sides(run_state.hero_sides)
	_refresh_leader_selection_label()

# --- Tribute / Resources / Tech / Next / Restart -----------------------------

func _on_cards_pressed() -> void:
	if picked_reward:
		return
	pick_box.visible = false
	tribute_box.visible = true
	_populate_tribute_cards()

func _populate_tribute_cards() -> void:
	_clear_tribute_row()
	var pool := defeated_deck.duplicate()
	pool.shuffle()
	var n: int = mini(3, pool.size())
	for i in range(n):
		var card_view: CardView = CARD_VIEW_SCENE.instantiate()
		tribute_cards_row.add_child(card_view)
		card_view.set_card(pool[i])
		card_view.set_clickable(true)
		card_view.clicked.connect(_on_card_picked.bind(pool[i]))

func _on_card_picked(card: CardData) -> void:
	if picked_reward:
		return
	picked_reward = true
	if run_state != null:
		run_state.add_card(card)
	for child in tribute_cards_row.get_children():
		var cv := child as CardView
		if cv == null:
			continue
		cv.set_clickable(false)
		if cv.card_data != card:
			cv.modulate.a = 0.35
	next_battle_btn.visible = true

func _on_resources_pressed() -> void:
	if picked_reward:
		return
	pick_box.visible = false
	resources_box.visible = true

func _on_rare_picked(rare: StringName) -> void:
	if picked_reward:
		return
	picked_reward = true
	if run_state != null:
		run_state.add_resource(rare, RARE_PICK_AMOUNT)
	crystal_btn.disabled = true
	soul_btn.disabled = true
	next_battle_btn.visible = true

func _on_tech_pressed() -> void:
	if picked_reward:
		return
	picked_reward = true
	if run_state != null:
		run_state.add_tech_points(TECH_POINTS_PER_PICK)
	pick_box.visible = false
	next_battle_btn.visible = true
	_stash_main_views()
	_populate_tech_tree()
	tech_tree_box.visible = true

func _on_next_pressed() -> void:
	visible = false
	next_battle_requested.emit()

func _on_restart_pressed() -> void:
	visible = false
	restart_run_requested.emit()
