extends RefCounted
class_name MainUIActionFlow

const TownAlchemyCraftScript := preload("res://core/town/TownAlchemyCraft.gd")


func open_smith(town_overlays) -> void:
	if town_overlays:
		town_overlays.open_smith()


func open_inventory(town_overlays) -> void:
	if town_overlays:
		town_overlays.open_storage_inventory()


func open_alchemy(town_overlays) -> void:
	if town_overlays:
		town_overlays.open_alchemy()


func restart_game(castle_core) -> void:
	if castle_core:
		castle_core.reset_game()


func run_debug_grant(economy_core, town_core, debug_ingredients: Array, qty: int) -> void:
	if economy_core:
		economy_core.add_gold(100000.0)
	if town_core:
		if town_core.has_method("debug_set_building_level"):
			town_core.debug_set_building_level("house", 50)
		town_core.add_test_population(50)
		var inv = town_core.get_town_inventory()
		if inv:
			for ing in debug_ingredients:
				var item_id: String = str(ing.get("id", ""))
				if item_id == "":
					continue
				var icon_path: String = str(ing.get("icon", ""))
				if icon_path == "":
					icon_path = str(TownAlchemyCraftScript.INGREDIENT_ICONS.get(item_id, ""))
				var item = ItemSystem.create_item(item_id, ItemSystem.ItemType.INGREDIENT, ItemSystem.Rarity.COMMON, icon_path, 0, 0, qty)
				inv.add_item(item)
