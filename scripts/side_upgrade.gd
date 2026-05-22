class_name SideUpgrade
extends Resource

enum Type {
	NONE = 0,
	SHIELD = 1,
	CANNON = 2,
	ACCELERATOR = 3,
}

@export var type: int = Type.NONE
@export var strength: int = 0

func is_shield() -> bool:
	return type == Type.SHIELD

func is_cannon() -> bool:
	return type == Type.CANNON

func is_accelerator() -> bool:
	return type == Type.ACCELERATOR

func type_name() -> String:
	match type:
		Type.SHIELD: return "Shield"
		Type.CANNON: return "Cannon"
		Type.ACCELERATOR: return "Accel"
	return "None"
