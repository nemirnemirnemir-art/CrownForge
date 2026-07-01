extends SceneTree

const BridgeScript := preload("res://scripts/ui/hud/MainUIOverlayTargetBridge.gd")


class FakeOverlayFlow:
	extends RefCounted

	var calls: Array = []

	func apply_overlay_visibility(overlays, hero_bar, hero_card) -> void:
		calls.append([overlays, hero_bar, hero_card])


class FakeOverlays:
	extends RefCounted


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var bridge = BridgeScript.new()
	if bridge == null:
		push_error("[test_mainui_overlay_target_bridge] failed to instantiate helper")
		quit(1)
		return

	var hero_bar := Node.new()
	hero_bar.add_to_group("hero_bar")
	root.add_child(hero_bar)
	var hero_card := Node.new()
	hero_card.add_to_group("hero_card")
	root.add_child(hero_card)

	var targets: Dictionary = bridge.find_overlay_targets(self)
	if targets.get("hero_bar", null) != hero_bar:
		push_error("[test_mainui_overlay_target_bridge] hero_bar lookup mismatch")
		quit(1)
		return
	if targets.get("hero_card", null) != hero_card:
		push_error("[test_mainui_overlay_target_bridge] hero_card lookup mismatch")
		quit(1)
		return

	var flow := FakeOverlayFlow.new()
	var overlays := FakeOverlays.new()
	bridge.apply_overlay_visibility(self, flow, overlays)
	if flow.calls.size() != 1:
		push_error("[test_mainui_overlay_target_bridge] overlay flow should be invoked once")
		quit(1)
		return
	var call: Array = flow.calls[0]
	if call[0] != overlays or call[1] != hero_bar or call[2] != hero_card:
		push_error("[test_mainui_overlay_target_bridge] overlay target routing mismatch")
		quit(1)
		return

	print("[test_mainui_overlay_target_bridge] PASS")
	quit(0)
