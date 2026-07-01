extends SceneTree

const ProphecyMenuScene = preload("res://scenes/ui/prophecy/ProphecyMenu.tscn")

const EXPECTED_HARD_COUNT := 6
const EXPECTED_MID_COUNT := 6
const EXPECTED_EASY_COUNT := 6

func _init() -> void:
	var menu := ProphecyMenuScene.instantiate()
	if menu == null:
		push_error("[test_prophecy_single_pattern_distribution] failed to instantiate ProphecyMenu")
		quit(1)
		return

	get_root().add_child(menu)
	call_deferred("_run_test", menu)


func _run_test(menu: ProphecyMenu) -> void:
	if menu == null:
		push_error("[test_prophecy_single_pattern_distribution] menu is null in _run_test")
		quit(1)
		return

	menu.open(null, 2, 0)

	var options_container: Node = menu.options_container
	if options_container == null:
		push_error("[test_prophecy_single_pattern_distribution] options_container is null")
		quit(1)
		return

	var cards: Array = []
	_collect_cards(options_container, cards)

	if cards.is_empty():
		push_error("[test_prophecy_single_pattern_distribution] no cards generated")
		quit(1)
		return

	var hard_count := 0
	var mid_count := 0
	var easy_count := 0

	for card in cards:
		if card.option_patterns == null or card.option_patterns.size() != 1:
			push_error(
				"[test_prophecy_single_pattern_distribution] expected single-pattern card, got size=%d" % [
					(card.option_patterns.size() if card.option_patterns != null else -1)
				]
			)
			quit(1)
			return

		var pattern = card.option_patterns[0]
		if pattern == null:
			push_error("[test_prophecy_single_pattern_distribution] card contains null pattern")
			quit(1)
			return

		if not ("difficulty_tier" in pattern):
			push_error("[test_prophecy_single_pattern_distribution] pattern has no difficulty_tier")
			quit(1)
			return

		if not ("power_rating" in pattern):
			push_error("[test_prophecy_single_pattern_distribution] pattern has no power_rating")
			quit(1)
			return

		if float(pattern.power_rating) <= 0.0:
			push_error("[test_prophecy_single_pattern_distribution] pattern power_rating must be > 0")
			quit(1)
			return

		match int(pattern.difficulty_tier):
			2:
				hard_count += 1
			1:
				mid_count += 1
			0:
				easy_count += 1
			_:
				push_error("[test_prophecy_single_pattern_distribution] invalid difficulty_tier=%s" % str(pattern.difficulty_tier))
				quit(1)
				return

	if hard_count != EXPECTED_HARD_COUNT or mid_count != EXPECTED_MID_COUNT or easy_count != EXPECTED_EASY_COUNT:
		push_error(
			"[test_prophecy_single_pattern_distribution] expected hard/mid/easy=%d/%d/%d, got %d/%d/%d" % [
				EXPECTED_HARD_COUNT,
				EXPECTED_MID_COUNT,
				EXPECTED_EASY_COUNT,
				hard_count,
				mid_count,
				easy_count,
			]
		)
		quit(1)
		return

	print("[test_prophecy_single_pattern_distribution] PASS")
	quit(0)


func _collect_cards(node: Node, out: Array) -> void:
	if node == null:
		return
	if node is ProphecyWaveCard:
		out.append(node)
	for child in node.get_children():
		_collect_cards(child, out)
