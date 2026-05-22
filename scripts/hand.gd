class_name Hand
extends HBoxContainer

const CARD_VIEW_SCENE := preload("res://scenes/card_view.tscn")

func add_card(card_data: CardData) -> void:
	var view := CARD_VIEW_SCENE.instantiate() as CardView
	add_child(view)
	view.set_card(card_data)
