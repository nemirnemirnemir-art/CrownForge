extends SceneTree

const ProphecyMenuScene = preload("res://scenes/ui/prophecy/ProphecyMenu.tscn")

func _init() -> void:
	var menu := ProphecyMenuScene.instantiate() as ProphecyMenu
	if menu == null:
		push_error("[test_prophecy_slot_tier_chips] failed to instantiate ProphecyMenu")
		quit(1)
		return

	get_root().add_child(menu)
	call_deferred("_run_test", menu)


func _run_test(menu: ProphecyMenu) -> void:
	menu.open(null, 2, 0)

	var options_container := menu.options_container
	if options_container == null:
		push_error("[test_prophecy_slot_tier_chips] options_container is null")
		quit(1)
		return

	var hard_option: Array = []
	var mid_option: Array = []
	var easy_option: Array = []

	var cards: Array = []
	_collect_cards(options_container, cards)
	for card in cards:
		if card.option_patterns == null or card.option_patterns.size() != 1:
			continue
		var p: ProphecyPattern = card.option_patterns[0]
		if p == null:
			continue
		match int(p.difficulty_tier):
			ProphecyPattern.DifficultyTier.HARD:
				if hard_option.is_empty():
					hard_option = card.option_patterns
			ProphecyPattern.DifficultyTier.MID:
				if mid_option.is_empty():
					mid_option = card.option_patterns
			ProphecyPattern.DifficultyTier.EASY:
				if easy_option.is_empty():
					easy_option = card.option_patterns

	if hard_option.is_empty() or mid_option.is_empty() or easy_option.is_empty():
		push_error("[test_prophecy_slot_tier_chips] missing hard/mid/easy test options")
		quit(1)
		return

	if not menu._try_add_pattern_to_slot(0, hard_option):
		push_error("[test_prophecy_slot_tier_chips] failed to add hard")
		quit(1)
		return
	if not menu._try_add_pattern_to_slot(0, mid_option):
		push_error("[test_prophecy_slot_tier_chips] failed to add mid")
		quit(1)
		return
	if not menu._try_add_pattern_to_slot(0, easy_option):
		push_error("[test_prophecy_slot_tier_chips] failed to add easy")
		quit(1)
		return

	var slot := menu.selected_slot_1 as ProphecySelectedSlot
	if slot == null:
		push_error("[test_prophecy_slot_tier_chips] selected_slot_1 is null")
		quit(1)
		return

	var hard_chip := slot.get_node_or_null("TierSummary/HardChip") as Label
	var mid_chip := slot.get_node_or_null("TierSummary/MidChip") as Label
	var easy_chip := slot.get_node_or_null("TierSummary/EasyChip") as Label

	if hard_chip == null or mid_chip == null or easy_chip == null:
		push_error("[test_prophecy_slot_tier_chips] slot tier chips are missing")
		quit(1)
		return

	if hard_chip.text != "HARD x1" or mid_chip.text != "MID x1" or easy_chip.text != "EASY x1":
		push_error("[test_prophecy_slot_tier_chips] expected HARD/MID/EASY x1, got %s | %s | %s" % [hard_chip.text, mid_chip.text, easy_chip.text])
		quit(1)
		return

	print("[test_prophecy_slot_tier_chips] PASS")
	quit(0)


func _collect_cards(node: Node, out: Array) -> void:
	if node == null:
		return
	if node is ProphecyWaveCard:
		out.append(node)
	for child in node.get_children():
		_collect_cards(child, out)
