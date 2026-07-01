extends SceneTree

const RewardPoolScript := preload("res://scripts/prophecy/modules/ProphecyRewardPool.gd")
const ProphecyPatternScript := preload("res://scripts/resources/ProphecyPattern.gd")

func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var pool: ProphecyRewardPool = RewardPoolScript.new() as ProphecyRewardPool
	if pool == null:
		push_error("[test_prophecy_reward_pool_candidates] failed to instantiate ProphecyRewardPool")
		quit(1)
		return
	pool.setup(rng)

	var level_1_low: Array = pool.get_reward_candidates(1, 45.0)
	if _contains_reward(level_1_low, ProphecyPattern.RewardType.LEGENDARY_ARTIFACT) or _contains_reward(level_1_low, ProphecyPattern.RewardType.LEGENDARY_SPELL) or _contains_reward(level_1_low, ProphecyPattern.RewardType.ELITE_BARRACKS):
		push_error("[test_prophecy_reward_pool_candidates] level 1 low-power rewards must exclude legendary and elite rewards")
		quit(1)
		return
	if _contains_reward(level_1_low, ProphecyPattern.RewardType.ESTABLISHED_PRODUCTION) or _contains_reward(level_1_low, ProphecyPattern.RewardType.VETERAN_BARRACKS):
		push_error("[test_prophecy_reward_pool_candidates] normal prophecy 1 rewards must exclude EP and VB")
		quit(1)
		return

	var level_1_strong: Array = pool.callv("get_reward_candidates", [1, 95.0, "", true])
	if not _contains_reward(level_1_strong, ProphecyPattern.RewardType.ESTABLISHED_PRODUCTION) and not _contains_reward(level_1_strong, ProphecyPattern.RewardType.VETERAN_BARRACKS):
		push_error("[test_prophecy_reward_pool_candidates] rare strong prophecy 1 rewards must expose EP or VB")
		quit(1)
		return
	if not _contains_reward(level_1_strong, ProphecyPattern.RewardType.ARTIFACT):
		push_error("[test_prophecy_reward_pool_candidates] rare strong prophecy 1 rewards must expose Artifact")
		quit(1)
		return
	if _contains_reward(level_1_strong, ProphecyPattern.RewardType.ADVANCED_PRODUCTION) or _contains_reward(level_1_strong, ProphecyPattern.RewardType.KINGDOM_INFRASTRUCTURE):
		push_error("[test_prophecy_reward_pool_candidates] prophecy 1 rare strong rewards must stay capped at EP/VB")
		quit(1)
		return

	var level_2_normal: Array = pool.get_reward_candidates(2, 70.0)
	if not _contains_reward_with_amount(level_2_normal, ProphecyPattern.RewardType.DENARII, 40):
		push_error("[test_prophecy_reward_pool_candidates] prophecy 2 normal rewards must expose Denarii 40")
		quit(1)
		return
	if not _contains_reward_with_amount(level_2_normal, ProphecyPattern.RewardType.RESOURCE, 45):
		push_error("[test_prophecy_reward_pool_candidates] prophecy 2 normal rewards must expose Resource 45")
		quit(1)
		return
	if _contains_reward(level_2_normal, ProphecyPattern.RewardType.TROOP_TRAINING):
		push_error("[test_prophecy_reward_pool_candidates] prophecy 2 normal rewards must not expose Troop Training")
		quit(1)
		return

	var level_2_strong: Array = pool.get_reward_candidates(2, 120.0)
	if not _contains_reward_with_amount(level_2_strong, ProphecyPattern.RewardType.DENARII, 50):
		push_error("[test_prophecy_reward_pool_candidates] prophecy 2 strong rewards must expose Denarii 50")
		quit(1)
		return
	if not _contains_reward_with_amount(level_2_strong, ProphecyPattern.RewardType.RESOURCE, 60):
		push_error("[test_prophecy_reward_pool_candidates] prophecy 2 strong rewards must expose Resource 60")
		quit(1)
		return
	if not _contains_reward(level_2_strong, ProphecyPattern.RewardType.TROOP_TRAINING):
		push_error("[test_prophecy_reward_pool_candidates] prophecy 2 strong rewards must expose Troop Training")
		quit(1)
		return

	var level_3_normal: Array = pool.get_reward_candidates(3, 120.0)
	if not _contains_reward_with_amount(level_3_normal, ProphecyPattern.RewardType.DENARII, 50):
		push_error("[test_prophecy_reward_pool_candidates] prophecy 3 rewards must expose Denarii 50")
		quit(1)
		return
	if not _contains_reward_with_amount(level_3_normal, ProphecyPattern.RewardType.RESOURCE, 60):
		push_error("[test_prophecy_reward_pool_candidates] prophecy 3 rewards must expose Resource 60")
		quit(1)
		return
	if not _contains_reward(level_3_normal, ProphecyPattern.RewardType.KINGDOM_INFRASTRUCTURE):
		push_error("[test_prophecy_reward_pool_candidates] prophecy 3 rewards must expose Kingdom Infrastructure")
		quit(1)
		return
	if not _contains_reward(level_3_normal, ProphecyPattern.RewardType.BUILDING_UPGRADE):
		push_error("[test_prophecy_reward_pool_candidates] prophecy 3 rewards must expose Building Upgrade")
		quit(1)
		return
	if not _contains_reward(level_3_normal, ProphecyPattern.RewardType.TROOP_TRAINING):
		push_error("[test_prophecy_reward_pool_candidates] prophecy 3 rewards must expose Troop Training")
		quit(1)
		return

	var level_4_boss: Array = pool.get_boss_reward_bundle(4)
	if level_4_boss.size() < 6:
		push_error("[test_prophecy_reward_pool_candidates] prophecy 4 boss bundle must contain a multi-card high-tier reward set")
		quit(1)
		return
	if not _bundle_contains(level_4_boss, ProphecyPattern.RewardType.LEGENDARY_ARTIFACT):
		push_error("[test_prophecy_reward_pool_candidates] prophecy 4 boss bundle must include Legendary Artifact")
		quit(1)
		return
	if not _bundle_contains(level_4_boss, ProphecyPattern.RewardType.LEGENDARY_SPELL):
		push_error("[test_prophecy_reward_pool_candidates] prophecy 4 boss bundle must include Legendary Spell")
		quit(1)
		return

	var p2: ProphecyPattern = ProphecyPatternScript.new() as ProphecyPattern
	p2.reward_bias = "mid_strong"
	pool.apply_rewards(p2, 2, 120.0)
	if bool(p2.reward_2_enabled):
		push_error("[test_prophecy_reward_pool_candidates] prophecy 2 cards must not get second reward")
		quit(1)
		return

	var p3: ProphecyPattern = ProphecyPatternScript.new() as ProphecyPattern
	pool.apply_rewards(p3, 3, 160.0)
	if bool(p3.reward_2_enabled):
		push_error("[test_prophecy_reward_pool_candidates] prophecy 3 cards must not get second reward")
		quit(1)
		return

	var p4: ProphecyPattern = ProphecyPatternScript.new() as ProphecyPattern
	pool.apply_rewards(p4, 4, 220.0)
	if bool(p4.reward_2_enabled):
		push_error("[test_prophecy_reward_pool_candidates] prophecy 4 cards must not get second reward")
		quit(1)
		return

	print("[test_prophecy_reward_pool_candidates] PASS")
	quit(0)


func _contains_reward(candidates: Array, reward_type: int) -> bool:
	for entry in candidates:
		if int((entry as Dictionary).get("type", -1)) == reward_type:
			return true
	return false


func _contains_reward_with_amount(candidates: Array, reward_type: int, amount: int) -> bool:
	for entry in candidates:
		if int((entry as Dictionary).get("type", -1)) == reward_type and int((entry as Dictionary).get("amount", -1)) == amount:
			return true
	return false


func _bundle_contains(bundle: Array, reward_type: int) -> bool:
	for entry in bundle:
		if int((entry as Dictionary).get("type", -1)) == reward_type:
			return true
	return false
