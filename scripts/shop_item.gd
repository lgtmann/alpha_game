class_name ShopItem
extends RefCounted

## One entry in the salesman's catalogue.

var label: String = ""
var card: CardData = null          # null for non-card rewards
var tech_points_reward: int = 0    # tech points granted on purchase (if > 0)
var cost: Dictionary = {}          # StringName -> int  (resource name -> amount)


func can_afford(inventory: Dictionary) -> bool:
	for res: StringName in cost:
		if inventory.get(res, 0) < cost[res]:
			return false
	return true


## Human-readable cost string, e.g. "3 Wood + 2 Iron".
func cost_string() -> String:
	var parts: Array[String] = []
	for res: StringName in cost:
		parts.append("%d %s" % [cost[res], res])
	return " + ".join(parts)
