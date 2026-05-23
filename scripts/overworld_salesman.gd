class_name OverworldSalesman
extends Node2D

## Stationary merchant NPC on the overworld.
## Walking into his tile emits Overworld.shop_requested instead of starting a battle.

const TILE_SIZE: int = 48
const SPRITE_SCALE: float = 0.10
const FRAME_W: int = 482
const FRAME_H: int = 426
const FRAME_COUNT: int = 6
const IDLE_ROW: int = 0   # Row 0 — standing idle

# One full cycle per ~0.8 s looks natural for an idle breathing loop.
const ANIM_FPS: float = 7.5

const _TEX := preload("res://art/salesman.png")

var tile_pos: Vector2i = Vector2i.ZERO
var npc_name: String = "Merchant"

var _anim_sprite: AnimatedSprite2D = null
var _label: Label = null


func _ready() -> void:
	_setup_sprite()
	_make_label()


func _setup_sprite() -> void:
	var frames := SpriteFrames.new()
	frames.add_animation(&"idle")
	frames.set_animation_loop(&"idle", true)
	frames.set_animation_speed(&"idle", ANIM_FPS)
	for col in range(FRAME_COUNT):
		var atlas := AtlasTexture.new()
		atlas.atlas = _TEX
		atlas.region = Rect2(col * FRAME_W, IDLE_ROW * FRAME_H, FRAME_W, FRAME_H)
		frames.add_frame(&"idle", atlas)

	_anim_sprite = AnimatedSprite2D.new()
	_anim_sprite.sprite_frames = frames
	_anim_sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	_anim_sprite.play(&"idle")
	add_child(_anim_sprite)


func _make_label() -> void:
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.position = Vector2(-48.0, -(FRAME_H * SPRITE_SCALE) / 2.0 - 20.0)
	_label.custom_minimum_size = Vector2(96.0, 0.0)
	_label.text = npc_name
	add_child(_label)


func setup(tp: Vector2i, name_: String) -> void:
	tile_pos = tp
	npc_name  = name_
	position  = Vector2(tp.x * TILE_SIZE + TILE_SIZE / 2.0,
						tp.y * TILE_SIZE + TILE_SIZE / 2.0)
	if _label == null:
		_make_label()
	else:
		_label.text = name_


func _draw() -> void:
	# Layered gold-coin bubble so players can tell this is a shop NPC.
	var top_y: float = -(FRAME_H * SPRITE_SCALE) / 2.0 - 10.0
	draw_circle(Vector2(0.0, top_y), 6.0, Color("#ffd070"))
	draw_circle(Vector2(0.0, top_y), 4.5, Color("#b87820"))
	draw_circle(Vector2(0.0, top_y), 2.8, Color("#ffd070"))
