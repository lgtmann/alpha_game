class_name Unit
extends Node2D

const SIZE: int = 46
const PLAYER_COLOR := Color("#3aa6e0")
const ENEMY_COLOR := Color("#e63939")

const COL_SHIELD := Color("#ffd770")
const COL_CANNON := Color("#e85a3a")
const COL_ACCEL := Color("#5fb6ff")

var data: UnitData
var owner_id: int = 0
var tile: Vector2i = Vector2i.ZERO
var has_moved: bool = false
var has_rotated: bool = false
var selected: bool = false
# 0..5 hex direction (0=E, 1=SE, 2=SW, 3=W, 4=NW, 5=NE)
var facing: int = 0

var atk_bonus: int = 0
var hp_bonus: int = 0
var current_hp: int = 1

# Per-instance copy of upgrade-by-side. Defaults to UnitData.sides, but Main
# can replace this (e.g. with Hero's RunState.hero_sides).
var sides: Array[SideUpgrade] = []

var _move_tween: Tween = null

func setup(d: UnitData, owner: int) -> void:
	data = d
	owner_id = owner
	current_hp = d.max_hp + hp_bonus
	if d != null and d.sides.size() > 0:
		sides = d.sides.duplicate()
	else:
		sides = []
	queue_redraw()

func set_selected(v: bool) -> void:
	selected = v
	queue_redraw()

func mark_moved(v: bool) -> void:
	has_moved = v
	queue_redraw()

func mark_rotated(v: bool) -> void:
	has_rotated = v
	queue_redraw()

func set_facing(d: int) -> void:
	if d < 0:
		return
	facing = d % 6
	queue_redraw()

func get_atk() -> int:
	return data.atk + atk_bonus if data != null else 0

func get_max_hp() -> int:
	return data.max_hp + hp_bonus if data != null else 0

func add_buff(atk_delta: int, hp_delta: int) -> void:
	atk_bonus += atk_delta
	hp_bonus += hp_delta
	if hp_delta > 0:
		current_hp = mini(get_max_hp(), current_hp + hp_delta)
	elif hp_delta < 0:
		current_hp = mini(current_hp, get_max_hp())
	queue_redraw()

func take_damage(amount: int) -> int:
	var dealt: int = mini(amount, current_hp)
	current_hp = maxi(0, current_hp - amount)
	queue_redraw()
	return dealt

func is_dead() -> bool:
	return current_hp <= 0

func _get_side(side_idx: int) -> SideUpgrade:
	if side_idx < 0 or side_idx >= sides.size():
		return null
	return sides[side_idx]

func get_shield_at_side(side_idx: int) -> int:
	var s := _get_side(side_idx)
	if s != null and s.is_shield():
		return s.strength
	return 0

func get_cannon_bonus_at_side(side_idx: int) -> int:
	var s := _get_side(side_idx)
	if s != null and s.is_cannon():
		return s.strength
	return 0

func get_accelerator_at_side(side_idx: int) -> int:
	var s := _get_side(side_idx)
	if s != null and s.is_accelerator():
		return s.strength
	return 0

func tween_to(target_pos: Vector2, duration: float = 0.18) -> void:
	if _move_tween != null and _move_tween.is_running():
		_move_tween.kill()
	_move_tween = create_tween()
	_move_tween.tween_property(self, "position", target_pos, duration) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)

func play_destroy() -> void:
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(self, "scale", Vector2(0.4, 0.4), 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.tween_property(self, "modulate:a", 0.0, 0.25)
	t.chain().tween_callback(queue_free)

# --- Drawing ---------------------------------------------------------------

func _draw() -> void:
	if data == null:
		return
	var radius: float = SIZE / 2.0
	var fill: Color = PLAYER_COLOR if owner_id == 0 else ENEMY_COLOR
	if has_moved:
		fill = fill.darkened(0.4)

	# Hex vertices, rotated so side 0 sits at the facing angle.
	var side_0_angle: float = facing * PI / 3.0
	var vertices := PackedVector2Array()
	for i in range(6):
		var vertex_angle := side_0_angle - PI / 6.0 + i * PI / 3.0
		vertices.append(Vector2(cos(vertex_angle), sin(vertex_angle)) * radius)

	# Selection outline (drawn behind the hex)
	if selected:
		var sel := PackedVector2Array()
		for v in vertices:
			sel.append(v * 1.18)
		var sel_closed := sel.duplicate()
		sel_closed.append(sel[0])
		draw_polyline(sel_closed, Color.YELLOW, 3.0)

	# Fill hex
	draw_colored_polygon(vertices, fill)

	# Side decorations (colored thick edges based on upgrades)
	for i in range(6):
		var up := _get_side(i)
		if up == null or up.type == SideUpgrade.Type.NONE:
			continue
		var v1 := vertices[i]
		var v2 := vertices[(i + 1) % 6]
		var c := Color.WHITE
		match up.type:
			SideUpgrade.Type.SHIELD: c = COL_SHIELD
			SideUpgrade.Type.CANNON: c = COL_CANNON
			SideUpgrade.Type.ACCELERATOR: c = COL_ACCEL
		draw_line(v1, v2, c, 5.0)

	# Hex outline
	var closed := vertices.duplicate()
	closed.append(vertices[0])
	draw_polyline(closed, Color.BLACK, 1.8)

	# Facing arrow (white, pointing along side 0)
	var front_dir := Vector2(cos(side_0_angle), sin(side_0_angle))
	var arrow_tip := front_dir * radius * 0.62
	draw_line(Vector2.ZERO, arrow_tip, Color.WHITE, 2.0)
	var perp := Vector2(-front_dir.y, front_dir.x)
	var head_a := arrow_tip - front_dir * 5.0 + perp * 3.5
	var head_b := arrow_tip - front_dir * 5.0 - perp * 3.5
	draw_line(arrow_tip, head_a, Color.WHITE, 1.8)
	draw_line(arrow_tip, head_b, Color.WHITE, 1.8)

	# Stats text (ATK + current/max HP). Color HP by ratio.
	var font := ThemeDB.fallback_font
	var font_size := 11
	var max_hp_v := get_max_hp()
	var hp_color: Color = Color.WHITE
	if max_hp_v > 0:
		var ratio := float(current_hp) / float(max_hp_v)
		if ratio <= 0.34:
			hp_color = Color(1.0, 0.45, 0.45)
		elif ratio <= 0.66:
			hp_color = Color(1.0, 0.9, 0.4)
	var stats_text := "%d  %d/%d" % [get_atk(), current_hp, max_hp_v]
	var stats_size := font.get_string_size(stats_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, Vector2(-stats_size.x / 2.0, radius - 2.0), stats_text,
		HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, hp_color)

	# Marker / badge overlays (not rotated — always at fixed corner of bounding box)
	if data.is_deck_leader:
		draw_string(font, Vector2(-radius + 2.0, -radius + 10.0), "*",
			HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.YELLOW)
	if data.attack_range > 1:
		var rbadge := "R%d" % data.attack_range
		var rs := font.get_string_size(rbadge, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		draw_string(font, Vector2(radius - rs.x - 2.0, -radius + 10.0), rbadge,
			HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.6, 0.85, 1.0))
	if data.speed > 1:
		var sbadge := "S%d" % data.speed
		draw_string(font, Vector2(-radius + 3.0, radius - 14.0), sbadge,
			HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1.0, 0.82, 0.4))
