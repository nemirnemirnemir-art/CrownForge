extends Node
class_name HeroState

## Базовый класс для состояний героя

var hero: Node2D
var state_machine: Node

func set_hero(hero_node: Node2D) -> void:
	hero = hero_node

func set_state_machine(machine: Node) -> void:
	state_machine = machine

func enter() -> void:
	pass

func exit() -> void:
	pass

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass


func _get_hero_core() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("HeroCore")


func _get_map_marker_service() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("MapMarkerService")


func _is_hero_orphaned() -> bool:
	if hero == null or not ("hero_id" in hero):
		return false

	var hero_id := String(hero.hero_id)
	if hero_id == "":
		return false

	var hero_core := _get_hero_core()
	if hero_core == null:
		return false

	var query: Variant = hero_core.get("query")
	if query == null:
		return false
	if not query.has_method("has_hero"):
		return false

	return not bool(query.call("has_hero", hero_id))

