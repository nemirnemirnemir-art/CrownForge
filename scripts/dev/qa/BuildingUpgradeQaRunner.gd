extends RefCounted
class_name BuildingUpgradeQaRunner

## Orchestrates building upgrade QA across all 141 matrix entries.
## Wraps BuildingUpgradeFamilyRunner and returns structured result dicts.
## All methods are static — no scene tree required.

const AuditMatrixScript := preload("res://scripts/dev/audit/BuildingUpgradeAuditMatrix.gd")
const AuditHarnessScript := preload("res://scripts/dev/audit/BuildingUpgradeAuditHarness.gd")
const FamilyRunnerScript := preload("res://scripts/dev/audit/BuildingUpgradeFamilyRunner.gd")

static var _FAMILY_NAMES: Dictionary = {
	0: "PRODUCTION_SPEED",
	1: "PRODUCTION_BONUS",
	2: "EFFICIENT_PROCESSING",
	3: "CAPACITY",
	4: "TROOP_STAT",
	5: "COMBAT_HOOK",
	6: "DEATH_REWARD",
	7: "COST_MODIFIER",
	8: "MORALE",
	9: "SPELL_DAMAGE",
	10: "UNIT_AURA",
	11: "PRODUCTION_EVENT",
	12: "MEGA_MILITIA",
	13: "LION_CIRCUS",
	14: "SPECIAL",
	15: "INCONCLUSIVE",
}


## Run all 141 entries, return structured results.
static func run_all() -> Array[Dictionary]:
	return _run_entries(AuditMatrixScript.get_all_entries())


## Run only entries for a specific family (int from AuditMatrix.EffectFamily).
static func run_family(family: int) -> Array[Dictionary]:
	return _run_entries(AuditMatrixScript.get_entries_by_family(family))


## Run only entries for a specific building_id.
static func run_building(building_id: String) -> Array[Dictionary]:
	var filtered: Array[Dictionary] = []
	for entry: Dictionary in AuditMatrixScript.get_all_entries():
		if String(entry.get("building_id", "")) == building_id:
			filtered.append(entry)
	return _run_entries(filtered)


## Re-run entries that previously failed (status begins with "FAIL").
static func run_failed(previous_results: Array[Dictionary]) -> Array[Dictionary]:
	var failed_ids: Dictionary = {}
	for rec: Dictionary in previous_results:
		var status: String = String(rec.get("status", ""))
		if status.begins_with("FAIL"):
			failed_ids[String(rec.get("upgrade_id", ""))] = true
	var filtered: Array[Dictionary] = []
	for entry: Dictionary in AuditMatrixScript.get_all_entries():
		if failed_ids.has(String(entry.get("upgrade_id", ""))):
			filtered.append(entry)
	return _run_entries(filtered)


static func _run_entries(entries: Array[Dictionary]) -> Array[Dictionary]:
	var harness := AuditHarnessScript.new()
	var ts: String = Time.get_datetime_string_from_system(false, true)
	var results: Array[Dictionary] = []
	for entry: Dictionary in entries:
		var entry_result: Dictionary = FamilyRunnerScript.run_entry_result(entry, harness)
		var status: String = String(entry_result.get("status", "MANUAL_CHECK_REQUIRED"))
		var family_int: int = int(entry.get("family", -1))
		results.append({
			"upgrade_id": entry.get("upgrade_id", ""),
			"building_id": entry.get("building_id", ""),
			"upgrade_index": int(entry.get("upgrade_index", 0)),
			"family": family_int,
			"family_name": _FAMILY_NAMES.get(family_int, str(family_int)),
			"status": status,
			"target": entry_result.get("target", ""),
			"before": entry_result.get("before", null),
			"after": entry_result.get("after", null),
			"expected": entry_result.get("expected", null),
			"reason": entry_result.get("reason", ""),
			"ran_at": ts,
		})
	return results
