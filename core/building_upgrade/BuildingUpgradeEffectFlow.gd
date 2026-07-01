extends RefCounted
class_name BuildingUpgradeEffectFlow


func get_buddhist_temple_production_speed_multiplier(count: int) -> float:
	return 1.0 + (0.05 * float(count))


func get_buddhist_temple_troop_damage_multiplier(count: int) -> float:
	return 1.0 + (0.10 * float(count))


func get_buddhist_temple_spell_damage_multiplier(count: int) -> float:
	return 1.0 + (0.10 * float(count))


func get_active_concert_morale_bonus(count: int) -> int:
	return count * 10


func get_passive_concert_morale_bonus(count: int) -> int:
	return count * 5


func get_active_tesla_tower_spell_damage_multiplier(active_count: int) -> float:
	if active_count <= 0:
		return 1.0
	return 1.5
