extends SceneTree

const BuildingConfigScript := preload("res://core/buildings/BuildingConfig.gd")
const BuildingCostEntryScript := preload("res://core/buildings/BuildingCostEntry.gd")
const BuildingCostServiceScript := preload("res://core/buildings/BuildingCostService.gd")


class FakeSlot:
	extends Node

	var current_building_id: String = ""


class FakeResourceCore:
	extends Node

	var amounts: Dictionary = {}
	var consumed: Array[Dictionary] = []

	func get_resource(resource_id: String) -> int:
		return int(amounts.get(resource_id, 0))

	func consume_resource(resource_id: String, amount: int) -> bool:
		if get_resource(resource_id) < amount:
			return false
		amounts[resource_id] = get_resource(resource_id) - amount
		consumed.append({"resource_id": resource_id, "amount": amount})
		return true


class FakeArtifactCore:
	extends Node

	var build_cost_multiplier: float = 1.0
	var refunds: Array = []

	func get_build_cost_multiplier() -> float:
		return build_cost_multiplier

	func apply_build_refund(paid_costs: Array[Dictionary]) -> void:
		refunds.append(paid_costs.duplicate(true))


class FakeEconomyCore:
	extends Node

	var gold: int = 0
	var spent_gold: float = 0.0

	func get_gold() -> int:
		return gold

	func can_afford(amount: float) -> bool:
		return gold >= int(amount)

	func spend_gold(amount: float) -> bool:
		var required := int(amount)
		if gold < required:
			return false
		gold -= required
		spent_gold += amount
		return true


class FakeMapLayout:
	extends Node

	var slots: Array = []


class FakeCurrentScene:
	extends Node

	var map_layout: Node = null

	func _get_map_layout_node() -> Node:
		return map_layout


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var service = BuildingCostServiceScript.new()
	var config := _make_building("house", [{"resource_id": "wood", "amount": 10}, {"resource_id": "stone", "amount": 3}])
	var buildings_by_id := {"house": config}

	var resource_core := FakeResourceCore.new()
	resource_core.amounts = {"wood": 30, "stone": 10}

	var artifact_core := FakeArtifactCore.new()
	artifact_core.build_cost_multiplier = 0.5

	var current_scene := Node.new()
	current_scene.name = "CurrentScene"

	var world := Node.new()
	world.name = "WorldYSort"
	current_scene.add_child(world)
	var map_container := Node.new()
	map_container.name = "MapContainer"
	world.add_child(map_container)
	var map_layout := FakeMapLayout.new()
	map_layout.name = "MapLayout"
	map_layout.slots = [_make_slot("house"), _make_slot("HOUSE"), _make_slot("well")]
	map_container.add_child(map_layout)

	var next_cost: Dictionary = service.get_next_build_cost("house", buildings_by_id, 0.2, artifact_core, current_scene)
	if int(next_cost.get("wood", 0)) != 7 or int(next_cost.get("stone", 0)) != 3:
		_fail("expected artifact and placed-count scaling to match current math: %s" % [next_cost])
		return

	if service.get_next_build_markup_percent("house", current_scene) != 40:
		_fail("expected markup percent to reflect two placed buildings")
		return

	var custom_step := 0.15
	if service.get_next_build_markup_percent("house", custom_step, current_scene) != 30:
		_fail("expected markup percent to align with configured build-cost step")
		return

	var gold_house := _make_building("gold_house", [{"resource_id": "gold", "amount": 10}, {"resource_id": "wood", "amount": 3}])
	var gold_buildings_by_id := {"gold_house": gold_house}
	var economy_core := FakeEconomyCore.new()
	economy_core.gold = 12
	resource_core.amounts = {"gold": 0, "wood": 5}
	if not service.can_afford_building("gold_house", gold_buildings_by_id, 0.0, resource_core, null, null, economy_core):
		_fail("expected gold affordability to use EconomyCore even when ResourceCore gold is zero")
		return
	if not service.pay_for_building("gold_house", gold_buildings_by_id, 0.0, resource_core, null, null, economy_core):
		_fail("expected gold payment to spend EconomyCore gold and ResourceCore materials")
		return
	if economy_core.gold != 2:
		_fail("expected EconomyCore gold to be reduced by the building gold cost")
		return
	if resource_core.amounts.get("wood", 0) != 2:
		_fail("expected non-gold resources to still be consumed from ResourceCore")
		return
	resource_core.amounts = {"wood": 30, "stone": 10}

	var seam_scene := FakeCurrentScene.new()
	seam_scene.map_layout = FakeMapLayout.new()
	seam_scene.map_layout.slots = [_make_slot("house"), _make_slot("HOUSE"), _make_slot("well")]
	if service.get_placed_building_count("house", seam_scene) != 2:
		_fail("expected placed-building count to use scene map-layout seam before fallback path")
		return

	if not service.can_afford_building("house", buildings_by_id, 0.2, resource_core, artifact_core, current_scene):
		_fail("expected resources to cover scaled cost")
		return

	resource_core.amounts = {"wood": 6, "stone": 2}
	if service.can_afford_building("house", buildings_by_id, 0.2, resource_core, artifact_core, current_scene):
		_fail("expected affordability check to fail when one resource is short")
		return

	resource_core.amounts = {"wood": 30, "stone": 10}
	if not service.pay_for_building("house", buildings_by_id, 0.2, resource_core, artifact_core, current_scene):
		_fail("expected payment to succeed")
		return
	if resource_core.amounts.get("wood", 0) != 23 or resource_core.amounts.get("stone", 0) != 7:
		_fail("expected resources to be consumed using scaled cost")
		return
	if artifact_core.refunds.size() != 1:
		_fail("expected build refund hook to receive paid costs")
		return

	print("[test_building_cost_service] PASS")
	quit(0)


func _make_building(building_id: String, costs: Array[Dictionary]) -> BuildingConfig:
	var config := BuildingConfigScript.new()
	config.building_id = building_id
	for cost_data in costs:
		var cost := BuildingCostEntryScript.new()
		cost.resource_id = String(cost_data.get("resource_id", ""))
		cost.amount = int(cost_data.get("amount", 0))
		config.build_costs.append(cost)
	return config


func _make_slot(building_id: String) -> FakeSlot:
	var slot := FakeSlot.new()
	slot.current_building_id = building_id
	return slot


func _fail(message: String) -> void:
	push_error("[test_building_cost_service] %s" % message)
	quit(1)
