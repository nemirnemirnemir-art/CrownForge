extends RefCounted
class_name ArtifactCastleHooks

const BROKEN_PENNY_ID := "broken_penny"
const GOLDEN_BALL_ID := "golden_ball"
const GOLDEN_BALL_USED_KEY := "depletion_heal_used"
const GOLDEN_BALL_MAX_USES := 5


func on_castle_damaged(active: Dictionary, amount: int, economy_core: Variant) -> void:
	if amount <= 0:
		return
	if not active.has(BROKEN_PENNY_ID):
		return
	if economy_core == null or not economy_core.has_method("add_gold"):
		return
	economy_core.call("add_gold", float(amount * 3))


func on_resource_building_depleted(active: Dictionary, state: Dictionary, castle_core: Variant) -> bool:
	if not active.has(GOLDEN_BALL_ID):
		return false
	if castle_core == null or not castle_core.has_method("heal"):
		return false
	var artifact_state := _get_artifact_state(state, GOLDEN_BALL_ID)
	var used := int(artifact_state.get(GOLDEN_BALL_USED_KEY, 0))
	if used >= GOLDEN_BALL_MAX_USES:
		return false
	artifact_state[GOLDEN_BALL_USED_KEY] = used + 1
	state[GOLDEN_BALL_ID] = artifact_state
	castle_core.call("heal", 10)
	return true


func _get_artifact_state(state: Dictionary, artifact_id: String) -> Dictionary:
	var raw_state: Variant = state.get(artifact_id, {})
	if raw_state is Dictionary:
		return (raw_state as Dictionary).duplicate(true)
	return {}
