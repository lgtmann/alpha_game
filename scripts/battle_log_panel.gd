class_name BattleLogPanel
extends PanelContainer

const MAX_ENTRIES: int = 100

@onready var scroll: ScrollContainer = $V/Scroll
@onready var log_box: VBoxContainer = $V/Scroll/LogBox

var game_state: GameState = null

func bind(gs: GameState) -> void:
	game_state = gs
	gs.log_message.connect(_on_log_message)
	gs.turn_started.connect(_on_turn_started)
	gs.game_ended.connect(_on_game_ended)

func clear() -> void:
	if log_box == null:
		return
	for child in log_box.get_children():
		child.queue_free()

func _on_turn_started(turn_: int, active_player: int) -> void:
	var side := "Your" if active_player == GameState.PLAYER else "Enemy"
	_append("— Turn %d (%s) —" % [turn_, side], Color(0.7, 0.85, 1.0))

func _on_game_ended(winner: int) -> void:
	if winner == GameState.PLAYER:
		_append("Victory!", Color(0.6, 1.0, 0.6))
	else:
		_append("Defeat.", Color(1.0, 0.6, 0.6))

func _on_log_message(text: String) -> void:
	_append(text, Color.WHITE)

func _append(text: String, color: Color) -> void:
	if log_box == null:
		return
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 11)
	if color != Color.WHITE:
		label.add_theme_color_override("font_color", color)
	log_box.add_child(label)
	while log_box.get_child_count() > MAX_ENTRIES:
		log_box.get_child(0).queue_free()
	# Defer one frame so the layout updates before we read max_value.
	await get_tree().process_frame
	if is_instance_valid(scroll):
		var sb := scroll.get_v_scroll_bar()
		scroll.scroll_vertical = int(sb.max_value)
