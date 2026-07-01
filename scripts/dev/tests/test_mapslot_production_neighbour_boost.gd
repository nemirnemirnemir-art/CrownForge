extends SceneTree

const MapSlotProductionScript := preload("res://scripts/map_slot/MapSlotProduction.gd")
const BuildingConfigScript := preload("res://core/buildings/BuildingConfig.gd")

var _failed: bool = false
var _game_scene: Node = null


class FakeSlot:
	extends Node2D

	var slot_index: int = -1
	var current_building_id: String = ""
	var _vzor_active: bool = false

	func _init(new_slot_index: int, new_position: Vector2, building_id: String, vzor_active: bool) -> void:
		slot_index = new_slot_index
		position = new_position
		current_building_id = building_id
		_vzor_active = vzor_active

	func is_effectively_vzor_active() -> bool:
		return _vzor_active


class FakeMapLayout:
	extends Node

	var slots: Array = []


class FakeGameScene:
	extends Node

	var map_layout_node: Node = null


func _init() -> void:
	call_deferred("_run_test")


func _upgrade_core() -> Node:
	return get_root().get_node_or_null("BuildingUpgradeCore")


func _cleanup() -> void:
	var upgrade_core := _upgrade_core()
	if upgrade_core != null:
		upgrade_core.call("load_save_data", {"unlocked_by_building": {}, "mega_militia_counter": 0})
	if _game_scene != null and is_instance_valid(_game_scene):
		_game_scene.queue_free()
	_game_scene = null


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	_cleanup()
	push_error("[test_mapslot_production_neighbour_boost] %s" % message)
	quit(1)


func _run_test() -> void:
	var upgrade_core := _upgrade_core()
	if upgrade_core == null:
		_fail("BuildingUpgradeCore autoload must exist")
		return

	_cleanup()

	var sawmill_slot := FakeSlot.new(1, Vector2(100.0, 100.0), "sawmill", true)
	var target_slot := FakeSlot.new(2, Vector2(200.0, 100.0), "test_target", true)

	var map_layout := FakeMapLayout.new()
	map_layout.slots = [sawmill_slot, target_slot]

	_game_scene = FakeGameScene.new()
	_game_scene.map_layout_node = map_layout
	_game_scene.add_to_group("game_scene")
	get_root().add_child(_game_scene)
	await process_frame

	upgrade_core.call("unlock_building_upgrade", "sawmill", "sawmill:1")

	var production = MapSlotProductionScript.new()
	production.initialize(10.0, -1, 2, "test_target")

	var config := BuildingConfigScript.new()
	config.building_id = "test_target"
	config.building_type = BuildingConfigScript.BuildingType.RESOURCE
	config.cycle_time = 10.0

	var result: Dictionary = production.tick(0.5, "test_target", config)
	var actual_cycle := float(result.get("cycle_time", -1.0))
	var expected_cycle := 10.0 / 1.2
	if absf(actual_cycle - expected_cycle) > 0.01:
		_fail("Friendly Lumberjacks must reduce neighbour cycle time to %.3f, got %.3f" % [expected_cycle, actual_cycle])
		return

	_cleanup()
	print("[test_mapslot_production_neighbour_boost] PASS")
	quit(0)
