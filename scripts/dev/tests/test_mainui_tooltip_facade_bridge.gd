extends SceneTree

const BridgeScript := preload("res://scripts/ui/hud/MainUITooltipFacadeBridge.gd")

class FakeTooltips:
	extends RefCounted

	var calls: Array = []

	func show_hero_hp_tooltip(hero) -> void:
		calls.append(["show_hero", hero])

	func hide_hero_hp_tooltip(hero) -> void:
		calls.append(["hide_hero", hero])

	func show_enemy_hp_tooltip(mob) -> void:
		calls.append(["show_enemy", mob])

	func hide_enemy_hp_tooltip(mob) -> void:
		calls.append(["hide_enemy", mob])

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var bridge = BridgeScript.new()
	if bridge == null:
		push_error("[test_mainui_tooltip_facade_bridge] failed to instantiate helper")
		quit(1)
		return
	var tooltips := FakeTooltips.new()
	var hero := Node.new()
	var mob := Node.new()
	bridge.show_hero_hp_tooltip(tooltips, hero)
	bridge.hide_hero_hp_tooltip(tooltips, hero)
	bridge.show_enemy_hp_tooltip(tooltips, mob)
	bridge.hide_enemy_hp_tooltip(tooltips, mob)
	if tooltips.calls.size() != 4:
		push_error("[test_mainui_tooltip_facade_bridge] tooltip routing call count mismatch")
		quit(1)
		return
	if tooltips.calls[0][0] != "show_hero" or tooltips.calls[1][0] != "hide_hero" or tooltips.calls[2][0] != "show_enemy" or tooltips.calls[3][0] != "hide_enemy":
		push_error("[test_mainui_tooltip_facade_bridge] tooltip routing order mismatch")
		quit(1)
		return
	bridge.show_hero_hp_tooltip(null, hero)
	print("[test_mainui_tooltip_facade_bridge] PASS")
	quit(0)
