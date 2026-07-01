extends RefCounted
class_name HeroRecruitment

## Рекрутинг героев
## Генерация ID, имен, расчет стоимости

## Constants
const SWORDSMAN_COST: float = 25.0
const ARCHER_COST: float = 120.0
const WARRIOR_WOMAN_COST: float = 600.0

var _hero_data: HeroData
var _hero_names: HeroNames

func _init(hero_data: HeroData) -> void:
	_hero_data = hero_data
	_hero_names = HeroNames.new()
	# Initialize used names from existing heroes
	_register_existing_heroes()

func _register_existing_heroes() -> void:
	if not _hero_data: return
	for hero_id in _hero_data.get_all_hero_ids():
		var hero = _hero_data.get_hero(hero_id)
		if hero.has("name"):
			_hero_names.register_existing_name(hero["name"])

func try_recruit_hero(type: String) -> Dictionary:
	var result = {
		"success": false,
		"hero_id": "",
		"name": "",
		"icon_id": "",
		"cost": 0.0,
		"person_id": "",
		"error": ""
	}
	
	var config = _get_hero_config(type)
	if config.is_empty():
		result["error"] = "Unknown hero type: %s" % type
		return result
	
	var cost = _calculate_recruitment_cost(type, config.base_cost)
	
	# Generate ID and Name
	var hero_id = _generate_unique_hero_id(type)
	var name = generate_random_hero_name(config.icon_id)
	
	result["success"] = true
	result["hero_id"] = hero_id
	result["name"] = name
	result["icon_id"] = config.icon_id
	result["cost"] = cost
	result["person_id"] = ""
	
	return result

func _get_hero_config(type: String) -> Dictionary:
	match type:
		"swordsman": return {"icon_id": "swordman", "base_cost": SWORDSMAN_COST}
		"archer": return {"icon_id": "archer", "base_cost": ARCHER_COST}
		"warrior_woman": return {"icon_id": "shieldmaiden", "base_cost": WARRIOR_WOMAN_COST}
	return {}

func _get_hero_count_by_type(type: String) -> int:
	var count = 0
	for id in _hero_data.get_all_hero_ids():
		if id.begins_with(type):
			count += 1
	return count

func _generate_unique_hero_id(type: String) -> String:
	var num = 1
	while num < 10000:
		var candidate_id = "%s_%d" % [type, num]
		if not _hero_data.has_hero(candidate_id):
			return candidate_id
		num += 1
	return "%s_%d" % [type, num]

func get_recruitment_cost(type: String) -> int:
	var config = _get_hero_config(type)
	if config.is_empty():
		return 0
	return int(_calculate_recruitment_cost(type, config.base_cost))

func _calculate_recruitment_cost(type: String, base_cost: float) -> float:
	var count = _get_hero_count_by_type(type)
	return base_cost * pow(2.0, count)

func generate_random_hero_name(icon_id: String) -> String:
	return _hero_names.generate_name(icon_id)
