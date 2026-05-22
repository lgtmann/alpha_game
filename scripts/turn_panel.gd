class_name TurnPanel
extends PanelContainer

@onready var turn_label: Label = $V/TurnLabel
@onready var energy_label: Label = $V/EnergyLabel
@onready var deck_label: Label = $V/DeckLabel
@onready var units_label: Label = $V/UnitsLabel
@onready var end_turn_button: Button = $V/EndTurnButton
@onready var debug_win_button: Button = $V/DebugWinButton

var game_state: GameState

func bind(gs: GameState) -> void:
	game_state = gs
	gs.turn_started.connect(_on_turn_started)
	gs.energy_changed.connect(_on_energy_changed)
	gs.deck_changed.connect(_on_deck_changed)
	gs.game_ended.connect(_on_game_ended)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	debug_win_button.pressed.connect(_on_debug_win_pressed)
	if gs.board != null:
		gs.board.units_changed.connect(_refresh_units_count)
	_refresh_units_count()

func _on_turn_started(turn: int, active_player: int) -> void:
	var side := "Your" if active_player == GameState.PLAYER else "Enemy"
	turn_label.text = "Turn %d — %s" % [turn, side]
	var is_player := active_player == GameState.PLAYER
	end_turn_button.disabled = not is_player
	debug_win_button.disabled = not is_player
	_refresh_units_count()

func _on_energy_changed(current: int, max_value: int) -> void:
	energy_label.text = "Energy %d (+%d/turn)" % [current, max_value]

func _on_deck_changed(draw_n: int, discard_n: int) -> void:
	if discard_n > 0:
		deck_label.text = "Deck %d  Discard %d" % [draw_n, discard_n]
	else:
		deck_label.text = "Deck %d" % draw_n

func _on_game_ended(winner: int) -> void:
	turn_label.text = "You Win!" if winner == GameState.PLAYER else "You Lose!"
	end_turn_button.disabled = true
	debug_win_button.disabled = true

func _on_end_turn_pressed() -> void:
	if game_state != null:
		game_state.end_turn()

func _on_debug_win_pressed() -> void:
	if game_state != null:
		game_state.debug_win()

func _refresh_units_count() -> void:
	if game_state == null or game_state.board == null or units_label == null:
		return
	var count := game_state.board.count_units(GameState.PLAYER)
	units_label.text = "Units %d / %d" % [count, game_state.max_units]
