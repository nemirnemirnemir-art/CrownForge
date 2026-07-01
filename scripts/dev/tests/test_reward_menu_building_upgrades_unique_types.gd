extends SceneTree

const MENU_SCENE := preload("res://scenes/ui/rewards/RewardMenuBuildingUpgrades.tscn")

var _failed: bool = false

class FakeSlot:
	extends Node

	var slot_index: int = -1
	var current_building_id: String = ""

	func _init(new_slot_index: int, building_id: String) -> void:
		slot_index = new_slot_index
		current_building_id = building_id

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
	push_error("[test_reward_menu_building_upgrades_unique_types] %s" % message)
	quit(1)

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	if MENU_SCENE == null:
		_fail("RewardMenuBuildingUpgrades scene must exist")
		return

	var upgrade_core := _upgrade_core()
	if upgrade_core:
		upgrade_core.call("load_save_data", {"upgrades_by_slot": {}})

	var map_layout := FakeMapLayout.new()
	map_layout.slots = [
		FakeSlot.new(1, "concert"),
		FakeSlot.new(2, "concert"),
		FakeSlot.new(3, "research_table"),
		FakeSlot.new(4, "magic_ball"),
		FakeSlot.new(5, "clay_mine"),
	]

	var game_scene := FakeGameScene.new()
	game_scene.map_layout_node = map_layout
	game_scene.add_to_group("game_scene")
	get_root().add_child(game_scene)

	var menu := MENU_SCENE.instantiate() as Control
	if menu == null:
		_fail("Failed to instantiate RewardMenuBuildingUpgrades")
		return
	get_root().add_child(menu)
	await process_frame

	menu.call("open")
	await process_frame

	var visible_buildings := []
	for card_name in ["Card1", "Card2", "Card3"]:
		var card := menu.get_node_or_null(card_name)
		if card == null or not card.visible:
			continue
		visible_buildings.append(String(card.get("_building_id")))

	if visible_buildings.has("research_table"):
		_fail("Reward menu must not offer buildings without upgrades")
		return
	if not visible_buildings.has("clay_mine"):
		_fail("Reward menu must still offer BASIC_PRODUCTION buildings when they have upgrades")
		return

	var unique_ids := {}
	for building_id in visible_buildings:
		if unique_ids.has(building_id):
			_fail("Reward menu must not offer duplicate building types in one roll: %s" % building_id)
			return
		unique_ids[building_id] = true

	if visible_buildings.size() != 3:
		_fail("Reward menu must offer 3 unique upgradable building types when available, got %d" % visible_buildings.size())
		return

	menu.queue_free()
	game_scene.queue_free()
	print("[test_reward_menu_building_upgrades_unique_types] PASS")
	quit(0)
