extends RefCounted
class_name ArtifactWorkingBuildingFlow

const ArtifactBuildingCombatHooksScript := preload("res://core/artifacts/ArtifactBuildingCombatHooks.gd")
const ArtifactRuntimeTargetBridgeScript := preload("res://core/artifacts/ArtifactRuntimeTargetBridge.gd")
const SpellDamageApplicatorScript := preload("res://scripts/effects/shared/SpellDamageApplicator.gd")

const SWEEPING_BLADE_ID := "sweeping_blade"
const SWEEPING_BLADE_BUILDING_IDS := {
	"tree": true,
	"sawmill": true,
}
const SWEEPING_BLADE_DAMAGE_PER_SECOND := 10.0

var _damage_applicator: RefCounted = SpellDamageApplicatorScript.new()
var _building_combat_hooks: RefCounted = ArtifactBuildingCombatHooksScript.new()
var _runtime_target_bridge: RefCounted = ArtifactRuntimeTargetBridgeScript.new()


func process_working_tick(delta: float, building_id: String, slot_index: int, active: Dictionary = {}) -> void:
	if delta <= 0.0:
		return
	var normalized_building_id := String(building_id).strip_edges().to_lower()
	if not SWEEPING_BLADE_BUILDING_IDS.has(normalized_building_id):
		return
	var active_artifacts := active
	if active_artifacts.is_empty():
		var artifact_core := _get_artifact_core()
		if artifact_core == null or not artifact_core.has_method("is_active"):
			return
		if not bool(artifact_core.call("is_active", SWEEPING_BLADE_ID)):
			return
	elif not active_artifacts.has(SWEEPING_BLADE_ID):
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var slot := _get_slot_node(tree, slot_index, normalized_building_id)
	if slot == null:
		return
	var target := _find_nearest_enemy(tree, slot.global_position)
	if target == null:
		return
	var damage := SWEEPING_BLADE_DAMAGE_PER_SECOND * delta
	if _building_combat_hooks != null and _building_combat_hooks.has_method("get_scaled_attacking_building_damage"):
		damage = float(_building_combat_hooks.call("get_scaled_attacking_building_damage", damage))
	if damage <= 0.0:
		return
	var attack_id := Time.get_ticks_msec() + int(slot.get_instance_id())
	if _damage_applicator != null and _damage_applicator.has_method("apply_damage"):
		_damage_applicator.call("apply_damage", target, damage, slot, attack_id)


func _find_nearest_enemy(tree: SceneTree, origin: Vector2) -> Node2D:
	if _runtime_target_bridge == null or not _runtime_target_bridge.has_method("collect_alive_enemies"):
		return null
	var candidates: Array[Node2D] = _runtime_target_bridge.call("collect_alive_enemies", tree)
	if candidates.is_empty():
		return null
	var best_target: Node2D = null
	var best_distance_sq := INF
	for candidate in candidates:
		if candidate == null or not is_instance_valid(candidate):
			continue
		var distance_sq := origin.distance_squared_to(candidate.global_position)
		if distance_sq < best_distance_sq:
			best_distance_sq = distance_sq
			best_target = candidate
	return best_target


func _get_slot_node(tree: SceneTree, slot_index: int, building_id: String) -> Node2D:
	if _runtime_target_bridge == null or not _runtime_target_bridge.has_method("get_slot_by_index"):
		return null
	return _runtime_target_bridge.call("get_slot_by_index", tree, slot_index, building_id)


func _get_artifact_core() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("ArtifactCore")
