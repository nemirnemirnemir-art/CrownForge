extends RefCounted
class_name MapSlotMilitaryTracker

func _hero_core() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("HeroCore")

func _building_registry() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("BuildingRegistry")

func _building_upgrade_core() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("BuildingUpgradeCore")

func on_military_building_removed(removed_building_id: String, removed_slot_index: int = -1) -> void:
	if removed_building_id == "":
		return
	var hero_core := _hero_core()
	if hero_core == null:
		return

	var to_remove: Array[String] = []
	var to_unown: Array[String] = []

	for hero in hero_core.get("heroes").values():
		if not (hero is Dictionary):
			continue
		if not bool(hero.get("is_hired", false)):
			continue
		if bool(hero.get("is_summon", false)):
			continue
		if bool(hero.get("isDead", false)):
			continue
		var produced_id := str(hero.get("produced_by_building_id", ""))
		if produced_id != removed_building_id:
			continue
		if removed_slot_index >= 0 and int(hero.get("produced_by_slot_index", -1)) != removed_slot_index:
			continue
		var produced_type := int(hero.get("produced_by_building_type", -1))
		if produced_type != int(BuildingConfig.BuildingType.MILITARY):
			continue
		var hero_id := str(hero.get("id", ""))
		if hero_id == "":
			continue
		if bool(hero.get("isActive", false)):
			to_unown.append(hero_id)
		else:
			to_remove.append(hero_id)

	for hero_id in to_unown:
		hero_core.call("update_hero", hero_id, {
			"produced_by_building_id": "",
			"produced_by_building_type": -1
		})

	for hero_id in to_remove:
		hero_core.call("remove_hero", hero_id)

func get_unit_label_info(building_id: String) -> Dictionary:
	var building_registry := _building_registry()
	if not building_registry:
		return {"show": false}
	
	var config: BuildingConfig = building_registry.get_building(building_id)
	if config == null or config.building_type != BuildingConfig.BuildingType.MILITARY:
		return {"show": false}
	
	var unit_id := str(config.produced_unit_id).to_lower()
	if unit_id == "":
		return {"show": false}
	
	var totals := get_global_military_unit_totals(unit_id)
	var current_count := int(totals.get("count", 0))
	var total_capacity := int(totals.get("capacity", 0))
	if total_capacity <= 0:
		total_capacity = int(config.max_units)
	
	return {
		"show": true,
		"count": current_count,
		"capacity": total_capacity
	}

func get_global_military_unit_totals(unit_id: String) -> Dictionary:
	var target_unit := unit_id.to_lower()
	var total_count := 0
	var total_capacity := 0

	var hero_core := _hero_core()
	if hero_core:
		for hero_data in hero_core.get("heroes").values():
			if not (hero_data is Dictionary):
				continue
			var hero := hero_data as Dictionary
			if not bool(hero.get("is_hired", false)):
				continue
			if bool(hero.get("is_summon", false)):
				continue
			if bool(hero.get("isDead", false)):
				continue
			var hero_id := str(hero.get("id", ""))
			if hero_id == "":
				continue
			if resolve_unit_id_from_hero_id(hero_id) == target_unit:
				total_count += 1

	var tree := Engine.get_main_loop() as SceneTree
	var building_registry := _building_registry()
	if tree and tree.current_scene and building_registry:
		var map_layout := tree.current_scene.get_node_or_null("WorldYSort/MapContainer/MapLayout")
		if map_layout and "slots" in map_layout:
			for slot in map_layout.slots:
				if slot == null or not is_instance_valid(slot):
					continue
				if not ("current_building_id" in slot):
					continue
				var building_id := str(slot.current_building_id)
				if building_id == "":
					continue
				var cfg: BuildingConfig = building_registry.get_building(building_id)
				if cfg == null:
					continue
				if cfg.building_type != BuildingConfig.BuildingType.MILITARY:
					continue
				if str(cfg.produced_unit_id).to_lower() != target_unit:
					continue
				var slot_capacity := int(cfg.max_units)
				var upgrade_core := _building_upgrade_core()
				if upgrade_core != null and upgrade_core.has_method("get_capacity_bonus"):
					slot_capacity += int(upgrade_core.call("get_capacity_bonus", building_id))
				total_capacity += slot_capacity

	return {
		"count": total_count,
		"capacity": total_capacity,
	}

func resolve_unit_id_from_hero_id(hero_id: String) -> String:
	var id := hero_id.to_lower()
	if id.contains("_"):
		var parts := id.rsplit("_", true, 1)
		if parts.size() == 2 and String(parts[1]).is_valid_int():
			return String(parts[0])
	return id

func refresh_military_unit_labels_across_map(owner: Node2D, update_callback: Callable) -> void:
	var tree := owner.get_tree()
	if tree == null or tree.current_scene == null:
		update_callback.call()
		return

	var map_layout := tree.current_scene.get_node_or_null("WorldYSort/MapContainer/MapLayout")
	if map_layout == null or not ("slots" in map_layout):
		update_callback.call()
		return

	for slot in map_layout.slots:
		if slot == null or not is_instance_valid(slot):
			continue
		if slot.has_method("_update_unit_label"):
			slot._update_unit_label()
