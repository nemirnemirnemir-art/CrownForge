extends RefCounted
class_name HeroPersistenceFlow


func get_save_data(hero_data, hero_squad, hero_buffs) -> Dictionary:
	return {
		"heroes": hero_data.heroes if hero_data else {},
		"active_hero_ids": hero_squad.active_hero_ids if hero_squad else [],
		"hero_buffs": hero_buffs.hero_buffs if hero_buffs else {}
	}


func load_save_data(data: Dictionary, hero_data, hero_squad, hero_buffs, emit_squad_changed: Callable) -> void:
	if hero_data and data.has("heroes"):
		hero_data.heroes = data["heroes"]
	if hero_squad and data.has("active_hero_ids"):
		var filtered_active_ids: Array[String] = []
		for id in data["active_hero_ids"]:
			var hero_id_str := str(id)
			if hero_data.has_hero(hero_id_str):
				var hero = hero_data.get_hero(hero_id_str)
				if not hero.get("isDead", false):
					filtered_active_ids.append(hero_id_str)
				else:
					hero_data.update_hero(hero_id_str, {"isActive": false})
		hero_squad.active_hero_ids = filtered_active_ids
	if hero_data:
		for hero_id in hero_data.get_all_hero_ids():
			hero_data.validate_equipment_structure(hero_id)
	if hero_buffs and data.has("hero_buffs"):
		hero_buffs.hero_buffs = data["hero_buffs"]
	if hero_data:
		hero_data.revalidate_all_heroes()
	if emit_squad_changed.is_valid():
		emit_squad_changed.call()
