extends RefCounted
class_name MapSlotBuildingConfigFlow

const MapSlotAnimationsScript := preload("res://scripts/map_slot/MapSlotAnimations.gd")
const BuildingUpgradeVisualsScript := preload("res://scripts/ui/town/buildings/BuildingUpgradeVisuals.gd")
const ArtifactBuildingLifecycleBonusesScript := preload("res://core/artifacts/ArtifactBuildingLifecycleBonuses.gd")

var _artifact_building_lifecycle_bonuses: RefCounted = ArtifactBuildingLifecycleBonusesScript.new()


func clear_building(slot, prev_building_id: String, prev_cfg, town_core, options: Dictionary = {}) -> void:
	if slot._special_handler and slot._special_handler.has_method("cleanup"):
		slot._special_handler.call("cleanup")
	slot._special_handler = null
	var preserve_military_units: bool = bool(options.get("preserve_military_units", false))
	var preserve_slot_state: bool = bool(options.get("preserve_slot_state", false))
	if not preserve_military_units and prev_cfg != null and int(prev_cfg.building_type) == int(BuildingConfig.BuildingType.MILITARY):
		slot._military_tracker.on_military_building_removed(prev_building_id, slot.slot_index)
	_reset_vzor_animation_state(slot)
	slot._reset_active_mine_transform()
	slot.sprite.texture = null
	if slot.anim_vzor:
		slot.anim_vzor.visible = false
		slot.anim_vzor.sprite_frames = null
	if slot._production:
		slot._production.reset()
	if slot._market:
		slot._market.reset()
	if slot._basic_construction_ui:
		slot._basic_construction_ui.visible = false
	if slot._basic_action_btn:
		slot._basic_action_btn.visible = false
	if slot._research_table_ui:
		slot._research_table_ui.visible = false
	if not preserve_slot_state and prev_building_id != "" and town_core and town_core.has_method("clear_building_slot_state"):
		town_core.clear_building_slot_state(prev_building_id, slot.slot_index, true)
	slot._update_research_table_visuals()
	slot._update_basic_construction_visuals()
	slot._update_upgrade_stripe()


func setup_building(building_registry, building_id: String, prev_building_id: String, prev_cfg, military_tracker, slot_index: int):
	if building_registry:
		var config = building_registry.get_building(building_id)
		if prev_cfg != null and int(prev_cfg.building_type) == int(BuildingConfig.BuildingType.MILITARY) and prev_building_id != building_id:
			military_tracker.on_military_building_removed(prev_building_id, slot_index)
		return config
	return null


func apply_building_config(slot, config, building_registry) -> void:
	if slot._special_handler and slot._special_handler.has_method("cleanup"):
		slot._special_handler.call("cleanup")
	slot._special_handler = null
	if bool(config.has_special_behavior) and String(config.special_script_path) != "":
		var scr := load(config.special_script_path)
		if scr != null and scr is Script:
			var inst: Variant = (scr as Script).new()
			if inst is RefCounted:
				slot._special_handler = inst as RefCounted
				if slot._special_handler.has_method("initialize"):
					slot._special_handler.call("initialize", slot, config)
				slot._restore_special_runtime_state(config.building_id)
				if slot._special_handler.has_method("set_vzor_active"):
					slot._special_handler.call("set_vzor_active", _is_effectively_vzor_active(slot))

	if bool(config.use_vzor_animation) and slot.anim_vzor and config.vzor_frames:
		slot.anim_vzor.sprite_frames = config.vzor_frames
		slot.anim_vzor.animation = config.vzor_animation_name
		slot.anim_vzor.visible = true
		slot.anim_vzor.stop()
		slot.anim_vzor.frame = 0
		_reset_vzor_animation_state(slot)
		slot.sprite.visible = false
		slot.sprite.texture = null
	else:
		if slot.anim_vzor:
			slot.anim_vzor.visible = false
			slot.anim_vzor.sprite_frames = null
		slot.sprite.visible = true
		if config.icon:
			slot.sprite.texture = config.icon
		else:
			slot.sprite.texture = MapSlotAnimationsScript.create_placeholder_texture()
			MapSlotAnimationsScript.add_placeholder_label(slot.sprite, config.display_name)

	if slot.sprite:
		var base_position: Vector2 = slot._default_sprite_position
		var base_rotation: float = slot._default_sprite_rotation
		var base_scale: Vector2 = slot._default_sprite_scale
		if building_registry and building_registry.has_method("get_placed_building_scale"):
			base_scale *= building_registry.get_placed_building_scale(config.building_id)
		_apply_base_sprite_state(slot, base_position, base_rotation, base_scale)
		_reset_vzor_animation_state(slot)

	slot._apply_mine_visual_state()
	var durability := -1
	if int(config.building_type) == int(BuildingConfig.BuildingType.RESOURCE) and int(config.max_units) > 0:
		durability = int(config.max_units)
		var artifact_core := _get_artifact_core()
		if artifact_core != null and artifact_core.has_method("get_resource_building_durability_limit"):
			durability = int(artifact_core.call("get_resource_building_durability_limit", config, durability))
		elif _artifact_building_lifecycle_bonuses != null and _artifact_building_lifecycle_bonuses.has_method("get_resource_building_durability"):
			var active_artifacts := _get_active_artifacts()
			durability = int(_artifact_building_lifecycle_bonuses.call("get_resource_building_durability", active_artifacts, config, durability))
	if slot._production:
		slot._production.initialize(config.cycle_time, durability, slot.slot_index, config.building_id)
		slot._seal_logic._update_seal_modifier()
	slot._update_upgrade_stripe()


func update_upgrade_stripe(current_building_id: String, upgrade_stripe, building_upgrade_core) -> void:
	if upgrade_stripe == null:
		return
	if current_building_id == "":
		upgrade_stripe.visible = false
		upgrade_stripe.texture = null
		return
	var level := int(building_upgrade_core.call("get_building_upgrade_level", current_building_id)) if building_upgrade_core and building_upgrade_core.has_method("get_building_upgrade_level") else 0
	var texture = BuildingUpgradeVisualsScript.get_stripe_texture(level)
	upgrade_stripe.texture = texture
	upgrade_stripe.visible = texture != null


func handle_resource_depletion(slot, config, clear_building_callback: Callable) -> void:
	if config == null:
		return
	if int(config.building_type) != int(BuildingConfig.BuildingType.RESOURCE):
		return
	if String(config.building_id) == "well":
		return
	if slot._production == null:
		return
	if slot._production.get_durability() != 0:
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		var artifact_core := tree.root.get_node_or_null("ArtifactCore")
		if artifact_core != null and artifact_core.has_method("on_resource_building_depleted"):
			artifact_core.call("on_resource_building_depleted")
	if clear_building_callback.is_valid():
		clear_building_callback.call()


func _is_effectively_vzor_active(slot) -> bool:
	if slot.has_method("is_effectively_vzor_active"):
		return bool(slot.call("is_effectively_vzor_active"))
	return bool(slot.get("_vzor_active"))


func _reset_vzor_animation_state(slot) -> void:
	if slot.has_method("set"):
		slot.set("_mine_anim_time", 0.0)
		if slot.get("_vzor_anim_frame") != null:
			slot.set("_vzor_anim_frame", 0)
	var vzor_state_flow: Variant = slot.get("_vzor_state_flow")
	if vzor_state_flow != null and vzor_state_flow.has_method("load_visual_runtime_state"):
		vzor_state_flow.call("load_visual_runtime_state", {
			"vzor_anim_frame": 0,
			"mine_anim_time": 0.0,
		})


func _apply_base_sprite_state(slot, base_position: Vector2, base_rotation: float, base_scale: Vector2) -> void:
	if slot.has_method("set"):
		slot.set("_base_sprite_position", base_position)
		slot.set("_base_sprite_rotation", base_rotation)
		slot.set("_base_sprite_scale", base_scale)
	if slot.sprite:
		slot.sprite.position = base_position
		slot.sprite.rotation = base_rotation
		slot.sprite.scale = base_scale
	var vzor_state_flow: Variant = slot.get("_vzor_state_flow")
	if vzor_state_flow != null and vzor_state_flow.has_method("load_visual_runtime_state"):
		vzor_state_flow.call("load_visual_runtime_state", {
			"base_sprite_position": base_position,
			"base_sprite_rotation": base_rotation,
			"base_sprite_scale": base_scale,
		})


func _get_active_artifacts() -> Dictionary:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return {}
	var artifact_core := tree.root.get_node_or_null("ArtifactCore")
	if artifact_core == null or not artifact_core.has_method("get_active_ids"):
		return {}
	var active: Dictionary = {}
	for artifact_id in artifact_core.call("get_active_ids"):
		active[String(artifact_id)] = true
	return active

func _get_artifact_core() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("ArtifactCore")
