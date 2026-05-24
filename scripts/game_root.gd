extends Node

@onready var _battle_layer:    CanvasLayer = $BattleLayer
@onready var _overworld_layer: Node2D      = $OverworldLayer
@onready var _shop_layer:      CanvasLayer = $ShopLayer
@onready var _dialogue_layer:  CanvasLayer = $DialogueLayer
@onready var _intro_layer:     CanvasLayer = $IntroLayer
@onready var _intro_screen:    IntroScreen = $IntroLayer/IntroScreen
@onready var _title_layer:     CanvasLayer = $TitleLayer
@onready var _title_screen:    TitleScreen = $TitleLayer/TitleScreen
@onready var _main:            Node        = $BattleLayer/Main
@onready var _overworld:       Overworld   = $OverworldLayer/Overworld
@onready var _shop_screen:     ShopScreen  = $ShopLayer/ShopScreen
@onready var _dialogue_box:    DialogueBox = $DialogueLayer/DialogueBox

## Active save slot (1-3). Set when the player picks a slot on the title screen.
var _active_slot: int = 1

## Cached before a battle so we know where to drop bones on defeat.
var _last_battle_pos:      Vector2i            = Vector2i.ZERO
var _last_battle_level_id: String              = ""

## Peer warrior whose dialogue is open (or whose fight was started).
var _active_peer_warrior: OverworldPeerWarrior = null

var _fresh_run: bool = true   # true at start + after each death restart


func _ready() -> void:
	# Set up run / overworld state (slot-independent).
	_main.setup_run()
	_overworld.initialize(_main.run_state)

	# Wire signals.
	_overworld.battle_requested.connect(_on_battle_requested)
	_overworld.door_requested.connect(_on_door_requested)
	_overworld.shop_requested.connect(_on_shop_requested)
	_overworld.dialogue_requested.connect(_on_dialogue_requested)
	_main.returned_to_overworld.connect(_on_returned_to_overworld)
	_main.run_restarted.connect(_on_run_restarted)
	_shop_screen.shop_closed.connect(_on_shop_closed)
	_dialogue_box.choice_made.connect(_on_dialogue_choice)
	_intro_screen.intro_finished.connect(_on_intro_finished)
	_title_screen.slot_selected.connect(_on_slot_selected)

	# Title screen is already visible (set in tscn). Everything else starts hidden.
	_battle_layer.visible    = false
	_overworld_layer.visible = false
	_intro_layer.visible     = false


# ── title screen ──────────────────────────────────────────────────────────────

func _on_slot_selected(slot: int) -> void:
	_active_slot               = slot
	DeathRegistry.active_slot  = slot
	_title_layer.visible       = false
	# Load death markers for this slot's save data.
	_overworld.spawn_death_markers(
		DeathRegistry.get_deaths_for_level(_overworld.current_level_id))
	_begin_run()


# ── battle (robot NPCs) ───────────────────────────────────────────────────────

func _on_battle_requested(enc_idx: int) -> void:
	_last_battle_pos      = _overworld.player_tile_pos
	_last_battle_level_id = _overworld.current_level_id
	_main.run_state.encounter_index = enc_idx
	var enc: EncounterData = _main.run_state.current_encounter()
	if enc == null:
		return
	_show_battle()
	_main.begin_battle(enc)


# ── death bones ───────────────────────────────────────────────────────────────

func _on_run_restarted() -> void:
	_fresh_run = true
	if _last_battle_level_id != "":
		DeathRegistry.record_death(_last_battle_level_id, _last_battle_pos)
	# Persist run count for the title screen.
	SaveData.record_run_end(_active_slot)


func _on_returned_to_overworld() -> void:
	# Mark a peer warrior defeated if the player won the peer fight.
	if _active_peer_warrior != null and _main.last_battle_winner == 0:  # 0 = GameState.PLAYER
		_active_peer_warrior.mark_defeated()
	_active_peer_warrior = null
	_overworld.refresh_npcs()
	_overworld.spawn_death_markers(
		DeathRegistry.get_deaths_for_level(_overworld.current_level_id))
	if _fresh_run:
		_begin_run()
	else:
		_show_overworld()


# ── dialogue ──────────────────────────────────────────────────────────────────

func _on_dialogue_requested(pw: OverworldPeerWarrior) -> void:
	_active_peer_warrior = pw
	_dialogue_layer.visible = true
	_overworld_layer.process_mode = Node.PROCESS_MODE_DISABLED
	_dialogue_box.open(pw.warrior_name, pw.portrait_color(),
					   pw.get_dialogue_lines(), pw.get_dialogue_choices())


func _on_dialogue_choice(choice_id: String) -> void:
	match choice_id:
		"fight":
			_close_dialogue()
			_start_peer_battle()
		"talk":
			# Advance to after_talk phase and reopen dialogue.
			if _active_peer_warrior != null:
				_active_peer_warrior.has_talked = true
				_dialogue_box.open(
					_active_peer_warrior.warrior_name,
					_active_peer_warrior.portrait_color(),
					_active_peer_warrior.get_dialogue_lines(),
					_active_peer_warrior.get_dialogue_choices())
				_dialogue_layer.visible = true
		"leave":
			_close_dialogue()
			_active_peer_warrior = null
		_:
			_close_dialogue()
			_active_peer_warrior = null


func _close_dialogue() -> void:
	_dialogue_layer.visible       = false
	_overworld_layer.process_mode = Node.PROCESS_MODE_INHERIT


func _start_peer_battle() -> void:
	_last_battle_pos      = _overworld.player_tile_pos
	_last_battle_level_id = _overworld.current_level_id
	_main.is_peer_battle  = true
	var enc: EncounterData = _main.build_peer_encounter()
	_show_battle()
	_main.begin_battle(enc)


# ── door ──────────────────────────────────────────────────────────────────────

func _on_door_requested(dest_level_id: String) -> void:
	print("[GameRoot] Door -> level '%s' (not yet implemented)" % dest_level_id)


# ── shop ──────────────────────────────────────────────────────────────────────

func _on_shop_requested() -> void:
	_shop_layer.visible           = true
	_overworld_layer.process_mode = Node.PROCESS_MODE_DISABLED
	_shop_screen.open(_main.run_state)


func _on_shop_closed() -> void:
	_shop_layer.visible           = false
	_overworld_layer.process_mode = Node.PROCESS_MODE_INHERIT


# ── intro cutscene ────────────────────────────────────────────────────────────

func _begin_run() -> void:
	_intro_layer.visible     = true
	_battle_layer.visible    = false
	_overworld_layer.visible = false


func _on_intro_finished() -> void:
	_intro_layer.visible = false
	_fresh_run           = false
	_show_overworld()


# ── visibility helpers ────────────────────────────────────────────────────────

func _show_overworld() -> void:
	_overworld_layer.visible = true
	_battle_layer.visible    = false


func _show_battle() -> void:
	_overworld_layer.visible = false
	_battle_layer.visible    = true
