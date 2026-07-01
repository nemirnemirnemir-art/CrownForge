extends SceneTree

const MainUIGameOverFlowScript := preload("res://scripts/ui/hud/MainUIGameOverFlow.gd")


class FakeGameOverPanel:
	extends Control

	signal restart_requested

	var marked_top_level: bool = false

	func mark_top_level(enabled: bool) -> void:
		marked_top_level = enabled


class FakePopupHost:
	extends RefCounted

	var added: Array = []

	func add_popup(node: Node) -> void:
		added.append(node)


class FakeFactory:
	extends RefCounted

	var created: Array = []

	func make_panel() -> FakeGameOverPanel:
		var panel := FakeGameOverPanel.new()
		created.append(panel)
		return panel


class CallbackHost:
	extends RefCounted

	func on_restart() -> void:
		pass


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = MainUIGameOverFlowScript.new()
	if flow == null:
		push_error("[test_mainui_game_over_flow] failed to instantiate helper")
		quit(1)
		return

	var popup_host := FakePopupHost.new()
	var factory := FakeFactory.new()
	var callbacks := CallbackHost.new()

	var panel = flow.open_game_over_panel(null, Callable(factory, "make_panel"), popup_host, Callable(callbacks, "on_restart"))
	if panel == null or factory.created.size() != 1:
		push_error("[test_mainui_game_over_flow] panel should be created on first open")
		quit(1)
		return
	if popup_host.added.size() != 1 or popup_host.added[0] != panel:
		push_error("[test_mainui_game_over_flow] panel should be added through popup host")
		quit(1)
		return
	if not panel.restart_requested.is_connected(Callable(callbacks, "on_restart")):
		push_error("[test_mainui_game_over_flow] restart signal should be connected")
		quit(1)
		return
	if not panel.visible or not panel.marked_top_level:
		push_error("[test_mainui_game_over_flow] panel should become visible and top level")
		quit(1)
		return

	panel.visible = false
	var reopened = flow.open_game_over_panel(panel, Callable(factory, "make_panel"), popup_host, Callable(callbacks, "on_restart"))
	if reopened != panel or factory.created.size() != 1:
		push_error("[test_mainui_game_over_flow] panel should be reused on reopen")
		quit(1)
		return
	if popup_host.added.size() != 1:
		push_error("[test_mainui_game_over_flow] reused panel should not be added again")
		quit(1)
		return
	if panel.restart_requested.get_connections().size() != 1:
		push_error("[test_mainui_game_over_flow] restart signal should not duplicate")
		quit(1)
		return

	print("[test_mainui_game_over_flow] PASS")
	quit(0)
