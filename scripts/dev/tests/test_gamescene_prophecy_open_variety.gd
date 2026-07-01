extends SceneTree

const GameSceneScene := preload("res://scenes/game/GameScene.tscn")

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var game_scene := GameSceneScene.instantiate() as GameScene
	if game_scene == null:
		push_error("[test_gamescene_prophecy_open_variety] failed to instantiate GameScene")
		quit(1)
		return

	get_root().add_child(game_scene)
	await process_frame
	await process_frame

	if game_scene.prophecy_pattern_pool == null:
		push_error("[test_gamescene_prophecy_open_variety] prophecy_pattern_pool is null")
		quit(1)
		return
	if game_scene.prophecy_pattern_pool.patterns.is_empty():
		push_error("[test_gamescene_prophecy_open_variety] prophecy pattern pool is empty")
		quit(1)
		return

	game_scene.open_reward_menu_prophecy()
	await process_frame
	await process_frame

	var prophecy_menu := game_scene.prophecy_menu as ProphecyMenu
	if prophecy_menu == null:
		push_error("[test_gamescene_prophecy_open_variety] prophecy_menu is null")
		quit(1)
		return

	var cards: Array = []
	_collect_cards(prophecy_menu.options_container, cards)
	if cards.is_empty():
		push_error("[test_gamescene_prophecy_open_variety] no cards generated in GameScene prophecy menu")
		quit(1)
		return

	var unique_signatures: Dictionary = {}
	var non_wall_buster_found := false
	for card in cards:
		if card.option_patterns == null or card.option_patterns.size() != 1:
			continue
		var pattern: ProphecyPattern = card.option_patterns[0]
		if pattern == null:
			continue
		var signature := "%s:%d:%s:%d" % [
			String(pattern.mob_1_id),
			int(pattern.mob_1_count),
			String(pattern.mob_2_id),
			int(pattern.mob_2_count),
		]
		unique_signatures[signature] = true
		if String(pattern.mob_1_id) != "wall_buster" or bool(pattern.mob_2_enabled):
			non_wall_buster_found = true

	if unique_signatures.size() <= 1:
		push_error("[test_gamescene_prophecy_open_variety] expected more than one runtime prophecy signature, got %s" % str(unique_signatures.keys()))
		quit(1)
		return

	if not non_wall_buster_found:
		push_error("[test_gamescene_prophecy_open_variety] expected at least one non-wall_buster runtime prophecy option, got %s" % str(unique_signatures.keys()))
		quit(1)
		return

	print("[test_gamescene_prophecy_open_variety] PASS")
	quit(0)

func _collect_cards(node: Node, out: Array) -> void:
	if node == null:
		return
	if node is ProphecyWaveCard:
		out.append(node)
	for child in node.get_children():
		_collect_cards(child, out)
