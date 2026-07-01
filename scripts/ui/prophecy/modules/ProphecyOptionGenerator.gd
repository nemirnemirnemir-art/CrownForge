extends RefCounted
class_name ProphecyOptionGenerator

const ProphecyWaveGeneratorScript := preload("res://scripts/prophecy/ProphecyWaveGenerator.gd")
const ProphecyPatternScript := preload("res://scripts/resources/ProphecyPattern.gd")
const MAX_ARTIFACT_REWARD_OPTIONS: int = 3

const HARD_OPTION_COUNT: int = 6
const MID_OPTION_COUNT: int = 6
const EASY_OPTION_COUNT: int = 6

var _rng: RandomNumberGenerator = null
var _prophecy_level: int = 1
var _pattern_pool: ProphecyPatternPool = null

func setup(rng: RandomNumberGenerator, prophecy_level: int = 1, pattern_pool: ProphecyPatternPool = null) -> void:
    _rng = rng
    _prophecy_level = max(1, prophecy_level)
    _pattern_pool = pattern_pool

func generate_wave_options() -> Array:
    var result: Array = []
    var family_counts: Dictionary = {}

    var gen := ProphecyWaveGeneratorScript.new()
    if gen:
        gen.setup(_rng, HARD_OPTION_COUNT + MID_OPTION_COUNT + EASY_OPTION_COUNT, _prophecy_level)

    var bands := _split_power_bands(gen)

    var pooled_by_tier := _build_pooled_options_by_tier(
        float(bands.get("easy_min", 60.0)),
        float(bands.get("easy_max", 80.0)),
        float(bands.get("mid_min", 80.0)),
        float(bands.get("mid_max", 100.0)),
        float(bands.get("hard_min", 100.0)),
        float(bands.get("hard_max", 120.0))
    )

    result.append_array(_merge_with_fallback(
        pooled_by_tier.get(int(ProphecyPattern.DifficultyTier.HARD), []),
        gen,
        ProphecyPattern.DifficultyTier.HARD,
        HARD_OPTION_COUNT,
        float(bands.get("hard_min", 100.0)),
        float(bands.get("hard_max", 120.0)),
        family_counts
    ))
    result.append_array(_merge_with_fallback(
        pooled_by_tier.get(int(ProphecyPattern.DifficultyTier.MID), []),
        gen,
        ProphecyPattern.DifficultyTier.MID,
        MID_OPTION_COUNT,
        float(bands.get("mid_min", 80.0)),
        float(bands.get("mid_max", 100.0)),
        family_counts
    ))
    result.append_array(_merge_with_fallback(
        pooled_by_tier.get(int(ProphecyPattern.DifficultyTier.EASY), []),
        gen,
        ProphecyPattern.DifficultyTier.EASY,
        EASY_OPTION_COUNT,
        float(bands.get("easy_min", 60.0)),
        float(bands.get("easy_max", 80.0)),
        family_counts
    ))

    _limit_artifact_reward_options(result)
    return result

func _merge_with_fallback(
    pooled_options: Array,
    gen: ProphecyWaveGenerator,
    tier: int,
    count: int,
    min_power: float,
    max_power: float,
    family_counts: Dictionary
) -> Array:
    var out: Array = []
    var seen_signatures: Dictionary = {}

    for option in pooled_options:
        if out.size() >= count:
            break
        if not (option is Array) or option.is_empty():
            continue
        var pattern := option[0] as ProphecyPattern
        if pattern == null:
            continue
        var signature := _build_pattern_signature(pattern)
        if seen_signatures.has(signature):
            continue
        if not _can_add_family(pattern, family_counts):
            continue
        seen_signatures[signature] = true
        out.append([pattern])
        _register_family(pattern, family_counts)

    if _pattern_pool != null and not _pattern_pool.patterns.is_empty():
        if out.size() < count:
            for option in pooled_options:
                if out.size() >= count:
                    break
                if not (option is Array) or option.is_empty():
                    continue
                var pattern_relaxed := option[0] as ProphecyPattern
                if pattern_relaxed == null:
                    continue
                var relaxed_signature := _build_pattern_signature(pattern_relaxed)
                if seen_signatures.has(relaxed_signature):
                    continue
                seen_signatures[relaxed_signature] = true
                out.append([pattern_relaxed])
                _register_family(pattern_relaxed, family_counts)

    var fallback_options := _generate_single_pattern_options(gen, tier, count - out.size(), min_power, max_power)
    for option in fallback_options:
        if out.size() >= count:
            break
        if not (option is Array) or option.is_empty():
            continue
        var pattern := option[0] as ProphecyPattern
        if pattern == null:
            continue
        var signature := _build_pattern_signature(pattern)
        if seen_signatures.has(signature):
            continue
        if not _can_add_family(pattern, family_counts):
            continue
        seen_signatures[signature] = true
        out.append([pattern])
        _register_family(pattern, family_counts)

    if out.size() < count:
        for option in fallback_options:
            if out.size() >= count:
                break
            if not (option is Array) or option.is_empty():
                continue
            var relaxed_pattern := option[0] as ProphecyPattern
            if relaxed_pattern == null:
                continue
            var relaxed_signature := _build_pattern_signature(relaxed_pattern)
            if seen_signatures.has(relaxed_signature):
                continue
            seen_signatures[relaxed_signature] = true
            out.append([relaxed_pattern])

    var pad_index: int = 0
    while out.size() < count and not out.is_empty():
        var source_option: Array = out[pad_index % out.size()]
        if source_option != null and not source_option.is_empty():
            var source_pattern := source_option[0] as ProphecyPattern
            if source_pattern != null:
                var cloned := source_pattern.duplicate(true) as ProphecyPattern
                if cloned != null:
                    out.append([cloned])
        pad_index += 1

    return out

func _build_pooled_options_by_tier(
    easy_min: float,
    easy_max: float,
    mid_min: float,
    mid_max: float,
    hard_min: float,
    hard_max: float
) -> Dictionary:
    var result := {
        int(ProphecyPattern.DifficultyTier.EASY): [],
        int(ProphecyPattern.DifficultyTier.MID): [],
        int(ProphecyPattern.DifficultyTier.HARD): [],
    }
    if _pattern_pool == null:
        return result
    if _pattern_pool.patterns.is_empty():
        return result

    var unique_by_signature: Dictionary = {}
    for raw_pattern in _pattern_pool.patterns:
        var source_pattern := raw_pattern as ProphecyPattern
        if source_pattern == null:
            continue
        var signature := _build_pattern_signature(source_pattern)
        if unique_by_signature.has(signature):
            continue
        unique_by_signature[signature] = source_pattern

    var entries: Array = unique_by_signature.values()
    if _rng:
        for i in range(entries.size() - 1, 0, -1):
            var swap_index := _rng.randi_range(0, i)
            var tmp = entries[i]
            entries[i] = entries[swap_index]
            entries[swap_index] = tmp

    for raw_pattern in entries:
        var source_pattern := raw_pattern as ProphecyPattern
        if source_pattern == null:
            continue
        var level_min_value = source_pattern.get("level_min")
        var level_max_value = source_pattern.get("level_max")
        var level_min := int(level_min_value) if level_min_value != null else 1
        var level_max := int(level_max_value) if level_max_value != null else 7
        if _prophecy_level < level_min or _prophecy_level > level_max:
            continue
        var cloned := source_pattern.duplicate(true) as ProphecyPattern
        if cloned == null:
            continue
        var power := _compute_pattern_power(cloned)
        if power <= 0.0:
            continue
        cloned.power_rating = power
        var tier := int(cloned.difficulty_tier)
        if String(cloned.get("family")) == "":
            tier = _resolve_tier_for_power(power, easy_min, easy_max, mid_min, mid_max, hard_min, hard_max)
        cloned.difficulty_tier = tier
        var tier_options: Array = result.get(int(tier), [])
        tier_options.append([cloned])
        result[int(tier)] = tier_options

    return result

func _compute_pattern_power(pattern: ProphecyPattern) -> float:
    if pattern == null:
        return 0.0
    var total := 0.0
    var gen := ProphecyWaveGeneratorScript.new()
    if gen == null:
        return float(pattern.power_rating)
    gen.setup(_rng, 1, _prophecy_level)
    if gen.has_method("_compute_pattern_power"):
        total = float(gen._compute_pattern_power(pattern))
    return total

func _resolve_tier_for_power(
    power: float,
    easy_min: float,
    easy_max: float,
    mid_min: float,
    mid_max: float,
    hard_min: float,
    hard_max: float
) -> int:
    if power >= hard_min and power <= hard_max:
        return int(ProphecyPattern.DifficultyTier.HARD)
    if power >= mid_min and power <= mid_max:
        return int(ProphecyPattern.DifficultyTier.MID)
    if power >= easy_min and power <= easy_max:
        return int(ProphecyPattern.DifficultyTier.EASY)

    var easy_distance := _distance_to_band(power, easy_min, easy_max)
    var mid_distance := _distance_to_band(power, mid_min, mid_max)
    var hard_distance := _distance_to_band(power, hard_min, hard_max)
    if hard_distance <= mid_distance and hard_distance <= easy_distance:
        return int(ProphecyPattern.DifficultyTier.HARD)
    if mid_distance <= easy_distance:
        return int(ProphecyPattern.DifficultyTier.MID)
    return int(ProphecyPattern.DifficultyTier.EASY)

func _generate_single_pattern_options(
    gen: ProphecyWaveGenerator,
    tier: int,
    count: int,
    min_power: float,
    max_power: float
) -> Array:
    var out: Array = []
    var seen_signatures: Dictionary = {}
    if gen == null:
        return out
    for _i in range(max(0, count)):
        var p: ProphecyPattern = null
        for _attempt in range(10):
            p = _pick_pattern_for_power_band(gen, min_power, max_power)
            if p == null:
                continue
            var signature := _build_pattern_signature(p)
            if not seen_signatures.has(signature):
                seen_signatures[signature] = true
                break
        if p == null:
            continue
        p.difficulty_tier = tier
        out.append([p])
    return out

func _build_pattern_signature(pattern: ProphecyPattern) -> String:
    if pattern == null:
        return ""
    return "%s:%d:%s:%d:%d:%d:%d:%d" % [
        String(pattern.mob_1_id),
        int(pattern.mob_1_count),
        String(pattern.mob_2_id),
        int(pattern.mob_2_count),
        int(pattern.reward_1_type),
        int(pattern.reward_1_amount),
        int(pattern.reward_2_type),
        int(pattern.reward_2_amount)
    ]

func _pick_pattern_for_power_band(gen: ProphecyWaveGenerator, min_power: float, max_power: float) -> ProphecyPattern:
    if gen == null:
        return null

    var best: ProphecyPattern = null
    var best_distance := INF
    for _attempt in range(180):
        var candidate := gen.generate_pattern(_prophecy_level)
        if candidate == null:
            continue
        var power := float(candidate.power_rating)
        if power <= 0.0:
            continue

        var distance := _distance_to_band(power, min_power, max_power)
        if distance < best_distance:
            best_distance = distance
            best = candidate

        if distance <= 0.0:
            return candidate

    if best != null:
        return best

    return gen.generate_pattern(_prophecy_level)

func _distance_to_band(value: float, min_value: float, max_value: float) -> float:
    if value < min_value:
        return min_value - value
    if value > max_value:
        return value - max_value
    return 0.0


func _can_add_family(pattern: ProphecyPattern, family_counts: Dictionary) -> bool:
    if pattern == null:
        return false
    var family := String(pattern.get("family"))
    if family == "":
        return true
    return int(family_counts.get(family, 0)) < 5


func _register_family(pattern: ProphecyPattern, family_counts: Dictionary) -> void:
    if pattern == null:
        return
    var family := String(pattern.get("family"))
    if family == "":
        return
    family_counts[family] = int(family_counts.get(family, 0)) + 1

func _limit_artifact_reward_options(options: Array) -> void:
    var artifact_count := 0
    for option in options:
        if not (option is Array) or option.is_empty():
            continue
        var pattern := option[0] as ProphecyPattern
        if pattern == null:
            continue
        if not _has_artifact_reward(pattern):
            continue
        artifact_count += 1
        if artifact_count <= MAX_ARTIFACT_REWARD_OPTIONS:
            continue
        _replace_artifact_reward(pattern)

func _has_artifact_reward(pattern: ProphecyPattern) -> bool:
    if pattern == null:
        return false
    if int(pattern.reward_1_type) == int(ProphecyPattern.RewardType.ARTIFACT) or int(pattern.reward_1_type) == int(ProphecyPattern.RewardType.LEGENDARY_ARTIFACT):
        return true
    if not bool(pattern.reward_2_enabled):
        return false
    return int(pattern.reward_2_type) == int(ProphecyPattern.RewardType.ARTIFACT) or int(pattern.reward_2_type) == int(ProphecyPattern.RewardType.LEGENDARY_ARTIFACT)

func _replace_artifact_reward(pattern: ProphecyPattern) -> void:
    if pattern == null:
        return
    var replacement := int(ProphecyPattern.RewardType.DENARII)
    if _prophecy_level >= 2:
        replacement = int(ProphecyPattern.RewardType.BASIC_PRODUCTION)
    if int(pattern.reward_1_type) == int(ProphecyPattern.RewardType.ARTIFACT) or int(pattern.reward_1_type) == int(ProphecyPattern.RewardType.LEGENDARY_ARTIFACT):
        pattern.reward_1_type = replacement
        pattern.reward_1_amount = max(1, int(pattern.reward_1_amount))
    if bool(pattern.reward_2_enabled) and (int(pattern.reward_2_type) == int(ProphecyPattern.RewardType.ARTIFACT) or int(pattern.reward_2_type) == int(ProphecyPattern.RewardType.LEGENDARY_ARTIFACT)):
        pattern.reward_2_enabled = false

func _split_power_bands(gen: ProphecyWaveGenerator) -> Dictionary:
    var fallback := {
        "easy_min": 60.0,
        "easy_max": 80.0,
        "mid_min": 80.0,
        "mid_max": 100.0,
        "hard_min": 100.0,
        "hard_max": 120.0,
    }
    if gen == null:
        return fallback

    var range_data: Dictionary = {}
    if gen and gen.has_method("get_level_power_range"):
        var data: Variant = gen.get_level_power_range(_prophecy_level)
        if data is Dictionary:
            range_data = data
    var min_power := float(range_data.get("min", 60.0))
    var max_power := float(range_data.get("max", 120.0))
    var span := maxf(1.0, max_power - min_power)
    var third := span / 3.0

    return {
        "easy_min": min_power,
        "easy_max": min_power + third,
        "mid_min": min_power + third,
        "mid_max": min_power + third * 2.0,
        "hard_min": min_power + third * 2.0,
        "hard_max": max_power,
    }

static func get_pattern_tier(pattern: ProphecyPattern) -> int:
    if pattern == null:
        return ProphecyPattern.DifficultyTier.MID
    return int(pattern.difficulty_tier)
