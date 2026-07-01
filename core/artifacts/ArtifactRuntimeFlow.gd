extends RefCounted
class_name ArtifactRuntimeFlow

const CUPBEARERS_VESSEL_ID := "cupbearers_vessel"
const STONE_GAZE_ID := "stone_gaze"
const STONE_GAZE_SOURCE_ID := "artifact_stone_gaze"
const ArtifactDeathSummonDomainScript := preload("res://core/artifacts/ArtifactDeathSummonDomain.gd")
const CUPBEARERS_WELL_IDS := {
	"well": true,
	"big_well": true,
}

func process_active_effects(active: Dictionary, state: Dictionary, delta: float) -> void:
	if delta <= 0.0:
		return
	ArtifactDeathSummonDomainScript.tick(active, state, delta)
	if active.has(CUPBEARERS_VESSEL_ID):
		ArtifactState.run_periodic_timer(state, CUPBEARERS_VESSEL_ID, "cupbearers_accum", 10.0, delta, func() -> void:
			_grant_cupbearers_vessel_wine()
		)
	if active.has(STONE_GAZE_ID):
		ArtifactState.run_periodic_timer(state, STONE_GAZE_ID, "stone_gaze_accum", 0.5, delta, func() -> void:
			_apply_stone_gaze()
		)
	for artifact_id in active.keys():
		var aid := str(artifact_id)
		var def := ArtifactCatalog.get_def(aid)
		var kind := str(def.get("effect_kind", ""))
		if kind == "periodic_random_enemy_damage":
			var period := maxf(0.05, float(def.get("effect_period", 1.0)))
			var damage := float(def.get("effect_value", 0.0))
			if damage > 0.0:
				ArtifactState.run_periodic_timer(state, aid, "periodic_damage_accum", period, delta, func():
					ArtifactHealDamage.damage_random_enemy(damage)
				)
		elif kind == "periodic_class_regen_hp_per_sec":
			var period := maxf(0.05, float(def.get("effect_period", 1.0)))
			var heal_per_tick := float(def.get("effect_value", 0.0))
			if heal_per_tick > 0.0:
				ArtifactState.run_periodic_timer(state, aid, "periodic_class_regen_accum", period, delta, func():
					ArtifactHealDamage.heal_active_class_units(str(def.get("effect_unit_class", "")), heal_per_tick)
				)

func process_pending_spell_choice_rewards(pending: int, pending_legendary: int) -> Dictionary:
	return ArtifactSpellRewards.process_pending_spell_rewards(pending, pending_legendary)


func _grant_cupbearers_vessel_wine() -> void:
	var resource_core := _get_resource_core()
	if resource_core == null or not resource_core.has_method("add_resource"):
		return
	var well_count := _count_placed_buildings(CUPBEARERS_WELL_IDS)
	if well_count <= 0:
		return
	resource_core.call("add_resource", "wine", well_count)


func _count_placed_buildings(building_ids: Dictionary) -> int:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return 0
	var game_scene := tree.get_first_node_in_group("game_scene")
	if game_scene == null:
		game_scene = tree.current_scene
	if game_scene == null:
		return 0
	var map_layout: Node = game_scene.get("map_layout_node")
	if map_layout == null:
		map_layout = game_scene.get_node_or_null("WorldYSort/MapContainer/MapLayout")
	if map_layout == null:
		return 0
	var raw_slots: Variant = map_layout.get("slots")
	if not (raw_slots is Array):
		return 0

	var count := 0
	for slot_value in raw_slots:
		var slot := slot_value as Node
		if slot == null:
			continue
		var building_id := String(slot.get("current_building_id")).strip_edges().to_lower()
		if building_ids.has(building_id):
			count += 1
	return count


func _apply_stone_gaze() -> void:
	var center_slot := _get_center_castle_slot()
	if center_slot == null or not center_slot.has_method("set_external_vzor_active"):
		return
	center_slot.call("set_external_vzor_active", STONE_GAZE_SOURCE_ID, true)


func _get_center_castle_slot() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	var game_scene := tree.get_first_node_in_group("game_scene")
	if game_scene == null:
		game_scene = tree.current_scene
	if game_scene == null:
		return null
	var map_layout: Node = game_scene.get("map_layout_node")
	if map_layout == null:
		map_layout = game_scene.get_node_or_null("WorldYSort/MapContainer/MapLayout")
	if map_layout == null:
		return null
	var raw_slots: Variant = map_layout.get("slots")
	if not (raw_slots is Array):
		return null
	var slots := raw_slots as Array
	if slots.is_empty():
		return null
	var center := Vector2.ZERO
	var counted := 0
	for slot_value in slots:
		var slot := slot_value as Node2D
		if slot == null:
			continue
		center += slot.global_position
		counted += 1
	if counted <= 0:
		return null
	center /= float(counted)
	var best_slot: Node2D = null
	var best_dist_sq := INF
	for slot_value in slots:
		var slot := slot_value as Node2D
		if slot == null:
			continue
		var d2 := slot.global_position.distance_squared_to(center)
		if d2 < best_dist_sq:
			best_dist_sq = d2
			best_slot = slot
	return best_slot


func _get_resource_core() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("ResourceCore")
