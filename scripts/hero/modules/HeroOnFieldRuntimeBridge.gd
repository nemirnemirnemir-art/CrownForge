extends RefCounted
class_name HeroOnFieldRuntimeBridge

var hero: Node2D = null
var _hero_core_override: Node = null
var _event_bus_override: Node = null
var _damage_popup_pool_override: Node = null


func setup(hero_ref: Node2D) -> void:
	hero = hero_ref


func set_overrides(hero_core = null, event_bus = null, damage_popup_pool = null) -> void:
	_hero_core_override = hero_core
	_event_bus_override = event_bus
	_damage_popup_pool_override = damage_popup_pool


func get_hero_core() -> Node:
	if _hero_core_override != null:
		return _hero_core_override
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var direct := tree.root.get_node_or_null("HeroCore")
	if direct != null:
		return direct
	return tree.root.get_node_or_null("/root/HeroCore")


func get_event_bus() -> Node:
	if _event_bus_override != null:
		return _event_bus_override
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var direct := tree.root.get_node_or_null("EventBus")
	if direct != null:
		return direct
	return tree.root.get_node_or_null("/root/EventBus")


func get_damage_popup_pool() -> Node:
	if _damage_popup_pool_override != null:
		return _damage_popup_pool_override
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var direct := tree.root.get_node_or_null("DamagePopupPool")
	if direct != null:
		return direct
	return tree.root.get_node_or_null("/root/DamagePopupPool")


func get_current_hp() -> float:
	var hero_core := get_hero_core()
	if hero_core == null or hero == null:
		return 0.0
	var hero_id := String(hero.get("hero_id"))
	if hero_id == "":
		return 0.0
	var hero_data: Dictionary = hero_core.call("get_hero", hero_id)
	return float(hero_data.get("hp", 0.0)) if hero_data is Dictionary else 0.0


func get_max_hp() -> float:
	var hero_core := get_hero_core()
	if hero_core == null or hero == null:
		return 1.0
	var hero_id := String(hero.get("hero_id"))
	if hero_id == "":
		return 1.0
	var total_stats: Dictionary = hero_core.call("get_hero_total_stats", hero_id)
	return max(1.0, float(total_stats.get("maxHp", 1.0))) if total_stats is Dictionary else 1.0


func get_attack_damage() -> float:
	var hero_core := get_hero_core()
	if hero_core == null or hero == null:
		return 1.0
	var hero_id := String(hero.get("hero_id"))
	if hero_id == "":
		return 1.0
	var total_stats: Dictionary = hero_core.call("get_hero_total_stats", hero_id)
	if total_stats is Dictionary and total_stats.has("damage"):
		return float(total_stats.get("damage", 1.0))
	var hero_data: Dictionary = hero_core.call("get_hero", hero_id)
	return float(hero_data.get("damage", 1.0)) if hero_data is Dictionary else 1.0


func send_damage(hero_id: String, amount: int) -> void:
	var hero_core := get_hero_core()
	if hero_core == null or hero_id == "":
		return
	if hero_core.has_method("take_damage"):
		hero_core.call("take_damage", hero_id, float(amount))
	elif hero_core.has_method("modify_hero_hp"):
		hero_core.call("modify_hero_hp", hero_id, -float(amount))
