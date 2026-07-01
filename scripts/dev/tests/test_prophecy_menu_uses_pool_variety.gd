extends SceneTree

const ProphecyMenuScene := preload("res://scenes/ui/prophecy/ProphecyMenu.tscn")
const ProphecyPatternPoolScript := preload("res://scripts/resources/ProphecyPatternPool.gd")

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var menu := ProphecyMenuScene.instantiate() as ProphecyMenu
	if menu == null:
		push_error("[test_prophecy_menu_uses_pool_variety] failed to instantiate ProphecyMenu")
		quit(1)
		return

	var pool := ProphecyPatternPoolScript.new() as ProphecyPatternPool
	if pool == null:
		push_error("[test_prophecy_menu_uses_pool_variety] failed to instantiate ProphecyPatternPool")
		quit(1)
		return

	get_root().add_child(pool)
	get_root().add_child(menu)
	await process_frame

	if pool.patterns.is_empty():
		push_error("[test_prophecy_menu_uses_pool_variety] prophecy pattern pool is empty after _ready")
		quit(1)
		return

	var pool_signatures: Dictionary = {}
	for raw_pattern in pool.patterns:
		var pool_pattern := raw_pattern as ProphecyPattern
		if pool_pattern == null:
			continue
		var pool_signature := "%s:%d:%s:%d" % [
			String(pool_pattern.mob_1_id),
			int(pool_pattern.mob_1_count),
			String(pool_pattern.mob_2_id),
			int(pool_pattern.mob_2_count),
		]
		pool_signatures[pool_signature] = true

	menu.open(pool, 1, 0)
	await process_frame

	var cards: Array = []
	_collect_cards(menu.options_container, cards)
	if cards.is_empty():
		push_error("[test_prophecy_menu_uses_pool_variety] no prophecy cards generated")
		quit(1)
		return

	var unique_signatures: Dictionary = {}
	var runtime_fallback_found := false
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
		if not pool_signatures.has(signature):
			runtime_fallback_found = true
		unique_signatures[signature] = true
		if String(pattern.mob_1_id) != "wall_buster" or bool(pattern.mob_2_enabled):
			non_wall_buster_found = true

	if cards.size() != 18:
		push_error("[test_prophecy_menu_uses_pool_variety] expected 18 prophecy cards (6 per tier), got %d" % cards.size())
		quit(1)
		return

	if unique_signatures.size() <= 1:
		push_error("[test_prophecy_menu_uses_pool_variety] expected more than one unique prophecy signature, got %s" % str(unique_signatures.keys()))
		quit(1)
		return

	if not non_wall_buster_found:
		push_error("[test_prophecy_menu_uses_pool_variety] expected at least one non-wall_buster prophecy option, got %s" % str(unique_signatures.keys()))
		quit(1)
		return

	if not runtime_fallback_found:
		push_error("[test_prophecy_menu_uses_pool_variety] expected runtime fallback to fill prophecy menu up to 6/6/6 options")
		quit(1)
		return

	print("[test_prophecy_menu_uses_pool_variety] PASS")
	quit(0)

func _collect_cards(node: Node, out: Array) -> void:
	if node == null:
		return
	if node is ProphecyWaveCard:
		out.append(node)
	for child in node.get_children():
		_collect_cards(child, out)
