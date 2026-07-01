extends RefCounted
class_name MainUIOverlayFlow


func apply_overlay_visibility(town_overlays, hero_bar, hero_card) -> void:
	var overlay_visible := false
	if town_overlays:
		overlay_visible = town_overlays.is_any_overlay_visible()
	if hero_bar:
		hero_bar.visible = not overlay_visible
	if hero_card:
		hero_card.visible = not overlay_visible
