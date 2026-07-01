extends SceneTree

const WaveStartFlowScript := preload("res://scripts/game_scene/modules/WaveStartFlow.gd")


class FakeWaveTimerBar:
	extends RefCounted

	var cleared: Array[int] = []

	func clear_wave_preview(wave_number: int) -> void:
		cleared.append(wave_number)


class FakeBattleCore:
	extends RefCounted

	var start_calls: int = 0

	func start_wave() -> void:
		start_calls += 1


class FakeTraderSpawner:
	extends RefCounted

	var post_trader_first_wave_number: int = 8

	func get_post_trader_first_wave_number() -> int:
		return post_trader_first_wave_number

	func set_post_trader_first_wave_number(value: int) -> void:
		post_trader_first_wave_number = value


class FakeWaveStateFlow:
	extends RefCounted

	var begin_calls: int = 0
	var counts_to_return: Dictionary = {"goblin_bandit": 2}

	func begin_wave(state: Dictionary) -> void:
		begin_calls += 1
		state["wave_active"] = true
		state["alive_wave_mob_ids"] = {}
		state["current_wave_mob_counts"] = {}
		state["current_wave_rewards"] = []

	func get_current_wave_counts(_state: Dictionary) -> Dictionary:
		return counts_to_return.duplicate(true)


class FakeSignalRecorder:
	extends RefCounted

	var events: Array[String] = []

	func record_wave_spawned(_wave_number: int) -> void:
		events.append("wave_spawned")

	func record_event_bus(_wave_number: int, _counts: Dictionary) -> void:
		events.append("event_bus")


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = WaveStartFlowScript.new()
	if flow == null:
		push_error("[test_gamescenewaves_wave_start_flow] failed to instantiate helper")
		quit(1)
		return

	var facade_state := {
		"current_wave": 1,
		"current_wave_is_prophecy": true,
		"current_wave_is_trader": true,
		"current_wave_is_placeholder": true,
		"current_wave_display_number": 9,
		"wave_active": false,
	}
	var wave_state := {
		"wave_active": false,
		"alive_wave_mob_ids": {101: true, 202: true},
		"current_wave_mob_counts": {"old_enemy": 5},
		"current_wave_rewards": [{"custom_id": "carry_over"}],
	}
	var wave_timer := FakeWaveTimerBar.new()
	var battle_core := FakeBattleCore.new()
	var trader_spawner := FakeTraderSpawner.new()
	var wave_state_flow := FakeWaveStateFlow.new()

	flow.begin_wave(8, facade_state, wave_state, wave_timer, battle_core, trader_spawner, wave_state_flow)
	if facade_state["current_wave"] != 8:
		push_error("[test_gamescenewaves_wave_start_flow] current wave not updated")
		quit(1)
		return
	if battle_core.start_calls != 1 or wave_timer.cleared != [8]:
		push_error("[test_gamescenewaves_wave_start_flow] startup side effects mismatch")
		quit(1)
		return
	if trader_spawner.post_trader_first_wave_number != -1:
		push_error("[test_gamescenewaves_wave_start_flow] post-trader reset mismatch")
		quit(1)
		return
	if not bool(facade_state["wave_active"]) or bool(facade_state["current_wave_is_prophecy"]) or bool(facade_state["current_wave_is_trader"]) or bool(facade_state["current_wave_is_placeholder"]) or int(facade_state["current_wave_display_number"]) != 0:
		push_error("[test_gamescenewaves_wave_start_flow] bookkeeping reset mismatch")
		quit(1)
		return
	if not Dictionary(wave_state.get("alive_wave_mob_ids", {})).is_empty() or not Dictionary(wave_state.get("current_wave_mob_counts", {})).is_empty() or not Array(wave_state.get("current_wave_rewards", [])).is_empty():
		push_error("[test_gamescenewaves_wave_start_flow] authoritative wave state must be reset without carry-over")
		quit(1)
		return

	wave_state["current_wave_mob_counts"] = {"fresh_enemy": 3}
	wave_state_flow.counts_to_return = {"fresh_enemy": 3}

	var recorder := FakeSignalRecorder.new()
	flow.notify_wave_started(
		8,
		wave_state_flow,
		wave_state,
		Callable(recorder, "record_wave_spawned"),
		Callable(recorder, "record_event_bus")
	)
	if recorder.events != ["wave_spawned", "event_bus"]:
		push_error("[test_gamescenewaves_wave_start_flow] signal timing mismatch")
		quit(1)
		return

	print("[test_gamescenewaves_wave_start_flow] PASS")
	quit(0)
