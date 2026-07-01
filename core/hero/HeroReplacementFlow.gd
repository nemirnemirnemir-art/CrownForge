extends RefCounted
class_name HeroReplacementFlow


func remove_hero(hero_data, recruitment_service, hero_battle, hero_squad, hero_id: String, emit_squad_changed: Callable, emit_hero_removed: Callable, request_save: Callable) -> void:
	var hero = hero_data.remove_hero(hero_id)
	if hero.is_empty():
		return
	if recruitment_service:
		recruitment_service.on_hero_removed(hero)
	if hero_battle:
		var battle_heroes = hero_battle.get_heroes_in_battle()
		if hero_id in battle_heroes:
			hero_battle.replace_dead_hero(hero_id)
	if hero_squad:
		hero_squad.remove_from_squad(hero_id)
	if emit_squad_changed.is_valid():
		emit_squad_changed.call()
	if emit_hero_removed.is_valid():
		emit_hero_removed.call(hero_id)
	if request_save.is_valid():
		request_save.call()


func try_spawn_survivor_rider(hero_data, hero_squad, hero_battle, building_upgrade_core, dead_hero_id: String, ensure_template: Callable, hire_copy: Callable, update_hero: Callable, emit_auto_replaced: Callable, add_to_squad: Callable) -> String:
	if hero_data == null or not hero_data.has_hero(dead_hero_id):
		return ""
	var dead_hero: Dictionary = hero_data.get_hero(dead_hero_id)
	var dead_unit_id := String(dead_hero.get("icon_id", dead_hero.get("id", ""))).to_lower()
	if dead_unit_id != "horseman":
		return ""
	var building_id := String(dead_hero.get("produced_by_building_id", "")).to_lower()
	var slot_index := int(dead_hero.get("produced_by_slot_index", -1))
	if building_id != "stables" or slot_index < 0:
		return ""
	if building_upgrade_core == null or not building_upgrade_core.has_method("has_upgrade"):
		return ""
	if not bool(building_upgrade_core.has_upgrade(slot_index, "stables:2")):
		return ""
	if ensure_template.is_valid():
		ensure_template.call("rider", "Rider")
	if not hire_copy.is_valid():
		return ""
	var new_id: String = String(hire_copy.call("rider"))
	if new_id == "":
		return ""
	if update_hero.is_valid():
		update_hero.call(new_id, {
			"produced_by_building_id": dead_hero.get("produced_by_building_id", ""),
			"produced_by_building_type": dead_hero.get("produced_by_building_type", -1),
			"produced_by_slot_index": slot_index
		})
	var was_active: bool = hero_squad.is_in_squad(dead_hero_id) if hero_squad else false
	var replaced_in_battle: bool = hero_battle.replace_dead_hero_with(dead_hero_id, new_id) if hero_battle else false
	if replaced_in_battle:
		if emit_auto_replaced.is_valid():
			emit_auto_replaced.call(dead_hero_id, new_id)
	elif was_active and add_to_squad.is_valid():
		add_to_squad.call(new_id)
	return new_id
