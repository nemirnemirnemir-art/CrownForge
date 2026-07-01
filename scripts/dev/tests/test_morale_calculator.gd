extends SceneTree

const MoraleCalculatorScript := preload("res://scripts/systems/morale/MoraleCalculator.gd")


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var calculator = MoraleCalculatorScript.new()
	if calculator == null:
		push_error("[test_morale_calculator] failed to instantiate helper")
		quit(1)
		return

	var result: Dictionary = calculator.calculate_morale({
		"wine_stock_morale_bonus": 30,
		"additional_wine_stock_morale_bonus": 20,
		"artifact_bonus": 5,
		"building_sources": {
			"Concert (active)": 6,
			"Tavern": 5,
		},
		"arena_bonus": 7,
		"debug_bonus": 100,
	})

	if int(result.get("total", -1)) != 173:
		push_error("[test_morale_calculator] total morale mismatch")
		quit(1)
		return

	var breakdown: Dictionary = result.get("breakdown", {})
	if int(breakdown.get("Wine Stock", -1)) != 30:
		push_error("[test_morale_calculator] wine stock breakdown mismatch")
		quit(1)
		return
	if int(breakdown.get("Tavern (wine bonus)", -1)) != 20:
		push_error("[test_morale_calculator] tavern wine breakdown mismatch")
		quit(1)
		return
	if breakdown.has("Unit Diversity"):
		push_error("[test_morale_calculator] unit diversity breakdown must be disabled")
		quit(1)
		return
	if int(breakdown.get("Artifacts", -1)) != 5:
		push_error("[test_morale_calculator] artifact breakdown mismatch")
		quit(1)
		return
	if int(breakdown.get("Concert (active)", -1)) != 6:
		push_error("[test_morale_calculator] concert breakdown mismatch")
		quit(1)
		return
	if int(breakdown.get("Tavern", -1)) != 5:
		push_error("[test_morale_calculator] tavern breakdown mismatch")
		quit(1)
		return
	if breakdown.has("Buildings"):
		push_error("[test_morale_calculator] merged buildings breakdown must not exist")
		quit(1)
		return
	if int(breakdown.get("Arena", -1)) != 7:
		push_error("[test_morale_calculator] arena breakdown mismatch")
		quit(1)
		return
	if int(breakdown.get("Debug Bonus", -1)) != 100:
		push_error("[test_morale_calculator] debug breakdown mismatch")
		quit(1)
		return

	if calculator.get_wine_morale_bonus(0, 3) != 0:
		push_error("[test_morale_calculator] empty wine must give zero morale")
		quit(1)
		return
	if calculator.get_wine_morale_bonus(2, 3) != 15:
		push_error("[test_morale_calculator] low wine morale mismatch")
		quit(1)
		return
	if calculator.get_wine_morale_bonus(3, 3) != 30:
		push_error("[test_morale_calculator] full wine morale mismatch")
		quit(1)
		return
	if calculator.get_additional_wine_stock_morale_bonus(true) != 20:
		push_error("[test_morale_calculator] tavern wine stock bonus mismatch")
		quit(1)
		return
	if absf(calculator.get_wine_consumption_multiplier(true) - 0.5) > 0.001:
		push_error("[test_morale_calculator] tavern wine multiplier mismatch")
		quit(1)
		return
	if absf(calculator.get_damage_modifier(173) - 0.865) > 0.001:
		push_error("[test_morale_calculator] damage modifier mismatch")
		quit(1)
		return
	if absf(calculator.get_productivity_modifier(173) - 0.4325) > 0.001:
		push_error("[test_morale_calculator] productivity modifier mismatch")
		quit(1)
		return

	print("[test_morale_calculator] PASS")
	quit(0)
