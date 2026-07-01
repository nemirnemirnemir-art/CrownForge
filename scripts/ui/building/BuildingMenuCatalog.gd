extends RefCounted
class_name BuildingMenuCatalog

const BuildingIconTileScene: PackedScene = preload("res://scenes/ui/town/BuildingIconTile.tscn")

func refresh_building_list(menu: BuildingMenu) -> void:
	var building_registry := menu._building_registry()
	var town_core := menu._town_core()
	var seal_registry := menu._seal_registry()
	if menu._current_category == -1:
		if building_registry:
			if building_registry.has_method("get_building_ids_for_menu"):
				menu._building_ids = building_registry.get_building_ids_for_menu(-1)
			else:
				menu._building_ids = building_registry.get_all_building_ids()
		else:
			menu._building_ids = town_core.get_all_building_ids()
	elif menu._current_category == 99:
		if seal_registry:
			menu._building_ids = seal_registry.get_all_seal_ids()
			menu._building_ids.sort_custom(func(a, b):
				var sa = seal_registry.get_seal(a)
				var sb = seal_registry.get_seal(b)
				if sa and sb:
					return sa.tier < sb.tier
				return a < b
			)
	else:
		menu._building_ids.clear()
		if building_registry:
			if building_registry.has_method("get_building_ids_for_menu"):
				menu._building_ids = building_registry.get_building_ids_for_menu(menu._current_category)
			else:
				var filtered: Array = building_registry.get_buildings_by_category(menu._current_category as BuildingConfig.BuildingCategory)
				for config in filtered:
					menu._building_ids.append(config.building_id)
	if menu._current_category != 99:
		menu._building_ids.sort()

func refresh_tiles_for_page(menu: BuildingMenu) -> void:
	if not menu.container:
		return
	
	for child in menu.container.get_children():
		child.queue_free()
	
	var start_index: int = menu._current_page * menu.TILES_PER_PAGE
	var end_index: int = min(start_index + menu.TILES_PER_PAGE, menu._building_ids.size())
	
	for i in range(start_index, end_index):
		var id: String = menu._building_ids[i]
		var tile = BuildingIconTileScene.instantiate()
		menu.container.add_child(tile)
		
		var config = null
		var building_registry := menu._building_registry()
		var town_core := menu._town_core()
		var seal_registry := menu._seal_registry()
		if building_registry:
			config = building_registry.get_building(id)
		if not config and town_core:
			config = town_core.get_building_config(id)
		if not config and seal_registry:
			config = seal_registry.get_seal(id)
		
		if tile and tile.has_method("setup"):
			tile.setup(id, config)
		if tile and tile.has_signal("tile_pressed"):
			tile.tile_pressed.connect(menu._on_tile_pressed)
		
		if tile.has_signal("hover_started"):
			tile.hover_started.connect(menu._on_tile_hover_started)
		if tile.has_signal("hover_ended"):
			tile.hover_ended.connect(menu._on_tile_hover_ended)
		if tile.has_signal("drag_started"):
			tile.drag_started.connect(menu._on_tile_drag_started)

func get_max_page(menu: BuildingMenu) -> int:
	if menu._building_ids.is_empty():
		return 0
	return max(0, int(ceil(float(menu._building_ids.size()) / float(menu.TILES_PER_PAGE))) - 1)

func ensure_building_visible(menu: BuildingMenu, building_id: String) -> void:
	var idx: int = menu._building_ids.find(building_id)
	if idx == -1:
		return
	var target_page: int = int(idx / float(menu.TILES_PER_PAGE))
	if target_page != menu._current_page:
		menu._current_page = target_page
		menu._refresh_menu()

func update_nav_buttons(menu: BuildingMenu) -> void:
	if menu.prev_button:
		menu.prev_button.disabled = (menu._current_page <= 0)
	if menu.next_button:
		menu.next_button.disabled = (menu._current_page >= get_max_page(menu))
