class_name OverworldVat
extends Node2D

## Decorative growth-vat sprite placed in the overworld.
## The sheet is a 4-column × 4-row atlas (256×256 px per frame).
##   • vat_type (0-3) selects the ROW — i.e. the colour variant
##       row 0 = blue, row 1 = orange, row 2 = red, row 3 = teal
##   • The 4 columns of that row are the animation frames (bubble activity)

const TILE_SIZE:   int   = 48
const SHEET_COLS:  int   = 4
const FRAME_PX:    int   = 256
const DISPLAY_PX:  float = 96.0   # rendered at 2 tiles wide (96 × 96 px)
const ANIM_FPS:    float = 2.5    # bubbling speed

const _TEX := preload("res://art/vat_with_human.png")

var tile_pos:  Vector2i = Vector2i.ZERO
var vat_type:  int      = 0   # 0-3 selects the row (colour variant)


func setup(tp: Vector2i, type_: int = 0) -> void:
	tile_pos = tp
	vat_type = clamp(type_, 0, 3)
	position = Vector2(tp.x * TILE_SIZE + TILE_SIZE / 2.0,
					   tp.y * TILE_SIZE + TILE_SIZE / 2.0)
	_build_sprite()


func _build_sprite() -> void:
	# Build a SpriteFrames resource with one "idle" animation cycling the 4 columns
	var frames := SpriteFrames.new()
	frames.add_animation(&"idle")
	frames.set_animation_loop(&"idle", true)
	frames.set_animation_speed(&"idle", ANIM_FPS)

	var row := vat_type
	for col in SHEET_COLS:
		var atlas := AtlasTexture.new()
		atlas.atlas  = _TEX
		atlas.region = Rect2(col * FRAME_PX, row * FRAME_PX, FRAME_PX, FRAME_PX)
		frames.add_frame(&"idle", atlas)

	var spr := AnimatedSprite2D.new()
	spr.sprite_frames = frames
	spr.scale         = Vector2.ONE * (DISPLAY_PX / float(FRAME_PX))
	spr.z_index       = -1   # draw behind player, NPCs, and bones
	# Stagger start frame so not all vats bubble in sync
	spr.frame         = (tile_pos.x + tile_pos.y) % SHEET_COLS
	spr.play(&"idle")
	add_child(spr)
