extends SceneTree

const GameSceneEncounterFlowScript := preload("res://scripts/game_scene/GameSceneEncounterFlow.gd")


class FakeWavesManager:
	extends RefCounted

	var paused_values: Array[bool] = []
	var prophecy_queue: Array = []
	var current_paused: bool = false

	func set_paused(value: bool) -> void:
		current_paused = value
		paused_values.append(value)

	func is_paused() -> bool:
		return current_paused

	func set_prophecy_queue(selected_waves: Array) -> void:
		prophecy_queue = selected_waves.duplicate(true)


class FakePauseState:
	extends RefCounted

	var transfer_calls: int = 0
	var release_prophecy_calls: int = 0
	var release_encounter_calls: int = 0

	func transfer_prophecy_pause_to_encounter() -> void:
		transfer_calls += 1

	func release_prophecy_pause() -> void:
		release_prophecy_calls += 1

	func release_encounter_pause() -> void:
		release_encounter_calls += 1


class FakeEncounterMenu:
	extends Control

	var opened_encounter: Dictionary = {}

	func open(encounter: Dictionary) -> void:
		opened_encounter = encounter.duplicate(true)
		visible = true


class FakeEncounterService:
	extends RefCounted

	var next_encounter: Dictionary = {}
	var pending_actions: Array = []
	var applied_pairs: Array[String] = []
	var should_apply: bool = true

	func build_random_encounter() -> Dictionary:
		return next_encounter.duplicate(true)

	func apply_encounter_option(encounter_id: String, option_id: String) -> bool:
		applied_pairs.append("%s/%s" % [encounter_id, option_id])
		return should_apply

	func consume_pending_ui_actions() -> Array:
		var result := pending_actions.duplicate()
		pending_actions.clear()
		return result


class FakeHost:
	extends Node

	var recover_calls: int = 0
	var action_log: Array[String] = []
	var pause_after_prophecy_enabled: bool = true
	var waves_paused: bool = false
	var active_reward_chain: bool = false
	var open_results := {
		"queue_a": false,
		"queue_b": false,
		"queue_c": true,
	}

	func is_pause_after_prophecy_enabled() -> bool:
		return pause_after_prophecy_enabled

	func recover_production() -> void:
		recover_calls += 1

	func run_ui_action(action_id: String) -> bool:
		action_log.append(action_id)
		return bool(open_results.get(action_id, false))

	func has_active_reward_chain() -> bool:
		return active_reward_chain


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var host := FakeHost.new()
	get_root().add_child(host)

	var reward_menu := Control.new()
	host.add_child(reward_menu)

	var menu := FakeEncounterMenu.new()
	menu.visible = false
	host.add_child(menu)

	var waves := FakeWavesManager.new()
	waves.current_paused = true
	var pause_state := FakePauseState.new()
	var service := FakeEncounterService.new()
	service.next_encounter = {"id": "enc_1"}
	service.pending_actions = ["queue_a", "queue_b", "queue_c"]

	var flow = GameSceneEncounterFlowScript.new()
	if flow == null:
		push_error("[test_gamescene_encounter_flow] failed to instantiate GameSceneEncounterFlow")
		quit(1)
		return

	flow.initialize(
		host,
		waves,
		pause_state,
		menu,
		service,
		[reward_menu],
		Callable(host, "is_pause_after_prophecy_enabled"),
		Callable(host, "run_ui_action"),
		Callable(host, "recover_production")
	)

	host.active_reward_chain = true
	menu.visible = false
	service.next_encounter = {"id": "enc_deferred"}
	flow.on_prophecy_confirmed([11, 12, 13])
	if menu.opened_encounter.get("id", "") == "enc_deferred":
		push_error("[test_gamescene_encounter_flow] encounter must not open while reward chain still active")
		quit(1)
		return
	host.active_reward_chain = false
	reward_menu.visible = false
	flow.on_reward_menu_visibility_changed()
	if menu.opened_encounter.get("id", "") != "enc_deferred":
		push_error("[test_gamescene_encounter_flow] deferred encounter must open after reward chain ends")
		quit(1)
		return
	menu.visible = false
	flow.on_encounter_closed()
	menu.opened_encounter = {}
	service.next_encounter = {"id": "enc_1"}
	pause_state.release_encounter_calls = 0
	pause_state.release_prophecy_calls = 0

	flow.on_prophecy_confirmed([1, 2, 3])
	if waves.prophecy_queue.size() != 3:
		push_error("[test_gamescene_encounter_flow] prophecy queue was not forwarded")
		quit(1)
		return
	if pause_state.transfer_calls != 1:
		push_error("[test_gamescene_encounter_flow] expected prophecy pause transfer when encounter opens")
		quit(1)
		return
	if waves.paused_values.is_empty() or waves.paused_values[-1] != true:
		push_error("[test_gamescene_encounter_flow] waves must pause when encounter opens")
		quit(1)
		return
	if menu.opened_encounter.get("id", "") != "enc_1":
		push_error("[test_gamescene_encounter_flow] encounter menu did not receive encounter payload")
		quit(1)
		return

	host.action_log.clear()
	service.pending_actions = ["queue_c"]
	reward_menu.visible = false
	flow.on_encounter_option_selected("enc_1", "option_reward")
	if host.action_log.size() != 0:
		push_error("[test_gamescene_encounter_flow] actions must wait until encounter closes before opening reward menu")
		quit(1)
		return
	flow.on_encounter_closed()
	if pause_state.release_encounter_calls != 1 or pause_state.release_prophecy_calls != 1:
		push_error("[test_gamescene_encounter_flow] encounter close after direct reward must release both pause states")
		quit(1)
		return
	if host.action_log != ["queue_c"]:
		push_error("[test_gamescene_encounter_flow] queued encounter reward must open after encounter closes: %s" % [host.action_log])
		quit(1)
		return
	if waves.paused_values[-1] != false:
		push_error("[test_gamescene_encounter_flow] opening encounter reward after close must preserve resumed wave state")
		quit(1)
		return

	host.action_log.clear()
	host.recover_calls = 0
	waves.paused_values.clear()
	waves.current_paused = true
	host.waves_paused = false
	menu.visible = false
	service.pending_actions = []
	pause_state.release_encounter_calls = 0
	pause_state.release_prophecy_calls = 0
	flow.on_prophecy_confirmed([7, 8, 9])
	if not waves.paused_values.has(true):
		push_error("[test_gamescene_encounter_flow] encounter open must pause waves")
		quit(1)
		return
	waves.current_paused = false
	flow.on_encounter_closed()
	if waves.paused_values[-1] != false:
		push_error("[test_gamescene_encounter_flow] encounter close must restore host wave pause policy, not stale reward-menu pause")
		quit(1)
		return

	host.action_log.clear()
	waves.paused_values.clear()
	waves.current_paused = true
	host.recover_calls = 0
	service.pending_actions = ["queue_a", "queue_b", "queue_c"]
	pause_state.release_encounter_calls = 0
	pause_state.release_prophecy_calls = 0

	reward_menu.visible = true
	flow.on_encounter_option_selected("enc_1", "option_a")
	if host.action_log.size() != 0:
		push_error("[test_gamescene_encounter_flow] actions must wait while reward menu is visible")
		quit(1)
		return

	reward_menu.visible = false
	flow.on_reward_menu_visibility_changed()
	if host.action_log != ["queue_a", "queue_b", "queue_c"]:
		push_error("[test_gamescene_encounter_flow] queued actions drained in wrong order: %s" % [host.action_log])
		quit(1)
		return

	flow.on_encounter_closed()
	if pause_state.release_encounter_calls != 1 or pause_state.release_prophecy_calls != 1:
		push_error("[test_gamescene_encounter_flow] encounter close must release both pause states")
		quit(1)
		return
	if waves.paused_values[-1] != false:
		push_error("[test_gamescene_encounter_flow] encounter close must restore host wave pause policy")
		quit(1)
		return
	if host.recover_calls != 1:
		push_error("[test_gamescene_encounter_flow] production recovery callback was not called")
		quit(1)
		return

	print("[test_gamescene_encounter_flow] PASS")
	quit(0)
