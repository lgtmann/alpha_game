class_name OverworldNpc
extends Node2D

const TILE_SIZE: int = 48
const ANIM_FPS: float = 6.0
const SPRITE_SCALE: float = 0.10

# Row in robot_walk.png that gives the best side-profile walk.
# Change this (0-5) if you want a different viewing angle.
const WALK_ROW: int = 2

const FRAME_W: int = 532
const FRAME_H: int = 552
const FRAME_COUNT: int = 6

# Pacing behaviour
const PACE_MOVE_TIME: float  = 0.45   # seconds to cross one tile
const PACE_PAUSE_TIME: float = 1.0    # seconds to wait at each end

const _TEX := preload("res://art/robot_walk.png")

var tile_pos: Vector2i = Vector2i.ZERO
var npc_name: String = ""
var encounter_index: int = 0
var defeated: bool = false

# Direction: 1 = right (default), -1 = left (flipped)
var facing_dir: int = 1

# Pacing state
var _start_tile: Vector2i = Vector2i.ZERO
var _pace_dir: Vector2i  = Vector2i(1, 0)  # horizontal by default
var _pace_range: int     = 1               # tiles to travel each way
var _at_end: bool        = false           # true when at the far end
var _pace_timer: float   = 0.0
var _pace_moving: bool   = false
var _tween: Tween        = null

var _anim_sprite: AnimatedSprite2D = null
var _label: Label = null


func _ready() -> void:
	_setup_sprite()
	_make_label()


func _setup_sprite() -> void:
	var frames := SpriteFrames.new()
	frames.add_animation(&"walk")
	frames.set_animation_loop(&"walk", true)
	frames.set_animation_speed(&"walk", ANIM_FPS)
	for col in range(FRAME_COUNT):
		var atlas := AtlasTexture.new()
		atlas.atlas = _TEX
		atlas.region = Rect2(col * FRAME_W, WALK_ROW * FRAME_H, FRAME_W, FRAME_H)
		frames.add_frame(&"walk", atlas)

	_anim_sprite = AnimatedSprite2D.new()
	_anim_sprite.sprite_frames = frames
	_anim_sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	_anim_sprite.pause()   # idle until first pace step
	add_child(_anim_sprite)


func _make_label() -> void:
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Position above the sprite (half sprite height + padding)
	_label.position = Vector2(-48.0, -(FRAME_H * SPRITE_SCALE) / 2.0 - 20.0)
	_label.custom_minimum_size = Vector2(96.0, 0.0)
	add_child(_label)
	if npc_name != "":
		_label.text = npc_name


func setup(tp: Vector2i, name_: String, enc_idx: int) -> void:
	tile_pos    = tp
	_start_tile = tp
	npc_name       = name_
	encounter_index = enc_idx
	position = Vector2(tp.x * TILE_SIZE + TILE_SIZE / 2.0,
					   tp.y * TILE_SIZE + TILE_SIZE / 2.0)
	if _label == null:
		_make_label()
	else:
		_label.text = name_
	# Stagger start times so all robots don't step in sync.
	_pace_timer = randf_range(0.0, PACE_PAUSE_TIME)
	queue_redraw()


func mark_defeated() -> void:
	defeated = true
	_pace_moving = false
	if is_instance_valid(_tween):
		_tween.kill()
	_tween = null
	if is_instance_valid(_anim_sprite):
		_anim_sprite.modulate = Color(0.45, 0.45, 0.45, 1.0)
		_anim_sprite.pause()
	if is_instance_valid(_label):
		_label.modulate = Color(0.55, 0.55, 0.55, 1.0)
	queue_redraw()


# Called by overworld (or level data) to override the default horizontal pace.
func set_facing(dir: int) -> void:
	facing_dir = dir
	if is_instance_valid(_anim_sprite):
		_anim_sprite.flip_h = (dir < 0)


# ── pacing loop ──────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if defeated or _pace_moving:
		return
	_pace_timer -= delta
	if _pace_timer <= 0.0:
		_do_pace_step()


func _do_pace_step() -> void:
	var target: Vector2i
	if _at_end:
		target  = _start_tile
		_at_end = false
	else:
		target  = _start_tile + _pace_dir * _pace_range
		_at_end = true
	_move_to(target)


func _move_to(target: Vector2i) -> void:
	var dir := target - tile_pos
	if dir == Vector2i.ZERO:
		_pace_timer = PACE_PAUSE_TIME
		return

	# Face the direction of travel.
	if dir.x > 0:
		set_facing(1)
	elif dir.x < 0:
		set_facing(-1)

	# Play walk animation while moving.
	if is_instance_valid(_anim_sprite) and not _anim_sprite.is_playing():
		_anim_sprite.play(&"walk")

	_pace_moving = true
	tile_pos = target
	var world_pos := Vector2(target.x * TILE_SIZE + TILE_SIZE / 2.0,
							 target.y * TILE_SIZE + TILE_SIZE / 2.0)

	if is_instance_valid(_tween):
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "position", world_pos, PACE_MOVE_TIME)
	_tween.tween_callback(func() -> void:
		_pace_moving = false
		if is_instance_valid(_anim_sprite):
			_anim_sprite.pause()
		_pace_timer = PACE_PAUSE_TIME
	)


func _draw() -> void:
	if defeated:
		return
	# "!" exclamation mark above the sprite
	var top_y: float = -(FRAME_H * SPRITE_SCALE) / 2.0 - 6.0
	draw_rect(Rect2(-2.5, top_y - 14.0, 5.0, 9.0), Color("#ffd070"))
	draw_circle(Vector2(0.0, top_y - 1.0), 3.0, Color("#ffd070"))
