extends SceneTree

const MainUIResourceDisplayFlowScript := preload("res://scripts/ui/hud/MainUIResourceDisplayFlow.gd")


class FakeLabel:
	extends RefCounted

	var text: String = ""


class FakeEconomy:
	extends RefCounted

	func get_gold() -> float:
		return 321.0


class FakeResourceCore:
	extends RefCounted

	func get_resource(resource_id: String) -> int:
		return {"water": 5, "wood": 7}.get(resource_id, 0)


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = MainUIResourceDisplayFlowScript.new()
	if flow == null:
		push_error("[test_mainui_resource_display_flow] failed to instantiate helper")
		quit(1)
		return

	var labels := {
		"gold": FakeLabel.new(),
		"water": FakeLabel.new(),
		"wood": FakeLabel.new()
	}
	flow.refresh_all_resources(labels, ["water", "gold", "wood"], FakeEconomy.new(), FakeResourceCore.new())
	if labels["gold"].text != "321" or labels["water"].text != "5" or labels["wood"].text != "7":
		push_error("[test_mainui_resource_display_flow] resource label refresh mismatch")
		quit(1)
		return

	print("[test_mainui_resource_display_flow] PASS")
	quit(0)
