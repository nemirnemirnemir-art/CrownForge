extends RefCounted
class_name BuildingUpgradeBonusFlow


func get_scaled_multiplier(count: int, step: float) -> float:
	return 1.0 + (step * float(count))


func get_magic_ball_spell_damage_multiplier(active_count: int, has_upgrade: bool) -> float:
	if active_count <= 0:
		return 1.0
	var slot_multiplier := 1.5
	if has_upgrade:
		slot_multiplier += 0.3
	return slot_multiplier
