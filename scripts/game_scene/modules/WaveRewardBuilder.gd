extends RefCounted
class_name WaveRewardBuilder


func collect_rewards_from_pattern(target_rewards: Array, pattern) -> void:
	target_rewards.append({
		"type": int(pattern.reward_1_type),
		"amount": int(pattern.reward_1_amount),
	})
	if bool(pattern.reward_2_enabled):
		target_rewards.append({
			"type": int(pattern.reward_2_type),
			"amount": int(pattern.reward_2_amount),
		})


func append_trader_reward(target_rewards: Array) -> void:
	target_rewards.append({
		"custom_id": "trader",
	})
