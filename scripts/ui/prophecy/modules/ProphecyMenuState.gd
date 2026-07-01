extends RefCounted
class_name ProphecyMenuState

const ProphecyOptionGeneratorScript := preload("res://scripts/ui/prophecy/modules/ProphecyOptionGenerator.gd")

const SLOT_EASY: int = 0
const SLOT_MID: int = 1
const SLOT_HARD: int = 2

var pool: ProphecyPatternPool = null
var rng: RandomNumberGenerator
var selected: Array = [[], [], []]
var prophecy_level: int = 1
var locked_slot_count: int = 0
var target_slot_index: int = 0
var selected_pattern_ids: Dictionary = {}

var option_gen: ProphecyOptionGenerator = null


func setup() -> void:
    rng = RandomNumberGenerator.new()
    rng.randomize()
    option_gen = ProphecyOptionGeneratorScript.new()


func reset(new_pool: ProphecyPatternPool, new_prophecy_level: int, new_locked_slot_count: int) -> void:
    pool = new_pool
    prophecy_level = max(1, new_prophecy_level)
    locked_slot_count = clampi(new_locked_slot_count, 0, selected.size())
    selected = [[], [], []]
    selected_pattern_ids.clear()
    target_slot_index = get_first_unlocked_slot_index()


func get_first_unlocked_slot_index() -> int:
    for i in range(selected.size()):
        if not is_slot_locked(i):
            return i
    return 0


func get_target_slot_index() -> int:
    ensure_target_slot_valid()
    return target_slot_index


func set_target_slot_index(index: int) -> void:
    if index >= 0 and index < selected.size() and not is_slot_locked(index):
        target_slot_index = index
        return
    ensure_target_slot_valid()


func ensure_target_slot_valid() -> void:
    if target_slot_index < 0 or target_slot_index >= selected.size() or is_slot_locked(target_slot_index):
        target_slot_index = get_first_unlocked_slot_index()


func is_slot_locked(index: int) -> bool:
    if index < 0:
        return false
    return index < locked_slot_count


func is_all_selected() -> bool:
    return can_continue()


func can_continue() -> bool:
    for i in range(selected.size()):
        if is_slot_locked(i):
            continue
        if not _has_tier(selected[i], ProphecyPattern.DifficultyTier.EASY):
            return false
    return true


func is_all_slots_full() -> bool:
    for i in range(selected.size()):
        if is_slot_locked(i):
            continue
        if not _has_tier(selected[i], ProphecyPattern.DifficultyTier.EASY):
            return false
        if not _has_tier(selected[i], ProphecyPattern.DifficultyTier.MID):
            return false
        if not _has_tier(selected[i], ProphecyPattern.DifficultyTier.HARD):
            return false
    return true


func is_partial_slot_mix_valid(patterns: Array) -> bool:
    if patterns == null:
        return false
    var has_easy := false
    var has_mid := false
    var has_hard := false
    for raw_pattern in patterns:
        var pattern := raw_pattern as ProphecyPattern
        if pattern == null:
            return false
        match int(pattern.difficulty_tier):
            ProphecyPattern.DifficultyTier.EASY:
                if has_easy:
                    return false
                has_easy = true
            ProphecyPattern.DifficultyTier.MID:
                if has_mid:
                    return false
                has_mid = true
            ProphecyPattern.DifficultyTier.HARD:
                if has_hard:
                    return false
                has_hard = true
            _:
                return false
    if has_mid and not has_easy:
        return false
    if has_hard and (not has_easy or not has_mid):
        return false
    return true


func can_select_option(option_patterns: Array) -> bool:
    var pattern := extract_single_pattern(option_patterns)
    if pattern == null:
        return false
    if is_pattern_already_selected(pattern):
        return false
    for wave_index in range(selected.size()):
        if can_add_pattern_to_slot(wave_index, option_patterns):
            return true
    return false


func get_preview_slot_for_option(option_patterns: Array, preferred_index: int = -1) -> int:
    var pattern := extract_single_pattern(option_patterns)
    if pattern == null:
        return -1
    if is_pattern_already_selected(pattern):
        return -1

    ensure_target_slot_valid()
    var safe_preferred := preferred_index
    if safe_preferred < 0 or safe_preferred >= selected.size() or is_slot_locked(safe_preferred):
        safe_preferred = target_slot_index

    for wave_index in _build_scan_order(safe_preferred):
        if can_add_pattern_to_slot(wave_index, option_patterns):
            return wave_index
    return -1


func can_add_pattern_to_slot(index: int, option_patterns: Array) -> bool:
    if index < 0 or index >= selected.size():
        return false
    if is_slot_locked(index):
        return false

    var pattern := extract_single_pattern(option_patterns)
    if pattern == null:
        return false
    if is_pattern_already_selected(pattern):
        return false

    var next_wave: Array = selected[index].duplicate()
    if _has_tier(next_wave, int(pattern.difficulty_tier)):
        return false
    next_wave.append(pattern)
    return is_partial_slot_mix_valid(next_wave)


func try_add_pattern_to_slot(index: int, option_patterns: Array) -> bool:
    if not can_add_pattern_to_slot(index, option_patterns):
        return false

    var pattern := extract_single_pattern(option_patterns)
    var wave: Array = selected[index].duplicate()
    wave.append(pattern)
    selected[index] = wave
    rebuild_selected_option_keys()
    return true


func try_add_pattern_to_best_slot(preferred_index: int, option_patterns: Array) -> int:
    ensure_target_slot_valid()
    var safe_preferred := preferred_index
    if safe_preferred < 0 or safe_preferred >= selected.size() or is_slot_locked(safe_preferred):
        safe_preferred = target_slot_index

    var scan_order := _build_scan_order(safe_preferred)
    for wave_index in scan_order:
        if try_add_pattern_to_slot(wave_index, option_patterns):
            return wave_index
    return -1


func clear_slot(index: int) -> void:
    if index < 0 or index >= selected.size():
        return
    if is_slot_locked(index):
        return
    selected[index] = []
    rebuild_selected_option_keys()


func remove_bottom_pattern_from_slot(index: int) -> ProphecyPattern:
    if index < 0 or index >= selected.size():
        return null
    if is_slot_locked(index):
        return null

    var wave: Array = selected[index]
    if wave == null or wave.is_empty():
        return null

    var removed := wave[wave.size() - 1] as ProphecyPattern
    selected[index] = []
    rebuild_selected_option_keys()
    return removed


func extract_single_pattern(option_patterns: Array) -> ProphecyPattern:
    if option_patterns == null or option_patterns.size() != 1:
        return null
    return option_patterns[0] as ProphecyPattern


func compute_option_key(patterns: Array) -> String:
    var parts: Array[String] = []
    if patterns != null:
        for pattern in patterns:
            if pattern == null:
                continue
            parts.append(str(pattern.get_instance_id()))
    return ",".join(parts)


func rebuild_selected_option_keys() -> void:
    selected_pattern_ids.clear()
    for wave in selected:
        if wave == null:
            continue
        for pattern in wave:
            if pattern == null:
                continue
            selected_pattern_ids[str(pattern.get_instance_id())] = true


func is_option_used(option_patterns: Array) -> bool:
    if option_patterns == null:
        return false
    for pattern in option_patterns:
        if pattern == null:
            continue
        if selected_pattern_ids.has(str(pattern.get_instance_id())):
            return true
    return false


func is_pattern_already_selected(pattern: ProphecyPattern) -> bool:
    if pattern == null:
        return false
    return selected_pattern_ids.has(str(pattern.get_instance_id()))


func generate_wave_options() -> Array:
    option_gen.setup(rng, prophecy_level, pool)
    return option_gen.generate_wave_options()


func _build_scan_order(preferred_index: int) -> Array[int]:
    var order: Array[int] = []
    for offset in range(selected.size()):
        var wave_index := (preferred_index + offset) % selected.size()
        if is_slot_locked(wave_index):
            continue
        order.append(wave_index)
    return order


func _has_tier(patterns: Array, tier: int) -> bool:
    if patterns == null:
        return false
    for raw_pattern in patterns:
        var pattern := raw_pattern as ProphecyPattern
        if pattern == null:
            continue
        if int(pattern.difficulty_tier) == tier:
            return true
    return false
