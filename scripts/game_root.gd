extends Node

@onready var _battle_layer: CanvasLayer = $BattleLayer
@onready var _overworld_layer: Node2D = $OverworldLayer
@onready var _main: Node = $BattleLayer/Main
@onready var _overworld: Overworld = $OverworldLayer/Overworld

func _ready() -> void:
	_main.setup_run()
	_overworld.initialize(_main.run_state)
	_overworld.battle_requested.connect(_on_battle_requested)
	_main.returned_to_overworld.connect(_on_returned_to_overworld)
	_show_overworld()

func _on_battle_requested(enc_idx: int) -> void:
	_main.run_state.encounter_index = enc_idx
	var enc: EncounterData = _main.run_state.current_encounter()
	if enc == null:
		return
	_show_battle()
	_main.begin_battle(enc)

func _on_returned_to_overworld() -> void:
	_overworld.refresh_npcs()
	_show_overworld()

func _show_overworld() -> void:
	_overworld_layer.visible = true
	_battle_layer.visible = false

func _show_battle() -> void:
	_overworld_layer.visible = false
	_battle_layer.visible = true
