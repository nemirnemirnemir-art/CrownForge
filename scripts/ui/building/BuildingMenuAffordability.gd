extends RefCounted
class_name BuildingMenuAffordability

func update_affordability(menu: BuildingMenu) -> void:
	if not menu.container:
		return
	var seal_registry := menu._seal_registry()
	var building_registry := menu._building_registry()
	var town_core := menu._town_core()
	for child in menu.container.get_children():
		if child is BuildingIconTile:
			var tile := child as BuildingIconTile
			if seal_registry and seal_registry.get_seal(tile.building_id):
				tile.set_affordable(seal_registry.can_afford_seal(tile.building_id))
			elif building_registry:
				tile.set_affordable(building_registry.can_afford_building(tile.building_id))
			elif town_core:
				tile.set_affordable(town_core.can_build(tile.building_id))
