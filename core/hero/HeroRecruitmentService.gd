extends RefCounted
class_name HeroRecruitmentService

var _hero_data: HeroData
var _recruitment: HeroRecruitment

func _init(hero_data: HeroData, recruitment: HeroRecruitment) -> void:
	_hero_data = hero_data
	_recruitment = recruitment

func recruit(type: String) -> Dictionary:
	var result: Dictionary = _recruitment.try_recruit_hero(type)
	if not result.success:
		return result

	var town: Object = TownCore if is_instance_valid(TownCore) else null
	if town == null or not town.has_method("get_free_person"):
		result["success"] = false
		result["error"] = "TownCore not found"
		return result

	var person_id := str(town.get_free_person())
	if person_id == "":
		result["success"] = false
		result["error"] = "No free population to recruit!"
		return result

	var economy: Object = EconomyCore if is_instance_valid(EconomyCore) else null
	if economy == null or not economy.has_method("spend_gold"):
		result["success"] = false
		result["error"] = "EconomyCore not found"
		return result

	var cost: float = float(result.get("cost", 0.0))
	if not bool(economy.spend_gold(cost)):
		result["success"] = false
		result["error"] = "Not enough gold to recruit %s" % type
		return result

	result["person_id"] = person_id

	var base_hp: float = _hero_data.get_base_hp(type)
	var base_dmg: float = _hero_data.get_base_damage(type)

	if not _hero_data.create_hero(result.hero_id, result.name, result.icon_id, cost, person_id, base_hp, base_dmg):
		if economy.has_method("add_gold"):
			economy.add_gold(cost)
		result["success"] = false
		result["error"] = "Failed to create hero"
		return result

	if not town.has_method("convert_citizen_to_hero") or not bool(town.convert_citizen_to_hero(person_id)):
		_hero_data.remove_hero(result.hero_id)
		if economy.has_method("add_gold"):
			economy.add_gold(cost)
		result["success"] = false
		result["error"] = "Failed to convert citizen to hero"
		return result

	var hero := _hero_data.get_hero(result.hero_id)
	hero["is_hired"] = true

	return result

func hire_copy(base_id: String) -> Dictionary:
	var result := {
		"success": false,
		"hero_id": "",
		"name": "",
		"icon_id": "",
		"cost": 0.0,
		"person_id": "",
		"error": ""
	}

	if _hero_data == null or not _hero_data.has_hero(base_id):
		result["error"] = "Unknown hero base_id: %s" % base_id
		return result

	var template := _hero_data.get_hero(base_id)
	var cost: float = float(template.get("cost", 0.0))
	var base_hp: float = _hero_data.get_base_hp(base_id)
	var base_dmg: float = _hero_data.get_base_damage(base_id)
	result["cost"] = cost

	var new_id := ""
	var num := 1
	while num < 100000:
		var candidate := "%s_%d" % [base_id, num]
		if not _hero_data.has_hero(candidate):
			new_id = candidate
			break
		num += 1

	if new_id == "" or _hero_data.has_hero(new_id):
		result["error"] = "Failed to generate unique hero id"
		return result

	var icon_id := str(template.get("icon_id", ""))
	var new_name := str(template.get("name", base_id.capitalize()))

	if not _hero_data.create_hero(new_id, new_name, icon_id, cost, "", base_hp, base_dmg):
		result["error"] = "Failed to create hero"
		return result

	var hero := _hero_data.get_hero(new_id)
	hero["is_hired"] = true

	result["success"] = true
	result["hero_id"] = new_id
	result["name"] = new_name
	result["icon_id"] = icon_id
	result["person_id"] = ""

	return result

func on_hero_removed(hero: Dictionary) -> void:
	var town: Object = TownCore if is_instance_valid(TownCore) else null
	if town == null or not town.has_method("kill_citizen"):
		return

	var person_id := str(hero.get("person_id", ""))
	if person_id == "":
		return

	town.kill_citizen(person_id)
