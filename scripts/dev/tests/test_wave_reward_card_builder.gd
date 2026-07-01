extends SceneTree

const BUILDER_PATH := "res://scripts/ui/rewards/modules/WaveRewardCardBuilder.gd"
const ProphecyPatternScript := preload("res://scripts/resources/ProphecyPattern.gd")


func _init() -> void:
	call_deferred("_run_test")


func _assert(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("[test_wave_reward_card_builder] %s" % message)
	quit(1)
	return false


func _find_card(cards: Array, expected_type: String) -> Dictionary:
	for raw_card in cards:
		if raw_card is Dictionary:
			var card := raw_card as Dictionary
			if String(card.get("type", "")) == expected_type:
				return card
	return {}


func _run_test() -> void:
	var builder_script := load(BUILDER_PATH)
	if not _assert(builder_script != null, "failed to load WaveRewardCardBuilder.gd"):
		return

	var builder = builder_script.new()
	if not _assert(builder != null, "failed to instantiate WaveRewardCardBuilder"):
		return

	var mapped_result: Dictionary = builder.call("build", [
		{"type": ProphecyPatternScript.RewardType.DENARII, "amount": 30},
		{"type": ProphecyPatternScript.RewardType.RESOURCE, "amount": 45},
		{"type": ProphecyPatternScript.RewardType.BASIC_PRODUCTION, "amount": 1},
		{"type": ProphecyPatternScript.RewardType.ESTABLISHED_PRODUCTION, "amount": 1},
		{"type": ProphecyPatternScript.RewardType.ADVANCED_PRODUCTION, "amount": 1},
		{"type": ProphecyPatternScript.RewardType.LEVY_BARRACKS, "amount": 1},
		{"type": ProphecyPatternScript.RewardType.VETERAN_BARRACKS, "amount": 1},
		{"type": ProphecyPatternScript.RewardType.ELITE_BARRACKS, "amount": 1},
		{"type": ProphecyPatternScript.RewardType.KINGDOM_INFRASTRUCTURE, "amount": 1},
		{"type": ProphecyPatternScript.RewardType.ARTIFACT, "amount": 1},
		{"type": ProphecyPatternScript.RewardType.LEGENDARY_ARTIFACT, "amount": 1},
		{"type": ProphecyPatternScript.RewardType.SPELL, "amount": 1},
		{"type": ProphecyPatternScript.RewardType.LEGENDARY_SPELL, "amount": 1},
		{"type": ProphecyPatternScript.RewardType.BUILDING_UPGRADE, "amount": 1},
		{"type": ProphecyPatternScript.RewardType.TROOP_TRAINING, "amount": 1},
		{"type": ProphecyPatternScript.RewardType.PROPHECY, "amount": 1},
		{"custom_id": "trader"},
		{"custom_id": "no_rewards"},
		{"type": 999, "amount": 7},
	], false, 1)
	var cards: Array = mapped_result.get("cards", []) as Array
	if not _assert(cards.size() == 19, "expected 19 mapped reward cards"):
		return
	if not _assert(_find_card(cards, "denarii:30").get("text", "") == "Denarii 30", "denarii mapping must preserve amount text"):
		return
	if not _assert(_find_card(cards, "resource:45").get("text", "") == "Resource 45", "resource mapping must preserve amount text"):
		return
	if not _assert(_find_card(cards, "production_basic").get("text", "") == "Basic Production", "basic production mapping changed"):
		return
	if not _assert(_find_card(cards, "production_established").get("text", "") == "Established Production", "established production mapping changed"):
		return
	if not _assert(_find_card(cards, "production_advanced").get("text", "") == "Advanced Production", "advanced production mapping changed"):
		return
	if not _assert(_find_card(cards, "levy").get("text", "") == "Levy Barracks", "levy mapping changed"):
		return
	if not _assert(_find_card(cards, "veteran").get("text", "") == "Veteran Barracks", "veteran mapping changed"):
		return
	if not _assert(_find_card(cards, "elite").get("text", "") == "Elite Barracks", "elite mapping changed"):
		return
	if not _assert(_find_card(cards, "infrastructure").get("text", "") == "Kingdom Infrastructure", "infrastructure mapping changed"):
		return
	if not _assert(_find_card(cards, "artifact").get("text", "") == "Artifact", "artifact mapping changed"):
		return
	if not _assert(_find_card(cards, "legendary_artifact").get("text", "") == "Legendary Artifact", "legendary artifact mapping changed"):
		return
	if not _assert(_find_card(cards, "spell").get("text", "") == "Spell", "spell mapping changed"):
		return
	if not _assert(_find_card(cards, "legendary_spell").get("text", "") == "Legendary Spell", "legendary spell mapping changed"):
		return
	if not _assert(_find_card(cards, "building_upgrade").get("text", "") == "Building Upgrade", "building upgrade mapping changed"):
		return
	if not _assert(_find_card(cards, "troop_training").get("text", "") == "Troop Training", "troop training mapping changed"):
		return
	if not _assert(_find_card(cards, "prophecy").get("text", "") == "Prophecy", "prophecy mapping changed"):
		return
	if not _assert(_find_card(cards, "trader").get("text", "") == "Trader", "trader custom reward mapping changed"):
		return
	if not _assert(_find_card(cards, "no_reward").get("text", "") == "No rewards", "no reward custom mapping changed"):
		return
	var placeholder_card := _find_card(cards, "placeholder")
	if not _assert(placeholder_card.get("text", "") == "Reward", "unknown reward mapping must still fall back to placeholder card"):
		return
	if not _assert(placeholder_card.get("icon", null) != null, "placeholder reward must keep non-null fallback icon"):
		return

	var defaults_result: Dictionary = builder.call("build", [], true, 1)
	var default_cards: Array = defaults_result.get("cards", []) as Array
	var resolved_override: Array = defaults_result.get("resolved_override", []) as Array
	if not _assert(default_cards.size() == 4, "prophecy default path must still produce four cards at level 1"):
		return
	if not _assert(resolved_override.size() == 4, "prophecy default path must still resolve override payload"):
		return
	if not _assert(_find_card(default_cards, "denarii:10").get("text", "") == "Denarii 10", "default prophecy denarii card changed"):
		return
	if not _assert(_find_card(default_cards, "levy").get("text", "") == "Levy Barracks", "default prophecy levy card changed"):
		return
	if not _assert(_find_card(default_cards, "production_basic").get("text", "") == "Basic Production", "default prophecy production card changed"):
		return
	if not _assert(_find_card(default_cards, "prophecy").get("text", "") == "Prophecy", "default prophecy card changed"):
		return

	var empty_result: Dictionary = builder.call("build", [null], false, 1)
	var empty_cards: Array = empty_result.get("cards", []) as Array
	if not _assert(empty_cards.size() == 1, "empty reward override must still emit fallback no_reward card"):
		return
	if not _assert(_find_card(empty_cards, "no_reward").get("text", "") == "No rewards", "fallback no_reward card text changed"):
		return

	print("[test_wave_reward_card_builder] PASS")
	quit(0)
