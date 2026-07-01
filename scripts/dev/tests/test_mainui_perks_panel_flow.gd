extends SceneTree

const FlowScript := preload("res://scripts/ui/hud/MainUIPerksPanelFlow.gd")

class FakePerksPanel:
	extends RefCounted

	var open_calls: int = 0

	func open() -> void:
		open_calls += 1

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var flow = FlowScript.new()
	if flow == null:
		push_error("[test_mainui_perks_panel_flow] failed to instantiate helper")
		quit(1)
		return
	var panel := FakePerksPanel.new()
	flow.open_perks_panel(panel)
	if panel.open_calls != 1:
		push_error("[test_mainui_perks_panel_flow] perks panel should open")
		quit(1)
		return
	flow.open_perks_panel(null)
	print("[test_mainui_perks_panel_flow] PASS")
	quit(0)
