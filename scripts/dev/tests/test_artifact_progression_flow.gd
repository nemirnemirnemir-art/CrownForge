extends SceneTree

const ArtifactProgressionFlowScript := preload("res://core/artifacts/ArtifactProgressionFlow.gd")
const BUILDING_LIFECYCLE_HELPER_PATH := "res://core/artifacts/ArtifactBuildingLifecycleBonuses.gd"

var _failed: bool = false


class FakeHeroCore:
	extends RefCounted

	var ensured_templates: Array[String] = []
	var hired_units: Array[String] = []
	var squad_units: Array[String] = []
	var next_id: int = 1

	func ensure_hero_template(base_id: String, _display_name: String = "", _cost: float = 0.0) -> bool:
		ensured_templates.append(base_id)
		return true

	func hire_hero_copy(base_id: String) -> String:
		hired_units.append(base_id)
		var hero_id := "%s_%d" % [base_id, next_id]
		next_id += 1
		return hero_id

	func add_to_squad(hero_id: String) -> bool:
		squad_units.append(hero_id)
		return true


class FakeResourceCore:
	extends RefCounted

	var added: Array[Dictionary] = []

	func add_resource(resource_id: String, amount: int) -> void:
		added.append({"resource_id": resource_id, "amount": amount})


func _init() -> void:
	call_deferred("_run_test")


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error("[test_artifact_progression_flow] %s" % message)
	quit(1)


func _assert_true(value: bool, message: String) -> void:
	if not value:
		_fail(message)


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		_fail("%s (expected: %s, got: %s)" % [message, expected, actual])


func _run_test() -> void:
	var flow = ArtifactProgressionFlowScript.new()
	if flow == null:
		_fail("failed to instantiate artifact progression flow")
		return

	var hero_core := FakeHeroCore.new()
	var resource_core := FakeResourceCore.new()
	var active := {
		"moon_talisman": true,
		"royal_rune": true,
		"rune_shard_red": true,
		"comfy_bed": true,
		"wooden_key": true,
	}
	var state: Dictionary = {}

	flow.call("on_gaze_upgraded", active, state, hero_core)
	_assert_equal(hero_core.hired_units, ["healer_mage", "healer_mage", "healer_mage"], "moon_talisman must recruit 3 healer mages on gaze upgrade")
	if _failed:
		return
	_assert_equal(hero_core.squad_units.size(), 3, "moon_talisman must add recruited healer mages to the squad")
	if _failed:
		return

	var all_cooldowns := {
		"forced_tax": 100.0,
		"frenzy": 80.0,
		"training": 60.0,
		"unused": 40.0,
	}
	var reduced_all: Dictionary = flow.call("apply_active_cooldown_reduction", active, all_cooldowns)
	_assert_equal(float(reduced_all.get("forced_tax", -1.0)), 56.25, "royal_rune plus rune_shard_red must stack on the first active spell cooldown")
	if _failed:
		return
	_assert_equal(float(reduced_all.get("frenzy", -1.0)), 60.0, "royal_rune must reduce other cooldowns by 25% even without a shard")
	if _failed:
		return
	_assert_equal(float(reduced_all.get("training", -1.0)), 45.0, "royal_rune must reduce the third cooldown by 25% when no matching shard is active")
	if _failed:
		return

	var red_only := {"rune_shard_red": true}
	var reduced_red_only: Dictionary = flow.call("apply_active_cooldown_reduction", red_only, {"forced_tax": 100.0, "frenzy": 80.0, "training": 60.0})
	_assert_equal(float(reduced_red_only.get("forced_tax", -1.0)), 75.0, "rune_shard_red must reduce only the first active spell cooldown")
	if _failed:
		return
	_assert_equal(float(reduced_red_only.get("frenzy", -1.0)), 80.0, "rune_shard_red must not affect the second active spell cooldown")
	if _failed:
		return

	var capacity_bonus := int(flow.call("get_troop_building_capacity_bonus", active, {"building_type": int(BuildingConfig.BuildingType.MILITARY)}))
	_assert_equal(capacity_bonus, 1, "comfy_bed must add +1 troop building capacity")
	if _failed:
		return
	var non_troop_capacity_bonus := int(flow.call("get_troop_building_capacity_bonus", active, {"building_type": int(BuildingConfig.BuildingType.RESOURCE)}))
	_assert_equal(non_troop_capacity_bonus, 0, "comfy_bed must not affect non-troop buildings")
	if _failed:
		return

	var lifecycle_script := load(BUILDING_LIFECYCLE_HELPER_PATH)
	_assert_true(lifecycle_script != null, "building lifecycle helper must exist for iron_hoe")
	if _failed:
		return
	var lifecycle = lifecycle_script.new()
	_assert_true(lifecycle != null, "building lifecycle helper must instantiate")
	if _failed:
		return
	var starter_durability := int(lifecycle.call(
		"get_resource_building_durability",
		{"iron_hoe": true},
		{"building_id": "small_wheat_field", "building_type": int(BuildingConfig.BuildingType.RESOURCE)},
		3
	))
	_assert_equal(starter_durability, 6, "iron_hoe must double starter resource durability")
	if _failed:
		return
	var established_durability := int(lifecycle.call(
		"get_resource_building_durability",
		{"iron_hoe": true},
		{"building_id": "wheat_field", "building_type": int(BuildingConfig.BuildingType.RESOURCE)},
		3
	))
	_assert_equal(established_durability, 3, "iron_hoe must not change established resource durability")
	if _failed:
		return
	var starter_limit := int(lifecycle.call(
		"get_military_building_unit_limit",
		{"iron_hoe": true},
		{"building_id": "small_peasants_hut", "building_type": int(BuildingConfig.BuildingType.MILITARY)},
		3
	))
	_assert_equal(starter_limit, 6, "iron_hoe must double starter troop production limit")
	if _failed:
		return
	var veteran_limit := int(lifecycle.call(
		"get_military_building_unit_limit",
		{"iron_hoe": true},
		{"building_id": "peasants_hut", "building_type": int(BuildingConfig.BuildingType.MILITARY)},
		3
	))
	_assert_equal(veteran_limit, 3, "iron_hoe must not change non-starter troop production limit")
	if _failed:
		return

	flow.call("on_unit_created", active, resource_core)
	_assert_equal(resource_core.added.size(), 1, "wooden_key must grant exactly one resource payout per created unit")
	if _failed:
		return
	_assert_equal(resource_core.added[0], {"resource_id": "wood", "amount": 3}, "wooden_key must grant 3 wood on unit creation")
	if _failed:
		return

	print("[test_artifact_progression_flow] PASS")
	quit(0)
