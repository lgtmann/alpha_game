class_name OverworldNpc
extends Node2D

const TILE_SIZE: int = 48

var tile_pos: Vector2i = Vector2i.ZERO
var npc_name: String = ""
var encounter_index: int = 0
var defeated: bool = false

var _label: Label = null

func _ready() -> void:
	if _label == null:
		_make_label()

func _make_label() -> void:
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.position = Vector2(-40.0, -int(TILE_SIZE * 0.35) - 22)
	_label.custom_minimum_size = Vector2(80.0, 0.0)
	add_child(_label)
	if npc_name != "":
		_label.text = npc_name

func setup(tp: Vector2i, name_: String, enc_idx: int) -> void:
	tile_pos = tp
	npc_name = name_
	encounter_index = enc_idx
	position = Vector2(tp.x * TILE_SIZE + TILE_SIZE / 2.0,
					   tp.y * TILE_SIZE + TILE_SIZE / 2.0)
	if _label == null:
		_make_label()
	else:
		_label.text = name_
	queue_redraw()

func mark_defeated() -> void:
	defeated = true
	if _label != null:
		_label.modulate = Color("#888888")
	queue_redraw()

func _draw() -> void:
	var r: float = TILE_SIZE * 0.35
	var col: Color = Color("#888888") if defeated else Color("#c05030")
	draw_circle(Vector2.ZERO, r, col)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 24, Color("#802010"), 2.0)
	if not defeated:
		# "!" exclamation mark above NPC
		draw_rect(Rect2(-2.0, -r - 20.0, 4.0, 8.0), Color("#ffd070"))
		draw_circle(Vector2(0.0, -r - 8.0), 2.5, Color("#ffd070"))
