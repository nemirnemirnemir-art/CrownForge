extends RefCounted
class_name BuildingUpgradeFamilyQaRunner

## Generic runner for family-based QA testing.
## Uses the existing BuildingUpgradeFamilyRunner for actual verification.
## Returns structured results compatible with QA report stores.

const AuditMatrixScript := preload("res://scripts/dev/audit/BuildingUpgradeAuditMatrix.gd")
const AuditHarnessScript := preload("res://scripts/dev/audit/BuildingUpgradeAuditHarness.gd")
const FamilyRunnerScript := preload("res://scripts/dev/audit/BuildingUpgradeFamilyRunner.gd")
const RegistryScript := preload("res://scripts/dev/qa/families/BuildingUpgradeFamilyQaRegistry.gd")


## Run all entries for a specific family by family_id (enum value).
## Returns Array[Dictionary] of structured results.
static func run_family(family_id: int) -> Array[Dictionary]:
	var entries := AuditMatrixScript.get_entries_by_family(family_id)
	return _run_entries(entries, family_id)


## Run all entries for a specific family by slug.
## Returns Array[Dictionary] of structured results.
static func run_family_by_slug(slug: String) -> Array[Dictionary]:
	var family := RegistryScript.get_family_by_slug(slug)
	if family.is_empty():
		return []
	return run_family(int(family.get("family_id", -1)))


## Run a single upgrade entry by upgrade_id.
## Returns a single result Dictionary.
static func run_single(upgrade_id: String) -> Dictionary:
	var entries := AuditMatrixScript.get_all_entries()
	for entry: Dictionary in entries:
		if String(entry.get("upgrade_id", "")) == upgrade_id:
			var harness := AuditHarnessScript.new()
			var entry_result: Dictionary = FamilyRunnerScript.run_entry_result(entry, harness)
			return _build_result(entry, entry_result)
	return _error_result(upgrade_id, "Entry not found in matrix")


## Run all V1 families and return combined results.
## Returns Array[Dictionary] with all family results combined.
static func run_all_v1() -> Array[Dictionary]:
	var all_results: Array[Dictionary] = []
	for family: Dictionary in RegistryScript.get_v1_families():
		var family_results := run_family(int(family.get("family_id", -1)))
		all_results.append_array(family_results)
	return all_results


## Run only runtime-backed V1 families.
static func run_runtime_backed_v1() -> Array[Dictionary]:
	var all_results: Array[Dictionary] = []
	for family: Dictionary in RegistryScript.get_runtime_backed_families():
		var family_results := run_family(int(family.get("family_id", -1)))
		all_results.append_array(family_results)
	return all_results


static func _run_entries(entries: Array[Dictionary], family_id: int) -> Array[Dictionary]:
	var harness := AuditHarnessScript.new()
	var results: Array[Dictionary] = []
	for entry: Dictionary in entries:
		var entry_result: Dictionary = FamilyRunnerScript.run_entry_result(entry, harness)
		results.append(_build_result(entry, entry_result))
	return results


static func _build_result(entry: Dictionary, entry_result: Dictionary) -> Dictionary:
	var family_id := int(entry.get("family", -1))
	var family := RegistryScript.get_family_by_id(family_id)
	var ts: String = Time.get_datetime_string_from_system(false, true)
	
	return {
		"upgrade_id": entry.get("upgrade_id", ""),
		"building_id": entry.get("building_id", ""),
		"upgrade_index": int(entry.get("upgrade_index", 0)),
		"family_id": family_id,
		"family_slug": family.get("slug", ""),
		"family_label": family.get("label", str(family_id)),
		"status": entry_result.get("status", "MANUAL_CHECK_REQUIRED"),
		"target": entry_result.get("target", ""),
		"before": entry_result.get("before", null),
		"after": entry_result.get("after", null),
		"expected": entry_result.get("expected", null),
		"reason": entry_result.get("reason", ""),
		"ran_at": ts,
	}


static func _error_result(upgrade_id: String, reason: String) -> Dictionary:
	var ts: String = Time.get_datetime_string_from_system(false, true)
	return {
		"upgrade_id": upgrade_id,
		"building_id": "",
		"upgrade_index": -1,
		"family_id": -1,
		"family_slug": "",
		"family_label": "ERROR",
		"status": "FAIL_NOT_FOUND",
		"target": "",
		"before": null,
		"after": null,
		"expected": null,
		"reason": reason,
		"ran_at": ts,
	}


## Get summary statistics for a set of results.
static func get_summary(results: Array[Dictionary]) -> Dictionary:
	var pass_count := 0
	var fail_count := 0
	var logic_pass_count := 0
	var manual_count := 0
	
	for r: Dictionary in results:
		var status: String = String(r.get("status", ""))
		if status == "PASS":
			pass_count += 1
		elif status == "LOGIC_PASS":
			logic_pass_count += 1
		elif status.begins_with("FAIL"):
			fail_count += 1
		else:
			manual_count += 1
	
	return {
		"total": results.size(),
		"pass": pass_count,
		"logic_pass": logic_pass_count,
		"fail": fail_count,
		"manual": manual_count,
		"all_pass": fail_count == 0 and manual_count == 0,
	}
