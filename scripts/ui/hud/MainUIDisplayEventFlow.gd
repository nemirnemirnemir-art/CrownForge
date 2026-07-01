extends RefCounted
class_name MainUIDisplayEventFlow

func on_gold_changed(new_amount: float, set_label: Callable, hero_hire) -> void:
	if not set_label.is_null():
		set_label.call("gold", int(new_amount))
	if hero_hire != null and hero_hire.has_method("update_hero_costs"):
		hero_hire.update_hero_costs()

func on_stage_changed(refresh_callback: Callable, hero_hire) -> void:
	if not refresh_callback.is_null():
		refresh_callback.call()
	if hero_hire != null and hero_hire.has_method("update_hero_costs"):
		hero_hire.update_hero_costs()

func on_resource_changed(resource_id: String, amount: int, set_label: Callable) -> void:
	if not set_label.is_null():
		set_label.call(resource_id, amount)
