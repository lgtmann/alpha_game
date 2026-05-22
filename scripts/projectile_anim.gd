class_name ProjectileAnim
extends Node2D

var start_pos: Vector2 = Vector2.ZERO
var end_pos: Vector2 = Vector2.ZERO
var duration: float = 0.32
var arc_height: float = 22.0
var color: Color = Color("#ffd270")
var radius: float = 4.5

func _ready() -> void:
	position = start_pos
	z_index = 5
	var t := create_tween()
	t.tween_method(_set_progress, 0.0, 1.0, duration) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN_OUT)
	t.tween_callback(queue_free)

func _set_progress(p: float) -> void:
	var linear := start_pos.lerp(end_pos, p)
	var arc_off := sin(p * PI) * arc_height
	var delta := end_pos - start_pos
	if delta.length() > 0.01:
		var dir := delta.normalized()
		var perp := Vector2(-dir.y, dir.x)
		position = linear + perp * arc_off
	else:
		position = linear
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius * 1.8, Color(color.r, color.g, color.b, 0.28))
	draw_circle(Vector2.ZERO, radius, color)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 16, Color(0.1, 0.05, 0.0), 1.0)
