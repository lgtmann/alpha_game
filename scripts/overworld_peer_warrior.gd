class_name OverworldPeerWarrior
extends Node2D

const TILE_SIZE: int = 48

# Per-name portrait colours and dialogue content.
# Falls back to DEFAULT_COLOUR / DEFAULT_DIALOGUE for unknown names.
const PORTRAIT_COLOURS := {
	"Ash":  Color("#c87050"),
	"Mira": Color("#50a0c8"),
	"Cole": Color("#a0c850"),
}
const DEFAULT_COLOUR := Color("#c8a050")

# Dialogue structure: {initial: {lines, choices}, after_talk: {lines, choices}}
# choices: Array of {id: String, label: String}
const DIALOGUES := {
	"Ash": {
		"initial": {
			"lines": [
				"...I know what you're thinking.",
				"Don't. I've already dropped two others today."
			],
			"choices": [
				{id = "fight", label = "Then let's make it three."},
				{id = "talk",  label = "I'm not here to fight you."},
				{id = "leave", label = "Walk away."},
			]
		},
		"after_talk": {
			"lines": [
				"Smart. The AI wants us tearing each other apart.",
				"There might be another way out. But first — prove you're worth talking to."
			],
			"choices": [
				{id = "fight", label = "Fight me, then."},
				{id = "leave", label = "I'll remember that."},
			]
		}
	},
	"Mira": {
		"initial": {
			"lines": [
				"You're new. I can tell.",
				"I've been awake three hours. Already watched six people die in that pit."
			],
			"choices": [
				{id = "fight", label = "You could be next."},
				{id = "talk",  label = "How many of us are left?"},
				{id = "leave", label = "..."},
			]
		},
		"after_talk": {
			"lines": [
				"Six, maybe. More deeper in.",
				"The robots are counting. They won't open the door until there's one."
			],
			"choices": [
				{id = "fight", label = "Then I'm the one."},
				{id = "leave", label = "Not if I can help it."},
			]
		}
	},
	"Cole": {
		"initial": {
			"lines": [
				"Go ahead. I'm done fighting.",
				"I watched my other self die in there.",
				"What even is the point?"
			],
			"choices": [
				{id = "fight", label = "The point is survival."},
				{id = "talk",  label = "Your other self?"},
				{id = "leave", label = "I'll leave you alone."},
			]
		},
		"after_talk": {
			"lines": [
				"Another me. Same vat batch. Same face.",
				"The AI grew three of us identical.",
				"One minute you're nothing. The next, you're watching yourself die."
			],
			"choices": [
				{id = "fight", label = "(Fight Cole)"},
				{id = "leave", label = "Stay alive, Cole."},
			]
		}
	},
}
const DEFAULT_DIALOGUE := {
	"initial": {
		"lines": ["...", "What do you want?"],
		"choices": [
			{id = "fight", label = "Your life."},
			{id = "leave", label = "Nothing."},
		]
	},
	"after_talk": {
		"lines": ["..."],
		"choices": [{id = "leave", label = "Leave."}]
	}
}

var tile_pos: Vector2i    = Vector2i.ZERO
var warrior_name: String  = ""
var defeated: bool        = false
var has_talked: bool      = false

var _label: Label = null


func _ready() -> void:
	_make_label()


func _make_label() -> void:
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_color_override("font_color", Color(0.90, 0.85, 0.70))
	_label.position = Vector2(-40.0, -36.0)
	_label.custom_minimum_size = Vector2(80.0, 0.0)
	add_child(_label)


func setup(tp: Vector2i, name_: String) -> void:
	tile_pos     = tp
	warrior_name = name_
	position = Vector2(tp.x * TILE_SIZE + TILE_SIZE / 2.0,
					   tp.y * TILE_SIZE + TILE_SIZE / 2.0)
	if _label == null:
		_make_label()
	_label.text = name_
	queue_redraw()


func portrait_color() -> Color:
	return PORTRAIT_COLOURS.get(warrior_name, DEFAULT_COLOUR)


func get_dialogue_phase() -> String:
	return "after_talk" if has_talked else "initial"


func get_dialogue_lines() -> Array[String]:
	var d: Dictionary = DIALOGUES.get(warrior_name, DEFAULT_DIALOGUE)
	var phase: Dictionary = d.get(get_dialogue_phase(), {})
	var raw: Array = phase.get("lines", ["..."])
	var out: Array[String] = []
	for s in raw:
		out.append(str(s))
	return out


func get_dialogue_choices() -> Array[Dictionary]:
	var d: Dictionary = DIALOGUES.get(warrior_name, DEFAULT_DIALOGUE)
	var phase: Dictionary = d.get(get_dialogue_phase(), {})
	var raw: Array = phase.get("choices", [{id = "leave", label = "Leave."}])
	var out: Array[Dictionary] = []
	for c in raw:
		out.append(c)
	return out


func mark_defeated() -> void:
	defeated = true
	if is_instance_valid(_label):
		_label.modulate = Color(0.4, 0.4, 0.4, 1.0)
	queue_redraw()


func _draw() -> void:
	if defeated:
		# Draw a faded X
		draw_line(Vector2(-10, -10), Vector2(10, 10), Color(0.4, 0.35, 0.3, 0.6), 2.0)
		draw_line(Vector2(10, -10), Vector2(-10, 10), Color(0.4, 0.35, 0.3, 0.6), 2.0)
		return
	var col := portrait_color()
	# Body
	draw_circle(Vector2(0.0, 4.0), 9.0, col * Color(0.7, 0.7, 0.7))
	# Head
	draw_circle(Vector2(0.0, -8.0), 7.0, col)
	# "?" indicator above (peer warriors are uncertain, not threatening)
	var top_y: float = -20.0
	draw_string(ThemeDB.fallback_font, Vector2(-4.0, top_y), "?",
				HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color("#ffd070"))
