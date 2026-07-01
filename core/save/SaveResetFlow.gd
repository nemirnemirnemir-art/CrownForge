extends RefCounted
class_name SaveResetFlow


func reset_progress(stage_core, economy_core, hero_core, town_core, inventory, resource_core, gaze_core, artifact_core, forge_core, mine_core, damage_popup_pool, buildings, potions, perks, hospital, bonuses, save_manager, save_path: String, save_game: Callable) -> void:
	if economy_core:
		if economy_core.has_method("reset_progress"):
			economy_core.reset_progress()
		elif economy_core.has_method("reset"):
			economy_core.reset()
	if stage_core:
		if stage_core.has_method("reset_progress"):
			stage_core.reset_progress()
		elif stage_core.has_method("reset"):
			stage_core.reset()
	if hero_core:
		hero_core.reset()
	if town_core:
		town_core.reset()
	if inventory:
		if inventory.has_method("reset"):
			inventory.reset()
		else:
			inventory.items.clear()
	if resource_core:
		resource_core.reset()
	if gaze_core:
		gaze_core.reset()
	if artifact_core:
		artifact_core.reset()
	if forge_core:
		forge_core.reset()
	if mine_core:
		mine_core.reset()
	if damage_popup_pool:
		damage_popup_pool.reset_pool()
	if buildings and potions and perks and hospital and bonuses:
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
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		var game_scene = tree.get_first_node_in_group("game_scene")
		if game_scene and game_scene.has_method("reset_scene"):
			game_scene.reset_scene()
	if save_manager:
		save_manager.delete_file(save_path)
	if save_game.is_valid():
		save_game.call()
