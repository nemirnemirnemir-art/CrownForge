extends SceneTree

const FairyFountainScript := preload("res://core/buildings/special/FairyFountain.gd")
const FairyFountainConfig := preload("res://data/buildings/kingdom_infrastructure/fairy_fountain.tres")

var _failed := false

func _get_artifact_core() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("ArtifactCore")

func _get_resource_core() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("ResourceCore")

func _get_upgrade_core() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("BuildingUpgradeCore")

class FakeSlot:
	extends Node2D

	var slot_index: int = 444
	var popups: Array[Dictionary] = []

	func show_resource_popup(resource_id: String, amount: int, offset: Vector2 = Vector2.ZERO) -> void:
		popups.append({"resource_id": resource_id, "amount": amount, "offset": offset})

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
	push_error("[test_fairy_fountain_runtime] %s" % message)
	quit(1)

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var artifact_core := _get_artifact_core()
	var resource_core := _get_resource_core()
	var upgrade_core := _get_upgrade_core()
	if FairyFountainConfig == null or artifact_core == null or resource_core == null or upgrade_core == null:
		_fail("Fairy Fountain config and required autoloads must exist")
		return

	artifact_core.call("reset")
	resource_core.call("reset")
	upgrade_core.call("load_save_data", {"upgrades_by_slot": {"444": ["fairy_fountain:1"]}})

	var slot := FakeSlot.new()
	slot.position = Vector2(100, 100)
	get_root().add_child(slot)

	var enemy := FakeEnemy.new()
	enemy.position = Vector2(120, 100)
	enemy.add_to_group("enemy")
	get_root().add_child(enemy)

	var fountain := FairyFountainScript.new()
	fountain.initialize(slot, FairyFountainConfig)

	fountain.tick(10.0)
	if absf(enemy.total_damage - 15.0) > 0.001:
		_fail("Anti-Goblin Dust must deal 15 damage on each production cycle, got %.2f" % enemy.total_damage)
		return

	artifact_core.call("load_save_data", {"owned": ["frag_bomb"], "active": ["frag_bomb"], "state": {}})
	var boosted_before := enemy.total_damage
	fountain.tick(10.0)
	var boosted_damage := enemy.total_damage - boosted_before
	if absf(boosted_damage - 18.75) > 0.001:
		_fail("Anti-Goblin Dust must deal 18.75 damage per production cycle with frag_bomb active, got %.2f" % boosted_damage)
		return

	resource_core.call("reset")
	slot.popups.clear()
	fountain.tick(10.0)
	var all_resources := resource_core.call("get_all_resources") as Dictionary
	var total_amount := 0
	var non_zero := 0
	for resource_id in all_resources.keys():
		var amount := int(all_resources[resource_id])
		total_amount += amount
		if amount > 0:
			non_zero += 1
	if total_amount != 5:
		_fail("Fairy Fountain must produce exactly 5 resources per cycle, got %d" % total_amount)
		return
	if non_zero != 1:
		_fail("Fairy Fountain must produce one random resource type per cycle, got %d resource types" % non_zero)
		return
	if slot.popups.size() != 1:
		_fail("Fairy Fountain must show one popup for the 5-resource bundle, got %d popups" % slot.popups.size())
		return
	if int(slot.popups[0].get("amount", 0)) != 5:
		_fail("Fairy Fountain popup must show amount 5")
		return

	upgrade_core.call("load_save_data", {"upgrades_by_slot": {}})
	resource_core.call("reset")
	print("[test_fairy_fountain_runtime] PASS")
	quit(0)
