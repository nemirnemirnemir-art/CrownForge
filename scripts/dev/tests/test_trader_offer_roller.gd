extends SceneTree

const ROLLER_PATH := "res://scripts/ui/rewards/modules/TraderOfferRoller.gd"


class FakeTile:
	extends Control

	var setup_calls: Array[Dictionary] = []
	var purchased_state: bool = false
	var icon_size_override: Vector2 = Vector2.ZERO

	func setup(kind: String, payload: Variant, icon: Texture2D, price: int) -> void:
		setup_calls.append({
			"kind": kind,
			"payload": payload,
			"icon": icon,
			"price": price,
		})

	func set_purchased(value: bool) -> void:
		purchased_state = value


class FakeBuildingRegistry:
	extends RefCounted

	var icon_requests: Array[String] = []

	func get_building_icon(building_id: String) -> Texture2D:
		icon_requests.append(building_id)
		return GradientTexture2D.new()


class FakeArtifactCatalog:
	extends RefCounted

	func get_def(_artifact_id: String) -> Dictionary:
		return {"icon": ""}


class FakeOfferGenerator:
	extends RefCounted

	var building_registry_seen: Variant = null
	var artifact_catalog_seen: Variant = null
	var artifact_core_seen: Variant = null
	var building_upgrade_tree_seen: Variant = null
	var building_upgrade_core_seen: Variant = null
	var building_price_calls: Array[String] = []

	func roll_building_ids(building_registry: Object) -> Array[String]:
		building_registry_seen = building_registry
		return ["hut"]

	func get_building_price(building_id: String, _fallback_price: int, _building_registry: Object) -> int:
		building_price_calls.append(building_id)
		return 33

	func roll_artifact_ids(artifact_catalog: Object, artifact_core: Object) -> Array[String]:
		artifact_catalog_seen = artifact_catalog
		artifact_core_seen = artifact_core
		return ["orb"]

	func roll_building_upgrades(tree: SceneTree, _building_upgrade_data_script: Script, building_upgrade_core: Object) -> Array:
		building_upgrade_tree_seen = tree
		building_upgrade_core_seen = building_upgrade_core
		return [
			{"slot_index": 2, "building_id": "hut", "upgrade_index": 1, "upgrade_id": "hut:1"},
			{"slot_index": 5, "building_id": "farm", "upgrade_index": 0, "upgrade_id": "farm:0"},
		]

	func roll_resource_ids() -> Array[String]:
		return ["wood"]

	func roll_spell_ids() -> Array[String]:
		return ["meteorite"]


class FakeUIBuilder:
	extends RefCounted

	var empty_calls: int = 0
	var placeholder_requests: Array[String] = []

	func setup_empty_tile(tile: Control) -> void:
		empty_calls += 1
		if tile.has_method("setup"):
			tile.call("setup", "", null, null, 0)
		if tile.has_method("set_purchased"):
			tile.call("set_purchased", true)

	func make_placeholder_icon(key: String) -> Texture2D:
		placeholder_requests.append(key)
		return GradientTexture2D.new()


class FakeSpellConfig:
	extends RefCounted

	var icon: Texture2D = GradientTexture2D.new()

	func get_icon_or_placeholder() -> Texture2D:
		return icon


class FakeMenu:
	extends Control

	var building_price: int = 40
	var artifact_price: int = 70
	var building_upgrade_price: int = 60
	var resource_price: int = 20
	var spell_price: int = 30

	var buildings_grid: GridContainer
	var artifacts_grid: GridContainer
	var building_upgrades_grid: GridContainer
	var resources_grid: GridContainer
	var spells_grid: GridContainer
	var troop_row_grid: GridContainer

	var resource_icon_requests: Array[String] = []
	var spell_config_requests: Array[String] = []
	var delegated_calls: Array[String] = []

	func _init() -> void:
		buildings_grid = _make_grid(2)
		artifacts_grid = _make_grid(1)
		building_upgrades_grid = _make_grid(1)
		resources_grid = _make_grid(1)
		spells_grid = _make_grid(1)
		troop_row_grid = _make_grid(3)

	func _make_grid(tile_count: int) -> GridContainer:
		var grid := GridContainer.new()
		for _i in range(tile_count):
			grid.add_child(FakeTile.new())
		return grid

	func _collect_tiles(grid: GridContainer) -> Array:
		var out: Array = []
		for child in grid.get_children():
			out.append(child)
		return out

	func _get_resource_icon(resource_id: String) -> Texture2D:
		resource_icon_requests.append(resource_id)
		return GradientTexture2D.new()

	func _load_spell_config(spell_id: String) -> Variant:
		spell_config_requests.append(spell_id)
		return FakeSpellConfig.new()

	func _mark_delegated(section: String) -> void:
		delegated_calls.append(section)


func _init() -> void:
	call_deferred("_run_test")


func _assert(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("[test_trader_offer_roller] %s" % message)
	quit(1)
	return false


func _run_test() -> void:
	var roller_script := load(ROLLER_PATH)
	if not _assert(roller_script != null, "failed to load TraderOfferRoller.gd"):
		return

	var roller = roller_script.new()
	if not _assert(roller != null, "failed to instantiate TraderOfferRoller"):
		return
	if not _assert(not roller.has_method("open"), "roller must not own menu open flow"):
		return
	if not _assert(not roller.has_method("close_menu"), "roller must not own menu close flow"):
		return
	if not _assert(not roller.has_method("_on_tile_buy_pressed"), "roller must not own transaction flow"):
		return

	var menu := FakeMenu.new()
	get_root().add_child(menu)
	var offer_generator := FakeOfferGenerator.new()
	var ui_builder := FakeUIBuilder.new()
	var building_registry := FakeBuildingRegistry.new()
	var artifact_catalog := FakeArtifactCatalog.new()
	var artifact_core := RefCounted.new()
	var building_upgrade_core := RefCounted.new()

	roller.call(
		"roll_offers",
		menu,
		offer_generator,
		ui_builder,
		self,
		building_registry,
		artifact_catalog,
		artifact_core,
		building_upgrade_core,
		Callable(menu, "_load_spell_config")
	)

	if not _assert(offer_generator.building_registry_seen == building_registry, "building rolls must still use BuildingRegistry"):
		return
	if not _assert(offer_generator.artifact_catalog_seen == artifact_catalog and offer_generator.artifact_core_seen == artifact_core, "artifact rolls must still use catalog/core filtering"):
		return
	if not _assert(offer_generator.building_upgrade_tree_seen == self and offer_generator.building_upgrade_core_seen == building_upgrade_core, "building upgrade rolls must still use scene tree and BuildingUpgradeCore"):
		return

	var building_tiles := menu._collect_tiles(menu.buildings_grid)
	var building_call: Dictionary = (building_tiles[0] as FakeTile).setup_calls.back() as Dictionary
	if not _assert(building_call["kind"] == "building" and building_call["payload"] == "hut" and building_call["price"] == 33, "building tile must keep rolled id and category-based price"):
		return
	if not _assert((building_tiles[0] as FakeTile).icon_size_override == Vector2(144, 144), "building tile must keep enlarged icon size"):
		return
	if not _assert((building_tiles[1] as FakeTile).purchased_state, "unused building tile must still be cleared through empty setup"):
		return

	var artifact_tile := menu._collect_tiles(menu.artifacts_grid)[0] as FakeTile
	var artifact_call: Dictionary = artifact_tile.setup_calls.back() as Dictionary
	if not _assert(artifact_call["kind"] == "artifact" and artifact_call["payload"] == "orb" and artifact_call["price"] == menu.artifact_price, "artifact tile must keep artifact kind/id/pricing"):
		return

	var building_upgrade_tile := menu._collect_tiles(menu.building_upgrades_grid)[0] as FakeTile
	var building_upgrade_call: Dictionary = building_upgrade_tile.setup_calls.back() as Dictionary
	if not _assert(building_upgrade_call["kind"] == "building_upgrade" and int((building_upgrade_call["payload"] as Dictionary)["slot_index"]) == 2, "building upgrade tile must keep rolled upgrade payload"):
		return

	var resource_tile := menu._collect_tiles(menu.resources_grid)[0] as FakeTile
	var resource_call: Dictionary = resource_tile.setup_calls.back() as Dictionary
	if not _assert(resource_call["kind"] == "resource" and resource_call["payload"] == "wood" and resource_call["price"] == menu.resource_price, "resource tile must keep rolled resource payload and price"):
		return
	if not _assert(menu.resource_icon_requests == ["wood"], "resource tile must still resolve icons via menu resource helper"):
		return

	var spell_tile := menu._collect_tiles(menu.spells_grid)[0] as FakeTile
	var spell_call: Dictionary = spell_tile.setup_calls.back() as Dictionary
	if not _assert(spell_call["kind"] == "spell" and spell_call["payload"] == "meteorite" and spell_call["price"] == menu.spell_price, "spell tile must keep rolled spell payload and price"):
		return
	if not _assert(menu.spell_config_requests == ["meteorite"], "spell tile must still resolve spell config through the scene facade"):
		return

	var troop_tiles := menu._collect_tiles(menu.troop_row_grid)
	var troop_training_call: Dictionary = (troop_tiles[0] as FakeTile).setup_calls.back() as Dictionary
	if not _assert(troop_training_call["kind"] == "troop_training" and troop_training_call["price"] == 80, "troop section must keep fixed troop training offer"):
		return
	var troop_upgrade_1_call: Dictionary = (troop_tiles[1] as FakeTile).setup_calls.back() as Dictionary
	var troop_upgrade_2_call: Dictionary = (troop_tiles[2] as FakeTile).setup_calls.back() as Dictionary
	if not _assert(troop_upgrade_1_call["kind"] == "building_upgrade" and troop_upgrade_2_call["kind"] == "building_upgrade", "troop section must still reuse building upgrade offers for the remaining slots"):
		return

	roller.call("roll_building_upgrades_section", menu, offer_generator, ui_builder, self, building_registry, building_upgrade_core)
	roller.call("roll_troop_section", menu, offer_generator, ui_builder, self, building_registry, building_upgrade_core)
	if not _assert(menu.delegated_calls == ["building_upgrades", "troop_section"], "menu-level reroll entry points must delegate through TraderOfferRoller"):
		return

	print("[test_trader_offer_roller] PASS")
	quit(0)
