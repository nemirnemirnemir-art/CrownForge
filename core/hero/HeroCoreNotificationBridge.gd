extends RefCounted
class_name HeroCoreNotificationBridge


func emit_updated(hero_data, hero_id: String, emit_hero_updated: Callable) -> bool:
	if hero_data == null:
		return false
	if not emit_hero_updated.is_valid():
		return false
	emit_hero_updated.call(hero_id, hero_data.get_hero(hero_id))
	return true


func emit_updated_and_save(hero_data, hero_id: String, emit_hero_updated: Callable, request_save: Callable) -> bool:
	if not emit_updated(hero_data, hero_id, emit_hero_updated):
		return false
	if request_save.is_valid():
		request_save.call()
	return true
