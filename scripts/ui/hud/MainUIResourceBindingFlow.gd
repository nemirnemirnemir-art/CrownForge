extends RefCounted
class_name MainUIResourceBindingFlow

func collect_resource_labels(resource_bar_hbox: HBoxContainer, display_order: Array) -> Dictionary:
	var resource_labels: Dictionary = {}
	if resource_bar_hbox == null:
		return resource_labels
	for resource_id in display_order:
		var container: Control = resource_bar_hbox.get_node_or_null("Resource_%s" % resource_id)
		if not container:
			continue
		var label: Label = container.get_node_or_null("ValueLabel")
		if label == null:
			label = container.find_child("ValueLabel", true, false) as Label
		if label:
			resource_labels[str(resource_id)] = label
	return resource_labels
