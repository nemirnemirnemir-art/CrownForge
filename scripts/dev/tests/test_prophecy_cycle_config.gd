extends SceneTree

const ProphecyCycleConfigScript := preload("res://scripts/prophecy/modules/ProphecyCycleConfig.gd")


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var config = ProphecyCycleConfigScript.new()
	if config == null:
		push_error("[test_prophecy_cycle_config] failed to instantiate config helper")
		quit(1)
		return

	if not bool(config.call("load_from_json", "res://data/prophecy_cycle_config.json")):
		push_error("[test_prophecy_cycle_config] failed to load prophecy cycle config")
		quit(1)
		return

	_assert_single_pattern(config.call("get_intro_patterns", 1), "goblin_bandit", 1, "", 0, "prophecy 1 intro")
	_assert_single_pattern(config.call("get_intro_patterns", 2), "wall_buster", 4, "", 0, "prophecy 2 intro")
	_assert_single_pattern(config.call("get_intro_patterns", 3), "goblin_lizard", 2, "", 0, "prophecy 3 intro")

	_assert_single_pattern(config.call("get_trader_patterns", 1), "goblin_bandit", 1, "goblin_crossbowman", 1, "prophecy 1 trader")
	_assert_single_pattern(config.call("get_trader_patterns", 2), "goblin_bandit", 3, "goblin_fire_mage", 1, "prophecy 2 trader")
	_assert_single_pattern(config.call("get_trader_patterns", 3), "stone_golem", 2, "", 0, "prophecy 3 trader")

	var boss_patterns: Array = config.call("get_final_boss_patterns", 4)
	if boss_patterns.size() != 1:
		push_error("[test_prophecy_cycle_config] prophecy 4 boss must have exactly one authored pattern, got %d" % boss_patterns.size())
		quit(1)
		return
	_assert_single_pattern(boss_patterns, "homeseekerboss", 1, "", 0, "prophecy 4 boss")

	var boss_rewards: Array = config.call("get_final_boss_rewards", 4)
	_assert_bundle_contains(boss_rewards, ProphecyPattern.RewardType.DENARII, 10, "prophecy 4 boss rewards")
	_assert_bundle_contains(boss_rewards, ProphecyPattern.RewardType.LEGENDARY_ARTIFACT, 1, "prophecy 4 boss rewards")
	_assert_bundle_contains(boss_rewards, ProphecyPattern.RewardType.LEGENDARY_SPELL, 1, "prophecy 4 boss rewards")
	_assert_bundle_contains(boss_rewards, ProphecyPattern.RewardType.VETERAN_BARRACKS, 1, "prophecy 4 boss rewards")
	_assert_bundle_contains(boss_rewards, ProphecyPattern.RewardType.ESTABLISHED_PRODUCTION, 1, "prophecy 4 boss rewards")
	_assert_bundle_contains(boss_rewards, ProphecyPattern.RewardType.TROOP_TRAINING, 1, "prophecy 4 boss rewards")

	if not bool(config.call("should_show_victory_after_rewards", 4)):
		push_error("[test_prophecy_cycle_config] prophecy 4 must show victory after boss rewards")
		quit(1)
		return

	print("[test_prophecy_cycle_config] PASS")
	quit(0)


func _assert_single_pattern(patterns: Array, mob_1_id: String, mob_1_count: int, mob_2_id: String, mob_2_count: int, context: String) -> void:
	if patterns.size() != 1:
		push_error("[test_prophecy_cycle_config] %s must have exactly one pattern, got %d" % [context, patterns.size()])
		quit(1)
		return
	var pattern := patterns[0] as ProphecyPattern
	if pattern == null:
		push_error("[test_prophecy_cycle_config] %s pattern is null" % context)
		quit(1)
		return
	if String(pattern.mob_1_id) != mob_1_id or int(pattern.mob_1_count) != mob_1_count:
		push_error("[test_prophecy_cycle_config] %s mob_1 mismatch: expected %s x%d, got %s x%d" % [context, mob_1_id, mob_1_count, String(pattern.mob_1_id), int(pattern.mob_1_count)])
		quit(1)
		return
	var expected_mob_2_enabled := mob_2_id != "" and mob_2_count > 0
	if bool(pattern.mob_2_enabled) != expected_mob_2_enabled:
		push_error("[test_prophecy_cycle_config] %s mob_2_enabled mismatch" % context)
		quit(1)
		return
	if expected_mob_2_enabled and (String(pattern.mob_2_id) != mob_2_id or int(pattern.mob_2_count) != mob_2_count):
		push_error("[test_prophecy_cycle_config] %s mob_2 mismatch: expected %s x%d, got %s x%d" % [context, mob_2_id, mob_2_count, String(pattern.mob_2_id), int(pattern.mob_2_count)])
		quit(1)


func _assert_bundle_contains(bundle: Array, reward_type: int, amount: int, context: String) -> void:
	for reward in bundle:
		if int((reward as Dictionary).get("type", -1)) == reward_type and int((reward as Dictionary).get("amount", -1)) == amount:
			return
	push_error("[test_prophecy_cycle_config] %s missing reward type=%d amount=%d" % [context, reward_type, amount])
	quit(1)
