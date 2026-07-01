extends SceneTree

const MainUISignalFlowScript := preload("res://scripts/ui/hud/MainUISignalFlow.gd")


class FakeEventBus:
	extends Node

	signal gold_changed(new_amount: float, delta: float)
	signal stars_changed(new_amount: int)
	signal stage_changed(new_stage: int)
	signal game_loaded()
	signal forge_cores_changed(new_amount: int, delta: int)


class FakeResourceCore:
	extends Node

	signal resource_changed(resource_id: String, amount: int)


class FakeCastleCore:
	extends Node

	signal game_over()


class FakeDialog:
	extends AcceptDialog


class CallbackHost:
	extends RefCounted

	func on_gold_changed(_a: float, _b: float) -> void:
		pass

	func on_stars_changed(_a: int) -> void:
		pass

	func on_stage_changed(_a: int) -> void:
		pass

	func on_game_loaded() -> void:
		pass

	func on_forge_cores_changed(_a: int, _b: int) -> void:
		pass

	func on_resource_changed(_a: String, _b: int) -> void:
		pass

	func on_game_over() -> void:
		pass

	func on_reset_confirmed() -> void:
		pass


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = MainUISignalFlowScript.new()
	if flow == null:
		push_error("[test_mainui_signal_flow] failed to instantiate helper")
		quit(1)
		return

	var host := CallbackHost.new()
	var event_bus := FakeEventBus.new()
	var resource_core := FakeResourceCore.new()
	var castle_core := FakeCastleCore.new()
	var reset_dialog := FakeDialog.new()

	var callbacks := {
		"gold_changed": Callable(host, "on_gold_changed"),
		"stars_changed": Callable(host, "on_stars_changed"),
		"stage_changed": Callable(host, "on_stage_changed"),
		"game_loaded": Callable(host, "on_game_loaded"),
		"forge_cores_changed": Callable(host, "on_forge_cores_changed"),
		"resource_changed": Callable(host, "on_resource_changed"),
		"game_over": Callable(host, "on_game_over"),
		"reset_confirmed": Callable(host, "on_reset_confirmed"),
	}

	flow.connect_signals(event_bus, resource_core, castle_core, reset_dialog, callbacks)
	flow.connect_signals(event_bus, resource_core, castle_core, reset_dialog, callbacks)

	if not event_bus.gold_changed.is_connected(Callable(host, "on_gold_changed")):
		push_error("[test_mainui_signal_flow] gold_changed should be connected")
		quit(1)
		return
	if not event_bus.forge_cores_changed.is_connected(Callable(host, "on_forge_cores_changed")):
		push_error("[test_mainui_signal_flow] forge_cores_changed should be connected")
		quit(1)
		return
	if not resource_core.resource_changed.is_connected(Callable(host, "on_resource_changed")):
		push_error("[test_mainui_signal_flow] resource_changed should be connected")
		quit(1)
		return
	if not castle_core.game_over.is_connected(Callable(host, "on_game_over")):
		push_error("[test_mainui_signal_flow] game_over should be connected")
		quit(1)
		return
	if not reset_dialog.confirmed.is_connected(Callable(host, "on_reset_confirmed")):
		push_error("[test_mainui_signal_flow] reset dialog confirmed should be connected")
		quit(1)
		return
	if event_bus.gold_changed.get_connections().size() != 1:
		push_error("[test_mainui_signal_flow] signal connections should not duplicate")
		quit(1)
		return

	print("[test_mainui_signal_flow] PASS")
	quit(0)
