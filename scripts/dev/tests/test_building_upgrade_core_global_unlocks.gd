extends SceneTree

var _failed: bool = false

class FakeSlot:
	extends Node

	var slot_index: int = -1
	var current_building_id: String = ""
	var _vzor_active: bool = false

	func _init(new_slot_index: int, building_id: String, vzor_active: bool) -> void:
		slot_index = new_slot_index
		current_building_id = building_id
		_vzor_active = vzor_active

	func is_effectively_vzor_active() -> bool:
		return _vzor_active

	func set_vzor_active(value: bool) -> void:
		_vzor_active = value

class FakeMapLayout:
	extends Node

	var slots: Array = []

class FakeGameScene:
	extends Node

	var map_layout_node: Node = null

func _upgrade_core() -> Node:
	return get_root().get_node_or_null("BuildingUpgradeCore")

func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error("[test_building_upgrade_core_global_unlocks] %s" % message)
	var upgrade_core := _upgrade_core()
	if upgrade_core:
		upgrade_core.call("load_save_data", {"upgrades_by_slot": {}})
	quit(1)

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var upgrade_core := _upgrade_core()
	if upgrade_core == null:
		_fail("BuildingUpgradeCore autoload must exist")
		return

	upgrade_core.call("load_save_data", {"upgrades_by_slot": {}})

	var concert_slot_1 := FakeSlot.new(1, "concert", true)
	var concert_slot_2 := FakeSlot.new(2, "concert", false)

	var map_layout := FakeMapLayout.new()
	map_layout.slots = [
		concert_slot_1,
		concert_slot_2,
	]

	var game_scene := FakeGameScene.new()
	game_scene.map_layout_node = map_layout
	game_scene.add_to_group("game_scene")
	get_root().add_child(game_scene)
	await process_frame

	upgrade_core.call("load_save_data", {
		"upgrades_by_slot": {
			"1": ["concert:0", "concert:1"],
		}
	})

	if not bool(upgrade_core.call("has_upgrade", 2, "concert:0")):
		_fail("Concert upgrade unlocked on one slot must apply to every concert building")
		return

	var passive_concert_morale := int(upgrade_core.call("get_passive_concert_morale_bonus"))
	if passive_concert_morale != 10:
		_fail("Passive Concert morale must count all built concerts after one global unlock, got %d" % passive_concert_morale)
		return

	var active_concert_morale := int(upgrade_core.call("get_active_concert_morale_bonus"))
	if active_concert_morale != 10:
		_fail("Active Concert morale must count only active concerts, got %d" % active_concert_morale)
		return

	concert_slot_2.set_vzor_active(true)
	active_concert_morale = int(upgrade_core.call("get_active_concert_morale_bonus"))
	if active_concert_morale != 20:
		_fail("Active Concert morale must scale with all active copies of the building type, got %d" % active_concert_morale)
		return

	upgrade_core.call("apply_upgrade", 2, "concert:0")
	active_concert_morale = int(upgrade_core.call("get_active_concert_morale_bonus"))
	if active_concert_morale != 20:
		_fail("Unlocking the same upgrade again on another slot must not duplicate the global unlock, got %d" % active_concert_morale)
		return

	upgrade_core.call("load_save_data", {"upgrades_by_slot": {}})
	game_scene.queue_free()
	print("[test_building_upgrade_core_global_unlocks] PASS")
	quit(0)
