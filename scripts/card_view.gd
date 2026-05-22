class_name CardView
extends Control

const CARD_W: int = 110
const CARD_H: int = 160

# Card chrome
const COL_FRAME := Color("#2b1808")
const COL_BG := Color("#7a5630")
const COL_TITLE_TEXT := Color("#f0d8a0")
const COL_PARCHMENT := Color("#d6c08a")
const COL_PARCHMENT_EDGE := Color("#3d2818")
const COL_DESC_TEXT := Color("#2b1808")

# Cost badge (center upper)
const COL_COST_BG := Color("#1e1208")
const COL_COST_RING := Color("#d9a64a")
const COL_COST_TEXT := Color("#ffd770")

# Stat badges (4 corners — only on summon cards)
const COL_ATK_BG := Color("#a83232")
const COL_DEF_BG := Color("#3257a8")
const COL_SPD_BG := Color("#c89020")
const COL_RNG_BG := Color("#3aa055")
const COL_BADGE_RING := Color("#1a0e05")
const COL_BADGE_TEXT := Color.WHITE
const COL_BADGE_LABEL := Color("#f0d8a0")

const TITLE_FONT_SIZE := 10
const COST_FONT_SIZE := 13
const STAT_NUM_FONT_SIZE := 11
const STAT_LABEL_FONT_SIZE := 7
const DESC_FONT_SIZE := 9
const EMBLEM_LETTER_FONT_SIZE := 16

signal clicked

var card_data: CardData
var clickable: bool = false
var interactive: bool = true

func _init() -> void:
	custom_minimum_size = Vector2(CARD_W, CARD_H)
	mouse_filter = Control.MOUSE_FILTER_STOP

func _ready() -> void:
	if custom_minimum_size.x < CARD_W:
		custom_minimum_size = Vector2(CARD_W, CARD_H)
	queue_redraw()

func set_card(data: CardData) -> void:
	card_data = data
	if data != null:
		tooltip_text = data.description if data.description != "" else data.card_name
	else:
		tooltip_text = ""
	queue_redraw()

func set_clickable(v: bool) -> void:
	clickable = v
	_update_cursor()

func set_interactive(v: bool) -> void:
	interactive = v
	_update_cursor()

func _update_cursor() -> void:
	if interactive and clickable:
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	else:
		mouse_default_cursor_shape = Control.CURSOR_ARROW

func consume() -> void:
	queue_free()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

# --- Drawing ----------------------------------------------------------------

func _draw() -> void:
	var w: float = size.x if size.x > 0.0 else float(CARD_W)
	var h: float = size.y if size.y > 0.0 else float(CARD_H)
	var font := ThemeDB.fallback_font

	# Hex chrome — frame + inset fill
	draw_colored_polygon(_hex_polygon(w, h, 0.0), COL_FRAME)
	draw_colored_polygon(_hex_polygon(w, h, 3.0), COL_BG)

	if card_data == null:
		return

	# Title text (centered, floats over the frame at the top)
	var name_text: String = card_data.card_name
	var name_size := font.get_string_size(name_text, HORIZONTAL_ALIGNMENT_CENTER, -1, TITLE_FONT_SIZE)
	draw_string(font, Vector2((w - name_size.x) * 0.5, h * 0.16),
		name_text, HORIZONTAL_ALIGNMENT_CENTER, -1, TITLE_FONT_SIZE, COL_TITLE_TEXT)

	# Cost badge — small circle just below title
	var cost_pos := Vector2(w * 0.5, h * 0.30)
	var cost_radius: float = 10.0
	draw_circle(cost_pos, cost_radius + 2.0, COL_COST_RING)
	draw_circle(cost_pos, cost_radius, COL_COST_BG)
	var cost_text := str(card_data.cost)
	var cs := font.get_string_size(cost_text, HORIZONTAL_ALIGNMENT_CENTER, -1, COST_FONT_SIZE)
	draw_string(font, cost_pos + Vector2(-cs.x * 0.5, cs.y * 0.32),
		cost_text, HORIZONTAL_ALIGNMENT_CENTER, -1, COST_FONT_SIZE, COL_COST_TEXT)

	# Art area (icon or fallback emblem)
	var art_size: float = 36.0
	var art_x: float = (w - art_size) * 0.5
	var art_y: float = h * 0.38
	_draw_art(Rect2(art_x, art_y, art_size, art_size), font)

	# Parchment area
	var parch_top: float = h * 0.62
	var parch_height: float = h * 0.32
	var parch_width: float = w * 0.80
	var parch_x: float = (w - parch_width) * 0.5
	var parch_rect := Rect2(parch_x, parch_top, parch_width, parch_height)
	draw_rect(parch_rect, COL_PARCHMENT)
	draw_rect(parch_rect, COL_PARCHMENT_EDGE, false, 1.0)

	# Description (description + effect summary)
	var desc := _build_description_text()
	if desc != "":
		draw_multiline_string(font, Vector2(parch_x + 4, parch_top + 11), desc,
			HORIZONTAL_ALIGNMENT_CENTER, parch_width - 8, DESC_FONT_SIZE,
			-1, COL_DESC_TEXT)

	# Stat badges (only for summon cards)
	var stats := _summon_stats()
	if not stats.is_empty():
		var badge_r: float = 10.0
		var top_y: float = h * 0.30
		var bot_y: float = h * 0.78
		var left_x: float = w * 0.13
		var right_x: float = w * 0.87
		_draw_stat_badge(Vector2(left_x, top_y), badge_r, "ATK",
			int(stats.get("atk", 0)), COL_ATK_BG, font)
		_draw_stat_badge(Vector2(right_x, top_y), badge_r, "HP",
			int(stats.get("max_hp", 0)), COL_DEF_BG, font)
		_draw_stat_badge(Vector2(left_x, bot_y), badge_r, "SPD",
			int(stats.get("speed", 0)), COL_SPD_BG, font)
		_draw_stat_badge(Vector2(right_x, bot_y), badge_r, "RNG",
			int(stats.get("range", 0)), COL_RNG_BG, font)

const TERRAIN_EMBLEM_COLORS := [
	Color("#7ec850"),  # 0 plains
	Color("#2d5a27"),  # 1 forest
	Color("#3a78b5"),  # 2 water
]

func _draw_art(rect: Rect2, font: Font) -> void:
	if card_data.icon != null:
		draw_texture_rect(card_data.icon, rect, false)
		return
	var effect := card_data.effect
	if effect is PlaceTerrainEffect:
		_draw_terrain_emblem(rect, (effect as PlaceTerrainEffect).terrain_id, false)
	elif effect is AreaTerrainEffect:
		_draw_terrain_emblem(rect, (effect as AreaTerrainEffect).terrain_id, true)
	elif effect is SpawnUnitEffect:
		_draw_summon_emblem(rect, (effect as SpawnUnitEffect).unit_data, font)
	elif effect is DamageEffect:
		_draw_destroy_emblem(rect)
	elif effect is BuffUnitEffect:
		_draw_buff_emblem(rect)
	elif effect is WeaponEffect:
		_draw_weapon_emblem(rect)
	else:
		_draw_generic_emblem(rect, font)

func _draw_terrain_emblem(rect: Rect2, terrain_id: int, area: bool) -> void:
	var color: Color = Color.MAGENTA
	if terrain_id >= 0 and terrain_id < TERRAIN_EMBLEM_COLORS.size():
		color = TERRAIN_EMBLEM_COLORS[terrain_id]
	var center := rect.position + rect.size * 0.5
	if area:
		var r: float = rect.size.x * 0.22
		var positions: Array[Vector2] = [
			center + Vector2(0.0, -r * 0.95),
			center + Vector2(-r * 0.85, r * 0.5),
			center + Vector2(r * 0.85, r * 0.5),
		]
		for p: Vector2 in positions:
			_draw_emblem_hex(p, r, color)
	else:
		_draw_emblem_hex(center, rect.size.x * 0.42, color)

func _draw_emblem_hex(center: Vector2, r: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(6):
		var a := -PI / 2.0 + i * PI / 3.0
		pts.append(center + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(pts, color)
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, COL_FRAME, 1.0, true)

func _draw_summon_emblem(rect: Rect2, unit_data: UnitData, font: Font) -> void:
	var center := rect.position + rect.size * 0.5
	var radius := rect.size.x * 0.44
	draw_circle(center, radius, Color("#3aa6e0"))
	draw_arc(center, radius, 0.0, TAU, 32, COL_FRAME, 1.5)
	var letter: String = ""
	if unit_data != null and unit_data.unit_name != "":
		letter = unit_data.unit_name.substr(0, 1).to_upper()
	elif card_data.card_name != "":
		letter = card_data.card_name.substr(0, 1).to_upper()
	if letter != "":
		var ls := font.get_string_size(letter, HORIZONTAL_ALIGNMENT_CENTER, -1, EMBLEM_LETTER_FONT_SIZE)
		draw_string(font, center + Vector2(-ls.x * 0.5, ls.y * 0.3),
			letter, HORIZONTAL_ALIGNMENT_CENTER, -1, EMBLEM_LETTER_FONT_SIZE, Color.WHITE)

func _draw_destroy_emblem(rect: Rect2) -> void:
	# Stylized flame: outer red plume, inner gold core.
	var cx: float = rect.position.x + rect.size.x * 0.5
	var top: float = rect.position.y + rect.size.y * 0.05
	var bot: float = rect.position.y + rect.size.y * 0.92
	var hw: float = rect.size.x * 0.40
	var outer := PackedVector2Array([
		Vector2(cx - hw, bot),
		Vector2(cx - hw * 0.65, bot - rect.size.y * 0.45),
		Vector2(cx - hw * 0.30, bot - rect.size.y * 0.30),
		Vector2(cx, top),
		Vector2(cx + hw * 0.30, bot - rect.size.y * 0.30),
		Vector2(cx + hw * 0.65, bot - rect.size.y * 0.45),
		Vector2(cx + hw, bot),
	])
	draw_colored_polygon(outer, Color("#c83a18"))
	var inner := PackedVector2Array([
		Vector2(cx - hw * 0.45, bot - rect.size.y * 0.05),
		Vector2(cx - hw * 0.25, bot - rect.size.y * 0.30),
		Vector2(cx, top + rect.size.y * 0.32),
		Vector2(cx + hw * 0.25, bot - rect.size.y * 0.30),
		Vector2(cx + hw * 0.45, bot - rect.size.y * 0.05),
	])
	draw_colored_polygon(inner, Color("#fcb830"))

func _draw_weapon_emblem(rect: Rect2) -> void:
	# Crossed swords — silver blades on a brown grip cross.
	var center := rect.position + rect.size * 0.5
	var half: float = rect.size.x * 0.40
	var blade_color := Color("#c8ced8")
	var hilt_color := Color("#7a4020")
	# Blade 1: top-left to bottom-right
	draw_line(center + Vector2(-half, -half), center + Vector2(half, half), blade_color, 5.0)
	draw_line(center + Vector2(-half, -half), center + Vector2(half, half), Color("#1a0e05"), 1.5)
	# Blade 2: top-right to bottom-left
	draw_line(center + Vector2(half, -half), center + Vector2(-half, half), blade_color, 5.0)
	draw_line(center + Vector2(half, -half), center + Vector2(-half, half), Color("#1a0e05"), 1.5)
	# Hilt knobs at the bottom ends
	draw_circle(center + Vector2(half, half), 3.0, hilt_color)
	draw_circle(center + Vector2(-half, half), 3.0, hilt_color)

func _draw_buff_emblem(rect: Rect2) -> void:
	# Five-point gold star.
	var center := rect.position + rect.size * 0.5
	var outer_r := rect.size.x * 0.46
	var inner_r := outer_r * 0.45
	var pts := PackedVector2Array()
	for i in range(10):
		var r: float = outer_r if i % 2 == 0 else inner_r
		var angle := -PI / 2.0 + i * PI / 5.0
		pts.append(center + Vector2(cos(angle), sin(angle)) * r)
	draw_colored_polygon(pts, Color("#ffd770"))
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, Color("#7a5630"), 1.0, true)

func _draw_generic_emblem(rect: Rect2, font: Font) -> void:
	var center := rect.position + rect.size * 0.5
	var radius := rect.size.x * 0.45
	var seed_val: int = absi(hash(card_data.card_name)) % 1000
	var hue: float = float(seed_val) / 1000.0
	var emblem_color := Color.from_hsv(hue, 0.50, 0.80)
	draw_circle(center, radius, emblem_color)
	draw_arc(center, radius, 0.0, TAU, 32, COL_FRAME, 1.5)
	if card_data.card_name != "":
		var letter: String = card_data.card_name.substr(0, 1).to_upper()
		var ls := font.get_string_size(letter, HORIZONTAL_ALIGNMENT_CENTER, -1, EMBLEM_LETTER_FONT_SIZE)
		draw_string(font, center + Vector2(-ls.x * 0.5, ls.y * 0.3),
			letter, HORIZONTAL_ALIGNMENT_CENTER, -1, EMBLEM_LETTER_FONT_SIZE, COL_FRAME)

func _draw_stat_badge(center: Vector2, radius: float, label: String,
		value: int, color: Color, font: Font) -> void:
	draw_circle(center, radius + 1.5, COL_BADGE_RING)
	draw_circle(center, radius, color)
	var num_text := str(value)
	var num_size := font.get_string_size(num_text, HORIZONTAL_ALIGNMENT_CENTER, -1, STAT_NUM_FONT_SIZE)
	draw_string(font, center + Vector2(-num_size.x * 0.5, num_size.y * 0.3),
		num_text, HORIZONTAL_ALIGNMENT_CENTER, -1, STAT_NUM_FONT_SIZE, COL_BADGE_TEXT)
	var label_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, STAT_LABEL_FONT_SIZE)
	draw_string(font, center + Vector2(-label_size.x * 0.5, radius + label_size.y * 0.85),
		label, HORIZONTAL_ALIGNMENT_CENTER, -1, STAT_LABEL_FONT_SIZE, COL_BADGE_LABEL)

func _build_description_text() -> String:
	if card_data == null:
		return ""
	var parts: Array[String] = []
	if card_data.description != "":
		parts.append(card_data.description)
	if card_data.effect != null:
		var s := card_data.effect.summary()
		if s != "":
			parts.append(s)
	return "\n".join(parts)

func _summon_stats() -> Dictionary:
	if card_data == null or card_data.effect == null:
		return {}
	if card_data.effect is SpawnUnitEffect:
		var su: SpawnUnitEffect = card_data.effect
		if su.unit_data == null:
			return {}
		return {
			"atk": su.unit_data.atk,
			"max_hp": su.unit_data.max_hp,
			"speed": su.unit_data.speed,
			"range": su.unit_data.attack_range,
		}
	return {}

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

# Clip mouse events to the hex shape (no clicks in the rectangular dead corners).
func _has_point(point: Vector2) -> bool:
	if size.x <= 0.0 or size.y <= 0.0:
		return false
	return Geometry2D.is_point_in_polygon(point, _hex_polygon(size.x, size.y, 0.0))

# --- Input ------------------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	if not interactive or not clickable:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			clicked.emit()
			accept_event()

func _get_drag_data(_at_position: Vector2) -> Variant:
	if not interactive or clickable or card_data == null:
		return null
	var preview := CardView.new()
	preview.set_card(card_data)
	preview.modulate.a = 0.92
	preview.scale = Vector2(1.08, 1.08)
	set_drag_preview(preview)
	return {"card_data": card_data, "source": self}
