extends RefCounted
class_name HeroDamageFlow


func apply_damage(hero_combat, hero_id: String, amount: float, try_evade: Callable, on_spawn_replacement: Callable, on_hero_died: Callable, on_bus_hero_died: Callable, on_remove_hero: Callable, on_update_hero: Callable) -> bool:
	if try_evade.is_valid() and bool(try_evade.call(hero_id, amount)):
		return false
	var result: Dictionary = hero_combat.take_damage_with_amount(hero_id, amount)
	if bool(result.get("died", false)):
		if on_spawn_replacement.is_valid():
			on_spawn_replacement.call(hero_id)
		if on_hero_died.is_valid():
			on_hero_died.call(hero_id)
		if on_bus_hero_died.is_valid():
			on_bus_hero_died.call(hero_id)
		if on_remove_hero.is_valid():
			on_remove_hero.call(hero_id)
		return true
	if on_update_hero.is_valid():
		on_update_hero.call(hero_id, {})
	return false
