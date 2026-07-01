extends SceneTree

const ProphecyMenuScene = preload("res://scenes/ui/prophecy/ProphecyMenu.tscn")
const ProphecyWaveGeneratorScript = preload("res://scripts/prophecy/ProphecyWaveGenerator.gd")

func _init() -> void:
	var menu := ProphecyMenuScene.instantiate() as ProphecyMenu
	if menu == null:
		push_error("[test_prophecy_tier_power_bands] failed to instantiate menu")
		quit(1)
		return

	get_root().add_child(menu)
	call_deferred("_run_test", menu)


func _run_test(menu: ProphecyMenu) -> void:
	var prophecy_level := 2
	menu.open(null, prophecy_level, 0)

	var gen := ProphecyWaveGeneratorScript.new()
	gen.setup(RandomNumberGenerator.new(), 1, prophecy_level)
	var range_data := gen.get_level_power_range(prophecy_level)
	var min_power := float(range_data.get("min", 60.0))
	var max_power := float(range_data.get("max", 120.0))
	var third := maxf(1.0, max_power - min_power) / 3.0

	var easy_min := min_power
	var easy_max := min_power + third
	var mid_min := easy_max
	var mid_max := min_power + third * 2.0
	var hard_min := mid_max
	var hard_max := max_power

	var cards: Array = []
	_collect_cards(menu.options_container, cards)
	for card in cards:
		if card.option_patterns == null or card.option_patterns.size() != 1:
			continue
		var p: ProphecyPattern = card.option_patterns[0]
		if p == null:
			continue
		var power := float(p.power_rating)
		match int(p.difficulty_tier):
			ProphecyPattern.DifficultyTier.HARD:
				if power < hard_min or power > hard_max:
					push_error("[test_prophecy_tier_power_bands] HARD power out of band: %f not in [%f..%f]" % [power, hard_min, hard_max])
					quit(1)
					return
			ProphecyPattern.DifficultyTier.MID:
				if power < mid_min or power > mid_max:
					push_error("[test_prophecy_tier_power_bands] MID power out of band: %f not in [%f..%f]" % [power, mid_min, mid_max])
					quit(1)
					return
			ProphecyPattern.DifficultyTier.EASY:
				if power < easy_min or power > easy_max:
					push_error("[test_prophecy_tier_power_bands] EASY power out of band: %f not in [%f..%f]" % [power, easy_min, easy_max])
					quit(1)
					return

	print("[test_prophecy_tier_power_bands] PASS")
	quit(0)


func _collect_cards(node: Node, out: Array) -> void:
	if node == null:
		return
	if node is ProphecyWaveCard:
		out.append(node)
	for child in node.get_children():
		_collect_cards(child, out)
