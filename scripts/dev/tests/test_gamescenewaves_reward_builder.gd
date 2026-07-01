extends SceneTree

const WaveRewardBuilderScript := preload("res://scripts/game_scene/modules/WaveRewardBuilder.gd")


class FakePattern:
	extends RefCounted

	var reward_1_type: int = 1
	var reward_1_amount: int = 10
	var reward_2_enabled: bool = false
	var reward_2_type: int = 0
	var reward_2_amount: int = 0


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var builder = WaveRewardBuilderScript.new()
	var rewards: Array = []

	var pattern := FakePattern.new()
	pattern.reward_2_enabled = true
	pattern.reward_2_type = 3
	pattern.reward_2_amount = 2
	builder.collect_rewards_from_pattern(rewards, pattern)

	if rewards.size() != 2:
		push_error("[test_gamescenewaves_reward_builder] expected two rewards, got %d" % rewards.size())
		quit(1)
		return
	if int(rewards[1]["amount"]) != 2:
		push_error("[test_gamescenewaves_reward_builder] second reward amount mismatch")
		quit(1)
		return

	builder.append_trader_reward(rewards)
	if String(rewards[-1].get("custom_id", "")) != "trader":
		push_error("[test_gamescenewaves_reward_builder] trader reward marker missing")
		quit(1)
		return

	print("[test_gamescenewaves_reward_builder] PASS")
	quit(0)
