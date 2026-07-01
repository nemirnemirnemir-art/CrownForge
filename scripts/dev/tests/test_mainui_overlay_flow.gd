extends SceneTree

const MainUIOverlayFlowScript := preload("res://scripts/ui/hud/MainUIOverlayFlow.gd")


class FakeOverlays:
	extends RefCounted

	var visible: bool = true

	func is_any_overlay_visible() -> bool:
		return visible


class FakeNode:
	extends RefCounted

	var visible: bool = true


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = MainUIOverlayFlowScript.new()
	if flow == null:
		push_error("[test_mainui_overlay_flow] failed to instantiate helper")
		quit(1)
		return

	var hero_bar := FakeNode.new()
	var hero_card := FakeNode.new()
	flow.apply_overlay_visibility(FakeOverlays.new(), hero_bar, hero_card)
	if hero_bar.visible or hero_card.visible:
		push_error("[test_mainui_overlay_flow] overlay visible should hide hero HUD")
		quit(1)
		return

	var overlays := FakeOverlays.new()
	overlays.visible = false
	flow.apply_overlay_visibility(overlays, hero_bar, hero_card)
	if not hero_bar.visible or not hero_card.visible:
		push_error("[test_mainui_overlay_flow] overlay hidden should restore hero HUD")
		quit(1)
		return

	print("[test_mainui_overlay_flow] PASS")
	quit(0)
