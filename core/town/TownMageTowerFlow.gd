extends RefCounted
class_name TownMageTowerFlow


func debug_unlock_all_mage_tower_skills(mage_tower) -> void:
	if mage_tower and mage_tower.has_method("debug_unlock_all_skills"):
		mage_tower.debug_unlock_all_skills()


func get_mage_tower_skill_unlock_level(mage_tower, skill_index: int) -> int:
	return mage_tower.get_skill_unlock_level(skill_index) if mage_tower else max(1, skill_index) * 5


func is_mage_tower_skill_unlocked(mage_tower, skill_index: int) -> bool:
	return mage_tower.is_skill_unlocked(skill_index) if mage_tower else false


func is_mage_tower_skill_purchased(mage_tower, skill_index: int) -> bool:
	return mage_tower.is_skill_purchased(skill_index) if mage_tower else false


func get_mage_tower_skill_price(mage_tower, skill_index: int) -> int:
	return mage_tower.get_skill_price(skill_index) if mage_tower else 0


func try_purchase_mage_tower_skill(mage_tower, skill_index: int) -> bool:
	return mage_tower.try_purchase_skill(skill_index) if mage_tower else false
