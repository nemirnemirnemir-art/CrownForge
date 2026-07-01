extends RefCounted
class_name HeroBattleFlow


func add_to_squad(hero_squad, hero_id: String, emit_squad_changed: Callable, request_save: Callable) -> bool:
	if hero_squad == null:
		return false
	if hero_squad.add_to_squad(hero_id):
		if emit_squad_changed.is_valid():
			emit_squad_changed.call()
		if request_save.is_valid():
			request_save.call()
		return true
	return false


func remove_from_squad(hero_squad, hero_id: String, emit_squad_changed: Callable, request_save: Callable) -> void:
	if hero_squad == null:
		return
	hero_squad.remove_from_squad(hero_id)
	if emit_squad_changed.is_valid():
		emit_squad_changed.call()
	if request_save.is_valid():
		request_save.call()


func start_battle_with_heroes(hero_battle, hero_ids: Array, emit_battle_started: Callable, emit_squad_changed: Callable) -> bool:
	if hero_battle == null:
		return false
	if hero_battle.start_battle_with_heroes(hero_ids):
		if emit_battle_started.is_valid():
			emit_battle_started.call(hero_battle.get_heroes_in_battle())
		if emit_squad_changed.is_valid():
			emit_squad_changed.call()
		return true
	return false


func end_current_battle(hero_battle, is_victory: bool, emit_battle_ended: Callable, emit_squad_changed: Callable) -> void:
	if hero_battle == null:
		return
	var surviving: Array[String] = hero_battle.end_current_battle(is_victory)
	if emit_battle_ended.is_valid():
		emit_battle_ended.call(surviving)
	if emit_squad_changed.is_valid():
		emit_squad_changed.call()


func replace_dead_hero(hero_battle, dead_id: String, emit_auto_replaced: Callable) -> String:
	if hero_battle == null:
		return ""
	var new_id: String = hero_battle.replace_dead_hero(dead_id)
	if new_id != "" and emit_auto_replaced.is_valid():
		emit_auto_replaced.call(dead_id, new_id)
	return new_id
