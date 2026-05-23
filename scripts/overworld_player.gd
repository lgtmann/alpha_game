class_name OverworldPlayer
extends Node2D

const TILE_SIZE: int = 48
const MOVE_DURATION: float = 0.12
# One full leg cycle per tile crossed  →  FRAME_COUNT / MOVE_DURATION = 50
const ANIM_FPS: float = 6.0 / MOVE_DURATION
const SPRITE_SCALE: float = 0.15

# Adjust these row indices if directions look wrong in-game:
#   forward sheet rows  0-5 go from right-profile → left-profile → near-back
#   backwards sheet rows 0-5 go from back-right → straight-back → back-left
const ROW_DOWN: int  = 1   # forward sheet  — straight toward camera (south)
const ROW_UP: int    = 1   # backwards sheet — straight away from camera (north)
const ROW_LEFT: int  = 3   # forward sheet  — left profile (west)
const ROW_RIGHT: int = 0   # forward sheet  — right profile (east)

const FRAME_W: int     = 334
const FRAME_H_FWD: int = 580
const FRAME_H_BACK: int = 604
const FRAME_COUNT: int = 6

const _TEX_FWD  := preload("res://art/player_walk_forward.png")
const _TEX_BACK := preload("res://art/player_turn_walk_backwards.png")

var tile_pos: Vector2i = Vector2i(11, 19)
var _moving: bool = false
var _facing: Vector2i = Vector2i(0, 1)   # start facing south
var _anim_sprite: AnimatedSprite2D = null

func _ready() -> void:
	position = Vector2(tile_pos.x * TILE_SIZE + TILE_SIZE / 2.0,
					   tile_pos.y * TILE_SIZE + TILE_SIZE / 2.0)
	_setup_sprite()
	var cam := Camera2D.new()
	cam.zoom = Vector2(2.0, 2.0)
	add_child(cam)
	z_index = 1

func _setup_sprite() -> void:
	var frames := SpriteFrames.new()
	_add_anim(frames, &"walk_down",  _TEX_FWD,  ROW_DOWN,  FRAME_W, FRAME_H_FWD)
	_add_anim(frames, &"walk_up",    _TEX_BACK, ROW_UP,    FRAME_W, FRAME_H_BACK)
	_add_anim(frames, &"walk_left",  _TEX_FWD,  ROW_LEFT,  FRAME_W, FRAME_H_FWD)
	_add_anim(frames, &"walk_right", _TEX_FWD,  ROW_RIGHT, FRAME_W, FRAME_H_FWD)

	_anim_sprite = AnimatedSprite2D.new()
	_anim_sprite.sprite_frames = frames
	_anim_sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	_anim_sprite.play(&"walk_down")
	_anim_sprite.pause()
	add_child(_anim_sprite)

func _add_anim(frames: SpriteFrames, anim_name: StringName, tex: Texture2D,
			   row: int, fw: int, fh: int) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_loop(anim_name, true)
	frames.set_animation_speed(anim_name, ANIM_FPS)
	for col in range(FRAME_COUNT):
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(col * fw, row * fh, fw, fh)
		frames.add_frame(anim_name, atlas)

func move_to(target: Vector2i) -> void:
	if _moving:
		return
	var delta := target - tile_pos
	if delta != Vector2i.ZERO:
		_facing = delta
	tile_pos = target
	_moving = true
	_play_dir_anim(_facing)
	var world_pos := Vector2(target.x * TILE_SIZE + TILE_SIZE / 2.0,
							 target.y * TILE_SIZE + TILE_SIZE / 2.0)
	var tween := create_tween()
	tween.tween_property(self, "position", world_pos, MOVE_DURATION)
	tween.tween_callback(func() -> void:
		_moving = false
		if is_instance_valid(_anim_sprite):
			_anim_sprite.pause()
	)

func _play_dir_anim(dir: Vector2i) -> void:
	if _anim_sprite == null:
		return
	var anim: StringName = &"walk_down"
	if dir.y < 0:
		anim = &"walk_up"
	elif dir.x < 0:
		anim = &"walk_left"
	elif dir.x > 0:
		anim = &"walk_right"
	if _anim_sprite.animation != anim:
		_anim_sprite.play(anim)
	elif not _anim_sprite.is_playing():
		_anim_sprite.play()

func is_moving() -> bool:
	return _moving
