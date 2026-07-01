extends SceneTree

## Headless regression test for BuildingUpgradeFamilyQaRunner.
## Run with: godot --headless --script scripts/dev/tests/test_building_upgrade_family_qa_runner.gd

const RegistryScript := preload("res://scripts/dev/qa/families/BuildingUpgradeFamilyQaRegistry.gd")
const RunnerScript := preload("res://scripts/dev/qa/families/BuildingUpgradeFamilyQaRunner.gd")
const AuditMatrixScript := preload("res://scripts/dev/audit/BuildingUpgradeAuditMatrix.gd")

var _failed := false


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error("[test_building_upgrade_family_qa_runner] %s" % message)
	quit(1)


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	await process_frame

	# Test 1: Registry has V1 families
	var families := RegistryScript.get_v1_families()
	if families.size() < 6:
		_fail("Expected at least 6 V1 families, got %d" % families.size())
		return

	# Test 2: Registry has runtime-backed families
	var runtime_families := RegistryScript.get_runtime_backed_families()
	if runtime_families.size() < 6:
		_fail("Expected at least 6 runtime-backed families, got %d" % runtime_families.size())
		return

	for f: Dictionary in runtime_families:
		if not bool(f.get("runtime_backed", false)):
			_fail("Family %s should be runtime_backed" % f.get("slug", ""))
			return

	# Test 3: Get family by slug
	var spell_family := RegistryScript.get_family_by_slug("spell_damage")
	if spell_family.is_empty():
		_fail("Failed to get spell_damage family by slug")
		return
	if String(spell_family.get("label", "")) != "Spell Damage":
		_fail("spell_damage label mismatch")
		return
	if int(spell_family.get("family_id", -1)) != AuditMatrixScript.EffectFamily.SPELL_DAMAGE:
		_fail("spell_damage family_id mismatch")
		return

	# Test 4: Runner run_family returns results
	var morale_results := RunnerScript.run_family(AuditMatrixScript.EffectFamily.MORALE)
	if morale_results.is_empty():
		_fail("MORALE family returned empty results")
		return
	var first := morale_results[0]
	if not first.has("upgrade_id"):
		_fail("Result missing upgrade_id")
		return
	if not first.has("status"):
		_fail("Result missing status")
		return
	if not first.has("family_slug"):
		_fail("Result missing family_slug")
		return

	# Test 5: Runner run_single returns result
	var single_result := RunnerScript.run_single("vineyard:0")
	if single_result.is_empty():
		_fail("run_single returned empty result")
		return
	if String(single_result.get("upgrade_id", "")) != "vineyard:0":
		_fail("upgrade_id mismatch for run_single")
		return

	# Test 6: CHAMPION inspiration must be fully automated
	var champion_result := RunnerScript.run_single("kings_statue:1")
	if String(champion_result.get("status", "")) != "PASS":
		_fail("kings_statue:1 must be PASS, got %s (%s)" % [
			champion_result.get("status", ""),
			champion_result.get("reason", "")
		])
		return

	# Test 7: Summary calculation
	var test_results: Array[Dictionary] = [
		{"status": "PASS"},
		{"status": "PASS"},
		{"status": "LOGIC_PASS"},
		{"status": "FAIL_MISMATCH"},
		{"status": "MANUAL_CHECK_REQUIRED"},
	]
	var summary := RunnerScript.get_summary(test_results)
	if int(summary.get("total", 0)) != 5:
		_fail("summary total should be 5, got %d" % summary.get("total", 0))
		return
	if int(summary.get("pass", 0)) != 2:
		_fail("summary pass should be 2, got %d" % summary.get("pass", 0))
		return
	if int(summary.get("logic_pass", 0)) != 1:
		_fail("summary logic_pass should be 1")
		return
	if int(summary.get("fail", 0)) != 1:
		_fail("summary fail should be 1")
		return
	if int(summary.get("manual", 0)) != 1:
		_fail("summary manual should be 1")
		return

	# Test 8: All V1 families have matrix entries
	for f: Dictionary in families:
		var family_id := int(f.get("family_id", -1))
		var slug: String = String(f.get("slug", ""))
		var entries := AuditMatrixScript.get_entries_by_family(family_id)
		if entries.is_empty():
			_fail("Family %s has no matrix entries" % slug)
			return

	print("[test_building_upgrade_family_qa_runner] PASS — 8 tests passed")
	quit(0)
