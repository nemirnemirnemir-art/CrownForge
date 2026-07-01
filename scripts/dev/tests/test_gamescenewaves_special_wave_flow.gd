extends SceneTree

const SpecialWaveFlowScript := preload("res://scripts/game_scene/modules/SpecialWaveFlow.gd")


class FakeCounter:
	extends RefCounted

	var calls: Array = []

	func call0() -> void:
		calls.append([])

	func call1(a) -> void:
		calls.append([a])


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = SpecialWaveFlowScript.new()
	if flow == null:
		push_error("[test_gamescenewaves_special_wave_flow] failed to instantiate helper")
		quit(1)
		return

	var state := {
		"current_wave_is_prophecy": true,
		"current_wave_is_trader": false
	}
	var prophecy_updated := FakeCounter.new()
	var trader_completed := FakeCounter.new()
	var prophecy_completed := FakeCounter.new()
	var prophecy_rebuilt := FakeCounter.new()
	var previews_cleared := FakeCounter.new()
	var batch_finished := FakeCounter.new()
	var enemies_cleared := FakeCounter.new()

	flow.handle_all_enemies_cleared(state, 5, Callable(prophecy_updated, "call0"), Callable(trader_completed, "call1"), Callable(prophecy_completed, "call0"), Callable(previews_cleared, "call0"), Callable(batch_finished, "call0"), Callable(enemies_cleared, "call0"))
	if prophecy_updated.calls.size() != 1 or batch_finished.calls.size() != 0:
		push_error("[test_gamescenewaves_special_wave_flow] prophecy wave branch mismatch")
		quit(1)
		return

	state["current_wave_is_prophecy"] = false
	state["current_wave_is_trader"] = true
	flow.handle_all_enemies_cleared(state, 6, Callable(prophecy_rebuilt, "call0"), Callable(trader_completed, "call1"), Callable(prophecy_completed, "call0"), Callable(previews_cleared, "call0"), Callable(batch_finished, "call0"), Callable(enemies_cleared, "call0"))
	if trader_completed.calls != [[6]] or prophecy_completed.calls.size() != 1 or prophecy_rebuilt.calls.size() != 1 or previews_cleared.calls.size() != 0 or batch_finished.calls.size() != 1:
		push_error("[test_gamescenewaves_special_wave_flow] trader wave branch mismatch")
		quit(1)
		return

	if enemies_cleared.calls.size() != 2:
		push_error("[test_gamescenewaves_special_wave_flow] enemies cleared callback must always run")
		quit(1)
		return

	print("[test_gamescenewaves_special_wave_flow] PASS")
	quit(0)
