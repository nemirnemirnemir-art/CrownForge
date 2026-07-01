extends RefCounted
class_name PopulationBattlefieldQuery


func get_battlefield_occupied_count(hero_core: Node) -> int:
	if hero_core == null:
		return 0
	var total := 0
	var active_ids: Variant = hero_core.get("active_hero_ids") if hero_core.has_method("get") else []
	if not (active_ids is Array):
		return 0
	for hero_id_value in active_ids:
		var hero_id := String(hero_id_value)
		if hero_id == "" or not hero_core.has_method("get_hero"):
			continue
		var hero: Dictionary = hero_core.call("get_hero", hero_id)
		if hero.is_empty():
			continue
		if bool(hero.get("isDead", false)):
			continue
		total += 1
	return total


func get_available_field_capacity(hero_core: Node, population_core: Node) -> int:
	if population_core == null or not population_core.has_method("get_max_population"):
		return 999999
	var max_population := int(population_core.call("get_max_population"))
	return maxi(max_population - get_battlefield_occupied_count(hero_core), 0)


func has_field_capacity(hero_core: Node, population_core: Node) -> bool:
	return get_available_field_capacity(hero_core, population_core) > 0


func limit_hero_ids_to_available_capacity(hero_ids: Array, hero_core: Node, population_core: Node) -> Array:
	if hero_ids.is_empty():
		return []
	var available_capacity := get_available_field_capacity(hero_core, population_core)
	if available_capacity <= 0:
		return []
	if hero_ids.size() <= available_capacity:
		return hero_ids.duplicate()
	return hero_ids.slice(0, available_capacity)
