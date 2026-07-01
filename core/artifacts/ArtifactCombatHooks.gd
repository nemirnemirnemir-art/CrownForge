extends RefCounted
class_name ArtifactCombatHooks

const STUNNING_MACE_ID := "stunning_mace"
const STUNNING_MACE_EVERY_N_ATTACKS := 20
const STUNNING_MACE_STUN_DURATION := 1.0


func try_apply_post_hit_stun(active: Dictionary, target: Variant, unit_id: String, attack_count: int, troop_core: Variant) -> void:
	if not active.has(STUNNING_MACE_ID):
		return
	if attack_count <= 0 or attack_count % STUNNING_MACE_EVERY_N_ATTACKS != 0:
		return
	if not _is_champion_unit(unit_id, troop_core):
		return
	if target == null or not is_instance_valid(target):
		return
	if not target.has_method("apply_stun"):
		return
	target.apply_stun(STUNNING_MACE_STUN_DURATION)


func _is_champion_unit(unit_id: String, troop_core: Variant) -> bool:
	if troop_core == null or not troop_core.has_method("get_unit_classes"):
		return false
	var raw_classes: Variant = troop_core.call("get_unit_classes", unit_id)
	if not (raw_classes is Array):
		return false
	return (raw_classes as Array).has(UnitConfig.UnitClass.CHAMPION)
