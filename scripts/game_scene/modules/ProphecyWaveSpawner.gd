extends RefCounted
class_name ProphecyWaveSpawner

## Handles logic for spawning and orchestrating prophecy waves

const ProphecyCycleConfigScript := preload("res://scripts/prophecy/modules/ProphecyCycleConfig.gd")

var _waves_manager: Node = null
var _prophecy_queue: Array = []
var _prophecy_queue_display_slots: Array[int] = []
var _prophecy_index: int = 0
var _prophecy_wave_display_index: int = 0

var _prophecy_level: int = 1
var _prophecy_selection_pending: bool = true
var _placeholder_waves_spawned_before_selection: int = 0
var _intro_wave_pending: bool = true
var _final_boss_pending: bool = false
var _cycle_config: Variant = null


func _init() -> void:
	_cycle_config = ProphecyCycleConfigScript.new()
	_intro_wave_pending = _cycle_config != null and _cycle_config.has_intro_wave(_prophecy_level)


func setup(waves_manager: Node) -> void:
	_waves_manager = waves_manager
	if _cycle_config == null:
		_cycle_config = ProphecyCycleConfigScript.new()
	_intro_wave_pending = _cycle_config != null and _cycle_config.has_intro_wave(_prophecy_level)


func set_queue(selected_waves: Array, trader_spawner: Object, current_wave: int) -> void:
	_prophecy_queue.clear()
	_prophecy_queue_display_slots.clear()

	var locked_slots: int = get_locked_slot_count()
	var index: int = 0
	for selected_wave in selected_waves:
		if index < locked_slots:
			index += 1
			continue
		if selected_wave == null:
			index += 1
			continue
		if selected_wave is Array and (selected_wave as Array).is_empty():
			index += 1
			continue
		_prophecy_queue.append(selected_wave)
		_prophecy_queue_display_slots.append(index + 1)
		index += 1

	_prophecy_index = 0
	_prophecy_wave_display_index = 0
	_prophecy_selection_pending = false
	_placeholder_waves_spawned_before_selection = 0
	_intro_wave_pending = false
	_final_boss_pending = _cycle_config != null and _cycle_config.has_final_boss(_prophecy_level)

	if trader_spawner != null and _cycle_config != null and _cycle_config.has_trader(_prophecy_level):
		trader_spawner.setup_trader_cycle(_prophecy_level, current_wave, _prophecy_queue.size())
	elif trader_spawner != null and trader_spawner.has_method("clear_cycle"):
		trader_spawner.clear_cycle()


func get_locked_slot_count() -> int:
	if not _prophecy_selection_pending:
		return 0
	return clampi(_placeholder_waves_spawned_before_selection, 0, 3)


func get_current_patterns() -> Array:
	if _prophecy_index < _prophecy_queue.size():
		return _prophecy_queue[_prophecy_index]
	return []


func get_current_display_number() -> int:
	if _prophecy_index < _prophecy_queue_display_slots.size():
		return int(_prophecy_queue_display_slots[_prophecy_index])
	return _prophecy_wave_display_index + 1


func is_selection_pending() -> bool:
	return _prophecy_selection_pending


func is_intro_wave_pending() -> bool:
	return _prophecy_selection_pending and _intro_wave_pending


func get_intro_patterns() -> Array:
	if _cycle_config == null:
		return []
	return _cycle_config.get_intro_patterns(_prophecy_level)


func get_intro_patterns_for_level(level: int) -> Array:
	if _cycle_config == null:
		return []
	return _cycle_config.get_intro_patterns(level)


func get_intro_reward_bundle() -> Array:
	if _cycle_config == null:
		return []
	return _cycle_config.get_intro_reward_bundle(_prophecy_level)


func get_intro_reward_bundle_for_level(level: int) -> Array:
	if _cycle_config == null:
		return []
	return _cycle_config.get_intro_reward_bundle(level)


func consume_intro_wave() -> Array:
	var patterns: Array = get_intro_patterns()
	_intro_wave_pending = false
	return patterns


func has_pending_boss_wave() -> bool:
	return not _prophecy_selection_pending and _final_boss_pending and not has_active_queue()


func get_final_boss_patterns() -> Array:
	if _cycle_config == null:
		return []
	return _cycle_config.get_final_boss_patterns(_prophecy_level)


func get_final_boss_patterns_for_level(level: int) -> Array:
	if _cycle_config == null:
		return []
	return _cycle_config.get_final_boss_patterns(level)


func get_final_boss_rewards() -> Array:
	if _cycle_config == null:
		return []
	return _cycle_config.get_final_boss_rewards(_prophecy_level)


func get_final_boss_rewards_for_level(level: int) -> Array:
	if _cycle_config == null:
		return []
	return _cycle_config.get_final_boss_rewards(level)


func consume_final_boss_wave() -> Array:
	var patterns: Array = get_final_boss_patterns()
	_final_boss_pending = false
	return patterns


func should_show_victory_after_rewards() -> bool:
	if _cycle_config == null:
		return false
	return _cycle_config.should_show_victory_after_rewards(_prophecy_level)


func has_future_boss_wave() -> bool:
	if _cycle_config == null:
		return false
	if _cycle_config.has_trader(_prophecy_level):
		return false
	return _cycle_config.has_final_boss(_prophecy_level) and (_prophecy_selection_pending or _final_boss_pending or has_active_queue())


func get_display_index() -> int:
	return _prophecy_wave_display_index


func advance_wave() -> bool:
	_prophecy_wave_display_index += 1
	_prophecy_index += 1
	return _prophecy_index >= _prophecy_queue.size()


func complete_batch() -> void:
	_prophecy_queue.clear()
	_prophecy_queue_display_slots.clear()
	_prophecy_index = 0
	var old_level: int = _prophecy_level
	_prophecy_level = min(4, _prophecy_level + 1)
	_prophecy_selection_pending = true
	_placeholder_waves_spawned_before_selection = 0
	_intro_wave_pending = _cycle_config != null and _cycle_config.has_intro_wave(_prophecy_level)
	_final_boss_pending = false
	print("[ProphecyWaveSpawner] complete_batch: %d -> %d" % [old_level, _prophecy_level])


func record_placeholder_spawn() -> void:
	_placeholder_waves_spawned_before_selection += 1


func get_prophecy_level() -> int:
	return _prophecy_level


func has_active_queue() -> bool:
	return _prophecy_index < _prophecy_queue.size()


func get_queue_size() -> int:
	return _prophecy_queue.size()


func get_queue() -> Array:
	return _prophecy_queue


func get_display_slots() -> Array[int]:
	return _prophecy_queue_display_slots


func get_current_index() -> int:
	return _prophecy_index


## Debug: set prophecy level directly (1-4). Resets all wave state.
## Level 4 immediately forces boss wave (no prophecy selection phase).
func set_prophecy_level(level: int) -> void:
	_prophecy_level = clampi(level, 1, 4)
	_prophecy_queue.clear()
	_prophecy_queue_display_slots.clear()
	_prophecy_index = 0
	_prophecy_wave_display_index = 0
	_placeholder_waves_spawned_before_selection = 0
	if _prophecy_level == 4:
		_prophecy_selection_pending = false
		_intro_wave_pending = false
		_final_boss_pending = _cycle_config != null and _cycle_config.has_final_boss(_prophecy_level)
	else:
		_prophecy_selection_pending = true
		_intro_wave_pending = _cycle_config != null and _cycle_config.has_intro_wave(_prophecy_level)
		_final_boss_pending = false
	print("[ProphecyWaveSpawner] Debug: set prophecy level to %d" % _prophecy_level)


## Debug: force boss wave immediately. Sets level to 4 and skips all selection phases.
func force_boss_wave() -> void:
	_prophecy_level = 4
	_prophecy_queue.clear()
	_prophecy_queue_display_slots.clear()
	_prophecy_index = 0
	_prophecy_wave_display_index = 0
	_prophecy_selection_pending = false
	_placeholder_waves_spawned_before_selection = 0
	_intro_wave_pending = false
	_final_boss_pending = true
	print("[ProphecyWaveSpawner] Debug: force boss wave at level %d" % _prophecy_level)


## Debug: skip to next prophecy level (like completing a batch).
func skip_to_next_prophecy_level() -> void:
	_prophecy_queue.clear()
	_prophecy_queue_display_slots.clear()
	_prophecy_index = 0
	_prophecy_wave_display_index = 0
	_prophecy_level = min(4, _prophecy_level + 1)
	_prophecy_selection_pending = true
	_placeholder_waves_spawned_before_selection = 0
	_intro_wave_pending = _cycle_config != null and _cycle_config.has_intro_wave(_prophecy_level)
	_final_boss_pending = _cycle_config != null and _cycle_config.has_final_boss(_prophecy_level)
	print("[ProphecyWaveSpawner] Debug: skipped to prophecy level %d" % _prophecy_level)
