class_name DialogueBox
extends Control

signal choice_made(choice_id: String)

const BG_COL      := Color(0.06, 0.07, 0.09, 0.96)
const BORDER_COL  := Color(0.50, 0.42, 0.12, 1.0)
const NAME_COL    := Color(0.95, 0.80, 0.25, 1.0)
const TEXT_COL    := Color(0.88, 0.88, 0.80, 1.0)
const BTN_IDLE    := Color(0.13, 0.12, 0.16, 1.0)
const BTN_HOV     := Color(0.28, 0.22, 0.06, 1.0)
const BTN_TXT     := Color(0.95, 0.90, 0.65, 1.0)
const PANEL_H     := 160.0
const PORTRAIT_R  := 28.0

var _portrait_col: Color          = Color.WHITE
var _speaker_name: String         = ""
var _lines: Array[String]         = []
var _line_idx: int                = 0
var _choices: Array[Dictionary]   = []   # [{id:String, label:String}]

# Built nodes
var _portrait_rect: ColorRect
var _name_lbl:      Label
var _text_lbl:      Label
var _btn_row:       HBoxContainer
var _continue_btn:  Button

func _ready() -> void:
	# Full-screen anchor, contents drawn in the bottom strip
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP   # eat clicks behind dialogue

	# Dark panel at the bottom
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.set_offset(SIDE_TOP, -PANEL_H)
	panel.set_offset(SIDE_BOTTOM, 0.0)
	panel.set_offset(SIDE_LEFT, 0.0)
	panel.set_offset(SIDE_RIGHT, 0.0)
	var style := StyleBoxFlat.new()
	style.bg_color = BG_COL
	style.border_color = BORDER_COL
	style.set_border_width_all(2)
	style.set_corner_radius_all(0)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 16)
	panel.add_child(hbox)

	# Portrait + name on the left
	var left_vbox := VBoxContainer.new()
	left_vbox.custom_minimum_size = Vector2(PORTRAIT_R * 2.0 + 24.0, 0.0)
	left_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	left_vbox.add_theme_constant_override("separation", 6)
	hbox.add_child(left_vbox)

	_portrait_rect = ColorRect.new()
	_portrait_rect.custom_minimum_size = Vector2(PORTRAIT_R * 2.0, PORTRAIT_R * 2.0)
	# We draw a circle over it — just use it as backing size reference via _draw later.
	# Actually, use a simple square ColorRect clipped by a custom style.
	_portrait_rect.color = Color.TRANSPARENT
	left_vbox.add_child(_portrait_rect)

	_name_lbl = Label.new()
	_name_lbl.add_theme_color_override("font_color", NAME_COL)
	_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	left_vbox.add_child(_name_lbl)

	# Text + buttons on the right
	var right_vbox := VBoxContainer.new()
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.add_theme_constant_override("separation", 10)
	hbox.add_child(right_vbox)

	# Margin at top
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 14)
	right_vbox.add_child(margin)
	var margin_inner := VBoxContainer.new()
	margin.add_child(margin_inner)

	_text_lbl = Label.new()
	_text_lbl.add_theme_color_override("font_color", TEXT_COL)
	_text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_text_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin_inner.add_child(_text_lbl)

	_btn_row = HBoxContainer.new()
	_btn_row.add_theme_constant_override("separation", 8)
	margin_inner.add_child(_btn_row)

	_continue_btn = _make_btn("Continue >", "_on_continue")
	margin_inner.add_child(_continue_btn)

	# Portrait drawn via _draw — add a Node2D child for it
	var portrait_draw := _PortraitDraw.new()
	portrait_draw.dialogue_box = self
	_portrait_rect.add_child(portrait_draw)

	visible = false


## Open the dialogue with the given speaker, portrait colour, text lines, and final choices.
## choices is an Array of {id: String, label: String} dicts.
func open(speaker: String, portrait_col: Color, lines: Array[String], choices: Array[Dictionary]) -> void:
	_speaker_name = speaker
	_portrait_col = portrait_col
	_lines        = lines
	_line_idx     = 0
	_choices      = choices
	_show_line()
	visible = true


func _show_line() -> void:
	_name_lbl.text = _speaker_name
	_text_lbl.text = _lines[_line_idx] if _line_idx < _lines.size() else ""
	var is_last := _line_idx >= _lines.size() - 1
	_continue_btn.visible = not is_last
	_btn_row.visible = is_last
	if is_last:
		_rebuild_choice_buttons()
	# Redraw portrait
	for child in _portrait_rect.get_children():
		if child.has_method("queue_redraw"):
			child.queue_redraw()


func _rebuild_choice_buttons() -> void:
	for child in _btn_row.get_children():
		child.queue_free()
	for c: Dictionary in _choices:
		var btn := _make_btn(c.get("label", "?"), "")
		btn.pressed.connect(_on_choice.bind(c.get("id", "")))
		_btn_row.add_child(btn)


func _make_btn(label: String, method: String) -> Button:
	var btn := Button.new()
	btn.text = label
	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = BTN_IDLE
	style_normal.set_border_width_all(1)
	style_normal.border_color = BORDER_COL
	style_normal.set_corner_radius_all(3)
	var style_hover := StyleBoxFlat.new()
	style_hover.bg_color = BTN_HOV
	style_hover.set_border_width_all(1)
	style_hover.border_color = NAME_COL
	style_hover.set_corner_radius_all(3)
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover",  style_hover)
	btn.add_theme_stylebox_override("pressed", style_hover)
	btn.add_theme_color_override("font_color", BTN_TXT)
	if method != "":
		btn.pressed.connect(Callable(self, method))
	return btn


func _on_continue() -> void:
	_line_idx += 1
	_show_line()


func _on_choice(choice_id: String) -> void:
	visible = false
	choice_made.emit(choice_id)


class _PortraitDraw extends Node2D:
	var dialogue_box: DialogueBox = null
	func _draw() -> void:
		if dialogue_box == null:
			return
		var r: float = DialogueBox.PORTRAIT_R
		draw_circle(Vector2(r, r), r, dialogue_box._portrait_col)
		# Darker rim
		draw_arc(Vector2(r, r), r, 0.0, TAU, 32, Color(0.0, 0.0, 0.0, 0.4), 2.0)
