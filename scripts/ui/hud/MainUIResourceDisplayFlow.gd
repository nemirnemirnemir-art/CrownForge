extends RefCounted
class_name MainUIResourceDisplayFlow


func set_resource_label(resource_labels: Dictionary, resource_id: String, value: Variant) -> void:
	var label = resource_labels.get(resource_id, null)
	if label:
		label.text = str(value)


func refresh_all_resources(resource_labels: Dictionary, display_order: Array, economy_core, resource_core) -> void:
	if economy_core:
		set_resource_label(resource_labels, "gold", int(economy_core.get_gold()))
	if resource_core:
		for resource_id in display_order:
			if resource_id == "gold":
				continue
			set_resource_label(resource_labels, str(resource_id), resource_core.get_resource(str(resource_id)))
