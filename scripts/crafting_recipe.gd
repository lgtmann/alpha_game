class_name CraftingRecipe
extends Resource

@export var output_card: CardData
@export var costs: Dictionary = {}  # StringName -> int

func can_afford(inventory: Dictionary) -> bool:
	for resource: StringName in costs.keys():
		if inventory.get(resource, 0) < costs[resource]:
			return false
	return true

func spend(inventory: Dictionary) -> void:
	for resource: StringName in costs.keys():
		inventory[resource] = inventory.get(resource, 0) - costs[resource]

func cost_description() -> String:
	var parts: Array[String] = []
	for resource: StringName in costs.keys():
		parts.append("%d %s" % [costs[resource], resource])
	return ", ".join(parts)
