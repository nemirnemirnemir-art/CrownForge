extends RefCounted
class_name MainUIOverlayTargetBridge

func find_overlay_targets(tree: SceneTree) -> Dictionary:
	if tree == null:
		return {"hero_bar": null, "hero_card": null}
	return {
		"hero_bar": tree.get_first_node_in_group("hero_bar"),
		"hero_card": tree.get_first_node_in_group("hero_card"),
	}

func apply_overlay_visibility(tree: SceneTree, overlay_flow, town_overlays) -> void:
	if overlay_flow == null:
		return
	var targets := find_overlay_targets(tree)
	overlay_flow.apply_overlay_visibility(
		town_overlays,
		targets.get("hero_bar", null),
		targets.get("hero_card", null)
	)
