extends RefCounted
class_name MapSlotFeedbackFlow


func on_hero_departed(slot, production, military_tracker, hero_id: String, update_unit_label: Callable) -> void:
	if production:
		production.on_hero_died(hero_id)
	if military_tracker and military_tracker.has_method("refresh_military_unit_labels_across_map"):
		military_tracker.refresh_military_unit_labels_across_map(slot, update_unit_label)


func on_production_completed(animations, outputs: Array, popup_spacing: float, popup_vertical_step: float) -> void:
	var count := outputs.size()
	for i in range(count):
		var output: Variant = outputs[i]
		var resource_id := ""
		var amount := 1
		if output is BuildingProductionEntry:
			resource_id = String(output.resource_id)
			amount = int(output.amount)
		elif output is Dictionary:
			resource_id = String(output.get("resource_id", ""))
			amount = int(output.get("amount", 1))
		else:
			continue
		var offset_x := 0.0
		var offset_y := 0.0
		if count > 1:
			var centered_index := float(i) - float(count - 1) * 0.5
			offset_x = centered_index * popup_spacing
			offset_y = -absf(centered_index) * popup_vertical_step
		show_resource_popup(animations, resource_id, amount, Vector2(offset_x, offset_y))


func on_trade_completed(animations, resource_id: String, amount: int) -> void:
	show_resource_popup(animations, resource_id, amount)


func show_resource_popup(animations, resource_id: String, amount: int = 1, position_offset: Vector2 = Vector2.ZERO) -> void:
	if animations == null:
		return
	animations.show_production_animation(resource_id, amount, position_offset)
