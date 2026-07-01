extends SceneTree

const EXECUTOR_PATH := "res://scripts/ui/rewards/modules/WaveRewardExecutor.gd"


class FakeEconomyCore:
	extends RefCounted

	var add_gold_calls: Array[float] = []

	func add_gold(amount: float) -> void:
		add_gold_calls.append(amount)


class SubmenuRecorder:
	extends RefCounted

	var calls: Array[String] = []

	func open_submenu(menu_type: String, amount: int = 0) -> void:
		calls.append("%s:%d" % [menu_type, amount])


func _init() -> void:
	call_deferred("_run_test")


func _assert(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("[test_wave_reward_executor] %s" % message)
	quit(1)
	return false


func _run_test() -> void:
	var executor_script := load(EXECUTOR_PATH)
	if not _assert(executor_script != null, "failed to load WaveRewardExecutor.gd"):
		return

	var executor = executor_script.new()
	if not _assert(executor != null, "failed to instantiate WaveRewardExecutor"):
		return

	var economy_core := FakeEconomyCore.new()
	var submenu_recorder := SubmenuRecorder.new()
	var get_economy_cb := func() -> Variant:
		return economy_core

	var should_check: bool = bool(executor.call("execute", "denarii:25", get_economy_cb, Callable(submenu_recorder, "open_submenu")))
	if not _assert(should_check, "denarii reward must remain immediate and return check-all-claimed signal"):
		return
	if not _assert(economy_core.add_gold_calls == [25.0], "denarii reward must keep amount-based gold grant"):
		return
	if not _assert(submenu_recorder.calls.is_empty(), "denarii reward must not open a submenu"):
		return

	economy_core.add_gold_calls.clear()
	should_check = bool(executor.call("execute", "denarii", get_economy_cb, Callable(submenu_recorder, "open_submenu")))
	if not _assert(should_check, "default denarii reward must still request check-all-claimed"):
		return
	if not _assert(economy_core.add_gold_calls == [10.0], "default denarii reward must keep 10 gold fallback"):
		return

	var submenu_cases: Array[Dictionary] = [
		{"reward_type": "trader", "expected_call": "trader:0"},
		{"reward_type": "resource:45", "expected_call": "resource:45"},
		{"reward_type": "levy", "expected_call": "levy:0"},
		{"reward_type": "production", "expected_call": "production:0"},
		{"reward_type": "production_basic", "expected_call": "production:0"},
		{"reward_type": "production_established", "expected_call": "production_established:0"},
		{"reward_type": "production_advanced", "expected_call": "production_advanced:0"},
		{"reward_type": "infrastructure", "expected_call": "infrastructure:0"},
		{"reward_type": "spell", "expected_call": "spell:0"},
		{"reward_type": "legendary_spell", "expected_call": "legendary_spell:0"},
		{"reward_type": "veteran", "expected_call": "veteran:0"},
		{"reward_type": "elite", "expected_call": "elite:0"},
		{"reward_type": "artifact", "expected_call": "artifact:0"},
		{"reward_type": "legendary_artifact", "expected_call": "artifact:0"},
		{"reward_type": "building_upgrade", "expected_call": "building_upgrade:0"},
		{"reward_type": "troop_training", "expected_call": "troop_training:0"},
		{"reward_type": "prophecy", "expected_call": "prophecy:0"},
	]

	for entry in submenu_cases:
		submenu_recorder.calls.clear()
		should_check = bool(executor.call("execute", String(entry["reward_type"]), get_economy_cb, Callable(submenu_recorder, "open_submenu")))
		if not _assert(not should_check, "%s must keep submenu-owned follow-up flow" % entry["reward_type"]):
			return
		if not _assert(submenu_recorder.calls == [String(entry["expected_call"])], "%s must open the same submenu branch as before" % entry["reward_type"]):
			return

	submenu_recorder.calls.clear()
	should_check = bool(executor.call("execute", "placeholder", get_economy_cb, Callable(submenu_recorder, "open_submenu")))
	if not _assert(should_check, "placeholder reward must still fall through to scene-owned claim completion check"):
		return
	if not _assert(submenu_recorder.calls.is_empty(), "placeholder reward must not open submenu"):
		return

	should_check = bool(executor.call("execute", "no_reward", get_economy_cb, Callable(submenu_recorder, "open_submenu")))
	if not _assert(should_check, "no_reward branch must still fall through to scene-owned claim completion check"):
		return
	if not _assert(not executor.has_method("_check_all_claimed"), "check-all-claimed flow must remain on WaveRewardMenu"):
		return
	if not _assert(not executor.has_method("close_menu"), "menu close flow must remain on WaveRewardMenu"):
		return

	print("[test_wave_reward_executor] PASS")
	quit(0)
