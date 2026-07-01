extends SceneTree

const MainUIActionFlowScript := preload("res://scripts/ui/hud/MainUIActionFlow.gd")


class FakeTownOverlays:
	extends RefCounted

	var calls: Array[String] = []

	func open_smith() -> void:
		calls.append("smith")

	func open_storage_inventory() -> void:
		calls.append("inventory")

	func open_alchemy() -> void:
		calls.append("alchemy")


class FakeTownInventory:
	extends RefCounted

	var items: Array = []

	func add_item(item) -> void:
		items.append(item)


class FakeTownCore:
	extends RefCounted

	var debug_levels: Array = []
	var test_population: int = 0
	var inventory := FakeTownInventory.new()

	func debug_set_building_level(building_id: String, level: int) -> void:
		debug_levels.append([building_id, level])

	func add_test_population(amount: int) -> void:
		test_population += amount

	func get_town_inventory() -> FakeTownInventory:
		return inventory


class FakeEconomy:
	extends RefCounted

	var gold_added: float = 0.0

	func add_gold(value: float) -> void:
		gold_added += value


class FakeCastle:
	extends RefCounted

	var reset_calls: int = 0

	func reset_game() -> void:
		reset_calls += 1


class FakePopupHost:
	extends RefCounted

	var added: Array = []

	func add_popup(node: Node) -> void:
		added.append(node)


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = MainUIActionFlowScript.new()
	if flow == null:
		push_error("[test_mainui_action_flow] failed to instantiate helper")
		quit(1)
		return

	var overlays := FakeTownOverlays.new()
	flow.open_smith(overlays)
	flow.open_inventory(overlays)
	flow.open_alchemy(overlays)
	if overlays.calls != ["smith", "inventory", "alchemy"]:
		push_error("[test_mainui_action_flow] town button routing mismatch")
		quit(1)
		return

	var economy := FakeEconomy.new()
	var town := FakeTownCore.new()
	flow.run_debug_grant(economy, town, [{"id": "ingredient_hollow_bottle", "icon": "res://x.png"}], 3)
	if economy.gold_added != 100000.0:
		push_error("[test_mainui_action_flow] debug gold mismatch")
		quit(1)
		return
	if town.debug_levels.is_empty() or town.test_population != 50:
		push_error("[test_mainui_action_flow] debug town tweaks mismatch")
		quit(1)
		return
	if town.inventory.items.size() != 1:
		push_error("[test_mainui_action_flow] debug ingredient injection mismatch")
		quit(1)
		return

	var castle := FakeCastle.new()
	flow.restart_game(castle)
	if castle.reset_calls != 1:
		push_error("[test_mainui_action_flow] restart flow mismatch")
		quit(1)
		return

	print("[test_mainui_action_flow] PASS")
	quit(0)
