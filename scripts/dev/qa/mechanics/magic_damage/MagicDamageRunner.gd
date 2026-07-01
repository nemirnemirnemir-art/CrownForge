extends RefCounted
class_name MagicDamageRunner

## Runs magic damage test scenarios using the existing RuntimeProbe.
## Each scenario is run independently: reset runtime, create scene, check multiplier.
## Returns structured result dicts compatible with QA report stores.

const RuntimeProbeScript := preload("res://scripts/dev/qa/BuildingUpgradeRuntimeProbe.gd")
const CatalogScript := preload("res://scripts/dev/qa/mechanics/magic_damage/MagicDamageScenarioCatalog.gd")

const TOLERANCE := 0.001


## Run a single scenario by ID. Returns a result Dictionary.
static func run_scenario(scenario_id: String) -> Dictionary:
	var scenario := CatalogScript.get_scenario_by_id(scenario_id)
	if scenario.is_empty():
		return _make_result(scenario_id, "FAIL_NOT_FOUND", 0.0, 0.0, 0.0, "Scenario not found: " + scenario_id)
	return _execute_scenario(scenario)


## Run all scenarios. Returns Array[Dictionary] of results.
static func run_all() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for scenario: Dictionary in CatalogScript.get_all_scenarios():
		results.append(_execute_scenario(scenario))
	return results


## Run a single scenario dict. Resets runtime, builds scene, reads multiplier.
static func _execute_scenario(scenario: Dictionary) -> Dictionary:
	var scenario_id: String = String(scenario.get("id", ""))
	var expected_mult: float = float(scenario.get("expected_multiplier", 1.0))
	var expected_dmg: float = float(scenario.get("expected_damage", 110.0))
	var slot_specs: Array = scenario.get("slots", [])
	var upgrade_ids: Array = scenario.get("upgrades", [])

	var probe := RuntimeProbeScript.new()
	probe.reset_runtime()

	# Create fake game scene with slot specs
	var typed_slots: Array[Dictionary] = []
	for spec in slot_specs:
		typed_slots.append(spec as Dictionary)
	var _scene := probe.create_game_scene_with_slots(typed_slots)

	# Unlock upgrades
	for uid in upgrade_ids:
		probe.unlock_upgrade(String(uid))

	# Read the actual spell damage multiplier from ArtifactCore
	var actual_mult: float = probe.get_spell_damage_multiplier()
	var actual_dmg: float = CatalogScript.BASE_SPELL_DAMAGE * actual_mult

	# Cleanup
	probe.cleanup()

	# Evaluate
	var passed := absf(actual_mult - expected_mult) < TOLERANCE
	var status: String = "PASS" if passed else "FAIL_MISMATCH"
	var reason: String = ""
	if not passed:
		reason = "Expected multiplier %.4f (damage %.1f), got %.4f (damage %.1f)" % [
			expected_mult, expected_dmg, actual_mult, actual_dmg
		]

	return _make_result(scenario_id, status, actual_mult, expected_mult, actual_dmg, reason, scenario)


static func _make_result(
	scenario_id: String,
	status: String,
	actual_mult: float,
	expected_mult: float,
	actual_dmg: float,
	reason: String,
	scenario: Dictionary = {},
) -> Dictionary:
	var ts: String = Time.get_datetime_string_from_system(false, true)
	return {
		"scenario_id": scenario_id,
		"label": scenario.get("label", scenario_id),
		"status": status,
		"actual_multiplier": actual_mult,
		"expected_multiplier": expected_mult,
		"actual_damage": actual_dmg,
		"expected_damage": float(scenario.get("expected_damage", 0.0)),
		"base_damage": CatalogScript.BASE_SPELL_DAMAGE,
		"notes": scenario.get("notes", ""),
		"reason": reason,
		"ran_at": ts,
	}
