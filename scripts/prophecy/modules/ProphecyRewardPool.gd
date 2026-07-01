extends RefCounted
class_name ProphecyRewardPool

const ProphecyPatternScript := preload("res://scripts/resources/ProphecyPattern.gd")

const LEVEL_1_STRONG_POWER: float = 52.0
const LEVEL_2_STRONG_POWER: float = 82.0
const LEVEL_3_STRONG_POWER: float = 122.0
const LEVEL_4_STRONG_POWER: float = 170.0
const LEVEL_5_STRONG_POWER: float = 235.0

var _rng: RandomNumberGenerator = null


func setup(rng: RandomNumberGenerator) -> void:
	_rng = rng


func apply_rewards(p: Resource, prophecy_level: int, pattern_power: float) -> void:
	var reward_bias: String = ""
	var is_rare_strong: bool = false
	if p != null:
		var bias_value: Variant = p.get("reward_bias")
		if bias_value != null:
			reward_bias = String(bias_value)
		var rare_value: Variant = p.get("is_rare_strong")
		if rare_value != null:
			is_rare_strong = bool(rare_value)

	var candidates: Array = get_reward_candidates(prophecy_level, pattern_power, reward_bias, is_rare_strong)
	if candidates.is_empty():
		candidates = [_make_reward_entry(ProphecyPatternScript.RewardType.DENARII, 30)]

	var first_reward: Dictionary = _pick_reward_entry(candidates)
	p.reward_1_type = int(first_reward.get("type", ProphecyPatternScript.RewardType.DENARII))
	p.reward_1_amount = int(first_reward.get("amount", 1))
	p.reward_2_enabled = false

	if prophecy_level == 1:
		return

	if _should_grant_second_reward(prophecy_level, pattern_power, reward_bias):
		var secondary_candidates: Array = candidates.duplicate(true)
		_remove_matching_reward(secondary_candidates, int(first_reward.get("type", -1)), int(first_reward.get("amount", -1)))
		if not secondary_candidates.is_empty():
			var second_reward: Dictionary = _pick_reward_entry(secondary_candidates)
			p.reward_2_enabled = true
			p.reward_2_type = int(second_reward.get("type", ProphecyPatternScript.RewardType.DENARII))
			p.reward_2_amount = int(second_reward.get("amount", 1))


func get_reward_candidates(prophecy_level: int, pattern_power: float, reward_bias: String = "", is_rare_strong: bool = false) -> Array:
	var lvl: int = clampi(prophecy_level, 1, 7)
	var strong_pattern: bool = _is_strong_pattern(lvl, pattern_power)
	var boosted_level_2: bool = strong_pattern or reward_bias.strip_edges().to_lower() == "mid_strong"
	var candidates: Array = []

	match lvl:
		1:
			if is_rare_strong:
				candidates = [
					_make_reward_entry(ProphecyPatternScript.RewardType.ESTABLISHED_PRODUCTION, 1),
					_make_reward_entry(ProphecyPatternScript.RewardType.VETERAN_BARRACKS, 1),
					_make_reward_entry(ProphecyPatternScript.RewardType.ARTIFACT, 1),
				]
			else:
				candidates = [
					_make_reward_entry(ProphecyPatternScript.RewardType.DENARII, 30),
					_make_reward_entry(ProphecyPatternScript.RewardType.RESOURCE, 45),
					_make_reward_entry(ProphecyPatternScript.RewardType.BASIC_PRODUCTION, 1),
					_make_reward_entry(ProphecyPatternScript.RewardType.LEVY_BARRACKS, 1),
				]
		2:
			candidates = [
				_make_reward_entry(ProphecyPatternScript.RewardType.DENARII, 50 if boosted_level_2 else 40),
				_make_reward_entry(ProphecyPatternScript.RewardType.RESOURCE, 60 if boosted_level_2 else 45),
				_make_reward_entry(ProphecyPatternScript.RewardType.BASIC_PRODUCTION, 1),
				_make_reward_entry(ProphecyPatternScript.RewardType.ESTABLISHED_PRODUCTION, 1),
				_make_reward_entry(ProphecyPatternScript.RewardType.ADVANCED_PRODUCTION, 1),
				_make_reward_entry(ProphecyPatternScript.RewardType.LEVY_BARRACKS, 1),
				_make_reward_entry(ProphecyPatternScript.RewardType.VETERAN_BARRACKS, 1),
				_make_reward_entry(ProphecyPatternScript.RewardType.ARTIFACT, 1),
				_make_reward_entry(ProphecyPatternScript.RewardType.SPELL, 1),
			]
			if boosted_level_2:
				candidates.append(_make_reward_entry(ProphecyPatternScript.RewardType.TROOP_TRAINING, 1))
		3:
			candidates = [
				_make_reward_entry(ProphecyPatternScript.RewardType.DENARII, 50),
				_make_reward_entry(ProphecyPatternScript.RewardType.RESOURCE, 60),
				_make_reward_entry(ProphecyPatternScript.RewardType.BASIC_PRODUCTION, 1),
				_make_reward_entry(ProphecyPatternScript.RewardType.ESTABLISHED_PRODUCTION, 1),
				_make_reward_entry(ProphecyPatternScript.RewardType.ADVANCED_PRODUCTION, 1),
				_make_reward_entry(ProphecyPatternScript.RewardType.LEVY_BARRACKS, 1),
				_make_reward_entry(ProphecyPatternScript.RewardType.VETERAN_BARRACKS, 1),
				_make_reward_entry(ProphecyPatternScript.RewardType.KINGDOM_INFRASTRUCTURE, 1),
				_make_reward_entry(ProphecyPatternScript.RewardType.ARTIFACT, 1),
				_make_reward_entry(ProphecyPatternScript.RewardType.SPELL, 1),
				_make_reward_entry(ProphecyPatternScript.RewardType.BUILDING_UPGRADE, 1),
				_make_reward_entry(ProphecyPatternScript.RewardType.TROOP_TRAINING, 1),
			]
		4:
			candidates = [
				_make_reward_entry(ProphecyPatternScript.RewardType.DENARII, 60),
				_make_reward_entry(ProphecyPatternScript.RewardType.RESOURCE, 90),
				_make_reward_entry(ProphecyPatternScript.RewardType.BASIC_PRODUCTION, 1),
				_make_reward_entry(ProphecyPatternScript.RewardType.ESTABLISHED_PRODUCTION, 1),
				_make_reward_entry(ProphecyPatternScript.RewardType.ADVANCED_PRODUCTION, 1),
				_make_reward_entry(ProphecyPatternScript.RewardType.LEVY_BARRACKS, 1),
				_make_reward_entry(ProphecyPatternScript.RewardType.VETERAN_BARRACKS, 1),
				_make_reward_entry(ProphecyPatternScript.RewardType.ELITE_BARRACKS, 1),
				_make_reward_entry(ProphecyPatternScript.RewardType.KINGDOM_INFRASTRUCTURE, 1),
				_make_reward_entry(ProphecyPatternScript.RewardType.ARTIFACT, 1),
				_make_reward_entry(ProphecyPatternScript.RewardType.SPELL, 1),
				_make_reward_entry(ProphecyPatternScript.RewardType.BUILDING_UPGRADE, 1),
			]
		5:
			candidates = [
				_make_reward_entry(ProphecyPatternScript.RewardType.DENARII, 30),
				_make_reward_entry(ProphecyPatternScript.RewardType.ESTABLISHED_PRODUCTION, 1),
				_make_reward_entry(ProphecyPatternScript.RewardType.SPELL, 1),
				_make_reward_entry(ProphecyPatternScript.RewardType.ARTIFACT, 1),
				_make_reward_entry(ProphecyPatternScript.RewardType.TROOP_TRAINING, 1),
				_make_reward_entry(ProphecyPatternScript.RewardType.PROPHECY, 1),
			]
			if strong_pattern:
				candidates.append(_make_reward_entry(ProphecyPatternScript.RewardType.VETERAN_BARRACKS, 1))
				candidates.append(_make_reward_entry(ProphecyPatternScript.RewardType.ADVANCED_PRODUCTION, 1))
		_:
			candidates = [
				_make_reward_entry(ProphecyPatternScript.RewardType.DENARII, 30),
				_make_reward_entry(ProphecyPatternScript.RewardType.RESOURCE, 90),
				_make_reward_entry(ProphecyPatternScript.RewardType.SPELL, 1),
				_make_reward_entry(ProphecyPatternScript.RewardType.ARTIFACT, 1),
				_make_reward_entry(ProphecyPatternScript.RewardType.VETERAN_BARRACKS, 1),
			]
			if strong_pattern:
				candidates.append(_make_reward_entry(ProphecyPatternScript.RewardType.LEGENDARY_SPELL, 1))
				candidates.append(_make_reward_entry(ProphecyPatternScript.RewardType.LEGENDARY_ARTIFACT, 1))

	if lvl != 1:
		_apply_reward_bias(candidates, lvl, reward_bias, strong_pattern)
	return candidates


func get_default_reward_bundle(prophecy_level: int) -> Array:
	var lvl: int = clampi(prophecy_level, 1, 7)
	match lvl:
		1:
			return [
				_make_reward_entry(ProphecyPatternScript.RewardType.DENARII, 10),
				_make_reward_entry(ProphecyPatternScript.RewardType.LEVY_BARRACKS, 1),
				_make_reward_entry(ProphecyPatternScript.RewardType.BASIC_PRODUCTION, 1),
				_make_reward_entry(ProphecyPatternScript.RewardType.PROPHECY, 1),
			]
		2:
			return [
				_make_reward_entry(ProphecyPatternScript.RewardType.DENARII, 10),
				_make_reward_entry(ProphecyPatternScript.RewardType.LEVY_BARRACKS, 1),
				_make_reward_entry(ProphecyPatternScript.RewardType.BASIC_PRODUCTION, 1),
				_make_reward_entry(ProphecyPatternScript.RewardType.BASIC_PRODUCTION, 1),
				_make_reward_entry(ProphecyPatternScript.RewardType.ARTIFACT, 1),
				_make_reward_entry(ProphecyPatternScript.RewardType.BUILDING_UPGRADE, 1),
				_make_reward_entry(ProphecyPatternScript.RewardType.PROPHECY, 1),
			]
		3:
			return [
				_make_reward_entry(ProphecyPatternScript.RewardType.DENARII, 10),
				_make_reward_entry(ProphecyPatternScript.RewardType.BASIC_PRODUCTION, 1),
				_make_reward_entry(ProphecyPatternScript.RewardType.ESTABLISHED_PRODUCTION, 1),
				_make_reward_entry(ProphecyPatternScript.RewardType.LEVY_BARRACKS, 1),
				_make_reward_entry(ProphecyPatternScript.RewardType.SPELL, 1),
				_make_reward_entry(ProphecyPatternScript.RewardType.ARTIFACT, 1),
				_make_reward_entry(ProphecyPatternScript.RewardType.PROPHECY, 1),
			]
		4:
			return [_make_reward_entry(ProphecyPatternScript.RewardType.PROPHECY, 1)]
		5:
			return get_boss_reward_bundle(lvl)
		_:
			return [
				_make_reward_entry(ProphecyPatternScript.RewardType.DENARII, 10),
				_make_reward_entry(ProphecyPatternScript.RewardType.PROPHECY, 1),
			]


func get_boss_reward_bundle(prophecy_level: int) -> Array:
	var lvl: int = clampi(prophecy_level, 1, 7)
	if lvl < 4:
		return []
	if lvl == 4:
		return [
			_make_reward_entry(ProphecyPatternScript.RewardType.DENARII, 10),
			_make_reward_entry(ProphecyPatternScript.RewardType.LEGENDARY_ARTIFACT, 1),
			_make_reward_entry(ProphecyPatternScript.RewardType.LEGENDARY_SPELL, 1),
			_make_reward_entry(ProphecyPatternScript.RewardType.VETERAN_BARRACKS, 1),
			_make_reward_entry(ProphecyPatternScript.RewardType.ESTABLISHED_PRODUCTION, 1),
			_make_reward_entry(ProphecyPatternScript.RewardType.TROOP_TRAINING, 1),
		]
	return [
		_make_reward_entry(ProphecyPatternScript.RewardType.DENARII, 10),
		_make_reward_entry(ProphecyPatternScript.RewardType.LEGENDARY_ARTIFACT, 1),
		_make_reward_entry(ProphecyPatternScript.RewardType.LEGENDARY_SPELL, 1),
		_make_reward_entry(ProphecyPatternScript.RewardType.VETERAN_BARRACKS, 1),
		_make_reward_entry(ProphecyPatternScript.RewardType.ESTABLISHED_PRODUCTION, 1),
		_make_reward_entry(ProphecyPatternScript.RewardType.TROOP_TRAINING, 1),
		_make_reward_entry(ProphecyPatternScript.RewardType.PROPHECY, 1),
	]


func _make_reward_entry(reward_type: int, amount: int = 1) -> Dictionary:
	return {
		"type": reward_type,
		"amount": amount,
	}


func _pick_reward_entry(candidates: Array) -> Dictionary:
	if candidates.is_empty():
		return _make_reward_entry(ProphecyPatternScript.RewardType.DENARII, 30)
	if _rng == null:
		return candidates[0] as Dictionary
	var picked_index: int = _rng.randi_range(0, candidates.size() - 1)
	return candidates[picked_index] as Dictionary


func _remove_matching_reward(candidates: Array, reward_type: int, amount: int) -> void:
	for i in range(candidates.size() - 1, -1, -1):
		var candidate: Dictionary = candidates[i] as Dictionary
		if int(candidate.get("type", -1)) == reward_type and int(candidate.get("amount", -1)) == amount:
			candidates.remove_at(i)
			return


func _is_strong_pattern(prophecy_level: int, pattern_power: float) -> bool:
	var lvl: int = clampi(prophecy_level, 1, 7)
	match lvl:
		1:
			return pattern_power >= LEVEL_1_STRONG_POWER
		2:
			return pattern_power >= LEVEL_2_STRONG_POWER
		3:
			return pattern_power >= LEVEL_3_STRONG_POWER
		4:
			return pattern_power >= LEVEL_4_STRONG_POWER
		_:
			return pattern_power >= LEVEL_5_STRONG_POWER


func _should_grant_second_reward(prophecy_level: int, pattern_power: float, reward_bias: String = "") -> bool:
	var lvl: int = clampi(prophecy_level, 1, 7)
	if lvl <= 4:
		return false
	return _is_strong_pattern(lvl, pattern_power)


func _apply_reward_bias(candidates: Array, prophecy_level: int, reward_bias: String, strong_pattern: bool) -> void:
	var bias: String = reward_bias.strip_edges().to_lower()
	if bias == "":
		return
	match bias:
		"swarm":
			candidates.append(_make_reward_entry(ProphecyPatternScript.RewardType.DENARII, 45 if prophecy_level >= 4 else 30))
			candidates.append(_make_reward_entry(ProphecyPatternScript.RewardType.RESOURCE, 90 if prophecy_level >= 4 else 45))
		"gunline", "flank_pressure":
			candidates.append(_make_reward_entry(ProphecyPatternScript.RewardType.SPELL, 1))
			if prophecy_level >= 3 or strong_pattern:
				candidates.append(_make_reward_entry(ProphecyPatternScript.RewardType.TROOP_TRAINING, 1))
		"support_pack":
			candidates.append(_make_reward_entry(ProphecyPatternScript.RewardType.SPELL, 1))
			candidates.append(_make_reward_entry(ProphecyPatternScript.RewardType.ARTIFACT, 1))
			if prophecy_level >= 3 and strong_pattern:
				candidates.append(_make_reward_entry(ProphecyPatternScript.RewardType.BUILDING_UPGRADE, 1))
		"siege":
			if prophecy_level >= 3:
				candidates.append(_make_reward_entry(ProphecyPatternScript.RewardType.BUILDING_UPGRADE, 1))
				candidates.append(_make_reward_entry(ProphecyPatternScript.RewardType.TROOP_TRAINING, 1))
			if prophecy_level >= 4:
				candidates.append(_make_reward_entry(ProphecyPatternScript.RewardType.KINGDOM_INFRASTRUCTURE, 1))
		"elite_wall", "mixed_threat":
			candidates.append(_make_reward_entry(ProphecyPatternScript.RewardType.ARTIFACT, 1))
			candidates.append(_make_reward_entry(ProphecyPatternScript.RewardType.ADVANCED_PRODUCTION, 1))
			if strong_pattern:
				candidates.append(_make_reward_entry(ProphecyPatternScript.RewardType.VETERAN_BARRACKS, 1))
