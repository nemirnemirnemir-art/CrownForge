extends SceneTree

const FlowScript := preload("res://scripts/ui/hud/MainUIDisplayEventFlow.gd")

class FakeHeroHire:
	extends RefCounted

	var update_calls: int = 0

	func update_hero_costs() -> void:
		update_calls += 1

class FakeLabelSetter:
	extends RefCounted

	var calls: Array = []

	func set_label(resource_id: String, value: Variant) -> void:
		calls.append([resource_id, value])

class FakeRefresher:
	extends RefCounted

	var refresh_calls: int = 0

	func refresh() -> void:
		refresh_calls += 1

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var flow = FlowScript.new()
	if flow == null:
		push_error("[test_mainui_display_event_flow] failed to instantiate helper")
		quit(1)
		return

	var setter := FakeLabelSetter.new()
	var hire := FakeHeroHire.new()
	flow.on_gold_changed(123.7, Callable(setter, "set_label"), hire)
	if setter.calls.size() != 1 or setter.calls[0][0] != "gold" or setter.calls[0][1] != 123:
		push_error("[test_mainui_display_event_flow] gold label routing mismatch")
		quit(1)
		return
	if hire.update_calls != 1:
		push_error("[test_mainui_display_event_flow] gold change should refresh hero costs")
		quit(1)
		return

	var refresher := FakeRefresher.new()
	flow.on_stage_changed(Callable(refresher, "refresh"), hire)
	if refresher.refresh_calls != 1:
		push_error("[test_mainui_display_event_flow] stage change should refresh resources")
		quit(1)
		return
	if hire.update_calls != 2:
		push_error("[test_mainui_display_event_flow] stage change should refresh hero costs")
		quit(1)
		return

	flow.on_resource_changed("wood", 7, Callable(setter, "set_label"))
	if setter.calls.size() != 2 or setter.calls[1][0] != "wood" or setter.calls[1][1] != 7:
		push_error("[test_mainui_display_event_flow] resource change label routing mismatch")
		quit(1)
		return

	print("[test_mainui_display_event_flow] PASS")
	quit(0)
