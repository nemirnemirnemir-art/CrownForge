extends RefCounted
class_name MainUIResourceBarResolver

func resolve_resource_bar(resource_bar_unified: PanelContainer, owner: Control) -> Dictionary:
	var resolved_bar := resource_bar_unified
	var resolved_hbox: HBoxContainer = null
	if resolved_bar != null:
		resolved_hbox = resolved_bar.get_node_or_null("HBox") as HBoxContainer
	if resolved_hbox == null and owner != null:
		resolved_bar = owner.find_child("ResourceBarUnified", true, false) as PanelContainer
		if resolved_bar != null:
			resolved_hbox = resolved_bar.get_node_or_null("HBox") as HBoxContainer
	return {
		"resource_bar_unified": resolved_bar,
		"resource_bar_hbox": resolved_hbox,
	}
