extends RefCounted
class_name DebugProphecyTab

const ProphecyPatternPoolScript := preload("res://scripts/resources/ProphecyPatternPool.gd")
const ProphecyMenuStateScript := preload("res://scripts/ui/prophecy/modules/ProphecyMenuState.gd")
const ProphecyPatternScript := preload("res://scripts/resources/ProphecyPattern.gd")


func build_ui(parent: Control) -> void:
	var pattern_pool: ProphecyPatternPool = ProphecyPatternPoolScript.new()
	pattern_pool.ensure_loaded()

	for level in range(1, 5):
		_build_prophecy_level(parent, level, pattern_pool)


func _build_prophecy_level(parent: Control, level: int, pattern_pool: ProphecyPatternPool) -> void:
	var level_title := Label.new()
	level_title.text = "PROPHECY %d" % level
	level_title.add_theme_font_size_override("font_size", 20)
	parent.add_child(level_title)

	var level_box := VBoxContainer.new()
	level_box.add_theme_constant_override("separation", 6)
	parent.add_child(level_box)

	var sequence_label := Label.new()
	sequence_label.text = "Sequence: %s" % _build_sequence_text(level)
	level_box.add_child(sequence_label)

	var generated_by_tier := _generate_by_tier(pattern_pool, level)
	_add_tier_block(level_box, "EASY", generated_by_tier[int(ProphecyPatternScript.DifficultyTier.EASY)])
	_add_tier_block(level_box, "MID", generated_by_tier[int(ProphecyPatternScript.DifficultyTier.MID)])
	_add_tier_block(level_box, "HARD", generated_by_tier[int(ProphecyPatternScript.DifficultyTier.HARD)])

	parent.add_child(HSeparator.new())


func _generate_by_tier(pattern_pool: ProphecyPatternPool, level: int) -> Dictionary:
	var state = ProphecyMenuStateScript.new()
	state.setup()
	state.reset(pattern_pool, level, 0)
	var generated_options: Array = state.generate_wave_options()
	var grouped := {
		int(ProphecyPatternScript.DifficultyTier.EASY): [],
		int(ProphecyPatternScript.DifficultyTier.MID): [],
		int(ProphecyPatternScript.DifficultyTier.HARD): [],
	}
	for option in generated_options:
		var pattern := state.extract_single_pattern(option)
		if pattern == null:
			continue
		var tier_key := int(pattern.difficulty_tier)
		if not grouped.has(tier_key):
			grouped[tier_key] = []
		grouped[tier_key].append(pattern)
	return grouped


func _add_tier_block(parent: Control, tier_name: String, patterns: Array) -> void:
	var tier_label := Label.new()
	tier_label.text = "%s (%d)" % [tier_name, patterns.size()]
	tier_label.add_theme_font_size_override("font_size", 14)
	parent.add_child(tier_label)
	if patterns.is_empty():
		_add_empty_label(parent, "No patterns")
		return
	for raw_pattern in patterns:
		var pattern := raw_pattern as ProphecyPattern
		if pattern == null:
			continue
		var pattern_label := Label.new()
		pattern_label.text = _format_pattern(pattern)
		parent.add_child(pattern_label)


func _add_empty_label(parent: Control, text: String) -> void:
	var empty_label := Label.new()
	empty_label.text = text
	empty_label.modulate = Color(0.75, 0.75, 0.75)
	parent.add_child(empty_label)


func _format_pattern(pattern: ProphecyPattern) -> String:
	var parts: Array[String] = []
	parts.append("%s x%d" % [_format_id(pattern.mob_1_id), int(pattern.mob_1_count)])
	if pattern.mob_2_enabled and pattern.mob_2_id != "":
		parts.append("%s x%d" % [_format_id(pattern.mob_2_id), int(pattern.mob_2_count)])
	return " + ".join(parts)


func _format_id(raw_id: String) -> String:
	var parts: PackedStringArray = raw_id.split("_", false)
	var words: Array[String] = []
	for part in parts:
		words.append(String(part).capitalize())
	return " ".join(words)


func _build_sequence_text(level: int) -> String:
	var parts: Array[String] = ["P%d" % level, "1", "2", "3"]
	if level < 4:
		parts.append("T")
	else:
		parts.append("B")
	return " ".join(parts)
