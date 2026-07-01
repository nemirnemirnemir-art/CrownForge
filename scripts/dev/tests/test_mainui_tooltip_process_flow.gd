extends SceneTree

const FlowScript := preload("res://scripts/ui/hud/MainUITooltipProcessFlow.gd")

class FakeTooltips:
	extends RefCounted

	var process_calls: int = 0

	func process() -> void:
		process_calls += 1

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var flow = FlowScript.new()
	if flow == null:
		push_error("[test_mainui_tooltip_process_flow] failed to instantiate helper")
		quit(1)
		return
	var tooltips := FakeTooltips.new()
	flow.process_tooltips(tooltips)
	if tooltips.process_calls != 1:
		push_error("[test_mainui_tooltip_process_flow] tooltip process should be forwarded")
		quit(1)
		return
	flow.process_tooltips(null)
	print("[test_mainui_tooltip_process_flow] PASS")
	quit(0)
