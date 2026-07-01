extends RefCounted
class_name RewardPresentationRegistry

const ProphecyPatternScript := preload("res://scripts/resources/ProphecyPattern.gd")

const ICON_DENARII: Texture2D = preload("res://assets/ui/possible_rewards/Denarii.png")
const ICON_RESOURCE: Texture2D = preload("res://assets/ui/possible_rewards/Resource.png")
const ICON_BASIC_PROD: Texture2D = preload("res://assets/ui/possible_rewards/Basic Production.png")
const ICON_ESTABLISHED_PROD: Texture2D = preload("res://assets/ui/possible_rewards/Established Production.png")
const ICON_ADVANCED_PROD: Texture2D = preload("res://assets/ui/possible_rewards/Advanced Production.png")
const ICON_LEVY: Texture2D = preload("res://assets/ui/possible_rewards/Levy Barracks.png")
const ICON_VETERAN: Texture2D = preload("res://assets/ui/possible_rewards/Veteran Barracks.png")
const ICON_ELITE: Texture2D = preload("res://assets/ui/possible_rewards/Elite Barracks.png")
const ICON_INFRA: Texture2D = preload("res://assets/ui/possible_rewards/Kingdom Infrastructure.png")
const ICON_ARTIFACT: Texture2D = preload("res://assets/ui/possible_rewards/Artifact.png")
const ICON_LEGENDARY_ARTIFACT: Texture2D = preload("res://assets/ui/possible_rewards/Legendary Artifact.png")
const ICON_SPELL: Texture2D = preload("res://assets/ui/possible_rewards/Spell.png")
const ICON_LEGENDARY_SPELL: Texture2D = preload("res://assets/ui/possible_rewards/Legendary Spell.png")
const ICON_BUILDING_UPGRADE: Texture2D = preload("res://assets/ui/possible_rewards/Building Upgrade.png")
const ICON_TROOP_TRAINING: Texture2D = preload("res://assets/ui/possible_rewards/Troop Traning.png")
const ICON_PROPHECY: Texture2D = preload("res://assets/ui/possible_rewards/Prophesy.png")
const ICON_TRADER: Texture2D = preload("res://assets/ui/icons/trader_icon.png")

const _REWARD_ENTRIES: Array[Dictionary] = [
	{"type": ProphecyPatternScript.RewardType.DENARII, "name": "Denarii", "icon": ICON_DENARII},
	{"type": ProphecyPatternScript.RewardType.RESOURCE, "name": "Resource", "icon": ICON_RESOURCE},
	{"type": ProphecyPatternScript.RewardType.BASIC_PRODUCTION, "name": "Basic Production", "icon": ICON_BASIC_PROD},
	{"type": ProphecyPatternScript.RewardType.ESTABLISHED_PRODUCTION, "name": "Established Production", "icon": ICON_ESTABLISHED_PROD},
	{"type": ProphecyPatternScript.RewardType.ADVANCED_PRODUCTION, "name": "Advanced Production", "icon": ICON_ADVANCED_PROD},
	{"type": ProphecyPatternScript.RewardType.LEVY_BARRACKS, "name": "Levy Barracks", "icon": ICON_LEVY},
	{"type": ProphecyPatternScript.RewardType.VETERAN_BARRACKS, "name": "Veteran Barracks", "icon": ICON_VETERAN},
	{"type": ProphecyPatternScript.RewardType.ELITE_BARRACKS, "name": "Elite Barracks", "icon": ICON_ELITE},
	{"type": ProphecyPatternScript.RewardType.KINGDOM_INFRASTRUCTURE, "name": "Kingdom Infrastructure", "icon": ICON_INFRA},
	{"type": ProphecyPatternScript.RewardType.ARTIFACT, "name": "Artifact", "icon": ICON_ARTIFACT},
	{"type": ProphecyPatternScript.RewardType.LEGENDARY_ARTIFACT, "name": "Legendary Artifact", "icon": ICON_LEGENDARY_ARTIFACT},
	{"type": ProphecyPatternScript.RewardType.SPELL, "name": "Spell", "icon": ICON_SPELL},
	{"type": ProphecyPatternScript.RewardType.LEGENDARY_SPELL, "name": "Legendary Spell", "icon": ICON_LEGENDARY_SPELL},
	{"type": ProphecyPatternScript.RewardType.BUILDING_UPGRADE, "name": "Building Upgrade", "icon": ICON_BUILDING_UPGRADE},
	{"type": ProphecyPatternScript.RewardType.TROOP_TRAINING, "name": "Troop Training", "icon": ICON_TROOP_TRAINING},
	{"type": ProphecyPatternScript.RewardType.PROPHECY, "name": "Prophecy", "icon": ICON_PROPHECY},
]


static func get_reward_icon(reward_type: int) -> Texture2D:
	for entry in _REWARD_ENTRIES:
		if int(entry.get("type", -1)) == reward_type:
			return entry.get("icon", null) as Texture2D
	return null


static func get_reward_display_name(reward_type: int) -> String:
	for entry in _REWARD_ENTRIES:
		if int(entry.get("type", -1)) == reward_type:
			return str(entry.get("name", "Reward"))
	return "Reward"


static func get_reward_entries(include_prophecy: bool = false) -> Array:
	var out: Array = []
	for entry in _REWARD_ENTRIES:
		var reward_type := int(entry.get("type", -1))
		if not include_prophecy and reward_type == ProphecyPatternScript.RewardType.PROPHECY:
			continue
		out.append({
			"type": reward_type,
			"name": str(entry.get("name", "Reward")),
			"icon": entry.get("icon", null) as Texture2D,
		})
	return out


static func get_prophecy_icon() -> Texture2D:
	return ICON_PROPHECY


static func get_trader_icon() -> Texture2D:
	return ICON_TRADER
