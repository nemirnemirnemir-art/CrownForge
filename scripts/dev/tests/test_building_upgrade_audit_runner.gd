extends SceneTree

## Building Upgrade Audit Runner — Headless Entrypoint
## Run: Godot_v4.3-stable_win64.exe --headless --path C:\Godot\clickcer -s scripts/dev/tests/test_building_upgrade_audit_runner.gd

const AuditMatrixScript := preload("res://scripts/dev/audit/BuildingUpgradeAuditMatrix.gd")
const HarnessScript := preload("res://scripts/dev/audit/BuildingUpgradeAuditHarness.gd")
const FamilyRunnerScript := preload("res://scripts/dev/audit/BuildingUpgradeFamilyRunner.gd")

var _pass_count: int = 0
var _logic_pass_count: int = 0
var _fail_count: int = 0
var _manual_count: int = 0
var _results: Array[Dictionary] = []

func _init() -> void:
	call_deferred("_run_audit")

func _run_audit() -> void:
	var entries: Array[Dictionary] = AuditMatrixScript.get_all_entries()
	var harness := HarnessScript.new()

	print("=== Building Upgrade Audit Runner ===")
	print("Total entries: %d" % entries.size())
	print("")

	for entry: Dictionary in entries:
		var upgrade_id: String = String(entry.get("upgrade_id", "???"))
		var family: int = int(entry.get("family", -1))
		var family_name: String = _family_name(family)
		var result: String = FamilyRunnerScript.run_entry(entry, harness)

		var record := {"upgrade_id": upgrade_id, "result": result, "family": family_name}
		_results.append(record)

		if result == "PASS":
			_pass_count += 1
		elif result == "LOGIC_PASS":
			_logic_pass_count += 1
		elif result == "MANUAL_CHECK_REQUIRED":
			_manual_count += 1
			print("  SKIP  %-35s [%s] -> %s" % [upgrade_id, family_name, result])
		else:
			_fail_count += 1
			print("  FAIL  %-35s [%s] -> %s" % [upgrade_id, family_name, result])

	print("")
	print("=== Results ===")
	print("  PASS (runtime): %d" % _pass_count)
	print("  PASS (logic):   %d" % _logic_pass_count)
	print("  FAIL:           %d" % _fail_count)
	print("  MANUAL:         %d" % _manual_count)
	print("  TOTAL:          %d" % entries.size())

	if _fail_count > 0:
		print("")
		print("--- Failed entries ---")
		for rec: Dictionary in _results:
			if String(rec.get("result", "")) != "PASS" and String(rec.get("result", "")) != "LOGIC_PASS" and String(rec.get("result", "")) != "MANUAL_CHECK_REQUIRED":
				print("  %s [%s] -> %s" % [String(rec.get("upgrade_id", "")), String(rec.get("family", "")), String(rec.get("result", ""))])
		print("")
		print("[test_building_upgrade_audit_runner] FAIL (%d failures)" % _fail_count)
		quit(1)
	else:
		print("")
		print("[test_building_upgrade_audit_runner] PASS (%d runtime, %d logic, %d manual)" % [_pass_count, _logic_pass_count, _manual_count])
		quit(0)


static func _family_name(family: int) -> String:
	match family:
		AuditMatrixScript.EffectFamily.PRODUCTION_SPEED: return "production_speed"
		AuditMatrixScript.EffectFamily.PRODUCTION_BONUS: return "production_bonus"
		AuditMatrixScript.EffectFamily.EFFICIENT_PROCESSING: return "efficient_processing"
		AuditMatrixScript.EffectFamily.CAPACITY: return "capacity"
		AuditMatrixScript.EffectFamily.TROOP_STAT: return "troop_stat"
		AuditMatrixScript.EffectFamily.COMBAT_HOOK: return "combat_hook"
		AuditMatrixScript.EffectFamily.DEATH_REWARD: return "death_reward"
		AuditMatrixScript.EffectFamily.COST_MODIFIER: return "cost_modifier"
		AuditMatrixScript.EffectFamily.MORALE: return "morale"
		AuditMatrixScript.EffectFamily.SPELL_DAMAGE: return "spell_damage"
		AuditMatrixScript.EffectFamily.UNIT_AURA: return "unit_aura"
		AuditMatrixScript.EffectFamily.PRODUCTION_EVENT: return "production_event"
		AuditMatrixScript.EffectFamily.MEGA_MILITIA: return "mega_militia"
		AuditMatrixScript.EffectFamily.LION_CIRCUS: return "lion_circus"
		AuditMatrixScript.EffectFamily.SPECIAL: return "special"
		AuditMatrixScript.EffectFamily.INCONCLUSIVE: return "inconclusive"
		_: return "unknown"
