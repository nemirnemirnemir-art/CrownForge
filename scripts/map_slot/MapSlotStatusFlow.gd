extends RefCounted
class_name MapSlotStatusFlow


func update_unit_label(ui, military_tracker, current_building_id: String) -> void:
	if ui == null or military_tracker == null:
		return
	var info: Dictionary = military_tracker.get_unit_label_info(current_building_id)
	if bool(info.get("show", false)):
		ui.update_unit_count(int(info.get("count", 0)), int(info.get("capacity", 0)))
	else:
		ui.hide_unit_count()


func update_durability_display(ui, production) -> void:
	if ui and production:
		ui.update_durability(int(production.get_durability()))


func on_building_upgrades_changed(changed_building_id: String, current_building_id: String, update_upgrade_stripe: Callable) -> void:
	if changed_building_id == current_building_id and update_upgrade_stripe.is_valid():
		update_upgrade_stripe.call()


func on_hero_produced(refresh_labels: Callable) -> void:
	if refresh_labels.is_valid():
		refresh_labels.call()
