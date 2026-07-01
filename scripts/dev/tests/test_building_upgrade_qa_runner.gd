extends SceneTree

## BuildingUpgradeQaRunner — Headless Sanity Test
## Run: Godot_v4.3-stable_win64.exe --headless --path C:\Godot\clickcer -s scripts/dev/tests/test_building_upgrade_qa_runner.gd

const QaRunnerScript := preload("res://scripts/dev/qa/BuildingUpgradeQaRunner.gd")
const AuditMatrixScript := preload("res://scripts/dev/audit/BuildingUpgradeAuditMatrix.gd")

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	print("=== BuildingUpgradeQaRunner Sanity Tests ===")
	print("")

	_test_run_all_returns_141_entries()
	_test_result_shape()
	_test_pass_rows_have_runtime_evidence()
	_test_cost_modifier_runtime_entry()
	_test_mega_militia_runtime_entry()
	_test_run_family_filters_correctly()
	_test_run_building_filters_correctly()
	_test_run_failed_reruns_only_failures()

	print("")
	print("=== Results ===")
	if _failures.is_empty():
		print("[test_building_upgrade_qa_runner] PASS (all assertions passed)")
		quit(0)
	else:
		for msg: String in _failures:
			print("  FAIL: %s" % msg)
		print("[test_building_upgrade_qa_runner] FAIL (%d failures)" % _failures.size())
		quit(1)


func _test_run_all_returns_141_entries() -> void:
	var results: Array[Dictionary] = QaRunnerScript.run_all()
	var expected_count: int = AuditMatrixScript.get_all_entries().size()
	if results.size() != expected_count:
		_failures.append("run_all(): expected %d entries, got %d" % [expected_count, results.size()])
	else:
		print("  PASS  run_all() returns %d entries" % results.size())


func _test_result_shape() -> void:
	var results: Array[Dictionary] = QaRunnerScript.run_all()
	if results.is_empty():
		_failures.append("result_shape: no results to inspect")
		return
	var rec: Dictionary = results[0]
	var required_keys: Array[String] = [
		"upgrade_id", "building_id", "upgrade_index", "family", "family_name", "status", "ran_at",
		"target", "before", "after", "expected", "reason"
	]
	for key: String in required_keys:
		if not rec.has(key):
			_failures.append("result_shape: missing key '%s' in result dict" % key)
	var status: String = String(rec.get("status", ""))
	var valid_statuses: Array[String] = [
		"PASS",
		"LOGIC_PASS",
		"FAIL_RUNTIME_UNCHANGED",
		"FAIL_RUNTIME_MISMATCH",
		"FAIL_FIXTURE",
		"MANUAL_CHECK_REQUIRED",
		"FAIL_LOGIC",
		"FAIL_REFRESH",
		"INCONCLUSIVE"
	]
	if not valid_statuses.has(status):
		_failures.append("result_shape: unexpected status '%s'" % status)
	if not _failures.is_empty():
		return
	print("  PASS  result dict has correct shape")


func _test_pass_rows_have_runtime_evidence() -> void:
	var results: Array[Dictionary] = QaRunnerScript.run_all()
	for rec: Dictionary in results:
		var st: String = String(rec.get("status", ""))
		if st != "PASS" and st != "LOGIC_PASS":
			continue
		var upgrade_id: String = String(rec.get("upgrade_id", ""))
		var target: String = String(rec.get("target", ""))
		if target == "":
			_failures.append("pass_rows_have_runtime_evidence: %s row '%s' has empty target" % [st, upgrade_id])
			return
		if not rec.has("before") or not rec.has("after"):
			_failures.append("pass_rows_have_runtime_evidence: %s row '%s' missing before/after" % [st, upgrade_id])
			return
		if not rec.has("expected"):
			_failures.append("pass_rows_have_runtime_evidence: %s row '%s' missing expected" % [st, upgrade_id])
			return
		# PASS (runtime) must show actual change; LOGIC_PASS may have logical before/after that differ
		if st == "PASS" and rec.get("before") == rec.get("after"):
			_failures.append("pass_rows_have_runtime_evidence: PASS row '%s' has unchanged before/after values" % upgrade_id)
			return
	print("  PASS  all PASS/LOGIC_PASS rows carry evidence")


func _test_cost_modifier_runtime_entry() -> void:
	var rec := _find_result(QaRunnerScript.run_all(), "barbarian_tent:1")
	if rec.is_empty():
		_failures.append("cost_modifier_runtime_entry: missing result for barbarian_tent:1")
		return
	if String(rec.get("status", "")) != "PASS":
		_failures.append("cost_modifier_runtime_entry: expected PASS for barbarian_tent:1, got '%s'" % String(rec.get("status", "")))
		return
	if String(rec.get("target", "")) == "":
		_failures.append("cost_modifier_runtime_entry: missing runtime target for barbarian_tent:1")
		return
	if rec.get("before") == rec.get("after"):
		_failures.append("cost_modifier_runtime_entry: before/after must differ for barbarian_tent:1")
		return
	print("  PASS  cost modifier entry has runtime evidence")


func _test_mega_militia_runtime_entry() -> void:
	var rec := _find_result(QaRunnerScript.run_all(), "militia_camp:2")
	if rec.is_empty():
		_failures.append("mega_militia_runtime_entry: missing result for militia_camp:2")
		return
	if String(rec.get("status", "")) != "PASS":
		_failures.append("mega_militia_runtime_entry: expected PASS for militia_camp:2, got '%s'" % String(rec.get("status", "")))
		return
	if String(rec.get("target", "")) == "":
		_failures.append("mega_militia_runtime_entry: missing runtime target for militia_camp:2")
		return
	if rec.get("before") == rec.get("after"):
		_failures.append("mega_militia_runtime_entry: before/after must differ for militia_camp:2")
		return
	print("  PASS  mega militia entry has runtime evidence")


func _test_run_family_filters_correctly() -> void:
	var family: int = AuditMatrixScript.EffectFamily.CAPACITY
	var results: Array[Dictionary] = QaRunnerScript.run_family(family)
	if results.is_empty():
		_failures.append("run_family(CAPACITY): returned no results")
		return
	for rec: Dictionary in results:
		if int(rec.get("family", -1)) != family:
			_failures.append("run_family(CAPACITY): result has wrong family %d" % int(rec.get("family", -1)))
			return
	print("  PASS  run_family(CAPACITY) returns %d entries, all correct family" % results.size())


func _test_run_building_filters_correctly() -> void:
	var results: Array[Dictionary] = QaRunnerScript.run_building("vineyard")
	if results.is_empty():
		_failures.append("run_building('vineyard'): returned no results")
		return
	for rec: Dictionary in results:
		if String(rec.get("building_id", "")) != "vineyard":
			_failures.append("run_building('vineyard'): result has wrong building_id '%s'" % String(rec.get("building_id", "")))
			return
	print("  PASS  run_building('vineyard') returns %d entries, all correct building" % results.size())


func _test_run_failed_reruns_only_failures() -> void:
	# Build a fake previous_results with 1 FAIL and 1 PASS
	var fake_results: Array[Dictionary] = [
		{"upgrade_id": "vineyard:1", "status": "FAIL_LOGIC"},
		{"upgrade_id": "market:1", "status": "PASS"},
	]
	var results: Array[Dictionary] = QaRunnerScript.run_failed(fake_results)
	# Only vineyard:1 should be re-run
	if results.size() != 1:
		_failures.append("run_failed(): expected 1 re-run entry, got %d" % results.size())
		return
	if String(results[0].get("upgrade_id", "")) != "vineyard:1":
		_failures.append("run_failed(): expected upgrade_id 'vineyard:1', got '%s'" % String(results[0].get("upgrade_id", "")))
		return
	print("  PASS  run_failed() re-runs only FAIL entries (1 of 2)")


func _find_result(results: Array[Dictionary], upgrade_id: String) -> Dictionary:
	for rec: Dictionary in results:
		if String(rec.get("upgrade_id", "")) == upgrade_id:
			return rec
	return {}
