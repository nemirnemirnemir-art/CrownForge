extends SceneTree

const TeslaTowerScript := preload("res://core/buildings/special/TeslaTower.gd")
const TeslaTowerConfig := preload("res://data/buildings/kingdom_infrastructure/tesla_tower.tres")

var _failed := false

func _get_artifact_core() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("ArtifactCore")

func _get_upgrade_core() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("BuildingUpgradeCore")

func _get_resource_core() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("ResourceCore")

class FakeSlot:
	extends Node2D

	var slot_index: int = 222
	var current_building_id: String = "tesla_tower"

	func is_effectively_vzor_active() -> bool:
		return true

class FakeMapLayout:
	extends Node

	var slots: Array = []

class FakeGameScene:
	extends Node2D

	var map_layout_node: Node = null

class FakeEnemy:
	extends Node2D

	var total_damage: float = 0.0

	func take_damage(amount: float) -> void:
		total_damage += amount

func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	var artifact_core := _get_artifact_core()
	if artifact_core != null:
		artifact_core.call("reset")
	var upgrade_core := _get_upgrade_core()
	if upgrade_core != null:
		upgrade_core.call("load_save_data", {"upgrades_by_slot": {}})
	var resource_core := _get_resource_core()
	if resource_core != null:
		resource_core.call("reset")
	push_error("[test_tesla_tower_runtime_and_spell_bonus] %s" % message)
	quit(1)

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var artifact_core := _get_artifact_core()
	var upgrade_core := _get_upgrade_core()
	var resource_core := _get_resource_core()
	if TeslaTowerConfig == null or artifact_core == null or upgrade_core == null or resource_core == null:
		_fail("Tesla config and autoloads must exist")
		return

	artifact_core.call("reset")
	upgrade_core.call("load_save_data", {"upgrades_by_slot": {}})
	resource_core.call("reset")
	resource_core.call("add_resource", "crystal", 4)

	var slot := FakeSlot.new()
	slot.position = Vector2(100, 100)
	var map_layout := FakeMapLayout.new()
	map_layout.slots = [slot]
	var world := Node2D.new()
	world.name = "WorldYSort"
	var scene := FakeGameScene.new()
	scene.name = "FakeGameScene"
	scene.map_layout_node = map_layout
	scene.add_to_group("game_scene")
	scene.add_child(world)
	get_root().add_child(scene)
	current_scene = scene

	var enemy := FakeEnemy.new()
	enemy.position = Vector2(5000, 100)
	enemy.add_to_group("enemy")
	world.add_child(enemy)
	await process_frame

	var tesla := TeslaTowerScript.new()
	tesla.initialize(slot, TeslaTowerConfig)
	var result: Dictionary = tesla.tick(6.0)
	if not bool(result.get("completed", false)):
		_fail("Tesla Tower must complete an attack cycle when an enemy exists anywhere on the map")
		return
	if int(resource_core.call("get_resource", "crystal")) != 0:
		_fail("Tesla Tower must consume 4 crystal per shot")
		return

	await process_frame
	var effect := world.get_child(world.get_child_count() - 1)
	if effect == null:
		_fail("Tesla Tower must spawn a lightning effect when firing")
		return
	if absf(float(effect.get("line_width_multiplier")) - 2.0) > 0.001:
		_fail("Tesla Tower lightning line must be 2x standard size")
		return
	if absf(float(effect.get("start_anim_scale_multiplier")) - 2.0) > 0.001:
		_fail("Tesla Tower strike animation must be 2x standard size")
		return
	if absf(float(effect.get("pre_chain_delay_override")) - 0.0) > 0.001:
		_fail("Tesla Tower strike must not wait an extra pre-chain delay")
		return
	await process_frame
	await physics_frame
	await physics_frame
	await process_frame
	if absf(enemy.total_damage - 100.0) > 0.001:
		_fail("Tesla Tower must deal its base 100 damage without frag_bomb, got %.2f" % enemy.total_damage)
		return

	artifact_core.call("load_save_data", {"owned": ["frag_bomb"], "active": ["frag_bomb"], "state": {}})
	resource_core.call("add_resource", "crystal", 4)
	var boosted_before := enemy.total_damage
	result = tesla.tick(6.0)
	if not bool(result.get("completed", false)):
		_fail("Tesla Tower must still complete a strike cycle with frag_bomb active")
		return
	await process_frame
	await physics_frame
	await physics_frame
	await process_frame
	var boosted_damage := enemy.total_damage - boosted_before
	if absf(boosted_damage - 125.0) > 0.001:
		_fail("Tesla Tower must deal 125 damage with frag_bomb active, got %.2f" % boosted_damage)
		return

	upgrade_core.call("load_save_data", {"upgrades_by_slot": {"222": []}})
	var spell_mult := float(artifact_core.call("get_spell_damage_multiplier"))
	if absf(spell_mult - 1.5) > 0.001:
		_fail("Active Tesla Tower must give 1.5x spell damage, got %.3f" % spell_mult)
		return

	artifact_core.call("reset")
	upgrade_core.call("load_save_data", {"upgrades_by_slot": {}})
	resource_core.call("reset")
	print("[test_tesla_tower_runtime_and_spell_bonus] PASS")
	quit(0)
