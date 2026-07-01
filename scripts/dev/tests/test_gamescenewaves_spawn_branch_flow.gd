extends SceneTree

const SpawnBranchFlowScript := preload("res://scripts/game_scene/modules/WaveSpawnBranchFlow.gd")


class FakeCounter:
	extends RefCounted

	var calls: Array = []

	func call0() -> void:
		calls.append([])

	func call1(a) -> int:
		calls.append([a])
		return 1

	func call2(a, b) -> int:
		calls.append([a, b])
		return int(a)

	func call_wave(a) -> int:
		calls.append([a])
		return int(a)


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = SpawnBranchFlowScript.new()
	if flow == null:
		push_error("[test_gamescenewaves_spawn_branch_flow] failed to instantiate helper")
		quit(1)
		return

	var state := {
		"current_wave_is_intro": false,
		"current_wave_is_prophecy": false,
		"current_wave_is_trader": false,
		"current_wave_is_boss": false,
		"current_wave_is_placeholder": false,
		"current_wave_display_number": 0,
		"current_wave_use_prophecy_defaults": false,
		"current_wave_open_prophecy_after_reward": false,
		"current_wave_show_victory_after_reward": false,
	}
	var intro := FakeCounter.new()
	var trader := FakeCounter.new()
	var prophecy := FakeCounter.new()
	var boss := FakeCounter.new()
	var placeholder := FakeCounter.new()
	var randoms := FakeCounter.new()
	var queue_state := {
		"intro_pending": false,
		"is_trader": false,
		"has_queue": true,
		"boss_pending": false,
		"boss_victory": false,
		"pending": false,
		"patterns": [{"id": "p"}],
		"display": 4,
	}

	var spawned: int = flow.resolve_spawn_branch(
		5,
		state,
		queue_state,
		Callable(intro, "call0"),
		Callable(trader, "call0"),
		Callable(prophecy, "call1"),
		Callable(boss, "call0"),
		Callable(placeholder, "call_wave"),
		Callable(randoms, "call_wave")
	)
	if spawned != 1 or not bool(state["current_wave_is_prophecy"]):
		push_error("[test_gamescenewaves_spawn_branch_flow] prophecy branch mismatch")
		quit(1)
		return

	queue_state["has_queue"] = false
	queue_state["pending"] = true
	spawned = flow.resolve_spawn_branch(6, state, queue_state, Callable(intro, "call0"), Callable(trader, "call0"), Callable(prophecy, "call1"), Callable(boss, "call0"), Callable(placeholder, "call_wave"), Callable(randoms, "call_wave"))
	if spawned != 6 or not bool(state["current_wave_is_placeholder"]):
		push_error("[test_gamescenewaves_spawn_branch_flow] placeholder branch mismatch")
		quit(1)
		return

	queue_state["pending"] = false
	queue_state["is_trader"] = true
	spawned = flow.resolve_spawn_branch(7, state, queue_state, Callable(intro, "call0"), Callable(trader, "call0"), Callable(prophecy, "call1"), Callable(boss, "call0"), Callable(placeholder, "call_wave"), Callable(randoms, "call_wave"))
	if spawned != 0 or trader.calls.size() != 1 or not bool(state["current_wave_is_trader"]):
		push_error("[test_gamescenewaves_spawn_branch_flow] trader branch mismatch")
		quit(1)
		return

	queue_state["is_trader"] = false
	queue_state["intro_pending"] = true
	spawned = flow.resolve_spawn_branch(8, state, queue_state, Callable(intro, "call0"), Callable(trader, "call0"), Callable(prophecy, "call1"), Callable(boss, "call0"), Callable(placeholder, "call_wave"), Callable(randoms, "call_wave"))
	if intro.calls.size() != 1 or not bool(state["current_wave_is_intro"]) or not bool(state["current_wave_open_prophecy_after_reward"]):
		push_error("[test_gamescenewaves_spawn_branch_flow] intro branch mismatch")
		quit(1)
		return

	queue_state["intro_pending"] = false
	queue_state["boss_pending"] = true
	queue_state["boss_victory"] = true
	spawned = flow.resolve_spawn_branch(9, state, queue_state, Callable(intro, "call0"), Callable(trader, "call0"), Callable(prophecy, "call1"), Callable(boss, "call0"), Callable(placeholder, "call_wave"), Callable(randoms, "call_wave"))
	if boss.calls.size() != 1 or not bool(state["current_wave_is_boss"]) or not bool(state["current_wave_show_victory_after_reward"]):
		push_error("[test_gamescenewaves_spawn_branch_flow] boss branch mismatch")
		quit(1)
		return

	print("[test_gamescenewaves_spawn_branch_flow] PASS")
	quit(0)
