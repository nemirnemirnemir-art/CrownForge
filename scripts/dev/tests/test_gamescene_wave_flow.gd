extends SceneTree

const GameSceneWaveFlowScript := preload("res://scripts/game_scene/GameSceneWaveFlow.gd")


class FakeWavesManager:
	extends RefCounted

	var paused_values: Array[bool] = []
	var rewards: Array = [{"type": "gold"}]
	var prophecy_level: int = 3
	var current_paused: bool = false

	func set_paused(value: bool) -> void:
		current_paused = value
		paused_values.append(value)

	func is_paused() -> bool:
		return current_paused

	func get_current_wave_rewards() -> Array:
		return rewards.duplicate(true)

	func get_prophecy_level() -> int:
		return prophecy_level


class FakeRewardMenu:
	extends RefCounted

	var open_calls: Array[Dictionary] = []

	func open(rewards: Array, prophecy_level: int, should_open_prophecy: bool) -> void:
		open_calls.append({
			"rewards": rewards.duplicate(true),
			"prophecy_level": prophecy_level,
			"should_open_prophecy": should_open_prophecy,
		})


class FakeHost:
	extends RefCounted

	var prophecy_open_calls: int = 0
	var victory_calls: int = 0

	func open_reward_menu_prophecy() -> void:
		prophecy_open_calls += 1

	func show_prophecy_victory() -> void:
		victory_calls += 1


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = GameSceneWaveFlowScript.new()
	var waves := FakeWavesManager.new()
	var reward_menu := FakeRewardMenu.new()
	var host := FakeHost.new()
	waves.current_paused = true

	flow.initialize(host, waves, reward_menu, Callable(host, "open_reward_menu_prophecy"))

	flow.on_wave_completed(2)
	if waves.paused_values.is_empty() or waves.paused_values[-1] != true:
		push_error("[test_gamescene_wave_flow] waves must pause on wave completion")
		quit(1)
		return
	if reward_menu.open_calls.size() != 1:
		push_error("[test_gamescene_wave_flow] reward menu must open on wave completion")
		quit(1)
		return
	var call_payload: Dictionary = reward_menu.open_calls[0]
	if bool(call_payload.get("should_open_prophecy", true)):
		push_error("[test_gamescene_wave_flow] non-zero wave must not force prophecy open")
		quit(1)
		return

	flow.on_wave_reward_menu_closed()
	if waves.paused_values[-1] != true:
		push_error("[test_gamescene_wave_flow] reward close must restore prior wave pause state")
		quit(1)
		return

	waves.current_paused = false
	flow.on_wave_completed(0)
	if reward_menu.open_calls.size() != 2:
		push_error("[test_gamescene_wave_flow] first wave must still open reward menu")
		quit(1)
		return
	call_payload = reward_menu.open_calls[1]
	if not bool(call_payload.get("should_open_prophecy", false)):
		push_error("[test_gamescene_wave_flow] first wave must flag prophecy opening")
		quit(1)
		return

	flow.on_wave_reward_menu_closed()
	if host.prophecy_open_calls != 1:
		push_error("[test_gamescene_wave_flow] prophecy menu must open after first-wave reward menu closes")
		quit(1)
		return
	if waves.paused_values[-1] != false:
		push_error("[test_gamescene_wave_flow] first-wave reward close must restore wave pause state before opening prophecy menu")
		quit(1)
		return

	flow.on_wave_completed(0)
	if not flow.consume_pending_open_prophecy():
		push_error("[test_gamescene_wave_flow] first-wave pending prophecy flag must be consumable when prophecy opens early")
		quit(1)
		return
	flow.on_wave_reward_menu_closed()
	if host.prophecy_open_calls != 1:
		push_error("[test_gamescene_wave_flow] consuming pending prophecy open must prevent duplicate reopen on reward close")
		quit(1)
		return

	flow.on_prophecy_batch_finished()
	flow.on_wave_reward_menu_closed()
	if host.prophecy_open_calls != 2:
		push_error("[test_gamescene_wave_flow] prophecy batch finish must reopen prophecy flow on next close")
		quit(1)
		return

	flow.request_victory_after_reward_close()
	flow.on_wave_reward_menu_closed()
	if host.victory_calls != 1:
		push_error("[test_gamescene_wave_flow] pending victory must open victory panel on reward close")
		quit(1)
		return
	if host.prophecy_open_calls != 2:
		push_error("[test_gamescene_wave_flow] pending victory must not reopen prophecy menu")
		quit(1)
		return

	print("[test_gamescene_wave_flow] PASS")
	quit(0)
