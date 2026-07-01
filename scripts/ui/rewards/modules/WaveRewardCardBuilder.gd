extends RefCounted
class_name WaveRewardCardBuilder

const ProphecyPatternScript := preload("res://scripts/resources/ProphecyPattern.gd")
const ProphecyRewardPoolScript := preload("res://scripts/prophecy/modules/ProphecyRewardPool.gd")
const RewardPresentationRegistryScript := preload("res://scripts/ui/rewards/RewardPresentationRegistry.gd")


func build(reward_override: Array, use_prophecy_defaults: bool, prophecy_level: int) -> Dictionary:
	var denarii_icon := RewardPresentationRegistryScript.get_reward_icon(ProphecyPatternScript.RewardType.DENARII)
	var levy_icon := RewardPresentationRegistryScript.get_reward_icon(ProphecyPatternScript.RewardType.LEVY_BARRACKS)
	var basic_prod_icon := RewardPresentationRegistryScript.get_reward_icon(ProphecyPatternScript.RewardType.BASIC_PRODUCTION)
	var prophecy_icon := RewardPresentationRegistryScript.get_prophecy_icon()
	var denarii_name := RewardPresentationRegistryScript.get_reward_display_name(ProphecyPatternScript.RewardType.DENARII)
	var levy_name := RewardPresentationRegistryScript.get_reward_display_name(ProphecyPatternScript.RewardType.LEVY_BARRACKS)
	var basic_prod_name := RewardPresentationRegistryScript.get_reward_display_name(ProphecyPatternScript.RewardType.BASIC_PRODUCTION)
	var prophecy_name := RewardPresentationRegistryScript.get_reward_display_name(ProphecyPatternScript.RewardType.PROPHECY)
	var trader_icon := RewardPresentationRegistryScript.get_trader_icon()
	var placeholder_icon := prophecy_icon
	var resolved_override: Array = reward_override

	if (resolved_override == null or resolved_override.is_empty()) and use_prophecy_defaults:
		var prophecy_reward_pool := ProphecyRewardPoolScript.new() as ProphecyRewardPool
		if prophecy_reward_pool:
			resolved_override = prophecy_reward_pool.get_default_reward_bundle(prophecy_level)

	if resolved_override == null or resolved_override.is_empty():
		return {
			"cards": [
				{"type": "denarii", "icon": denarii_icon, "text": "%s 10" % denarii_name},
				{"type": "levy", "icon": levy_icon, "text": levy_name},
				{"type": "production", "icon": basic_prod_icon, "text": basic_prod_name},
				{"type": "prophecy", "icon": prophecy_icon, "text": prophecy_name}
			],
			"resolved_override": resolved_override,
		}

	var result: Array = []
	for reward_entry in resolved_override:
		if reward_entry == null:
			continue
		if reward_entry.has("custom_id"):
			var custom_id := str(reward_entry.get("custom_id", ""))
			if custom_id == "trader":
				result.append({"type": "trader", "icon": trader_icon, "text": "Trader"})
				continue
			if custom_id == "no_rewards":
				result.append({"type": "no_reward", "icon": placeholder_icon, "text": "No rewards"})
				continue

		var reward_type := int(reward_entry.get("type", -1))
		var amount := int(reward_entry.get("amount", 0))
		var icon := RewardPresentationRegistryScript.get_reward_icon(reward_type)
		if icon == null:
			icon = placeholder_icon
		var display_name := RewardPresentationRegistryScript.get_reward_display_name(reward_type)
		result.append(_build_reward_card(reward_type, amount, icon, display_name, placeholder_icon))

	if result.is_empty():
		print("[WaveRewardMenu][DEBUG] Reward override produced no cards; inserting fallback no_reward card")
		result.append({"type": "no_reward", "icon": placeholder_icon, "text": "No rewards"})

	return {
		"cards": result,
		"resolved_override": resolved_override,
	}


func _build_reward_card(reward_type: int, amount: int, icon: Texture2D, display_name: String, placeholder_icon: Texture2D) -> Dictionary:
	match reward_type:
		ProphecyPatternScript.RewardType.DENARII:
			return {"type": "denarii:%d" % amount, "icon": icon, "text": "%s %d" % [display_name, amount]}
		ProphecyPatternScript.RewardType.RESOURCE:
			return {"type": "resource:%d" % amount, "icon": icon, "text": "%s %d" % [display_name, amount]}
		ProphecyPatternScript.RewardType.BASIC_PRODUCTION:
			return {"type": "production_basic", "icon": icon, "text": display_name}
		ProphecyPatternScript.RewardType.ESTABLISHED_PRODUCTION:
			return {"type": "production_established", "icon": icon, "text": display_name}
		ProphecyPatternScript.RewardType.ADVANCED_PRODUCTION:
			return {"type": "production_advanced", "icon": icon, "text": display_name}
		ProphecyPatternScript.RewardType.LEVY_BARRACKS:
			return {"type": "levy", "icon": icon, "text": display_name}
		ProphecyPatternScript.RewardType.VETERAN_BARRACKS:
			return {"type": "veteran", "icon": icon, "text": display_name}
		ProphecyPatternScript.RewardType.ELITE_BARRACKS:
			return {"type": "elite", "icon": icon, "text": display_name}
		ProphecyPatternScript.RewardType.KINGDOM_INFRASTRUCTURE:
			return {"type": "infrastructure", "icon": icon, "text": display_name}
		ProphecyPatternScript.RewardType.ARTIFACT:
			return {"type": "artifact", "icon": icon, "text": display_name}
		ProphecyPatternScript.RewardType.LEGENDARY_ARTIFACT:
			return {"type": "legendary_artifact", "icon": icon, "text": display_name}
		ProphecyPatternScript.RewardType.SPELL:
			return {"type": "spell", "icon": icon, "text": display_name}
		ProphecyPatternScript.RewardType.LEGENDARY_SPELL:
			return {"type": "legendary_spell", "icon": icon, "text": display_name}
		ProphecyPatternScript.RewardType.BUILDING_UPGRADE:
			return {"type": "building_upgrade", "icon": icon, "text": display_name}
		ProphecyPatternScript.RewardType.TROOP_TRAINING:
			return {"type": "troop_training", "icon": icon, "text": display_name}
		ProphecyPatternScript.RewardType.PROPHECY:
			return {"type": "prophecy", "icon": icon, "text": display_name}
	return {"type": "placeholder", "icon": placeholder_icon, "text": "Reward"}
