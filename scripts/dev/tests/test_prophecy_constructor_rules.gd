extends SceneTree

const ProphecyMenuScene = preload("res://scenes/ui/prophecy/ProphecyMenu.tscn")

func _init() -> void:
	var menu := ProphecyMenuScene.instantiate() as ProphecyMenu
	if menu == null:
		push_error("[test_prophecy_constructor_rules] failed to instantiate ProphecyMenu")
		quit(1)
		return

	get_root().add_child(menu)
	call_deferred("_run_test", menu)


func _run_test(menu: ProphecyMenu) -> void:
	menu.open(null, 2, 0)

	var options_container := menu.options_container
	if options_container == null:
		push_error("[test_prophecy_constructor_rules] options_container is null")
		quit(1)
		return

	var hard_option: Array = []
	var mid_option: Array = []
	var easy_options: Array = []

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
				easy_options.append(card.option_patterns)

	if hard_option.is_empty() or mid_option.is_empty() or easy_options.size() < 3:
		push_error("[test_prophecy_constructor_rules] missing hard/mid/easy test options")
		quit(1)
		return

	if not menu.continue_button.disabled:
		push_error("[test_prophecy_constructor_rules] continue must start disabled before EASY selection")
		quit(1)
		return

	if menu._try_add_pattern_to_slot(2, hard_option):
		push_error("[test_prophecy_constructor_rules] hard must not be accepted before MID")
		quit(1)
		return

	if menu._try_add_pattern_to_slot(1, mid_option):
		push_error("[test_prophecy_constructor_rules] mid must not be accepted before EASY")
		quit(1)
		return

	if not menu._try_add_pattern_to_slot(0, easy_options[0]):
		push_error("[test_prophecy_constructor_rules] easy must be accepted into EASY slot")
		quit(1)
		return

	if not menu.continue_button.disabled:
		push_error("[test_prophecy_constructor_rules] continue must stay disabled until every unlocked slot has EASY")
		quit(1)
		return

	if not menu._try_add_pattern_to_slot(1, easy_options[1]):
		push_error("[test_prophecy_constructor_rules] easy must be accepted into second slot")
		quit(1)
		return

	if not menu.continue_button.disabled:
		push_error("[test_prophecy_constructor_rules] continue must stay disabled until third unlocked slot has EASY")
		quit(1)
		return

	if not menu._try_add_pattern_to_slot(2, easy_options[2]):
		push_error("[test_prophecy_constructor_rules] easy must be accepted into third slot")
		quit(1)
		return

	if menu.continue_button.disabled:
		push_error("[test_prophecy_constructor_rules] continue must enable only after every unlocked slot has EASY")
		quit(1)
		return

	if not menu._try_add_pattern_to_slot(0, mid_option):
		push_error("[test_prophecy_constructor_rules] mid must be accepted after EASY")
		quit(1)
		return

	if not menu._try_add_pattern_to_slot(0, hard_option):
		push_error("[test_prophecy_constructor_rules] hard must be accepted after MID")
		quit(1)
		return

	if menu._try_add_pattern_to_slot(0, easy_options[0]):
		push_error("[test_prophecy_constructor_rules] more than one EASY pattern must not be accepted")
		quit(1)
		return

	var banner_order := _collect_banner_order(options_container)
	if banner_order != ["EASY", "MID", "HARD"]:
		push_error("[test_prophecy_constructor_rules] expected section order EASY->MID->HARD, got %s" % str(banner_order))
		quit(1)
		return

	print("[test_prophecy_constructor_rules] PASS")
	quit(0)


func _collect_cards(node: Node, out: Array) -> void:
	if node == null:
		return
	if node is ProphecyWaveCard:
		out.append(node)
	for child in node.get_children():
		_collect_cards(child, out)


func _collect_banner_order(container: Node) -> Array:
	var order: Array = []
	if container == null:
		return order
	for child in container.get_children():
		var label := _find_banner_label(child)
		if label != "":
			order.append(label)
	return order


func _find_banner_label(node: Node) -> String:
	if node is Label:
		var text := String((node as Label).text)
		if text == "EASY" or text == "MID" or text == "HARD":
			return text
	for child in node.get_children():
		var nested := _find_banner_label(child)
		if nested != "":
			return nested
	return ""
