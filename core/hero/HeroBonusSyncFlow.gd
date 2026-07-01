extends RefCounted
class_name HeroBonusSyncFlow


func sync_after_troop_bonus_change(hero_data, get_total_stats: Callable, update_hero: Callable, emit_hp_changed: Callable, request_save: Callable = Callable()) -> void:
	if hero_data == null:
		return
	var changed := false
	for hero_id in hero_data.get_all_hero_ids():
		var hero: Dictionary = hero_data.get_hero(hero_id)
		if hero.is_empty():
			continue
		var old_max_hp: float = float(hero.get("maxHp", 10.0))
		var new_stats: Dictionary = get_total_stats.call(hero_id) if get_total_stats.is_valid() else {}
		var new_max_hp: float = float(new_stats.get("maxHp", 10.0))
		if not is_equal_approx(new_max_hp, old_max_hp):
			changed = true
		if update_hero.is_valid():
			update_hero.call(hero_id, {
				"maxHp": new_max_hp,
				"damage": float(new_stats.get("damage", 5.0))
			})
		if new_max_hp > old_max_hp:
			var diff := new_max_hp - old_max_hp
			var current_hp: float = float(hero.get("hp", 0.0))
			if current_hp > 0.0 and update_hero.is_valid():
				var new_current := minf(current_hp + diff, new_max_hp)
				update_hero.call(hero_id, {"hp": new_current})
				if emit_hp_changed.is_valid():
					emit_hp_changed.call(hero_id, new_current, new_max_hp)
		elif new_max_hp < old_max_hp:
			var current_hp_clamped: float = float(hero.get("hp", 0.0))
			if current_hp_clamped > new_max_hp and update_hero.is_valid():
				update_hero.call(hero_id, {"hp": new_max_hp})
				if emit_hp_changed.is_valid():
					emit_hp_changed.call(hero_id, new_max_hp, new_max_hp)
	if changed and request_save.is_valid():
		request_save.call()
