extends RefCounted
class_name TownMageTower

const MAGE_TOWER_SKILL_PRICES: Array[int] = [500, 1200, 2880, 6912, 16589, 39814, 95552, 229324, 550377, 1320904]

var _buildings: TownBuildings
var _upgrades: Dictionary = {}

func initialize(buildings: TownBuildings) -> void:
	_buildings = buildings
	_ensure_initialized()

func _ensure_initialized() -> void:
	if _upgrades.is_empty():
		_upgrades = {}

	if not _upgrades.has("skills_purchased"):
		_upgrades["skills_purchased"] = []

	var skills_arr: Array = _upgrades.get("skills_purchased", [])
	while skills_arr.size() < 10:
		skills_arr.append(false)
	_upgrades["skills_purchased"] = skills_arr

	# Mana system removed: drop any legacy keys from old saves
	if _upgrades.has("mana_regen_level"):
		_upgrades.erase("mana_regen_level")
	if _upgrades.has("max_mana_level"):
		_upgrades.erase("max_mana_level")

func get_skill_unlock_level(skill_index: int) -> int:
	return max(1, skill_index) * 5

func is_skill_unlocked(skill_index: int) -> bool:
	if skill_index == 7:
		return false
	if not _buildings:
		return false
	var required := get_skill_unlock_level(skill_index)
	return _buildings.get_building_level("mage_tower") >= required

func is_skill_purchased(skill_index: int) -> bool:
	_ensure_initialized()
	if skill_index < 1 or skill_index > 10:
		return false
	var skills_arr: Array = _upgrades.get("skills_purchased", [])
	if skills_arr.size() < 10:
		return false
	return bool(skills_arr[skill_index - 1])

func get_skill_price(skill_index: int) -> int:
	if skill_index < 1 or skill_index > 10:
		return 0
	if skill_index == 7:
		return 0
	return int(MAGE_TOWER_SKILL_PRICES[skill_index - 1])

func try_purchase_skill(skill_index: int) -> bool:
	_ensure_initialized()
	if skill_index < 1 or skill_index > 10:
		return false

	if skill_index == 7:
		return false

	if not is_skill_unlocked(skill_index):
		return false

	if is_skill_purchased(skill_index):
		return false

	var price: int = get_skill_price(skill_index)
	if price <= 0:
		return false

	if not EconomyCore or not EconomyCore.spend_gold(float(price)):
		return false

	var skills_arr: Array = _upgrades.get("skills_purchased", [])
	while skills_arr.size() < 10:
		skills_arr.append(false)
	skills_arr[skill_index - 1] = true
	_upgrades["skills_purchased"] = skills_arr

	if SaveCore:
		SaveCore.request_save()
	return true

func debug_unlock_all_skills() -> void:
	_ensure_initialized()
	var skills_arr: Array = _upgrades.get("skills_purchased", [])
	while skills_arr.size() < 10:
		skills_arr.append(false)

	for i in range(1, 11):
		if i == 7:
			skills_arr[i - 1] = false
		else:
			skills_arr[i - 1] = true

	_upgrades["skills_purchased"] = skills_arr
	if SaveCore:
		SaveCore.request_save()

func reset() -> void:
	_upgrades = {}
	_ensure_initialized()

func get_save_data() -> Dictionary:
	_ensure_initialized()
	return _upgrades

func load_save_data(data: Dictionary) -> void:
	if data is Dictionary:
		_upgrades = data
	_ensure_initialized()
