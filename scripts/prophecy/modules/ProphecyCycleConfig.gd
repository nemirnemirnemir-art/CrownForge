extends RefCounted
class_name ProphecyCycleConfig

const ProphecyPatternScript := preload("res://scripts/resources/ProphecyPattern.gd")

const DEFAULT_JSON_PATH := "res://data/prophecy_cycle_config.json"

var _levels: Dictionary = {}


func _init(auto_load_default: bool = true) -> void:
	if auto_load_default:
		load_from_json(DEFAULT_JSON_PATH)


func load_from_json(path: String = DEFAULT_JSON_PATH) -> bool:
	_levels.clear()
	if not FileAccess.file_exists(path):
		push_warning("[ProphecyCycleConfig] JSON not found: %s" % path)
		return false

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("[ProphecyCycleConfig] Failed to open JSON: %s" % path)
		return false

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("[ProphecyCycleConfig] Invalid JSON root in %s" % path)
		return false

	var levels_var: Variant = (parsed as Dictionary).get("levels", [])
	if not (levels_var is Array):
		return false
	for level_entry in levels_var:
		if typeof(level_entry) != TYPE_DICTIONARY:
			continue
		var level_dict := level_entry as Dictionary
		var level := int(level_dict.get("level", 0))
		if level <= 0:
			continue
		_levels[level] = level_dict.duplicate(true)
	return not _levels.is_empty()


func has_intro_wave(level: int) -> bool:
	var intro := _get_section(level, "intro")
	return not _build_patterns(intro.get("patterns", [])).is_empty()


func get_intro_patterns(level: int) -> Array:
	var intro := _get_section(level, "intro")
	return _build_patterns(intro.get("patterns", []))


func get_intro_reward_bundle(level: int) -> Array:
	var intro := _get_section(level, "intro")
	return _build_reward_bundle(intro.get("reward_bundle", []))


func has_trader(level: int) -> bool:
	var trader := _get_section(level, "trader")
	return not _build_patterns(trader.get("patterns", [])).is_empty()


func get_trader_patterns(level: int) -> Array:
	var trader := _get_section(level, "trader")
	return _build_patterns(trader.get("patterns", []))


func has_final_boss(level: int) -> bool:
	var boss := _get_section(level, "boss")
	return not _build_patterns(boss.get("patterns", [])).is_empty()


func get_final_boss_patterns(level: int) -> Array:
	var boss := _get_section(level, "boss")
	return _build_patterns(boss.get("patterns", []))


func get_final_boss_rewards(level: int) -> Array:
	var boss := _get_section(level, "boss")
	return _build_reward_bundle(boss.get("reward_bundle", []))


func should_show_victory_after_rewards(level: int) -> bool:
	var boss := _get_section(level, "boss")
	return bool(boss.get("show_victory_after_rewards", false))


func _get_level(level: int) -> Dictionary:
	var raw: Variant = _levels.get(level, {})
	return raw.duplicate(true) if raw is Dictionary else {}


func _get_section(level: int, section_name: String) -> Dictionary:
	var level_dict := _get_level(level)
	var section: Variant = level_dict.get(section_name, {})
	return section.duplicate(true) if section is Dictionary else {}


func _build_patterns(patterns_var: Variant) -> Array:
	var result: Array = []
	if not (patterns_var is Array):
		return result
	for raw_pattern in patterns_var:
		if typeof(raw_pattern) != TYPE_DICTIONARY:
			continue
		var pattern_dict := raw_pattern as Dictionary
		var pattern := ProphecyPatternScript.new() as ProphecyPattern
		if pattern == null:
			continue
		pattern.mob_1_id = String(pattern_dict.get("mob_1_id", "")).strip_edges().to_lower()
		pattern.mob_1_count = int(pattern_dict.get("mob_1_count", 0))
		pattern.mob_2_id = String(pattern_dict.get("mob_2_id", "")).strip_edges().to_lower()
		pattern.mob_2_count = int(pattern_dict.get("mob_2_count", 0))
		pattern.mob_2_enabled = pattern.mob_2_id != "" and pattern.mob_2_count > 0
		if pattern.mob_1_id == "" or pattern.mob_1_count <= 0:
			continue
		result.append(pattern)
	return result


func _build_reward_bundle(bundle_var: Variant) -> Array:
	var result: Array = []
	if not (bundle_var is Array):
		return result
	for raw_reward in bundle_var:
		if typeof(raw_reward) != TYPE_DICTIONARY:
			continue
		var reward_dict := raw_reward as Dictionary
		var reward_type := _parse_reward_type(String(reward_dict.get("type", "")))
		if reward_type < 0:
			continue
		result.append({
			"type": reward_type,
			"amount": int(reward_dict.get("amount", 1)),
		})
	return result


func _parse_reward_type(type_name: String) -> int:
	match type_name.strip_edges().to_upper():
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
