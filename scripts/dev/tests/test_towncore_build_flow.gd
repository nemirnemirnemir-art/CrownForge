extends SceneTree

const TownBuildFlowScript := preload("res://core/town/TownBuildFlow.gd")


class FakeBuildings:
	extends RefCounted

	var slot_states: Dictionary = {}
	var built_counts: Dictionary = {}

	func get_slot_state(building_id: String, slot_index: int) -> Dictionary:
		return slot_states.get("%s:%d" % [building_id, slot_index], {})

	func set_slot_state(building_id: String, slot_index: int, state: Dictionary) -> void:
		slot_states["%s:%d" % [building_id, slot_index]] = state.duplicate(true)

	func clear_slot_state(building_id: String, slot_index: int) -> void:
		slot_states.erase("%s:%d" % [building_id, slot_index])

	func increment_building_built_count(building_id: String) -> void:
		built_counts[building_id] = int(built_counts.get(building_id, 0)) + 1

	func get_building_built_count(building_id: String) -> int:
		return int(built_counts.get(building_id, 0))


class FakeBuildConfigEntry:
	extends RefCounted

	var free_build: bool = false
	var growth: float = 1.5
	var base_cost
	var provides


class FakeAmounts:
	extends RefCounted

	var values: Dictionary = {}

	func to_dict() -> Dictionary:
		return values.duplicate(true)


class FakeBuildConfig:
	extends RefCounted

	var entries: Dictionary = {}

	func get_entry(building_id: String):
		return entries.get(building_id, null)


class FakeSaveCore:
	extends RefCounted

	var requests: int = 0

	func request_save() -> void:
		requests += 1


class FakeResourceCore:
	extends RefCounted

	var resources: Dictionary = {}
	var spent: Array[Dictionary] = []

	func get_resource(resource_id: String) -> int:
		return int(resources.get(resource_id, 0))

	func consume_resource(resource_id: String, amount: int) -> bool:
		var current := int(resources.get(resource_id, 0))
		if current < amount:
			return false
		resources[resource_id] = current - amount
		spent.append({"resource_id": resource_id, "amount": amount})
		return true


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = TownBuildFlowScript.new()
	if flow == null:
		push_error("[test_towncore_build_flow] failed to instantiate helper")
		quit(1)
		return

	var buildings := FakeBuildings.new()
	var save_core := FakeSaveCore.new()
	var config := FakeBuildConfig.new()
	var entry := FakeBuildConfigEntry.new()
	entry.base_cost = FakeAmounts.new()
	entry.base_cost.values = {"wood": 10}
	entry.provides = FakeAmounts.new()
	entry.provides.values = {"food": 1}
	config.entries["farm"] = entry

	flow.set_building_slot_state(buildings, save_core, "farm", 2, {"progress": 0.5}, true)
	if save_core.requests != 1:
		push_error("[test_towncore_build_flow] slot-state save request not propagated")
		quit(1)
		return
	if flow.get_building_slot_state(buildings, "farm", 2).get("progress", 0.0) != 0.5:
		push_error("[test_towncore_build_flow] slot state was not persisted")
		quit(1)
		return

	var next_cost: Dictionary = flow.get_next_build_cost(null, buildings, config, "farm")
	if int(next_cost.get("wood", 0)) != 10:
		push_error("[test_towncore_build_flow] base build cost mismatch")
		quit(1)
		return

	buildings.increment_building_built_count("farm")
	next_cost = flow.get_next_build_cost(null, buildings, config, "farm")
	if int(next_cost.get("wood", 0)) != 15:
		push_error("[test_towncore_build_flow] scaled build cost mismatch: %s" % [next_cost])
		quit(1)
		return

	var resource_core := FakeResourceCore.new()
	resource_core.resources = {"wood": 20}
	if not flow.try_pay_build_cost(buildings, resource_core, null, config, "farm"):
		push_error("[test_towncore_build_flow] expected successful cost payment")
		quit(1)
		return
	if buildings.get_building_built_count("farm") != 2:
		push_error("[test_towncore_build_flow] built count not incremented after payment")
		quit(1)
		return

	print("[test_towncore_build_flow] PASS")
	quit(0)
