class_name DeckView
extends Control

const W: int = 90
const H: int = 170

const COL_FRAME := Color("#2b1808")
const COL_BACK := Color("#3d2818")
const COL_BACK_EMPTY := Color("#241510")
const COL_TEXT := Color("#e8d090")
const COL_DISCARD_TEXT := Color("#b09a6c")

var draw_n: int = 0
var discard_n: int = 0

func _init() -> void:
	custom_minimum_size = Vector2(W, H)

func bind(gs: GameState) -> void:
	gs.deck_changed.connect(_on_deck_changed)
	_refresh()

func _on_deck_changed(d: int, dc: int) -> void:
	draw_n = d
	discard_n = dc
	queue_redraw()

func _refresh() -> void:
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _draw() -> void:
	var w: float = size.x if size.x > 0.0 else float(W)
	var h: float = size.y if size.y > 0.0 else float(H)
	var font := ThemeDB.fallback_font

	# Stacked hex card backs — give some depth when the deck is full.
	var stack_layers: int = clampi(draw_n, 0, 3)
	if stack_layers == 0:
		draw_colored_polygon(_hex_polygon(w, h, 0.0), COL_FRAME)
		draw_colored_polygon(_hex_polygon(w, h, 3.0), COL_BACK_EMPTY)
	else:
		for i in range(stack_layers):
			var inset_outer: float = float(stack_layers - 1 - i) * 1.5
			var inset_inner: float = inset_outer + 3.0
			draw_colored_polygon(_hex_polygon(w, h, inset_outer), COL_FRAME)
			draw_colored_polygon(_hex_polygon(w, h, inset_inner),
				COL_BACK.lightened(0.06 * i))

	# Big deck count
	var text := str(draw_n)
	var ts := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 28)
	draw_string(font, Vector2((w - ts.x) * 0.5, h * 0.58), text,
		HORIZONTAL_ALIGNMENT_CENTER, -1, 28, COL_TEXT)

	# Label
	var label := "DECK"
	var ls := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, 11)
	draw_string(font, Vector2((w - ls.x) * 0.5, h * 0.32), label,
		HORIZONTAL_ALIGNMENT_CENTER, -1, 11, COL_TEXT)

	# Discard count (only when relevant)
	if discard_n > 0:
		var dtxt := "discard %d" % discard_n
		var ds := font.get_string_size(dtxt, HORIZONTAL_ALIGNMENT_CENTER, -1, 10)
		draw_string(font, Vector2((w - ds.x) * 0.5, h * 0.82), dtxt,
			HORIZONTAL_ALIGNMENT_CENTER, -1, 10, COL_DISCARD_TEXT)

func _hex_polygon(w: float, h: float, inset: float) -> PackedVector2Array:
	var hw := w * 0.5
	var quarter_h := h * 0.25
	return PackedVector2Array([
		Vector2(hw, inset),
		Vector2(w - inset, quarter_h),
		Vector2(w - inset, h - quarter_h),
		Vector2(hw, h - inset),
		Vector2(inset, h - quarter_h),
		Vector2(inset, quarter_h),
	])
