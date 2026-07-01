extends SceneTree

const ProdBoostScript := preload("res://core/building_upgrade/BuildingUpgradeProductionBoost.gd")
const ProdBonusScript := preload("res://core/building_upgrade/BuildingUpgradeProductionBonus.gd")
const NeighbourBoostScript := preload("res://core/building_upgrade/BuildingUpgradeNeighbourBoost.gd")
const TroopInspirationScript := preload("res://core/building_upgrade/BuildingUpgradeTroopInspiration.gd")


func _init() -> void:
	var passed := 0
	var failed := 0

	# Test 1: Production boost map has correct entries
	var boost_map: Dictionary = ProdBoostScript.PRODUCTION_BOOST_MAP
	if boost_map.has("vineyard") and boost_map.has("sawmill") and boost_map.has("fuel_pump"):
		passed += 1
		print("PASS: Production boost map has expected entries")
	else:
		failed += 1
		print("FAIL: Production boost map missing entries")

	# Test 2: get_production_multiplier with no upgrades returns 1.0
	var no_upgrades := func(_bid: String, _uid: String) -> bool: return false
	var mult: float = ProdBoostScript.get_production_multiplier("vineyard", no_upgrades)
	if is_equal_approx(mult, 1.0):
		passed += 1
		print("PASS: No upgrade = 1.0 multiplier")
	else:
		failed += 1
		print("FAIL: Expected 1.0, got %f" % mult)

	# Test 3: get_production_multiplier with upgrade returns correct value
	var has_vineyard_1 := func(bid: String, uid: String) -> bool: return bid == "vineyard" and uid == "vineyard:1"
	mult = ProdBoostScript.get_production_multiplier("vineyard", has_vineyard_1)
	if is_equal_approx(mult, 1.3):
		passed += 1
		print("PASS: Vineyard production boost = 1.3")
	else:
		failed += 1
		print("FAIL: Expected 1.3, got %f" % mult)

	# Test 4: Bonus map has correct entries
	var bonus_map: Dictionary = ProdBonusScript.BONUS_MAP
	if bonus_map.has("gold_mine") and bonus_map.has("fuel_pump") and bonus_map.has("clay_mine"):
		passed += 1
		print("PASS: Bonus map has expected entries")
	else:
		failed += 1
		print("FAIL: Bonus map missing entries")

	# Test 5: Neighbour boost with no sawmill neighbours
	var no_neighbours: Dictionary = {}
	var boost: float = NeighbourBoostScript.get_neighbour_boost_multiplier(Vector2i(5, 5), no_neighbours, no_upgrades)
	if is_equal_approx(boost, 1.0):
		passed += 1
		print("PASS: No neighbours = 1.0 boost")
	else:
		failed += 1
		print("FAIL: Expected 1.0 neighbour boost, got %f" % boost)

	# Test 6: Neighbour boost with active sawmill neighbour
	var has_sawmill_1 := func(bid: String, uid: String) -> bool: return bid == "sawmill" and uid == "sawmill:1"
	var neighbours_map: Dictionary = {
		Vector2i(5, 4): {"building_id": "sawmill", "is_vzor_active": true},
	}
	boost = NeighbourBoostScript.get_neighbour_boost_multiplier(Vector2i(5, 5), neighbours_map, has_sawmill_1)
	if is_equal_approx(boost, 1.2):
		passed += 1
		print("PASS: One sawmill neighbour = 1.2 boost")
	else:
		failed += 1
		print("FAIL: Expected 1.2 neighbour boost, got %f" % boost)

	# Test 7: Troop inspiration - no upgrades
	var dmg_mult: float = TroopInspirationScript.get_troop_class_damage_multiplier("WARRIOR", no_upgrades)
	if is_equal_approx(dmg_mult, 1.0):
		passed += 1
		print("PASS: No inspiration = 1.0 damage")
	else:
		failed += 1
		print("FAIL: Expected 1.0 troop damage, got %f" % dmg_mult)

	# Test 8: Troop inspiration - with iron_mine:0
	var has_iron_mine_0 := func(bid: String, uid: String) -> bool: return bid == "iron_mine" and uid == "iron_mine:0"
	dmg_mult = TroopInspirationScript.get_troop_class_damage_multiplier("WARRIOR", has_iron_mine_0)
	if is_equal_approx(dmg_mult, 1.1):
		passed += 1
		print("PASS: Iron mine inspiration = 1.1 Warrior damage")
	else:
		failed += 1
		print("FAIL: Expected 1.1 troop damage, got %f" % dmg_mult)

	# Test 9: Efficient processing - no upgrade
	var ep_mult: int = ProdBoostScript.get_efficient_processing_multiplier("forge", no_upgrades)
	if ep_mult == 1:
		passed += 1
		print("PASS: No efficient processing = 1")
	else:
		failed += 1
		print("FAIL: Expected 1 efficient processing, got %d" % ep_mult)

	# Test 10: Efficient processing - with upgrade
	var has_forge_0 := func(bid: String, uid: String) -> bool: return bid == "forge" and uid == "forge:0"
	ep_mult = ProdBoostScript.get_efficient_processing_multiplier("forge", has_forge_0)
	if ep_mult == 2:
		passed += 1
		print("PASS: Efficient processing = 2")
	else:
		failed += 1
		print("FAIL: Expected 2 efficient processing, got %d" % ep_mult)

	# Test 11: Troop inspiration map has 6 entries (WARRIOR, RIDER, RANGED, FLYING, GRUNT, CHAMPION)
	if TroopInspirationScript.INSPIRATION_MAP.size() == 6:
		passed += 1
		print("PASS: Inspiration map has 6 entries")
	else:
		failed += 1
		print("FAIL: Expected 6 inspiration entries, got %d" % TroopInspirationScript.INSPIRATION_MAP.size())

	# Test 12: All 13 resources in bonus pool
	if ProdBonusScript.ALL_RESOURCES.size() == 13:
		passed += 1
		print("PASS: ALL_RESOURCES has 13 entries")
	else:
		failed += 1
		print("FAIL: Expected 13 resources, got %d" % ProdBonusScript.ALL_RESOURCES.size())

	print("\nProduction infra tests: %d passed, %d failed" % [passed, failed])
	quit(failed)
