extends RefCounted
class_name TownPerks

## Управление перками
## Разблокировка, покупка, проверка доступности

var _unlocked_perks: Array[String] = [] # Set of unlocked perk IDs
var _available_perks: Array[String] = [] # Perks that reached level requirement but must be bought separately
var _buildings_manager: TownBuildings

func initialize(buildings_manager: TownBuildings) -> void:
	_buildings_manager = buildings_manager

func get_unlocked_perks() -> Array:
	return _unlocked_perks

func is_perk_unlocked(perk_id: String) -> bool:
	return perk_id in _unlocked_perks

func get_available_perks() -> Array:
	return _available_perks

func purchase_perk(perk_id: String, cost: float = 0.0) -> bool:
	if not _available_perks.has(perk_id):
		return false
	if cost > 0.0:
		if not EconomyCore or not EconomyCore.can_afford(cost):
			return false
		EconomyCore.spend_gold(cost)
	_available_perks.erase(perk_id)
	if not _unlocked_perks.has(perk_id):
		_unlocked_perks.append(perk_id)
		EventBus.perk_unlocked.emit(perk_id)
		# print("[TownPerks] ✅ Purchased perk: %s" % perk_id)
	if SaveCore:
		SaveCore.request_save()
	return true

func check_unlocked_perks(building_id: String, level: int) -> void:
	if not _buildings_manager:
		return
	
	var data = _buildings_manager.get_building_config(building_id)
	if not data:
		return
	
	for unlock_info in data.unlocked_perks:
		var unlock_level = unlock_info.get("level", 999)
		var perk_id = unlock_info.get("perk_id", "")
		
		if level >= unlock_level and perk_id != "":
			if not (_unlocked_perks.has(perk_id) or _available_perks.has(perk_id)):
				_available_perks.append(perk_id)
				EventBus.perk_available.emit(perk_id)
				# print("[TownPerks] 🟡 Perk available for purchase: %s" % perk_id)

func set_unlocked_perks(perks: Array) -> void:
	_unlocked_perks.clear()
	for p in perks:
		_unlocked_perks.append(str(p))

func set_available_perks(perks: Array) -> void:
	_available_perks.clear()
	for p in perks:
		_available_perks.append(str(p))

