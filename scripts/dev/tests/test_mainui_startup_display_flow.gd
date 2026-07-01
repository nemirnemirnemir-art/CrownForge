extends SceneTree

const FlowScript := preload("res://scripts/ui/hud/MainUIStartupDisplayFlow.gd")

class FakeHeroHire:
	extends RefCounted

	var update_calls: int = 0

	func update_hero_costs() -> void:
		update_calls += 1

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
		push_error("[test_mainui_startup_display_flow] failed to instantiate helper")
		quit(1)
		return
	var refresher := FakeRefresher.new()
	flow.update_all_display(Callable(refresher, "refresh"), FakeHeroHire.new())
	if refresher.refresh_calls != 1:
		push_error("[test_mainui_startup_display_flow] refresh callback should run once")
		quit(1)
		return
	var hire := FakeHeroHire.new()
	flow.update_all_display(Callable(refresher, "refresh"), hire)
	if hire.update_calls != 1:
		push_error("[test_mainui_startup_display_flow] hero hire costs should refresh")
		quit(1)
		return
	flow.update_all_display(Callable(), null)
	print("[test_mainui_startup_display_flow] PASS")
	quit(0)
