extends SceneTree

var _failed: bool = false


class FakeUI:
	extends MapSlotUI

	var hide_progress_calls: int = 0

	func hide_progress() -> void:
		hide_progress_calls += 1


class FakeProduction:
	extends MapSlotProduction

	var recover_calls: int = 0
	var next_result: Dictionary = {"is_producing": false}

	func recover_runtime_state(_config) -> Dictionary:
		recover_calls += 1
		return next_result.duplicate(true)


class FakeProductionFlow:
	extends RefCounted

	var recover_calls: int = 0
	var next_result: Dictionary = {}
	var last_ui = null
	var last_production = null
	var last_building_id: String = ""
	var last_config = null

	func recover_runtime(ui, production, current_building_id: String, config) -> Dictionary:
		recover_calls += 1
		last_ui = ui
		last_production = production
		last_building_id = current_building_id
		last_config = config
		return next_result.duplicate(true)


class FakeBuildingRegistry:
	extends Node

	var config_by_id: Dictionary = {}
	var requested_ids: Array[String] = []

	func get_building(building_id: String):
		requested_ids.append(building_id)
		return config_by_id.get(building_id, null)

	func get_building_icon(_building_id: String) -> Texture2D:
		return null


class FakeBuildingConfig:
	extends RefCounted

	enum BuildingType {
		MILITARY,
		RESOURCE,
		SPECIAL,
	}

	var building_type: int = BuildingType.RESOURCE
	var build_costs: Array = []
	var produces: Array = []
	var consumes: Array = []


class FakeVzorStateFlow:
	extends RefCounted

	var effectively_active: bool = false
	var apply_mine_visual_state_calls: int = 0
	var last_applied_building_id: String = ""

	func is_effectively_vzor_active() -> bool:
		return effectively_active

	func apply_mine_visual_state(current_building_id: String) -> void:
		apply_mine_visual_state_calls += 1
		last_applied_building_id = current_building_id


class FakeVisualApplier:
	extends RefCounted

	var call_count: int = 0

	func apply() -> void:
		call_count += 1


class FakeRecoveryFlow:
	extends RefCounted

	var recover_calls: int = 0
	var next_result: bool = false
	var last_current_building_id: String = ""
	var last_building_registry = null
	var last_ui = null
	var last_production = null
	var last_production_flow = null
	var last_anim_vzor: AnimatedSprite2D = null
	var last_vzor_state_flow = null
	var last_apply_mine_visual_state: Callable = Callable()

	func recover_after_encounter_pause(current_building_id: String, building_registry, ui, production, production_flow, anim_vzor: AnimatedSprite2D, vzor_state_flow, apply_mine_visual_state: Callable) -> bool:
		recover_calls += 1
		last_current_building_id = current_building_id
		last_building_registry = building_registry
		last_ui = ui
		last_production = production
		last_production_flow = production_flow
		last_anim_vzor = anim_vzor
		last_vzor_state_flow = vzor_state_flow
		last_apply_mine_visual_state = apply_mine_visual_state
		return next_result


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var helper_script = _recovery_flow_script()
	if helper_script == null:
		push_error("[test_mapslot_recovery_flow] helper script missing")
		quit(1)
		return

	var flow = helper_script.new()
	if flow == null:
		push_error("[test_mapslot_recovery_flow] failed to instantiate helper")
		quit(1)
		return

	_test_helper_fallbacks_to_direct_production_recovery(flow)
	if _failed:
		return
	await _test_mapslot_facade_delegates_and_returns_bool()
	if _failed:
		return
	await _test_mapslot_facade_marks_touched_for_producing_regular_building()
	if _failed:
		return
	await _test_mapslot_facade_marks_touched_when_vzor_animation_restarts()
	if _failed:
		return
	await _test_mapslot_facade_keeps_special_market_and_non_producing_cases_untouched()
	if _failed:
		return

	_test_returns_false_without_building(flow)
	if _failed:
		return
	_test_marks_slot_touched_for_producing_runtime(flow)
	if _failed:
		return
	_test_keeps_market_and_special_recovery_out_of_production(flow)
	if _failed:
		return
	await _test_marks_slot_touched_when_vzor_animation_restarts(flow)
	if _failed:
		return

	print("[test_mapslot_recovery_flow] PASS")
	await process_frame
	await process_frame
	quit(0)


func _test_helper_fallbacks_to_direct_production_recovery(flow) -> void:
	var production := FakeProduction.new()
	production.next_result = {"is_producing": true}
	var registry := FakeBuildingRegistry.new()
	var config: FakeBuildingConfig = _make_config()
	registry.config_by_id["farm"] = config
	var applier := FakeVisualApplier.new()

	var touched: bool = flow.recover_after_encounter_pause(
		"farm",
		registry,
		null,
		production,
		null,
		null,
		null,
		Callable(applier, "apply")
	)

	if not touched:
		_fail("helper fallback must mark slot as touched when direct production recovery is producing")
	if production.recover_calls != 1:
		_fail("helper fallback must call direct production recovery when production flow is missing")
	if applier.call_count != 1:
		_fail("helper fallback must still reapply mine visuals")


func _test_mapslot_facade_delegates_and_returns_bool() -> void:
	var fixture := await _create_mapslot_fixture()
	var slot = fixture["slot"]
	var registry = fixture["registry"]
	var recovery_flow := FakeRecoveryFlow.new()
	var ui := FakeUI.new()
	var production := FakeProduction.new()
	var production_flow := FakeProductionFlow.new()
	var anim_vzor := AnimatedSprite2D.new()
	var vzor_state_flow := FakeVzorStateFlow.new()

	slot.current_building_id = "farm"
	slot._ui = ui
	slot._production = production
	slot._production_flow = production_flow
	slot.add_child(anim_vzor)
	slot.anim_vzor = anim_vzor
	slot._vzor_state_flow = vzor_state_flow
	slot._recovery_flow = recovery_flow
	var expected_registry = slot.call("_building_registry")

	recovery_flow.next_result = true
	if not slot.recover_after_encounter_pause():
		_fail("MapSlot facade must return true when recovery flow returns true")
	if recovery_flow.recover_calls != 1:
		_fail("MapSlot facade must delegate recovery exactly once")
	if recovery_flow.last_current_building_id != "farm":
		_fail("MapSlot facade must forward current building id")
	if recovery_flow.last_building_registry != expected_registry:
		_fail("MapSlot facade must forward building registry seam")
	if recovery_flow.last_ui != ui or recovery_flow.last_production != production:
		_fail("MapSlot facade must forward runtime ui and production")
	if recovery_flow.last_production_flow != production_flow:
		_fail("MapSlot facade must forward production flow")
	if recovery_flow.last_anim_vzor != anim_vzor or recovery_flow.last_vzor_state_flow != vzor_state_flow:
		_fail("MapSlot facade must forward vzor dependencies")
	if not recovery_flow.last_apply_mine_visual_state.is_valid():
		_fail("MapSlot facade must forward mine visual callback")
	if vzor_state_flow.apply_mine_visual_state_calls != 0:
		_fail("MapSlot facade must stay thin and not apply mine visuals outside helper delegation")

	recovery_flow.next_result = false
	if slot.recover_after_encounter_pause():
		_fail("MapSlot facade must return false when recovery flow returns false")

	await _cleanup_mapslot_fixture(slot, registry)
	slot = null
	registry = null
	recovery_flow = null
	ui = null
	production = null
	production_flow = null
	anim_vzor = null
	vzor_state_flow = null


func _test_mapslot_facade_marks_touched_for_producing_regular_building() -> void:
	var fixture := await _create_mapslot_fixture("farm")
	var slot = fixture["slot"]
	var registry = fixture["registry"]
	var config: FakeBuildingConfig = _make_config()
	registry.config_by_id["farm"] = config
	slot._production = FakeProduction.new()
	slot._production_flow = FakeProductionFlow.new()
	slot._production_flow.next_result = {"is_producing": true}
	slot._ui = FakeUI.new()
	slot._vzor_state_flow = FakeVzorStateFlow.new()

	var touched: bool = slot.recover_after_encounter_pause()
	if not touched:
		_fail("MapSlot facade must report touched for producing regular building recovery")
	if slot._production_flow.recover_calls != 1:
		_fail("MapSlot facade must route regular building recovery through production flow")
	if slot._production.recover_calls != 0:
		_fail("MapSlot facade must not fall back to direct production recovery when production flow exists")
	if slot._vzor_state_flow.apply_mine_visual_state_calls != 1:
		_fail("MapSlot facade must apply mine visuals through helper path for producing recovery")

	await _cleanup_mapslot_fixture(slot, registry)
	slot = null
	registry = null
	config = null


func _test_mapslot_facade_marks_touched_when_vzor_animation_restarts() -> void:
	var fixture := await _create_mapslot_fixture("iron_mine")
	var slot = fixture["slot"]
	var registry = fixture["registry"]
	registry.config_by_id["iron_mine"] = _make_config()
	var sprite_frames: SpriteFrames = SpriteFrames.new()
	sprite_frames.add_animation("idle")
	var image: Image = Image.create(1, 1, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var texture: Texture2D = ImageTexture.create_from_image(image)
	sprite_frames.add_frame("idle", texture)
	var anim_vzor := AnimatedSprite2D.new()
	anim_vzor.sprite_frames = sprite_frames
	anim_vzor.animation = &"idle"
	anim_vzor.visible = true
	slot.add_child(anim_vzor)
	slot.anim_vzor = anim_vzor
	slot._production = null
	slot._production_flow = null
	slot._vzor_state_flow = FakeVzorStateFlow.new()
	slot._vzor_state_flow.effectively_active = true

	var touched: bool = slot.recover_after_encounter_pause()
	if not touched:
		_fail("MapSlot facade must report touched when vzor animation restarts")
	if not slot.anim_vzor.is_playing():
		_fail("MapSlot facade must restart vzor animation through helper path")
	if slot._vzor_state_flow.apply_mine_visual_state_calls != 1:
		_fail("MapSlot facade must apply mine visuals when vzor animation restarts")
	slot.anim_vzor = null
	anim_vzor.sprite_frames = null
	texture = null
	image = null
	sprite_frames = null

	await _cleanup_mapslot_fixture(slot, registry)
	slot = null
	registry = null


func _test_mapslot_facade_keeps_special_market_and_non_producing_cases_untouched() -> void:
	var special_fixture := await _create_mapslot_fixture("research_table")
	var special_slot = special_fixture["slot"]
	var special_registry = special_fixture["registry"]
	var special_config: FakeBuildingConfig = _make_config(FakeBuildingConfig.BuildingType.SPECIAL)
	special_registry.config_by_id["research_table"] = special_config
	special_slot._production = FakeProduction.new()
	special_slot._production_flow = FakeProductionFlow.new()
	special_slot._vzor_state_flow = FakeVzorStateFlow.new()
	if special_slot.recover_after_encounter_pause():
		_fail("MapSlot facade must keep special-building recovery untouched without animation restart")
	if special_slot._production_flow.recover_calls != 0 or special_slot._production.recover_calls != 0:
		_fail("MapSlot facade must skip regular production recovery for special buildings")
	if special_slot._vzor_state_flow.apply_mine_visual_state_calls != 1:
		_fail("MapSlot facade must still reapply mine visuals for special buildings")
	await _cleanup_mapslot_fixture(special_slot, special_registry)
	special_slot = null
	special_registry = null
	special_config = null

	var market_fixture := await _create_mapslot_fixture("market")
	var market_slot = market_fixture["slot"]
	var market_registry = market_fixture["registry"]
	market_slot._production = FakeProduction.new()
	market_slot._production_flow = FakeProductionFlow.new()
	market_slot._vzor_state_flow = FakeVzorStateFlow.new()
	if market_slot.recover_after_encounter_pause():
		_fail("MapSlot facade must keep market recovery untouched without animation restart")
	if market_slot._production_flow.recover_calls != 0 or market_slot._production.recover_calls != 0:
		_fail("MapSlot facade must skip regular production recovery for market")
	if market_slot._vzor_state_flow.apply_mine_visual_state_calls != 1:
		_fail("MapSlot facade must still reapply mine visuals for market")
	await _cleanup_mapslot_fixture(market_slot, market_registry)
	market_slot = null
	market_registry = null

	var regular_fixture := await _create_mapslot_fixture("farm")
	var regular_slot = regular_fixture["slot"]
	var regular_registry = regular_fixture["registry"]
	regular_registry.config_by_id["farm"] = _make_config()
	regular_slot._production = FakeProduction.new()
	regular_slot._production_flow = FakeProductionFlow.new()
	regular_slot._production_flow.next_result = {"is_producing": false}
	regular_slot._ui = FakeUI.new()
	regular_slot._vzor_state_flow = FakeVzorStateFlow.new()
	if regular_slot.recover_after_encounter_pause():
		_fail("MapSlot facade must keep non-producing regular recovery untouched")
	if regular_slot._production_flow.recover_calls != 1:
		_fail("MapSlot facade must still ask production flow to recover regular non-producing runtime")
	if regular_slot._vzor_state_flow.apply_mine_visual_state_calls != 1:
		_fail("MapSlot facade must still reapply mine visuals for non-producing regular recovery")
	await _cleanup_mapslot_fixture(regular_slot, regular_registry)
	regular_slot = null
	regular_registry = null


func _test_returns_false_without_building(flow) -> void:
	var applier := FakeVisualApplier.new()
	var touched: bool = flow.recover_after_encounter_pause(
		"",
		null,
		null,
		null,
		null,
		null,
		null,
		Callable(applier, "apply")
	)
	if touched:
		_fail("empty building id must not mark slot as touched")
	if applier.call_count != 0:
		_fail("empty building id must not reapply mine visuals")


func _test_marks_slot_touched_for_producing_runtime(flow) -> void:
	var ui := FakeUI.new()
	var production := FakeProduction.new()
	var production_flow := FakeProductionFlow.new()
	production_flow.next_result = {"is_producing": true}
	var registry := FakeBuildingRegistry.new()
	var config: FakeBuildingConfig = _make_config()
	registry.config_by_id["farm"] = config
	var applier := FakeVisualApplier.new()

	var touched: bool = flow.recover_after_encounter_pause(
		"farm",
		registry,
		ui,
		production,
		production_flow,
		null,
		null,
		Callable(applier, "apply")
	)

	if not touched:
		_fail("producing recovery must mark slot as touched")
	if production_flow.recover_calls != 1:
		_fail("production recovery flow must run for regular buildings")
	if production.recover_calls != 0:
		_fail("direct production recovery must stay unused when flow exists")
	if production_flow.last_ui != ui or production_flow.last_production != production:
		_fail("production recovery flow must receive slot ui and production runtime")
	if production_flow.last_building_id != "farm" or production_flow.last_config != config:
		_fail("production recovery flow must receive current building context")
	if applier.call_count != 1:
		_fail("recovering a placed building must reapply mine visuals once")


func _test_keeps_market_and_special_recovery_out_of_production(flow) -> void:
	var ui := FakeUI.new()
	var production := FakeProduction.new()
	var production_flow := FakeProductionFlow.new()
	var registry := FakeBuildingRegistry.new()
	var config: FakeBuildingConfig = _make_config(FakeBuildingConfig.BuildingType.SPECIAL)
	registry.config_by_id["research_table"] = config
	var applier := FakeVisualApplier.new()

	var touched: bool = flow.recover_after_encounter_pause(
		"research_table",
		registry,
		ui,
		production,
		production_flow,
		null,
		null,
		Callable(applier, "apply")
	)

	if touched:
		_fail("special building recovery must not report touched without runtime or animation restart")
	if production_flow.recover_calls != 0:
		_fail("special buildings must skip regular production recovery flow")
	if production.recover_calls != 0:
		_fail("special buildings must skip direct production recovery")
	if applier.call_count != 1:
		_fail("special building recovery must still reapply mine visuals")

	var market_applier := FakeVisualApplier.new()
	touched = flow.recover_after_encounter_pause(
		"market",
		registry,
		ui,
		production,
		production_flow,
		null,
		null,
		Callable(market_applier, "apply")
	)
	if touched:
		_fail("market recovery must not report touched without animation restart")
	if production_flow.recover_calls != 0:
		_fail("market must skip regular production recovery flow")
	if production.recover_calls != 0:
		_fail("market must skip direct production recovery")
	if market_applier.call_count != 1:
		_fail("market recovery must still reapply mine visuals")


func _test_marks_slot_touched_when_vzor_animation_restarts(flow) -> void:
	var registry := FakeBuildingRegistry.new()
	var config: FakeBuildingConfig = _make_config()
	registry.config_by_id["iron_mine"] = config
	var sprite_frames: SpriteFrames = SpriteFrames.new()
	sprite_frames.add_animation("idle")
	var image: Image = Image.create(1, 1, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var texture: Texture2D = ImageTexture.create_from_image(image)
	sprite_frames.add_frame("idle", texture)
	var anim_vzor := AnimatedSprite2D.new()
	anim_vzor.sprite_frames = sprite_frames
	anim_vzor.animation = &"idle"
	anim_vzor.visible = true
	var vzor_state_flow := FakeVzorStateFlow.new()
	vzor_state_flow.effectively_active = true
	var applier := FakeVisualApplier.new()

	var touched: bool = flow.recover_after_encounter_pause(
		"iron_mine",
		registry,
		null,
		null,
		null,
		anim_vzor,
		vzor_state_flow,
		Callable(applier, "apply")
	)

	if not touched:
		_fail("visible active vzor animation restart must mark slot as touched")
	if not anim_vzor.is_playing():
		_fail("visible active vzor animation must restart after encounter pause")
	if applier.call_count != 1:
		_fail("animation-only recovery must still reapply mine visuals")
	anim_vzor.sprite_frames = null
	anim_vzor.queue_free()
	texture = null
	image = null
	sprite_frames = null
	await process_frame
	registry = null
	config = null
	vzor_state_flow = null
	applier = null
	anim_vzor = null


func _fail(message: String) -> void:
	_failed = true
	push_error("[test_mapslot_recovery_flow] %s" % message)
	quit(1)


func _create_mapslot_fixture(building_id: String = "") -> Dictionary:
	var existing_registry := get_root().get_node_or_null("BuildingRegistry")
	if existing_registry:
		existing_registry.queue_free()
		await process_frame
	var registry := FakeBuildingRegistry.new()
	registry.name = "BuildingRegistry"
	get_root().add_child(registry)
	var slot = _map_slot_script().new()
	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	slot.add_child(sprite)
	var highlight := Node2D.new()
	highlight.name = "Highlight"
	slot.add_child(highlight)
	var click_area := Area2D.new()
	click_area.name = "ClickArea"
	var collision_shape := CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	click_area.add_child(collision_shape)
	slot.add_child(click_area)
	get_root().add_child(slot)
	await process_frame
	slot.set_process(false)
	slot.current_building_id = building_id
	slot._recovery_flow = _recovery_flow_script().new()
	return {"slot": slot, "registry": registry}


func _cleanup_mapslot_fixture(slot, registry: Node) -> void:
	if slot and is_instance_valid(slot):
		slot.free()
	if registry and is_instance_valid(registry):
		registry.config_by_id.clear()
		registry.requested_ids.clear()
		registry.free()
	await process_frame
	await process_frame


func _make_config(building_type: int = FakeBuildingConfig.BuildingType.RESOURCE):
	var config := FakeBuildingConfig.new()
	config.building_type = building_type
	config.build_costs = []
	config.produces = []
	config.consumes = []
	return config


func _recovery_flow_script() -> GDScript:
	return load("res://scripts/map_slot/MapSlotRecoveryFlow.gd")


func _map_slot_script() -> GDScript:
	return load("res://scripts/map/MapSlot.gd")
