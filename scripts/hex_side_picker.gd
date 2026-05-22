class_name HexSidePicker
extends Control

signal side_picked(index: int)

const RADIUS: float = 90.0
const SIDE_NAMES := ["Front", "Front-R", "Back-R", "Back", "Back-L", "Front-L"]

const COL_HEX := Color("#2c2c38")
const COL_HEX_OUTLINE := Color("#0a0a10")
const COL_SHIELD := Color("#ffd770")
const COL_CANNON := Color("#e85a3a")
const COL_ACCEL := Color("#5fb6ff")
const COL_NONE := Color("#5a5a68")
const COL_SELECT := Color("#ffff66")
const COL_ARROW := Color.WHITE

var sides: Array[SideUpgrade] = []
var selected_idx: int = 0

func _ready() -> void:
	custom_minimum_size = Vector2(RADIUS * 2.4, RADIUS * 2.4)
	mouse_filter = Control.MOUSE_FILTER_STOP

func set_sides(s: Array[SideUpgrade]) -> void:
	sides = s
	queue_redraw()

func select_side(idx: int) -> void:
	selected_idx = clampi(idx, 0, 5)
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	var center: Vector2 = size / 2.0
	var local: Vector2 = mb.position - center
	if local.length() < 6.0:
		return
	var angle: float = local.angle()
	var a: float = fmod(angle + 2.0 * PI + PI / 6.0, 2.0 * PI)
	var idx: int = int(a / (PI / 3.0)) % 6
	select_side(idx)
	side_picked.emit(idx)
	accept_event()

func _draw() -> void:
	var center: Vector2 = size / 2.0
	var vertices := PackedVector2Array()
	for i in range(6):
		var ang: float = -PI / 6.0 + i * PI / 3.0
		vertices.append(center + Vector2(cos(ang), sin(ang)) * RADIUS)

	draw_colored_polygon(vertices, COL_HEX)

	for i in range(6):
		var v1: Vector2 = vertices[i]
		var v2: Vector2 = vertices[(i + 1) % 6]
		var up: SideUpgrade = sides[i] if i < sides.size() else null
		var c: Color = COL_NONE
		if up != null:
			match up.type:
				SideUpgrade.Type.SHIELD: c = COL_SHIELD
				SideUpgrade.Type.CANNON: c = COL_CANNON
				SideUpgrade.Type.ACCELERATOR: c = COL_ACCEL
		var thickness: float = 9.0 if i == selected_idx else 6.0
		draw_line(v1, v2, c, thickness)
		if up != null and up.type != SideUpgrade.Type.NONE and up.strength > 0:
			var mid: Vector2 = (v1 + v2) / 2.0
			var inward: Vector2 = (center - mid).normalized() * 16.0
			var label: String = str(up.strength)
			var font := ThemeDB.fallback_font
			var s: Vector2 = font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, 14)
			draw_string(font, mid + inward - Vector2(s.x / 2.0, -5.0), label,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.BLACK)

	var sv1: Vector2 = vertices[selected_idx]
	var sv2: Vector2 = vertices[(selected_idx + 1) % 6]
	var mid_sel: Vector2 = (sv1 + sv2) / 2.0
	var outward: Vector2 = (mid_sel - center).normalized() * 12.0
	draw_line(sv1 + outward, sv2 + outward, COL_SELECT, 3.0)

	var closed := vertices.duplicate()
	closed.append(vertices[0])
	draw_polyline(closed, COL_HEX_OUTLINE, 1.5)

	# "Front" direction arrow inside hex (points east — side 0).
	var arrow_tip: Vector2 = center + Vector2(RADIUS * 0.55, 0)
	draw_line(center, arrow_tip, COL_ARROW, 2.0)
	var perp := Vector2(0, 1)
	var head_a: Vector2 = arrow_tip - Vector2(8, 0) + perp * 5.0
	var head_b: Vector2 = arrow_tip - Vector2(8, 0) - perp * 5.0
	draw_line(arrow_tip, head_a, COL_ARROW, 1.8)
	draw_line(arrow_tip, head_b, COL_ARROW, 1.8)

	var font2 := ThemeDB.fallback_font
	var name_text: String = SIDE_NAMES[selected_idx]
	var ns: Vector2 = font2.get_string_size(name_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 13)
	draw_string(font2, center + Vector2(-ns.x / 2.0, 22.0), name_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
