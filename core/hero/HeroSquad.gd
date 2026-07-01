extends RefCounted
class_name HeroSquad

## Управление отрядом героев
## Добавление/удаление из активного отряда

var active_hero_ids: Array[String] = []
var _hero_data: HeroData

func _init(hero_data: HeroData) -> void:
	_hero_data = hero_data

func add_to_squad(hero_id: String) -> bool:
	if not _hero_data.has_hero(hero_id):
		return false
	
	if hero_id in active_hero_ids:
		return false
	
	var hero = _hero_data.get_hero(hero_id)
	if hero.get("isDead", false):
		print("[HeroSquad] ⚠️ Cannot add dead hero %s to squad" % hero_id)
		return false
	
	active_hero_ids.append(hero_id)
	_hero_data.update_hero(hero_id, {"isActive": true})
	return true

func remove_from_squad(hero_id: String) -> void:
	if hero_id in active_hero_ids:
		active_hero_ids.erase(hero_id)
		if _hero_data.has_hero(hero_id):
			_hero_data.update_hero(hero_id, {"isActive": false})

func get_active_heroes() -> Array[Dictionary]:
	var active: Array[Dictionary] = []
	for hero_id in active_hero_ids:
		if _hero_data.has_hero(hero_id):
			var hero: Dictionary = _hero_data.get_hero(hero_id)
			if not hero.get("isDead", false) and not hero.get("isRemoved", false):
				active.append(hero)
	return active

func clear_squad() -> void:
	active_hero_ids.clear()

func is_in_squad(hero_id: String) -> bool:
	return hero_id in active_hero_ids

func reset() -> void:
	clear_squad()
	# print("[HeroSquad] Reset complete")

