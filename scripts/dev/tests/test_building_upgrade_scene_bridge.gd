extends SceneTree

const SceneBridgeScript := preload("res://core/building_upgrade/BuildingUpgradeSceneBridge.gd")


class FakeMapLayout:
	extends Node

	var slots: Array = [1, 2, 3]


class FakeGameScene:
	extends Node

	var map_layout_node = null
	var label: String = ""

	func _ready() -> void:
		add_to_group("game_scene")


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var bridge = SceneBridgeScript.new()
	if bridge == null:
		push_error("[test_building_upgrade_scene_bridge] failed to instantiate helper")
		quit(1)
		return

	var scene := FakeGameScene.new()
	var layout := FakeMapLayout.new()
	scene.map_layout_node = layout
	get_root().add_child(scene)
	await process_frame

	var slots: Array = bridge.get_map_slots()
	if slots.size() != 3:
		push_error("[test_building_upgrade_scene_bridge] slot lookup mismatch")
		quit(1)
		return

	var live_scene := FakeGameScene.new()
	live_scene.label = "live"
	live_scene.map_layout_node = FakeMapLayout.new()
	get_root().add_child(live_scene)
	await process_frame

	var qa_scene := FakeGameScene.new()
	qa_scene.label = "qa"
	var qa_layout := FakeMapLayout.new()
	qa_layout.slots = ["qa_slot"]
	qa_scene.map_layout_node = qa_layout
	get_root().add_child(qa_scene)
	current_scene = qa_scene
	await process_frame

	var qa_slots: Array = bridge.get_map_slots()
	if qa_slots.size() != 1 or qa_slots[0] != "qa_slot":
		push_error("[test_building_upgrade_scene_bridge] current_scene QA fixture must be preferred over earlier game_scene nodes")
		quit(1)
		return

	print("[test_building_upgrade_scene_bridge] PASS")
	quit(0)
