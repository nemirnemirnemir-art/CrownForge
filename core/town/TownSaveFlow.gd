extends RefCounted
class_name TownSaveFlow


func get_save_data(buildings, potions, perks, inventory, shop, alchemy_craft, mage_tower) -> Dictionary:
	return {
		"buildings": buildings.get_buildings(),
		"potions": potions.get_global_potions(),
		"potion_timer": potions.get_potion_timer(),
		"unlocked_perks": perks.get_unlocked_perks(),
		"available_perks": perks.get_available_perks(),
		"inventory": inventory.get_save_data(),
		"townhall_shop": shop.get_save_data() if shop else {},
		"alchemy_craft": alchemy_craft.get_save_data() if alchemy_craft else {},
		"mage_tower_upgrades": mage_tower.get_save_data() if mage_tower else {}
	}


func load_save_data(data: Dictionary, buildings, potions, perks, inventory, shop, alchemy_craft, mage_tower, bonuses) -> void:
	if data.has("buildings"):
		buildings.set_buildings(data["buildings"])
	if data.has("potions"):
		potions.set_potions(data["potions"])
	if data.has("potion_timer"):
		potions.set_potion_timer(data["potion_timer"])
	if data.has("unlocked_perks"):
		perks.set_unlocked_perks(data["unlocked_perks"])
	if data.has("available_perks"):
		perks.set_available_perks(data["available_perks"])
	if data.has("inventory"):
		inventory.load_save_data(data["inventory"])
	if data.has("townhall_shop") and data["townhall_shop"] is Dictionary and shop:
		shop.load_save_data(data["townhall_shop"])
	if data.has("alchemy_craft") and data["alchemy_craft"] is Dictionary and alchemy_craft:
		alchemy_craft.load_save_data(data["alchemy_craft"])
	if data.has("mage_tower_upgrades") and data["mage_tower_upgrades"] is Dictionary and mage_tower:
		mage_tower.load_save_data(data["mage_tower_upgrades"])
	bonuses.invalidate_cache()
	bonuses.get_global_defense_bonus()


func reset(buildings, potions, perks, inventory, shop, alchemy_craft, mage_tower, hospital, bonuses) -> void:
	var default_buildings := {}
	for id in buildings.get_building_registry():
		var init_level := 0
		if id == "town_hall":
			init_level = 1
		default_buildings[id] = {"level": init_level, "slots": {}, "workers": []}
	buildings.set_buildings(default_buildings)
	potions.set_potions(0)
	potions.set_potion_timer(0.0)
	perks.set_unlocked_perks([])
	perks.set_available_perks([])
	hospital.set_hospital_timer(0.0)
	bonuses.invalidate_cache()
	inventory.initialize()
	if shop:
		shop.reset()
	if mage_tower:
		mage_tower.reset()
	if alchemy_craft:
		alchemy_craft.reset()
