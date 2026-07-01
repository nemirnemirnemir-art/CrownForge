extends SceneTree

const RegistryScript := preload("res://scripts/ui/rewards/RewardPresentationRegistry.gd")
const ProphecyPatternScript := preload("res://scripts/resources/ProphecyPattern.gd")


func _init() -> void:
	var reward_types: Array[int] = [
		ProphecyPatternScript.RewardType.DENARII,
		ProphecyPatternScript.RewardType.RESOURCE,
		ProphecyPatternScript.RewardType.BASIC_PRODUCTION,
		ProphecyPatternScript.RewardType.ESTABLISHED_PRODUCTION,
		ProphecyPatternScript.RewardType.ADVANCED_PRODUCTION,
		ProphecyPatternScript.RewardType.LEVY_BARRACKS,
		ProphecyPatternScript.RewardType.VETERAN_BARRACKS,
		ProphecyPatternScript.RewardType.ELITE_BARRACKS,
		ProphecyPatternScript.RewardType.KINGDOM_INFRASTRUCTURE,
		ProphecyPatternScript.RewardType.ARTIFACT,
		ProphecyPatternScript.RewardType.LEGENDARY_ARTIFACT,
		ProphecyPatternScript.RewardType.SPELL,
		ProphecyPatternScript.RewardType.LEGENDARY_SPELL,
		ProphecyPatternScript.RewardType.BUILDING_UPGRADE,
		ProphecyPatternScript.RewardType.TROOP_TRAINING,
		ProphecyPatternScript.RewardType.PROPHECY,
	]

	for t in reward_types:
		var icon: Texture2D = RegistryScript.get_reward_icon(t)
		if icon == null:
			push_error("[test_reward_presentation_registry_consistency] missing icon for reward type=%d" % t)
			quit(1)
			return
		var name: String = RegistryScript.get_reward_display_name(t)
		if name.strip_edges() == "" or name == "Reward":
			push_error("[test_reward_presentation_registry_consistency] invalid name for reward type=%d, got '%s'" % [t, name])
			quit(1)
			return

	var entries_without_prophecy: Array = RegistryScript.get_reward_entries(false)
	for e in entries_without_prophecy:
		var reward_type := int((e as Dictionary).get("type", -1))
		if reward_type == ProphecyPatternScript.RewardType.PROPHECY:
			push_error("[test_reward_presentation_registry_consistency] prophecy reward must be excluded when include_prophecy=false")
			quit(1)
			return

	var found_prophecy_with_include := false
	var entries_with_prophecy: Array = RegistryScript.get_reward_entries(true)
	for e in entries_with_prophecy:
		var reward_type := int((e as Dictionary).get("type", -1))
		if reward_type == ProphecyPatternScript.RewardType.PROPHECY:
			found_prophecy_with_include = true
			break

	if not found_prophecy_with_include:
		push_error("[test_reward_presentation_registry_consistency] prophecy reward missing when include_prophecy=true")
		quit(1)
		return

	print("[test_reward_presentation_registry_consistency] PASS")
	quit(0)
