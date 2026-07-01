extends SceneTree


const Lib := preload("res://scripts/dev/ten_kings/TenKingsCardLibrary.gd")


func _init() -> void:
	var passed: int = 0
	var failed: int = 0
	
	# Test spawns_in_arena - only troops should return true
	if _test("spawns_in_arena(soldier) == true", Lib.spawns_in_arena(Lib.CARD_SOLDIER) == true):
		passed += 1
	else:
		failed += 1
	
	if _test("spawns_in_arena(archer) == true", Lib.spawns_in_arena(Lib.CARD_ARCHER) == true):
		passed += 1
	else:
		failed += 1
	
	if _test("spawns_in_arena(paladin) == true", Lib.spawns_in_arena(Lib.CARD_PALADIN) == true):
		passed += 1
	else:
		failed += 1
	
	if _test("spawns_in_arena(castle) == false", Lib.spawns_in_arena(Lib.CARD_CASTLE) == false):
		passed += 1
	else:
		failed += 1
	
	if _test("spawns_in_arena(farm) == false", Lib.spawns_in_arena(Lib.CARD_FARM) == false):
		passed += 1
	else:
		failed += 1
	
	# Test is_stationary_combat - only castle and scout_tower
	if _test("is_stationary_combat(castle) == true", Lib.is_stationary_combat(Lib.CARD_CASTLE) == true):
		passed += 1
	else:
		failed += 1
	
	if _test("is_stationary_combat(scout_tower) == true", Lib.is_stationary_combat(Lib.CARD_SCOUT_TOWER) == true):
		passed += 1
	else:
		failed += 1
	
	if _test("is_stationary_combat(soldier) == false", Lib.is_stationary_combat(Lib.CARD_SOLDIER) == false):
		passed += 1
	else:
		failed += 1
	
	if _test("is_stationary_combat(farm) == false", Lib.is_stationary_combat(Lib.CARD_FARM) == false):
		passed += 1
	else:
		failed += 1
	
	# Test is_support_only - farm, blacksmith, wildcard, steel_coat
	if _test("is_support_only(farm) == true", Lib.is_support_only(Lib.CARD_FARM) == true):
		passed += 1
	else:
		failed += 1
	
	if _test("is_support_only(blacksmith) == true", Lib.is_support_only(Lib.CARD_BLACKSMITH) == true):
		passed += 1
	else:
		failed += 1
	
	if _test("is_support_only(wildcard) == true", Lib.is_support_only(Lib.CARD_WILDCARD) == true):
		passed += 1
	else:
		failed += 1
	
	if _test("is_support_only(steel_coat) == true", Lib.is_support_only(Lib.CARD_STEEL_COAT) == true):
		passed += 1
	else:
		failed += 1
	
	if _test("is_support_only(castle) == false", Lib.is_support_only(Lib.CARD_CASTLE) == false):
		passed += 1
	else:
		failed += 1
	
	if _test("is_support_only(soldier) == false", Lib.is_support_only(Lib.CARD_SOLDIER) == false):
		passed += 1
	else:
		failed += 1
	
	# Verify classification is exhaustive (every card fits exactly one category)
	var all_cards := Lib.get_all_card_ids()
	var exhaustive_pass := true
	for card_id: StringName in all_cards:
		var spawns := Lib.spawns_in_arena(card_id)
		var stationary := Lib.is_stationary_combat(card_id)
		var support := Lib.is_support_only(card_id)
		var count := int(spawns) + int(stationary) + int(support)
		if count != 1:
			print("FAIL: Card '%s' has %d classifications (expected exactly 1)" % [card_id, count])
			exhaustive_pass = false
	
	if _test("All cards have exactly one classification", exhaustive_pass):
		passed += 1
	else:
		failed += 1
	
	print("")
	print("=== RESULTS: %d passed, %d failed ===" % [passed, failed])
	
	if failed > 0:
		quit(1)
	else:
		quit(0)


func _test(name: String, condition: bool) -> bool:
	if condition:
		print("PASS: %s" % name)
	else:
		print("FAIL: %s" % name)
	return condition
