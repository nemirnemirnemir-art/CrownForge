extends RefCounted
class_name MainUIStartupDisplayFlow

func update_all_display(refresh_callback: Callable, hero_hire) -> void:
	if not refresh_callback.is_null():
		refresh_callback.call()
	if hero_hire != null and hero_hire.has_method("update_hero_costs"):
		hero_hire.update_hero_costs()
