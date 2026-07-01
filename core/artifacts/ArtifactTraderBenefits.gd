extends RefCounted
class_name ArtifactTraderBenefits

const FREE_COUPON_ID := "free_coupon"
const SUSPICIOUS_PILE_ID := "suspicious_pile"
const FREE_COUPON_STATE_KEY := "trader_free_coupon_used"


func has_free_coupon_charge(active: Dictionary, state: Dictionary) -> bool:
	if not active.has(FREE_COUPON_ID):
		return false
	var artifact_state := _get_artifact_state(state, FREE_COUPON_ID)
	return not bool(artifact_state.get(FREE_COUPON_STATE_KEY, false))


func consume_free_coupon_charge(active: Dictionary, state: Dictionary) -> bool:
	if not has_free_coupon_charge(active, state):
		return false
	var artifact_state := _get_artifact_state(state, FREE_COUPON_ID)
	artifact_state[FREE_COUPON_STATE_KEY] = true
	state[FREE_COUPON_ID] = artifact_state
	return true


func has_extended_market_trades(active: Dictionary) -> bool:
	return active.has(SUSPICIOUS_PILE_ID)


func _get_artifact_state(state: Dictionary, artifact_id: String) -> Dictionary:
	var raw_state: Variant = state.get(artifact_id, {})
	if raw_state is Dictionary:
		return (raw_state as Dictionary).duplicate()
	return {}
