class_name TitleScreen
extends Control

signal slot_selected(slot: int)   # 1, 2, or 3

# ── palette ───────────────────────────────────────────────────────────────────
const COL_BG          := Color(0.02, 0.01, 0.04)
const COL_CARD_NORM   := Color(0.06, 0.05, 0.10)
const COL_CARD_HOVER  := Color(0.11, 0.09, 0.19)
const COL_BORDER      := Color(0.28, 0.22, 0.45)
const COL_BORDER_HI   := Color(0.55, 0.42, 0.80)
const COL_GOLD        := Color(0.90, 0.68, 0.18)
const COL_WHITE       := Color(0.88, 0.86, 0.80)
const COL_DIM         := Color(0.50, 0.48, 0.58)
const COL_BTN_NORM    := Color(0.18, 0.13, 0.32)
const COL_BTN_HOVER   := Color(0.32, 0.24, 0.55)
const COL_BTN_PRESS   := Color(0.42, 0.32, 0.68)

# ── layout ────────────────────────────────────────────────────────────────────
const VIEWPORT_W: float = 1280.0
const CARD_W:     float = 310.0
const CARD_H:     float = 290.0
const CARD_GAP:   float = 30.0

var _fade_rect: ColorRect


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	# ── background ────────────────────────────────────────────────────────────
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = COL_BG
	add_child(bg)

	# ── title ─────────────────────────────────────────────────────────────────
	var title_lbl := Label.new()
	title_lbl.text = "ALPHA  PROGRAM"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title_lbl.offset_top    =  80.0
	title_lbl.offset_bottom = 145.0
	title_lbl.add_theme_font_size_override("font_size", 48)
	title_lbl.add_theme_color_override("font_color", COL_GOLD)
	add_child(title_lbl)

	# ── subtitle ──────────────────────────────────────────────────────────────
	var sub_lbl := Label.new()
	sub_lbl.text = "C O N T E N D E R   R E G I S T R Y"
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	sub_lbl.offset_top    = 148.0
	sub_lbl.offset_bottom = 182.0
	sub_lbl.add_theme_font_size_override("font_size", 14)
	sub_lbl.add_theme_color_override("font_color", COL_DIM)
	add_child(sub_lbl)

	# ── slot cards ────────────────────────────────────────────────────────────
	var total_w := CARD_W * 3.0 + CARD_GAP * 2.0
	var start_x := (VIEWPORT_W - total_w) / 2.0
	var card_y  := 210.0

	for i in 3:
		_build_slot_card(i + 1,
						 start_x + i * (CARD_W + CARD_GAP),
						 card_y)

	# ── keyboard hint ─────────────────────────────────────────────────────────
	var hint_lbl := Label.new()
	hint_lbl.text = "press  1 · 2 · 3  to select"
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hint_lbl.offset_top    = -100.0
	hint_lbl.offset_bottom =  -72.0
	hint_lbl.add_theme_font_size_override("font_size", 13)
	hint_lbl.add_theme_color_override("font_color", COL_DIM)
	add_child(hint_lbl)

	# ── footer quote ──────────────────────────────────────────────────────────
	var foot_lbl := Label.new()
	foot_lbl.text = "\"ONE WILL EXIT.\""
	foot_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	foot_lbl.offset_top    = -58.0
	foot_lbl.offset_bottom = -30.0
	foot_lbl.add_theme_font_size_override("font_size", 13)
	foot_lbl.add_theme_color_override("font_color", Color(0.35, 0.33, 0.42))
	add_child(foot_lbl)

	# ── fade-in overlay ───────────────────────────────────────────────────────
	_fade_rect = ColorRect.new()
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_rect.color = Color(0, 0, 0, 1)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade_rect)
	var tw := create_tween()
	tw.tween_property(_fade_rect, "color", Color(0, 0, 0, 0), 1.0)


# ── slot card builder ─────────────────────────────────────────────────────────

func _build_slot_card(slot: int, x: float, y: float) -> void:
	var summary: Dictionary = SaveData.get_summary(slot)

	# ── outer panel ───────────────────────────────────────────────────────────
	var panel := Panel.new()
	panel.position         = Vector2(x, y)
	panel.size             = Vector2(CARD_W, CARD_H)
	panel.mouse_filter     = Control.MOUSE_FILTER_STOP

	var sbox := StyleBoxFlat.new()
	sbox.bg_color = COL_CARD_NORM
	sbox.set_border_width_all(2)
	sbox.border_color = COL_BORDER
	sbox.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", sbox)
	add_child(panel)

	# Hover highlight — swap border on mouse_entered / exited
	panel.mouse_entered.connect(func() -> void:
		sbox.border_color = COL_BORDER_HI
		sbox.bg_color     = COL_CARD_HOVER)
	panel.mouse_exited.connect(func() -> void:
		sbox.border_color = COL_BORDER
		sbox.bg_color     = COL_CARD_NORM)

	# ── inner VBox ────────────────────────────────────────────────────────────
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left   =  20.0
	vbox.offset_right  = -20.0
	vbox.offset_top    =  20.0
	vbox.offset_bottom = -20.0
	vbox.alignment     = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	# Header: slot number
	var header := Label.new()
	header.text                      = "SLOT  %d" % slot
	header.horizontal_alignment      = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 26)
	header.add_theme_color_override("font_color", COL_GOLD)
	vbox.add_child(header)

	# Horizontal rule
	var sep := HSeparator.new()
	var sep_sbox := StyleBoxFlat.new()
	sep_sbox.bg_color = COL_BORDER
	sep_sbox.content_margin_top = 1.0
	sep.add_theme_stylebox_override("separator", sep_sbox)
	vbox.add_child(sep)

	# Body: save info or "new save"
	if not summary.exists:
		var new_lbl := Label.new()
		new_lbl.text                 = "NEW  SAVE"
		new_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		new_lbl.add_theme_font_size_override("font_size", 20)
		new_lbl.add_theme_color_override("font_color", COL_DIM)
		vbox.add_child(new_lbl)
	else:
		var esc: int  = summary.warriors_escaped
		var runs: int = summary.runs_completed

		var esc_lbl := Label.new()
		esc_lbl.text                 = "WARRIORS  ESCAPED\n%d  /  5" % esc
		esc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		esc_lbl.add_theme_font_size_override("font_size", 17)
		esc_lbl.add_theme_color_override("font_color", COL_WHITE)
		vbox.add_child(esc_lbl)

		var runs_lbl := Label.new()
		runs_lbl.text                 = "runs  completed:  %d" % runs
		runs_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		runs_lbl.add_theme_font_size_override("font_size", 13)
		runs_lbl.add_theme_color_override("font_color", COL_DIM)
		vbox.add_child(runs_lbl)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	# SELECT button
	var btn := Button.new()
	btn.text = "SELECT"
	btn.custom_minimum_size = Vector2(130.0, 44.0)
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", COL_WHITE)

	var btn_n := _btn_sbox(COL_BTN_NORM)
	var btn_h := _btn_sbox(COL_BTN_HOVER)
	var btn_p := _btn_sbox(COL_BTN_PRESS)
	btn.add_theme_stylebox_override("normal",   btn_n)
	btn.add_theme_stylebox_override("hover",    btn_h)
	btn.add_theme_stylebox_override("pressed",  btn_p)
	btn.add_theme_stylebox_override("focus",    btn_n)

	btn.pressed.connect(func() -> void: _emit_slot(slot))
	vbox.add_child(btn)


func _emit_slot(slot: int) -> void:
	# Fade out, then emit so the caller can hide this layer smoothly.
	var tw := create_tween()
	tw.tween_property(_fade_rect, "color", Color(0, 0, 0, 1), 0.4)
	tw.tween_callback(func() -> void: slot_selected.emit(slot))


func _btn_sbox(col: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = col
	s.set_corner_radius_all(6)
	s.content_margin_left   = 12.0
	s.content_margin_right  = 12.0
	s.content_margin_top    =  8.0
	s.content_margin_bottom =  8.0
	return s


# ── keyboard shortcut ─────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).pressed:
		match (event as InputEventKey).keycode:
			KEY_1: _emit_slot(1)
			KEY_2: _emit_slot(2)
			KEY_3: _emit_slot(3)
