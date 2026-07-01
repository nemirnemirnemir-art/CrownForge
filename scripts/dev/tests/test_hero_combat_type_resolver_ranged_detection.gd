extends SceneTree

func _init() -> void:
	var cases := [
		{"unit_id": "gnome", "expected_ranged": false},
		{"unit_id": "madman", "expected_ranged": false},
		{"unit_id": "slinger", "expected_ranged": true},
		{"unit_id": "crossbowman", "expected_ranged": true}
	]

	for c in cases:
		var unit_id := String(c["unit_id"])
		var cfg := load("res://data/units/%s.tres" % unit_id)
		if cfg == null:
			push_error("[test_hero_combat_type_resolver_ranged_detection] failed to load config for %s" % unit_id)
			quit(1)
			return

		var expected_ranged := bool(c["expected_ranged"])
		var actual_ranged := bool(HeroCombatTypeResolver.is_ranged_unit_config(cfg))
		if actual_ranged != expected_ranged:
			push_error(
				"[test_hero_combat_type_resolver_ranged_detection] %s expected_ranged=%s got=%s" % [
					unit_id,
					str(expected_ranged),
					str(actual_ranged)
				]
			)
			quit(1)
			return

	print("[test_hero_combat_type_resolver_ranged_detection] PASS")
	quit(0)
