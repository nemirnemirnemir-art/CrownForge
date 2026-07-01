extends SceneTree

const MapSlotBootstrapScript := preload("res://scripts/map_slot/MapSlotBootstrap.gd")


class FakeSignalSource:
	extends Control

	signal trade_requested(resource_id: String)
	signal target_requested(building_id: String)
	signal close_requested
	signal mode_requested(mode: int)


class FakeProduction:
	extends RefCounted

	signal production_completed(outputs: Array)
	signal hero_produced(hero_id: String)


class FakeMarket:
	extends RefCounted

	signal trade_completed(resource_id: String, amount: int)


class FakeSealLogic:
	extends RefCounted

	var initialized_with_slot = null

	func initialize(slot, _production) -> void:
		initialized_with_slot = slot


class FakeMilitaryTracker:
	extends RefCounted


class FakeAnimations:
	extends RefCounted

	var initialized_with_parent = null

	func initialize(parent) -> void:
		initialized_with_parent = parent


class FakeHost:
	extends Node2D

	var progress_bar := TextureProgressBar.new()
	var radial_progress := Sprite2D.new()
	var click_area := Area2D.new()
	var collision_shape := CollisionShape2D.new()
	var highlight := Control.new()
	var current_seal_id: String = ""
	var sprite := Sprite2D.new()
	var UnderTexture = AtlasTexture.new()
	var BasicConstructionUIScene = null
	var ResearchTableUIScene = null
	var _production = null
	var _market = null
	var _seal_logic = null
	var _military_tracker = null
	var _animations = null
	var _popup_controller = null
	var _special_runtime = null
	var _building_lifecycle = null
	var _interaction_controller = null
	var _production_flow = null
	var _special_flow = null
	var _feedback_flow = null
	var _action_ui_flow = null
	var _vzor_visual_flow = null
	var _tick_routing = null
	var _building_config_flow = null
	var _ui = null
	var _unit_count_label = null
	var _durability_label = null
	var _market_action_btn = null
	var _market_ui = null
	var _basic_construction_ui = null
	var _basic_action_btn = null
	var _research_table_ui = null
	var _research_mode_badge = null
	var _on_market_action_pressed_calls: int = 0
	var _on_trade_requested_calls: int = 0
	var _on_basic_construction_target_requested_calls: int = 0
	var _on_basic_construction_close_requested_calls: int = 0
	var _on_basic_action_pressed_calls: int = 0
	var _on_research_mode_requested_calls: int = 0
	var hero_died_connected: bool = false
	var upgrade_connected: bool = false

	func _init() -> void:
		add_child(progress_bar)
		add_child(radial_progress)
		add_child(click_area)
		add_child(collision_shape)
		add_child(highlight)
		add_child(sprite)

	func _on_market_action_pressed() -> void:
		_on_market_action_pressed_calls += 1

	func _on_trade_requested(_resource_id: String) -> void:
		_on_trade_requested_calls += 1

	func _on_basic_construction_target_requested(_building_id: String) -> void:
		_on_basic_construction_target_requested_calls += 1

	func _on_basic_construction_close_requested() -> void:
		_on_basic_construction_close_requested_calls += 1

	func _on_basic_action_pressed() -> void:
		_on_basic_action_pressed_calls += 1

	func _on_research_mode_requested(_mode: int) -> void:
		_on_research_mode_requested_calls += 1

	func _position_popup_near_slot(_popup: Control, _prefer_right: bool) -> void:
		pass

	func _instantiate_market_ui() -> Node:
		return FakeSignalSource.new()


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var host := FakeHost.new()
	get_root().add_child(host)
	host.BasicConstructionUIScene = PackedScene.new()
	host.ResearchTableUIScene = PackedScene.new()

	var basic_ui := FakeSignalSource.new()
	host.BasicConstructionUIScene.pack(basic_ui)
	var research_ui := FakeSignalSource.new()
	host.ResearchTableUIScene.pack(research_ui)

	var bootstrap = MapSlotBootstrapScript.new()
	bootstrap.initialize_modules(
		host,
		func() -> Variant: return FakeProduction.new(),
		func() -> Variant: return FakeMarket.new(),
		func() -> Variant: return FakeSealLogic.new(),
		func() -> Variant: return FakeMilitaryTracker.new(),
		func() -> Variant: return FakeAnimations.new(),
		[
			func() -> Variant: return RefCounted.new(),
			func() -> Variant: return RefCounted.new(),
			func() -> Variant: return RefCounted.new(),
			func() -> Variant: return RefCounted.new(),
			func() -> Variant: return RefCounted.new(),
			func() -> Variant: return RefCounted.new(),
			func() -> Variant: return RefCounted.new(),
		]
	)
	bootstrap.setup_ui_nodes(host)
	bootstrap.setup_market_features(host)
	bootstrap.setup_basic_construction_features(host)
	bootstrap.setup_research_table_features(host)
	bootstrap.configure_click_area(host)

	if host._production == null or host._market == null or host._animations == null:
		push_error("[test_mapslot_bootstrap] core helpers were not initialized")
		quit(1)
		return
	if host._ui == null or host._unit_count_label == null or host._durability_label == null:
		push_error("[test_mapslot_bootstrap] UI nodes were not created")
		quit(1)
		return
	if host._unit_count_label.mouse_filter != Control.MOUSE_FILTER_IGNORE or host._durability_label.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		push_error("[test_mapslot_bootstrap] slot-local unit overlays must ignore mouse input so they do not block slot clicks")
		quit(1)
		return
	if absf(host._unit_count_label.position.x + 36.0) > 0.01 or absf(host._durability_label.position.x + 36.0) > 0.01:
		push_error("[test_mapslot_bootstrap] slot-local unit overlays must stay centered over the building cell")
		quit(1)
		return
	if host._unit_count_label.horizontal_alignment != HORIZONTAL_ALIGNMENT_CENTER or host._durability_label.horizontal_alignment != HORIZONTAL_ALIGNMENT_CENTER:
		push_error("[test_mapslot_bootstrap] slot-local unit overlays must center their text over the building cell")
		quit(1)
		return
	if host._unit_count_label.custom_minimum_size != Vector2(72.0, 24.0) or host._durability_label.custom_minimum_size != Vector2(72.0, 24.0):
		push_error("[test_mapslot_bootstrap] slot-local unit overlays must use the shared centered label footprint")
		quit(1)
		return
	if host._unit_count_label.get("theme_override_colors/font_color") != Color.WHITE or host._durability_label.get("theme_override_colors/font_color") != Color.WHITE:
		push_error("[test_mapslot_bootstrap] slot-local unit overlays must use white text on both military and resource buildings")
		quit(1)
		return
	if host._market_ui == null or host._basic_construction_ui == null or host._research_table_ui == null:
		push_error("[test_mapslot_bootstrap] feature UI scenes were not instantiated")
		quit(1)
		return
	if not host._market_ui.is_in_group("map_slot_special_popup") or not host._basic_construction_ui.is_in_group("map_slot_special_popup") or not host._research_table_ui.is_in_group("map_slot_special_popup"):
		push_error("[test_mapslot_bootstrap] special building popups must be registered in the shared popup group")
		quit(1)
		return
	if not (host._research_mode_badge is Button):
		push_error("[test_mapslot_bootstrap] research mode badge must be a clickable button")
		quit(1)
		return
	var research_button := host._research_mode_badge as Button
	research_button.pressed.emit()
	if host._on_research_mode_requested_calls != 0:
		push_error("[test_mapslot_bootstrap] research badge press must not emit mode directly")
		quit(1)
		return
	if research_button.pressed.get_connections().is_empty():
		push_error("[test_mapslot_bootstrap] research badge must wire a pressed handler")
		quit(1)
		return
	if host.collision_shape.shape == null:
		push_error("[test_mapslot_bootstrap] click area collision was not configured")
		quit(1)
		return

	print("[test_mapslot_bootstrap] PASS")
	quit(0)
