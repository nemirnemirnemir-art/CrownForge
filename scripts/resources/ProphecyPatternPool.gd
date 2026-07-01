extends Node
class_name ProphecyPatternPool

@export var patterns: Array[ProphecyPattern] = []

const ProphecyPatternScript := preload("res://scripts/resources/ProphecyPattern.gd")
const ProphecyRewardPoolScript := preload("res://scripts/prophecy/modules/ProphecyRewardPool.gd")
const ProphecyPowerParserScript := preload("res://scripts/prophecy/modules/ProhesyMatesParser.gd")

const DEFAULT_JSON_PATH := "res://data/prophecy_patterns_pool.json"

func _ready() -> void:
	_load_from_json(DEFAULT_JSON_PATH)

func ensure_loaded() -> bool:
	if not patterns.is_empty():
		return true
	_load_from_json(DEFAULT_JSON_PATH)
	return not patterns.is_empty()

func _load_from_json(path: String) -> void:
	if not FileAccess.file_exists(path):
		push_warning("[ProphecyPatternPool] JSON not found: %s" % path)
		return

	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		push_warning("[ProphecyPatternPool] Failed to open JSON: %s" % path)
		return

	var txt := f.get_as_text()
	var parsed = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("[ProphecyPatternPool] Invalid JSON root (expected object): %s" % path)
		return

	var root: Dictionary = parsed
	if root.has("levels"):
		patterns = _build_generated_patterns(root)
		print("[ProphecyPatternPool] Loaded patterns from %s: %d" % [path, patterns.size()])
		return
	var defaults: Dictionary = root.get("defaults", {})
	var groups: Array = root.get("patterns", [])
	if groups == null:
		groups = []

	var out: Array[ProphecyPattern] = []
	for g in groups:
		if typeof(g) != TYPE_DICTIONARY:
			continue
		var gd: Dictionary = g
		var mobs: Array = gd.get("mobs", [])
		var rewards: Array = gd.get("rewards", [])
		if mobs == null:
			mobs = []
		if rewards == null:
			rewards = []

		for r in rewards:
			if typeof(r) != TYPE_DICTIONARY:
				continue
			var rd: Dictionary = r
			var reward_type_str := String(rd.get("type", ""))
			var count := int(rd.get("count", 0))
			if count <= 0:
				continue
			var reward_type := _parse_reward_type(reward_type_str)
			if reward_type < 0:
				push_warning("[ProphecyPatternPool] Unknown reward type in JSON: %s" % reward_type_str)
				continue
			var amount := _resolve_reward_amount(reward_type_str, rd, defaults)

			for i in range(count):
				var p: ProphecyPattern = ProphecyPatternScript.new()
				p.weight = 1
				_apply_mobs(p, mobs)
				p.reward_1_type = reward_type
				p.reward_1_amount = amount
				p.reward_2_enabled = false
				out.append(p)

	patterns = out
	print("[ProphecyPatternPool] Loaded patterns from %s: %d" % [path, patterns.size()])


func _build_generated_patterns(root: Dictionary) -> Array[ProphecyPattern]:
	var out: Array[ProphecyPattern] = []
	var levels: Array = root.get("levels", [])
	var powers: Dictionary = ProphecyPowerParserScript.get_fallback_powers()
	for level_entry in levels:
		if typeof(level_entry) != TYPE_DICTIONARY:
			continue
		var level_dict: Dictionary = level_entry
		var level := int(level_dict.get("level", 1))
		_append_generated_tier(out, level_dict.get("easy", []), level, ProphecyPatternScript.DifficultyTier.EASY, powers)
		_append_generated_tier(out, level_dict.get("mid", []), level, ProphecyPatternScript.DifficultyTier.MID, powers)
		_append_generated_tier(out, level_dict.get("hard", []), level, ProphecyPatternScript.DifficultyTier.HARD, powers)
	return out


func _append_generated_tier(out: Array[ProphecyPattern], groups_any: Variant, level: int, tier: int, powers: Dictionary) -> void:
	if not (groups_any is Array):
		return
	var groups: Array = groups_any
	for group_any in groups:
		if typeof(group_any) != TYPE_DICTIONARY:
			continue
		var group: Dictionary = group_any
		var variants_any = group.get("variants", [])
		if not (variants_any is Array):
			continue
		var variants: Array = variants_any
		var variant_index := 0
		for variant_any in variants:
			if typeof(variant_any) != TYPE_DICTIONARY:
				continue
			var variant: Dictionary = variant_any
			var pattern := _build_generated_pattern(group, variant, level, tier, powers, variant_index)
			if pattern != null:
				out.append(pattern)
			variant_index += 1


func _build_generated_pattern(group: Dictionary, variant: Dictionary, level: int, tier: int, powers: Dictionary, variant_index: int) -> ProphecyPattern:
	var mob_1_id := String(group.get("mob_1_id", "")).strip_edges().to_lower()
	if mob_1_id == "":
		return null
	var mob_1_count := int(variant.get("mob_1_count", 0))
	if mob_1_count <= 0:
		return null
	var pattern: ProphecyPattern = ProphecyPatternScript.new()
	pattern.mob_1_id = mob_1_id
	pattern.mob_1_count = mob_1_count
	pattern.mob_2_id = String(group.get("mob_2_id", "")).strip_edges().to_lower()
	pattern.mob_2_count = int(variant.get("mob_2_count", 0))
	pattern.mob_2_enabled = pattern.mob_2_id != "" and pattern.mob_2_count > 0
	pattern.level_min = int(group.get("level_min", level))
	pattern.level_max = int(group.get("level_max", level))
	pattern.family = String(group.get("family", "")).strip_edges().to_lower()
	pattern.reward_bias = String(group.get("reward_bias", pattern.family)).strip_edges().to_lower()
	pattern.primary_role = String(group.get("primary_role", "")).strip_edges().to_lower()
	pattern.secondary_role = String(group.get("secondary_role", "")).strip_edges().to_lower()
	pattern.is_rare_strong = bool(variant.get("is_rare_strong", group.get("is_rare_strong", false)))
	pattern.difficulty_tier = tier
	pattern.power_rating = _compute_generated_power(pattern, powers)
	_apply_generated_rewards(pattern, level, variant_index)
	return pattern


func _compute_generated_power(pattern: ProphecyPattern, powers: Dictionary) -> float:
	if pattern == null:
		return 0.0
	var total := float(powers.get(pattern.mob_1_id, 0.0)) * float(pattern.mob_1_count)
	if pattern.mob_2_enabled and pattern.mob_2_id != "":
		total += float(powers.get(pattern.mob_2_id, 0.0)) * float(pattern.mob_2_count)
	return total


func _apply_generated_rewards(pattern: ProphecyPattern, level: int, variant_index: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s|%s|%d|%s|%d|%s|%d" % [
		pattern.family,
		pattern.reward_bias,
		level,
		pattern.mob_1_id,
		pattern.mob_1_count,
		pattern.mob_2_id,
		variant_index,
	])
	var reward_pool := ProphecyRewardPoolScript.new()
	reward_pool.setup(rng)
	reward_pool.apply_rewards(pattern, level, pattern.power_rating)

func _apply_mobs(p: ProphecyPattern, mobs: Array) -> void:
	if mobs.is_empty():
		return
	var m1 = mobs[0]
	if typeof(m1) == TYPE_DICTIONARY:
		p.mob_1_id = String(m1.get("id", p.mob_1_id)).to_lower()
		p.mob_1_count = int(m1.get("count", p.mob_1_count))

	if mobs.size() >= 2:
		var m2 = mobs[1]
		if typeof(m2) == TYPE_DICTIONARY:
			p.mob_2_enabled = true
			p.mob_2_id = String(m2.get("id", "")).to_lower()
			p.mob_2_count = int(m2.get("count", 1))
		else:
			p.mob_2_enabled = false
	else:
		p.mob_2_enabled = false

func _resolve_reward_amount(reward_type_str: String, rd: Dictionary, defaults: Dictionary) -> int:
	if rd.has("amount"):
		return int(rd.get("amount"))
	if defaults.has(reward_type_str):
		return int(defaults.get(reward_type_str))
	return int(defaults.get("DEFAULT", 1))

func _parse_reward_type(type_str: String) -> int:
	match type_str:
		"DENARII":
			return int(ProphecyPatternScript.RewardType.DENARII)
		"RESOURCE":
			return int(ProphecyPatternScript.RewardType.RESOURCE)
		"BASIC_PRODUCTION":
			return int(ProphecyPatternScript.RewardType.BASIC_PRODUCTION)
		"ESTABLISHED_PRODUCTION":
			return int(ProphecyPatternScript.RewardType.ESTABLISHED_PRODUCTION)
		"ADVANCED_PRODUCTION":
			return int(ProphecyPatternScript.RewardType.ADVANCED_PRODUCTION)
		"LEVY_BARRACKS":
			return int(ProphecyPatternScript.RewardType.LEVY_BARRACKS)
		"VETERAN_BARRACKS":
			return int(ProphecyPatternScript.RewardType.VETERAN_BARRACKS)
		"ELITE_BARRACKS":
			return int(ProphecyPatternScript.RewardType.ELITE_BARRACKS)
		"KINGDOM_INFRASTRUCTURE":
			return int(ProphecyPatternScript.RewardType.KINGDOM_INFRASTRUCTURE)
		"ARTIFACT":
			return int(ProphecyPatternScript.RewardType.ARTIFACT)
		"LEGENDARY_ARTIFACT":
			return int(ProphecyPatternScript.RewardType.LEGENDARY_ARTIFACT)
		"SPELL":
			return int(ProphecyPatternScript.RewardType.SPELL)
		"LEGENDARY_SPELL":
			return int(ProphecyPatternScript.RewardType.LEGENDARY_SPELL)
		"BUILDING_UPGRADE":
			return int(ProphecyPatternScript.RewardType.BUILDING_UPGRADE)
		"TROOP_TRAINING":
			return int(ProphecyPatternScript.RewardType.TROOP_TRAINING)
		"PROPHECY":
			return int(ProphecyPatternScript.RewardType.PROPHECY)
		_:
			return -1
