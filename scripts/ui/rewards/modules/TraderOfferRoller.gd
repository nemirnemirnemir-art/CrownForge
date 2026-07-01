extends RefCounted
class_name TraderOfferRoller

const BuildingUpgradeIconResolverScript := preload("res://scripts/ui/town/buildings/BuildingUpgradeIconResolver.gd")

func roll_offers(menu: Control, offer_generator, ui_builder, tree: SceneTree, building_registry, artifact_catalog, artifact_core, building_upgrade_core, load_spell_config: Callable) -> void:
	_roll_buildings(menu, offer_generator, ui_builder, building_registry)
	_roll_artifacts(menu, offer_generator, ui_builder, artifact_catalog, artifact_core)
	_roll_building_upgrades(menu, offer_generator, ui_builder, tree, building_registry, building_upgrade_core)
	_roll_resources(menu, offer_generator, ui_builder)
	_roll_spells(menu, offer_generator, ui_builder, load_spell_config)
	_roll_troop_section(menu, offer_generator, ui_builder, tree, building_registry, building_upgrade_core)


func _roll_buildings(menu, offer_generator, ui_builder, building_registry) -> void:
	var tiles: Array = menu._collect_tiles(menu.buildings_grid)
	var ids: Array[String] = offer_generator.roll_building_ids(building_registry)
	for i in range(tiles.size()):
		var tile = tiles[i]
		var building_id := ids[i] if i < ids.size() else ""
		if building_id == "":
			ui_builder.setup_empty_tile(tile)
			continue
		var icon: Texture2D = building_registry.get_building_icon(building_id) if building_registry != null else null
		if icon == null:
			icon = ui_builder.make_placeholder_icon(building_id)
		var price: int = offer_generator.get_building_price(building_id, menu.building_price, building_registry)
		if "icon_size_override" in tile:
			tile.icon_size_override = Vector2(144, 144)
		tile.setup("building", building_id, icon, price)


func _roll_artifacts(menu, offer_generator, ui_builder, artifact_catalog, artifact_core) -> void:
	var tiles: Array = menu._collect_tiles(menu.artifacts_grid)
	var ids: Array[String] = offer_generator.roll_artifact_ids(artifact_catalog, artifact_core)
	for i in range(tiles.size()):
		var tile = tiles[i]
		var artifact_id := ids[i] if i < ids.size() else ""
		if artifact_id == "":
			ui_builder.setup_empty_tile(tile)
			continue
		var icon: Texture2D = null
		if artifact_catalog != null:
			var def: Dictionary = artifact_catalog.get_def(artifact_id)
			var icon_path := String(def.get("icon", ""))
			if icon_path != "" and ResourceLoader.exists(icon_path):
				icon = load(icon_path) as Texture2D
		if icon == null:
			icon = ui_builder.make_placeholder_icon(artifact_id)
		tile.setup("artifact", artifact_id, icon, menu.artifact_price)


func _roll_building_upgrades(menu, offer_generator, ui_builder, tree: SceneTree, building_registry, building_upgrade_core) -> void:
	var tiles: Array = menu._collect_tiles(menu.building_upgrades_grid)
	var building_upgrade_data_script = load("res://scripts/ui/town/buildings/BuildingUpgradeData.gd")
	var offers: Array = offer_generator.roll_building_upgrades(tree, building_upgrade_data_script, building_upgrade_core)
	for i in range(tiles.size()):
		var tile = tiles[i]
		var payload: Variant = offers[i] if i < offers.size() else null
		if payload == null:
			ui_builder.setup_empty_tile(tile)
			continue
		var icon: Texture2D = null
		if payload is Dictionary:
			var building_id := String((payload as Dictionary).get("building_id", ""))
			var upgrade_idx := int((payload as Dictionary).get("upgrade_index", 0))
			icon = BuildingUpgradeIconResolverScript.get_icon(building_id, upgrade_idx)
			if icon == null and building_registry != null and building_id != "":
				icon = building_registry.get_building_icon(building_id)
		if icon == null:
			icon = ui_builder.make_placeholder_icon("upgrade")
		tile.setup("building_upgrade", payload, icon, menu.building_upgrade_price)


func _roll_resources(menu, offer_generator, ui_builder) -> void:
	var tiles: Array = menu._collect_tiles(menu.resources_grid)
	var ids: Array[String] = offer_generator.roll_resource_ids()
	for i in range(tiles.size()):
		var tile = tiles[i]
		var resource_id := ids[i] if i < ids.size() else ""
		if resource_id == "":
			ui_builder.setup_empty_tile(tile)
			continue
		var icon: Texture2D = menu._get_resource_icon(resource_id)
		if icon == null:
			icon = ui_builder.make_placeholder_icon(resource_id)
		tile.setup("resource", resource_id, icon, menu.resource_price)


func _roll_spells(menu, offer_generator, ui_builder, load_spell_config: Callable) -> void:
	var tiles: Array = menu._collect_tiles(menu.spells_grid)
	var ids: Array[String] = offer_generator.roll_spell_ids()
	for i in range(tiles.size()):
		var tile = tiles[i]
		var spell_id := ids[i] if i < ids.size() else ""
		if spell_id == "":
			ui_builder.setup_empty_tile(tile)
			continue
		var icon: Texture2D = null
		if load_spell_config.is_valid():
			var config = load_spell_config.call(spell_id)
			if config != null and config.has_method("get_icon_or_placeholder"):
				icon = config.get_icon_or_placeholder()
		if icon == null:
			icon = ui_builder.make_placeholder_icon(spell_id)
		tile.setup("spell", spell_id, icon, menu.spell_price)


func roll_building_upgrades_section(menu, offer_generator, ui_builder, tree: SceneTree, building_registry, building_upgrade_core) -> void:
	if menu != null and menu.has_method("_mark_delegated"):
		menu.call("_mark_delegated", "building_upgrades")
	_roll_building_upgrades(menu, offer_generator, ui_builder, tree, building_registry, building_upgrade_core)


func _roll_troop_section(menu, offer_generator, ui_builder, tree: SceneTree, building_registry, building_upgrade_core) -> void:
	var tiles: Array = menu._collect_tiles(menu.troop_row_grid)
	if tiles.is_empty():
		return
	var tt_icon: Texture2D = ui_builder.make_placeholder_icon("troop_training")
	tiles[0].setup("troop_training", "troop_training", tt_icon, 80)

	var building_upgrade_data_script = load("res://scripts/ui/town/buildings/BuildingUpgradeData.gd")
	var offers: Array = offer_generator.roll_building_upgrades(tree, building_upgrade_data_script, building_upgrade_core)
	for i in range(2):
		var tile_index := i + 1
		if tile_index >= tiles.size():
			continue
		var tile = tiles[tile_index]
		if i >= offers.size():
			ui_builder.setup_empty_tile(tile)
			continue
		var payload: Variant = offers[i]
		var icon: Texture2D = null
		if payload is Dictionary:
			var building_id := String((payload as Dictionary).get("building_id", ""))
			var upgrade_idx := int((payload as Dictionary).get("upgrade_index", 0))
			icon = BuildingUpgradeIconResolverScript.get_icon(building_id, upgrade_idx)
			if icon == null and building_registry != null and building_id != "":
				icon = building_registry.get_building_icon(building_id)
		if icon == null:
			icon = ui_builder.make_placeholder_icon("upgrade")
		tile.setup("building_upgrade", payload, icon, menu.building_upgrade_price)


func roll_troop_section(menu, offer_generator, ui_builder, tree: SceneTree, building_registry, building_upgrade_core) -> void:
	if menu != null and menu.has_method("_mark_delegated"):
		menu.call("_mark_delegated", "troop_section")
	_roll_troop_section(menu, offer_generator, ui_builder, tree, building_registry, building_upgrade_core)
