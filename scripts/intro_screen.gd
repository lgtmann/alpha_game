class_name IntroScreen
extends Control

signal intro_finished

# ── Slide definitions ─────────────────────────────────────────────────────────
const SLIDES: Array[Dictionary] = [
	{
		bg       = Color(0.02, 0.01, 0.03),
		show_vat = true,
		lines    = ["BATCH 7-ALPHA.", "INITIATION COMPLETE.", "CONTENDER ONLINE."],
		col      = Color(0.90, 0.68, 0.18),   # amber
	},
	{
		bg       = Color(0.03, 0.05, 0.04),
		show_vat = false,
		lines    = ["Your eyes open.", "The fluid tastes like rust.", "Around you, others stir in their tubes."],
		col      = Color(0.86, 0.86, 0.76),   # warm cream
	},
	{
		bg       = Color(0.02, 0.02, 0.06),
		show_vat = false,
		lines    = ["The AI's voice fills the chamber.", "\"ONE WILL EXIT.\"", "\"THE REST WILL NOT.\"", "\"BEGIN.\""],
		col      = Color(0.68, 0.82, 0.98),   # cold blue-white
	},
]

const CHAR_INTERVAL := 0.035   # seconds per character (typewriter speed)
const AUTO_ADVANCE  := 4.0     # seconds before auto-advancing after all lines shown

# ── State ─────────────────────────────────────────────────────────────────────
var _slide_idx:   int   = 0
var _line_idx:    int   = 0
var _char_idx:    int   = 0
var _all_shown:   bool  = false
var _char_timer:  float = 0.0
var _auto_timer:  float = 0.0
var _fading_out:  bool  = false

# ── Built nodes ───────────────────────────────────────────────────────────────
const _VAT_TEX        := preload("res://art/vat_with_human.png")
const _VAT_FRAME_PX:    int   = 256
const _VAT_DISPLAY_PX:  float = 200.0   # approx 1/4 of 800px screen height
const _VAT_SHEET_COLS:  int   = 4
const _VAT_ANIM_FPS:    float = 2.5

var _bg:          ColorRect
var _vat_node:    AnimatedSprite2D
var _text_labels: Array[Label] = []
var _prompt_lbl:  Label
var _fade_rect:   ColorRect    # black overlay for fade-in/out


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Background
	_bg = ColorRect.new()
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.color = SLIDES[0].bg
	add_child(_bg)

	# Vat sprite — row 0 (blue-lit), 4-frame bubble animation
	var frames := SpriteFrames.new()
	frames.add_animation(&"idle")
	frames.set_animation_loop(&"idle", true)
	frames.set_animation_speed(&"idle", _VAT_ANIM_FPS)
	for col in _VAT_SHEET_COLS:
		var atlas := AtlasTexture.new()
		atlas.atlas  = _VAT_TEX
		atlas.region = Rect2(col * _VAT_FRAME_PX, 0, _VAT_FRAME_PX, _VAT_FRAME_PX)
		frames.add_frame(&"idle", atlas)
	_vat_node = AnimatedSprite2D.new()
	_vat_node.sprite_frames = frames
	_vat_node.scale    = Vector2.ONE * (_VAT_DISPLAY_PX / float(_VAT_FRAME_PX))
	_vat_node.position = Vector2(640.0, 280.0)
	_vat_node.play(&"idle")
	add_child(_vat_node)

	# Text labels — up to 4 lines, centered in the lower portion
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	# Anchor VBox center-x, positioned in lower half
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.offset_top    = 150.0
	vbox.offset_bottom = 300.0
	vbox.offset_left   = -450.0
	vbox.offset_right  =  450.0
	add_child(vbox)

	for i in 4:
		var lbl := Label.new()
		lbl.text = ""
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		lbl.custom_minimum_size = Vector2(900.0, 0.0)
		lbl.add_theme_font_size_override("font_size", 18)
		vbox.add_child(lbl)
		_text_labels.append(lbl)

	# Prompt label
	_prompt_lbl = Label.new()
	_prompt_lbl.text = "— press any key —"
	_prompt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_prompt_lbl.offset_top  = -60.0
	_prompt_lbl.add_theme_font_size_override("font_size", 14)
	_prompt_lbl.modulate = Color(0.7, 0.7, 0.7, 1.0)
	_prompt_lbl.visible = false
	add_child(_prompt_lbl)

	# Fade overlay (topmost)
	_fade_rect = ColorRect.new()
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_rect.color = Color(0, 0, 0, 1)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade_rect)

	# Apply slide 0 state
	_begin_slide(0)

	# Fade in
	var tw := create_tween()
	tw.tween_property(_fade_rect, "color", Color(0, 0, 0, 0), 0.8)


func _process(delta: float) -> void:
	if _fading_out:
		return

	# Typewriter
	if not _all_shown:
		_char_timer -= delta
		if _char_timer <= 0.0:
			_char_timer = CHAR_INTERVAL
			_advance_char()
	else:
		_auto_timer -= delta
		if _auto_timer <= 0.0:
			_advance()

	# Prompt visibility: only on last slide when fully shown
	_prompt_lbl.visible = (_slide_idx == SLIDES.size() - 1 and _all_shown)


func _unhandled_input(event: InputEvent) -> void:
	if _fading_out:
		return
	var is_press: bool = (event is InputEventKey and (event as InputEventKey).pressed) \
		or (event is InputEventMouseButton and (event as InputEventMouseButton).pressed)
	if not is_press:
		return
	get_viewport().set_input_as_handled()
	if not _all_shown:
		_show_all_text()
		_all_shown = true
		_auto_timer = AUTO_ADVANCE
	else:
		_advance()


# ── Slide management ──────────────────────────────────────────────────────────

func _begin_slide(idx: int) -> void:
	_slide_idx  = idx
	_line_idx   = 0
	_char_idx   = 0
	_all_shown  = false
	_auto_timer = AUTO_ADVANCE
	_char_timer = CHAR_INTERVAL

	var slide: Dictionary = SLIDES[idx]
	_bg.color = slide.bg
	_vat_node.visible = slide.show_vat

	# Apply text color and clear labels
	var col: Color = slide.col
	for lbl in _text_labels:
		lbl.text = ""
		lbl.add_theme_color_override("font_color", col)

	# Font size: larger for the AI (slide 2)
	var fsize := 22 if idx == 2 else 18
	for lbl in _text_labels:
		lbl.add_theme_font_size_override("font_size", fsize)


func _advance_char() -> void:
	var slide: Dictionary = SLIDES[_slide_idx]
	var lines: Array = slide.lines

	if _line_idx >= lines.size():
		_all_shown = true
		return

	var full_line: String = lines[_line_idx]

	if _char_idx <= full_line.length():
		_text_labels[_line_idx].text = full_line.substr(0, _char_idx)
		_char_idx += 1
	else:
		# Move to next line
		_text_labels[_line_idx].text = full_line
		_line_idx += 1
		_char_idx  = 0
		if _line_idx >= lines.size():
			_all_shown = true


func _show_all_text() -> void:
	var slide: Dictionary = SLIDES[_slide_idx]
	var lines: Array = slide.lines
	for i in lines.size():
		_text_labels[i].text = lines[i]
	_line_idx = lines.size()
	_char_idx = 0


func _advance() -> void:
	if _slide_idx < SLIDES.size() - 1:
		_begin_slide(_slide_idx + 1)
		# Quick fade-in for slide transition
		_fade_rect.color = Color(0, 0, 0, 1)
		var tw := create_tween()
		tw.tween_property(_fade_rect, "color", Color(0, 0, 0, 0), 0.5)
	else:
		_start_fade_out()


func _start_fade_out() -> void:
	_fading_out = true
	var tw := create_tween()
	tw.tween_property(_fade_rect, "color", Color(0, 0, 0, 0), 0.0)  # ensure starts transparent
	tw.tween_property(_fade_rect, "color", Color(0, 0, 0, 1), 0.6)
	tw.tween_callback(func() -> void: intro_finished.emit())


