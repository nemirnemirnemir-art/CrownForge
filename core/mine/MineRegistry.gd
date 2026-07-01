extends Node

var ores: Dictionary = {} # id -> Ore (node instance)

func _ready() -> void:
	pass

func register_ore(ore_node: Node) -> void:
	if ore_node.get("ore_id") and ore_node.ore_id != "":
		ores[ore_node.ore_id] = ore_node
		print("[MineRegistry] Registered ore: ", ore_node.ore_id)
	else:
		print("[MineRegistry] Failed to register ore: invalid ID")

func get_ore_node(ore_id: String) -> Node:
	return ores.get(ore_id)

func get_all_ores() -> Array:
	return ores.values()

func clear_registry() -> void:
	ores.clear()
