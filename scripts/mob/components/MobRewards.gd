extends Node
class_name MobRewards

var _mob: Node2D
var _health: MobHealth

func setup(mob: Node2D, health: MobHealth) -> void:
	_mob = mob
	_health = health
	_health.died.connect(_on_mob_died)

func _on_mob_died() -> void:
	award()

func award() -> void:
	if not is_instance_valid(_mob):
		return
	_drop_inventory_reward()

func _drop_inventory_reward() -> void:
	var player_inventory := _get_singleton("PlayerInventory")
	if not is_instance_valid(player_inventory):
		return
	var type_str = ""
	var n = _mob.name
	if "Goblin" in n: type_str = "Goblin"
	
	if type_str == "":
		return
	
	call_deferred("_deferred_try_drop_inventory", type_str, _mob.global_position)


func _deferred_try_drop_inventory(type_str: String, drop_pos: Vector2) -> void:
	var player_inventory := _get_singleton("PlayerInventory")
	if is_instance_valid(player_inventory) and player_inventory.has_method("try_drop_from_enemy"):
		player_inventory.try_drop_from_enemy(type_str, drop_pos)

func _get_singleton(name: String) -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null(name)
