extends SceneTree

func _init() -> void:
	var base_cases := {
		"black_sheep": "black_sheep",
		"black_sheep_2": "black_sheep",
		"madman": "madman",
		"madman_10": "madman",
		"clown_3": "clown"
	}

	for source_id in base_cases.keys():
		var expected := String(base_cases[source_id])
		var got := HeroSpecialBehaviorRules.get_base_unit_id(source_id)
		if got != expected:
			push_error("[test_hero_special_behavior_rules] get_base_unit_id(%s) expected %s got %s" % [source_id, expected, got])
			quit(1)
			return

	var passive_cases := {
		"black_sheep": true,
		"black_sheep_4": true,
		"madman": false,
		"swordsman": false
	}

	for source_id in passive_cases.keys():
		var expected := bool(passive_cases[source_id])
		var got := HeroSpecialBehaviorRules.is_passive_patroller_id(source_id)
		if got != expected:
			push_error("[test_hero_special_behavior_rules] is_passive_patroller_id(%s) expected %s got %s" % [source_id, str(expected), str(got)])
			quit(1)
			return

	var har_cases := {
		"madman": true,
		"madman_2": true,
		"clown": true,
		"clown_8": true,
		"black_sheep": false,
		"swordsman": false
	}

	for source_id in har_cases.keys():
		var expected := bool(har_cases[source_id])
		var got := HeroSpecialBehaviorRules.is_hit_and_run_id(source_id)
		if got != expected:
			push_error("[test_hero_special_behavior_rules] is_hit_and_run_id(%s) expected %s got %s" % [source_id, str(expected), str(got)])
			quit(1)
			return

	print("[test_hero_special_behavior_rules] PASS")
	quit(0)
