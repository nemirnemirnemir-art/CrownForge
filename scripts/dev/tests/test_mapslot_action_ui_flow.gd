extends SceneTree

const MapSlotActionUIFlowScript := preload("res://scripts/map_slot/MapSlotActionUIFlow.gd")


class FakeMarket:
	extends RefCounted

	var active_resource: String = ""

	func set_active_resource(resource_id: String) -> void:
		active_resource = resource_id

	func get_active_resource() -> String:
		return active_resource


class FakeBadge:
	extends Button

	var empty_state_calls: int = 0
	var active_state_payloads: Array[String] = []

	func show_empty_state() -> void:
		empty_state_calls += 1

	func show_active_resource(resource_id: String) -> void:
		active_state_payloads.append(resource_id)


class FakeSpecialHandler:
	extends RefCounted

	var ready: bool = false
	var converted_to: String = ""
	var reward_type: int = 2
	var mode: int = 1

	func is_ready() -> bool:
		return ready

	func convert_to(building_id: String) -> bool:
		converted_to = building_id
		return true

	func get_current_reward_type() -> int:
		return reward_type

	func get_mode() -> int:
		return mode

	func get_ui_options() -> Array:
		return ["a", "b"]

	func set_mode(next_mode: int) -> void:
		mode = next_mode


class FakeSaveCore:
	extends RefCounted

	var save_requests: int = 0

	func request_save() -> void:
		save_requests += 1


class FakeCounter:
	extends RefCounted

	var count: int = 0

	func bump() -> void:
		count += 1


class FakePopup:
	extends Control

	var setup_calls: Array = []

	func setup(value) -> void:
		setup_calls.append(value)

	func setup_options(options: Array, mode: int) -> void:
		setup_calls.append({"options": options.duplicate(true), "mode": mode})


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = MapSlotActionUIFlowScript.new()
	if flow == null:
		push_error("[test_mapslot_action_ui_flow] failed to instantiate helper")
		quit(1)
		return

	var root := Node2D.new()
	get_root().add_child(root)

	var market_ui := Control.new()
	market_ui.visible = false
	root.add_child(market_ui)
	var basic_ui := FakePopup.new()
	basic_ui.visible = true
	root.add_child(basic_ui)
	var research_ui := FakePopup.new()
	research_ui.visible = true
	root.add_child(research_ui)
	var market_btn := FakeBadge.new()
	root.add_child(market_btn)
	var basic_btn := Button.new()
	root.add_child(basic_btn)
	var badge := Control.new()
	var icon := TextureRect.new()
	icon.name = "Icon"
	badge.add_child(icon)
	root.add_child(badge)

	var market := FakeMarket.new()
	var special := FakeSpecialHandler.new()
	var save_core := FakeSaveCore.new()
	var toggled_basic := FakeCounter.new()
	var positioned := FakeCounter.new()
	var closed_others := FakeCounter.new()
	var cancelled_vzor := FakeCounter.new()
	var refreshed_visibility := FakeCounter.new()
	var market_visuals_updated := FakeCounter.new()

	flow.call(
		"on_market_action_pressed",
		market_ui,
		basic_ui,
		research_ui,
		func(_popup, _prefer_right) -> void: positioned.bump(),
		func(_popup_to_keep) -> void: closed_others.bump(),
		Callable(cancelled_vzor, "bump"),
		Callable(refreshed_visibility, "bump")
	)
	if not market_ui.visible or basic_ui.visible or research_ui.visible:
		push_error("[test_mapslot_action_ui_flow] market button must toggle market popup and hide others")
		quit(1)
		return
	if positioned.count != 1:
		push_error("[test_mapslot_action_ui_flow] market popup must be positioned near slot")
		quit(1)
		return
	if closed_others.count != 1 or cancelled_vzor.count != 1 or refreshed_visibility.count != 1:
		push_error("[test_mapslot_action_ui_flow] market popup opening must close other special popups, cancel vzor drag, and refresh opener visibility")
		quit(1)
		return

	flow.on_trade_requested("gold", market, market_ui, Callable(market_visuals_updated, "bump"))
	if market.active_resource != "gold" or market_ui.visible:
		push_error("[test_mapslot_action_ui_flow] trade request must set active market resource and close popup")
		quit(1)
		return
	if market_visuals_updated.count != 1:
		push_error("[test_mapslot_action_ui_flow] trade request must refresh market visuals")
		quit(1)
		return

	flow.on_trade_requested("", market, market_ui, Callable(market_visuals_updated, "bump"))
	if market.active_resource != "":
		push_error("[test_mapslot_action_ui_flow] empty trade request must clear active market resource")
		quit(1)
		return

	basic_ui.visible = true
	special.converted_to = ""
	var save_requests_before_empty := save_core.save_requests
	var empty_selection_result := flow.on_basic_construction_target_requested("", special, basic_ui, research_ui, save_core)
	if not empty_selection_result:
		push_error("[test_mapslot_action_ui_flow] empty construction selection must be handled")
		quit(1)
		return
	if basic_ui.visible:
		push_error("[test_mapslot_action_ui_flow] empty construction selection must close the popup")
		quit(1)
		return
	if special.converted_to != "":
		push_error("[test_mapslot_action_ui_flow] empty construction selection must not convert a building")
		quit(1)
		return
	if save_core.save_requests != save_requests_before_empty:
		push_error("[test_mapslot_action_ui_flow] empty construction selection must not request save")
		quit(1)
		return

	basic_ui.visible = true
	research_ui.visible = true
	flow.on_basic_construction_target_requested("windmill", special, basic_ui, research_ui, save_core)
	if special.converted_to != "windmill":
		push_error("[test_mapslot_action_ui_flow] basic construction target must convert building")
		quit(1)
		return
	if basic_ui.visible or research_ui.visible:
		push_error("[test_mapslot_action_ui_flow] conversion must close both popups")
		quit(1)
		return
	if save_core.save_requests != 1:
		push_error("[test_mapslot_action_ui_flow] conversion must request save")
		quit(1)
		return

	special.ready = true
	basic_ui.visible = true
	flow.call("update_basic_construction_visuals", "basic_construction", basic_btn, special, basic_ui)
	if basic_btn.visible:
		push_error("[test_mapslot_action_ui_flow] basic action button must hide while popup is open")
		quit(1)
		return
	basic_ui.visible = false
	flow.call("update_basic_construction_visuals", "basic_construction", basic_btn, special, basic_ui)
	if not basic_btn.visible:
		push_error("[test_mapslot_action_ui_flow] basic action button must be visible when construction is ready")
		quit(1)
		return

	research_ui.visible = true
	flow.call("update_research_table_visuals", "research_table", badge, special, research_ui)
	if badge.visible:
		push_error("[test_mapslot_action_ui_flow] research badge must hide while popup is open")
		quit(1)
		return
	research_ui.visible = false
	flow.call("update_research_table_visuals", "research_table", badge, special, research_ui)
	if not badge.visible:
		push_error("[test_mapslot_action_ui_flow] research badge must be visible for research buildings")
		quit(1)
		return

	market_ui.visible = true
	flow.call("update_market_action_visibility", "market", market_btn, market_ui)
	if market_btn.visible:
		push_error("[test_mapslot_action_ui_flow] market opener must hide while market popup is open")
		quit(1)
		return
	market_ui.visible = false
	flow.call("update_market_action_visibility", "market", market_btn, market_ui)
	if not market_btn.visible:
		push_error("[test_mapslot_action_ui_flow] market opener must be visible when market popup is closed")
		quit(1)
		return

	flow.update_market_visuals(market_btn, market, null)
	if market_btn.empty_state_calls == 0:
		push_error("[test_mapslot_action_ui_flow] empty market selection must use empty-slot visual state")
		quit(1)
		return
	market.active_resource = "wheat"
	flow.update_market_visuals(market_btn, market, null)
	if market_btn.active_state_payloads != ["wheat"]:
		push_error("[test_mapslot_action_ui_flow] market visual must show active traded resource")
		quit(1)
		return

	flow.on_basic_action_pressed(Callable(toggled_basic, "bump"))
	if toggled_basic.count != 1:
		push_error("[test_mapslot_action_ui_flow] basic action button must delegate to popup toggle")
		quit(1)
		return

	print("[test_mapslot_action_ui_flow] PASS")
	quit(0)
