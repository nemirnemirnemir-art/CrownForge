extends SceneTree

const WaveStateFlowScript := preload("res://scripts/game_scene/modules/WaveStateFlow.gd")


class FakeCounter:
	extends RefCounted

	var calls: Array = []

	func call0() -> void:
		calls.append([])

	func call1(a) -> void:
		calls.append([a])


class FakeMob:
	extends Node


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = WaveStateFlowScript.new()
	if flow == null:
		push_error("[test_gamescenewaves_wave_state_flow] failed to instantiate helper")
		quit(1)
		return

	var state: Dictionary = flow.create_state()
	var mob := FakeMob.new()
	var completed := FakeCounter.new()
	var cleared := FakeCounter.new()

	flow.begin_wave(state)
	flow.register_spawned_mob(state, mob, true)
	flow.register_spawned_count(state, "goblin_bandit", 2)
	if not bool(state.get("wave_active", false)):
		push_error("[test_gamescenewaves_wave_state_flow] wave must become active")
		quit(1)
		return
	if int(state.get("current_wave_mob_counts", {}).get("goblin_bandit", 0)) != 2:
		push_error("[test_gamescenewaves_wave_state_flow] mob count registration mismatch")
		quit(1)
		return

	flow.on_mob_died(state, mob, true, Callable(completed, "call1"), Callable(cleared, "call0"), 7)
	if completed.calls != [[7]]:
		push_error("[test_gamescenewaves_wave_state_flow] wave complete signal mismatch")
		quit(1)
		return
	if cleared.calls.size() != 1:
		push_error("[test_gamescenewaves_wave_state_flow] clear callback mismatch")
		quit(1)
		return
	if bool(state.get("wave_active", true)):
		push_error("[test_gamescenewaves_wave_state_flow] wave must become inactive after last mob dies")
		quit(1)
		return

	print("[test_gamescenewaves_wave_state_flow] PASS")
	quit(0)
