class_name CardData
extends Resource

@export var card_name: String = "Unnamed"
@export var description: String = ""
@export var cost: int = 1
@export var effect: CardEffect
@export var icon: Texture2D = null
# When true, the card vanishes when played; otherwise it recycles to the
# bottom of the draw pile. Units (one-shot summons) use single_use=true.
@export var single_use: bool = false
