class_name Deck
extends RefCounted

var draw_pile: Array[CardData] = []
var discard_pile: Array[CardData] = []

func _init(starter_cards: Array[CardData] = []) -> void:
	for c in starter_cards:
		draw_pile.append(c)
	shuffle_draw_pile()

func shuffle_draw_pile() -> void:
	draw_pile.shuffle()

func draw_card() -> CardData:
	if draw_pile.is_empty():
		if discard_pile.is_empty():
			return null
		draw_pile = discard_pile.duplicate()
		discard_pile.clear()
		shuffle_draw_pile()
	return draw_pile.pop_back()

func discard(card: CardData) -> void:
	discard_pile.append(card)

# Recycle a played card back to the bottom of the draw pile, so the player
# can draw it again after cycling through the rest of the deck.
func recycle_to_bottom(card: CardData) -> void:
	if card == null:
		return
	draw_pile.insert(0, card)

func draw_count() -> int:
	return draw_pile.size()

func discard_count() -> int:
	return discard_pile.size()
