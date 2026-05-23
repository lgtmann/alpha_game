class_name ShopScreen
extends Control

## Barter overlay — shown as a CanvasLayer child so it's immune to camera zoom.
## Call open(run_state) to display it; it emits shop_closed when dismissed.

signal shop_closed

const _SALESMAN_TEX := preload("res://art/salesman.png")
const FRAME_W: int = 482
const FRAME_H: int = 426

# Items for sale — defined once at load time.
const _KNIGHT_CARD  := preload("res://cards/data/summon_knight.tres")
const _FIREBALL_CARD := preload("res://cards/data/fireball.tres")
const _BLESS_CARD   := preload("res://cards/data/bless.tres")
const _ARROW_CARD   := preload("res://cards/data/arrow.tres")
const _QS_CARD      := preload("res://cards/data/quick_strike.tres")
const _DRAGON_CARD  := preload("res://cards/data/summon_dragon.tres")

var _run_state: RunState = null
var _items: Array[ShopItem] = []
var _res_labels: Dictionary = {}   # StringName -> Label
var _buy_buttons: Array[Button] = []
var _feedback_label: Label = null


func _ready() -> void:
	_items = _build_items()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	visible = false


# ── public ───────────────────────────────────────────────────────────────────

func open(rs: RunState) -> void:
	_run_state = rs
	visible = true
	_refresh()


# ── input ────────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()


# ── internals ────────────────────────────────────────────────────────────────

func _close() -> void:
	visible = false
	shop_closed.emit()


func _build_items() -> Array[ShopItem]:
	var out: Array[ShopItem] = []

	out.append(_card_item("Summon Knight",  _KNIGHT_CARD,
			{Resources.WOOD: 3, Resources.IRON: 2}))
	out.append(_card_item("Summon Dragon",  _DRAGON_CARD,
			{Resources.CRYSTAL: 2, Resources.SOUL: 1}))
	out.append(_card_item("Fireball",       _FIREBALL_CARD,
			{Resources.STONE: 2, Resources.CRYSTAL: 1}))
	out.append(_card_item("Bless",          _BLESS_CARD,
			{Resources.CRYSTAL: 1, Resources.SOUL: 1}))
	out.append(_card_item("Arrow",          _ARROW_CARD,
			{Resources.IRON: 2, Resources.STONE: 1}))
	out.append(_card_item("Quick Strike",   _QS_CARD,
			{Resources.IRON: 3}))

	var tech := ShopItem.new()
	tech.label              = "+3 Tech Points"
	tech.tech_points_reward = 3
	tech.cost               = {Resources.CRYSTAL: 2, Resources.SOUL: 1}
	out.append(tech)

	return out


static func _card_item(lbl: String, card: CardData, cost: Dictionary) -> ShopItem:
	var item := ShopItem.new()
	item.label = lbl
	item.card  = card
	item.cost  = cost
	return item


func _build_ui() -> void:
	# ── full-screen click-blocker backdrop ──
	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.0, 0.0, 0.0, 0.72)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	# ── centered panel ──
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(600, 0)
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 16)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# ── header: portrait + title + close ──
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	vbox.add_child(header)

	var portrait_tex := AtlasTexture.new()
	portrait_tex.atlas  = _SALESMAN_TEX
	portrait_tex.region = Rect2(0, FRAME_H * 3, FRAME_W, FRAME_H)   # row 3 — coat open
	var portrait := TextureRect.new()
	portrait.texture               = portrait_tex
	portrait.custom_minimum_size   = Vector2(72, 64)
	portrait.stretch_mode          = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(portrait)

	var title_col := VBoxContainer.new()
	title_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_col)

	var title_lbl := Label.new()
	title_lbl.text = "BLACK MARKET"
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_col.add_child(title_lbl)

	var sub_lbl := Label.new()
	sub_lbl.text = "What'll it be, stranger?"
	sub_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	title_col.add_child(sub_lbl)

	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(36, 36)
	close_btn.pressed.connect(_close)
	header.add_child(close_btn)

	vbox.add_child(HSeparator.new())

	# ── resource bar ──
	var res_row := HBoxContainer.new()
	res_row.add_theme_constant_override("separation", 14)
	vbox.add_child(res_row)

	var res_hdr := Label.new()
	res_hdr.text = "Resources:"
	res_row.add_child(res_hdr)

	for res_name: StringName in Resources.ALL:
		var lbl := Label.new()
		lbl.add_theme_color_override("font_color", Color(0.88, 0.76, 0.38))
		res_row.add_child(lbl)
		_res_labels[res_name] = lbl

	vbox.add_child(HSeparator.new())

	# ── item rows ──
	for i in range(_items.size()):
		var item: ShopItem = _items[i]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		vbox.add_child(row)

		var name_lbl := Label.new()
		name_lbl.text = item.label
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.custom_minimum_size = Vector2(160, 0)
		row.add_child(name_lbl)

		var cost_lbl := Label.new()
		cost_lbl.text = item.cost_string()
		cost_lbl.custom_minimum_size = Vector2(240, 0)
		cost_lbl.add_theme_color_override("font_color", Color(0.85, 0.70, 0.28))
		row.add_child(cost_lbl)

		var btn := Button.new()
		btn.text = "Buy"
		btn.custom_minimum_size = Vector2(64, 0)
		var idx := i   # capture by value
		btn.pressed.connect(func() -> void: _on_buy(idx))
		row.add_child(btn)
		_buy_buttons.append(btn)

	vbox.add_child(HSeparator.new())

	# ── feedback ──
	_feedback_label = Label.new()
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	vbox.add_child(_feedback_label)


func _refresh() -> void:
	_refresh_resources()
	_refresh_buttons()


func _refresh_resources() -> void:
	if _run_state == null:
		return
	for res_name: StringName in _res_labels:
		var lbl: Label = _res_labels[res_name]
		lbl.text = "%s %d" % [res_name, _run_state.get_resource_count(res_name)]


func _refresh_buttons() -> void:
	if _run_state == null:
		return
	for i in range(_buy_buttons.size()):
		_buy_buttons[i].disabled = not _items[i].can_afford(_run_state.inventory)


func _on_buy(idx: int) -> void:
	if _run_state == null:
		return
	var item: ShopItem = _items[idx]
	if not item.can_afford(_run_state.inventory):
		return

	# Deduct resources directly (RunState.inventory is a public Dictionary).
	for res: StringName in item.cost:
		_run_state.inventory[res] = _run_state.inventory.get(res, 0) - item.cost[res]
	_run_state.inventory_changed.emit()

	# Grant reward.
	if item.card != null:
		_run_state.add_card(item.card)
	if item.tech_points_reward > 0:
		_run_state.add_tech_points(item.tech_points_reward)

	_refresh()
	_flash_feedback("Bought: " + item.label)


func _flash_feedback(msg: String) -> void:
	if _feedback_label == null:
		return
	_feedback_label.text    = msg
	_feedback_label.modulate = Color(1, 1, 1, 1)
	var tw := create_tween()
	tw.tween_interval(1.4)
	tw.tween_property(_feedback_label, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func() -> void: _feedback_label.text = "")
