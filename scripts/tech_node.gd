class_name TechNode
extends Resource

@export var id: StringName
@export var node_name: String = "Tech"
@export var description: String = ""
@export var cost: int = 1
@export var branch: StringName = &"economy"  # &"economy" or &"combat"
@export var prerequisites: Array[StringName] = []
