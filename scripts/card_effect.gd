class_name CardEffect
extends Resource

# Base class for card effects. Subclasses override apply() and optionally can_target().
# `board` is the Board node, `tile` is a Vector2i in board grid coordinates.

func apply(_board, _tile: Vector2i) -> void:
	pass

func can_target(board, tile: Vector2i) -> bool:
	return board.is_valid_tile(tile)

# Short type-specific blurb shown on the card under the description.
# Override in subclasses to surface stats / targeting constraints / etc.
func summary() -> String:
	return ""
