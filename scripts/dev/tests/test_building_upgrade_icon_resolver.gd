extends SceneTree

const IconResolverPath := "res://scripts/ui/town/buildings/BuildingUpgradeIconResolver.gd"

## All upgrade_ids that must have icons (from the canonical mapping).
const EXPECTED_ICONS := [
	"clay_mine:0", "clay_mine:1",
	"crystal_mine:0",
	"gold_mine:0", "gold_mine:1",
	"iron_mine:0", "iron_mine:1",
	"sawmill:0", "sawmill:1",
	"vineyard:0", "vineyard:1",
	"wheat_field:0", "wheat_field:1",
	"animal_farm:0", "animal_farm:1",
	"fishermans_hut:0", "fishermans_hut:1",
	"forge:0", "forge:1",
	"fuel_pump:0", "fuel_pump:1",
	"market:0", "market:1",
	"mill:0", "mill:1",
	"winery:0", "winery:1",
	"academy_of_fire:0", "academy_of_fire:1", "academy_of_fire:2",
	"academy_of_lightning:0", "academy_of_lightning:1", "academy_of_lightning:2",
]

## Upgrade IDs that must NOT have icons (buildings with no icon assets).
const EXPECTED_NO_ICONS := [
	"crystal_mine:1",
	"archery:0", "archery:1",
	"tesla_tower:0",
	"concert:0",
	"peasants_hut:0",
]

var _failed := false

func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error("[test_building_upgrade_icon_resolver] %s" % message)
	quit(1)

func _init() -> void:
	var resolver_script := load(IconResolverPath)
	if resolver_script == null:
		_fail("Cannot load icon resolver script: %s" % IconResolverPath)
		return

	# Test 1: ICON_PATHS dict exists and is non-empty
	var icon_paths: Dictionary = resolver_script.ICON_PATHS
	if icon_paths.is_empty():
		_fail("ICON_PATHS is empty")
		return

	# Test 2: All expected icons are present in ICON_PATHS
	for upgrade_id_value in EXPECTED_ICONS:
		var upgrade_id := String(upgrade_id_value)
		if not icon_paths.has(upgrade_id):
			_fail("Expected icon mapping missing for '%s'" % upgrade_id)
			return

	# Test 3: has_icon returns true for mapped entries
	for upgrade_id_value in EXPECTED_ICONS:
		var upgrade_id := String(upgrade_id_value)
		var parts := upgrade_id.split(":")
		var building_id := parts[0]
		var idx := int(parts[1])
		if not resolver_script.has_icon(building_id, idx):
			_fail("has_icon returned false for mapped entry '%s'" % upgrade_id)
			return

	# Test 4: has_icon returns false for unmapped entries
	for upgrade_id_value in EXPECTED_NO_ICONS:
		var upgrade_id := String(upgrade_id_value)
		var parts := upgrade_id.split(":")
		var building_id := parts[0]
		var idx := int(parts[1])
		if resolver_script.has_icon(building_id, idx):
			_fail("has_icon returned true for unmapped entry '%s'" % upgrade_id)
			return

	# Test 5: All ICON_PATHS resource files actually exist on disk
	for upgrade_id: String in icon_paths:
		var path: String = icon_paths[upgrade_id]
		if not FileAccess.file_exists(path):
			_fail("Icon file missing on disk for '%s': %s" % [upgrade_id, path])
			return

	# Test 6: get_icon returns non-null Texture2D for mapped entries (skip if not imported)
	var _first_path: String = icon_paths[icon_paths.keys()[0]]
	var _can_load := ResourceLoader.exists(_first_path)
	if _can_load:
		for upgrade_id_value in EXPECTED_ICONS:
			var upgrade_id := String(upgrade_id_value)
			var parts := upgrade_id.split(":")
			var building_id := parts[0]
			var idx := int(parts[1])
			var tex: Texture2D = resolver_script.get_icon(building_id, idx)
			if tex == null:
				_fail("get_icon returned null for '%s'" % upgrade_id)
				return
	else:
		print("[test_building_upgrade_icon_resolver] SKIP get_icon load tests (assets not imported yet)")

	# Test 7: get_icon returns null for unmapped entries
	for upgrade_id_value in EXPECTED_NO_ICONS:
		var upgrade_id := String(upgrade_id_value)
		var parts := upgrade_id.split(":")
		var building_id := parts[0]
		var idx := int(parts[1])
		var tex: Texture2D = resolver_script.get_icon(building_id, idx)
		if tex != null:
			_fail("get_icon returned non-null for unmapped entry '%s'" % upgrade_id)
			return

	# Test 8: icon_count_for_building returns correct counts
	var expected_counts := {
		"clay_mine": 2,
		"crystal_mine": 1,
		"academy_of_fire": 3,
		"academy_of_lightning": 3,
		"archery": 0,
		"tesla_tower": 0,
	}
	for bid: String in expected_counts:
		var expected: int = expected_counts[bid]
		var actual: int = resolver_script.icon_count_for_building(bid)
		if actual != expected:
			_fail("icon_count_for_building('%s') = %d, expected %d" % [bid, actual, expected])
			return

	# Test 9: clear_cache does not break subsequent lookups
	resolver_script.clear_cache()
	if _can_load:
		var tex_after_clear: Texture2D = resolver_script.get_icon("clay_mine", 0)
		if tex_after_clear == null:
			_fail("get_icon returned null after clear_cache for 'clay_mine:0'")
			return

	# Test 10: ICON_PATHS count matches expected (33 entries)
	if icon_paths.size() != 33:
		_fail("ICON_PATHS size = %d, expected 33" % icon_paths.size())
		return

	print("[test_building_upgrade_icon_resolver] PASS")
	quit(0)
