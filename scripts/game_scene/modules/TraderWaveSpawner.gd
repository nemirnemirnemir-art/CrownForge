extends RefCounted
class_name TraderWaveSpawner

## Handles logic for spawning and orchestrating trader waves

const ProphecyWaveGeneratorScript := preload("res://scripts/prophecy/ProphecyWaveGenerator.gd")
const ProphecyCycleConfigScript := preload("res://scripts/prophecy/modules/ProphecyCycleConfig.gd")
const RewardPresentationRegistryScript := preload("res://scripts/ui/rewards/RewardPresentationRegistry.gd")
const TRADER_WAVE_TITLE := "Wandering trader"

var _trader_patterns: Array = []
var _trader_wave_number: int = -1
var _post_trader_first_wave_number: int = -1


func setup_trader_cycle(prophecy_level: int, current_wave: int, queue_size: int) -> void:
	_trader_patterns = _generate_trader_patterns_for_level(prophecy_level)
	_trader_wave_number = current_wave + 1 + queue_size


func _generate_trader_patterns_for_level(prophecy_level: int) -> Array:
	var cycle_config: Variant = ProphecyCycleConfigScript.new()
	if cycle_config != null:
		var authored_patterns: Array = cycle_config.get_trader_patterns(prophecy_level)
		if not authored_patterns.is_empty():
			return authored_patterns

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	var gen: Object = ProphecyWaveGeneratorScript.new()
	if gen == null:
		return []

	var effective_level: int = max(1, prophecy_level - 1)
	gen.setup(rng, 1, effective_level)
	var generated_pattern: ProphecyPattern = gen.generate_pattern(effective_level) as ProphecyPattern
	if generated_pattern == null:
		return []
	return [generated_pattern]


func clear_cycle() -> void:
	_trader_patterns = []
	_trader_wave_number = -1
	_post_trader_first_wave_number = -1


func is_trader_wave(wave_number: int) -> bool:
	return _trader_wave_number >= 0 and wave_number == _trader_wave_number


func get_trader_wave_number() -> int:
	return _trader_wave_number


func get_post_trader_first_wave_number() -> int:
	return _post_trader_first_wave_number


func set_post_trader_first_wave_number(wave: int) -> void:
	_post_trader_first_wave_number = wave


func get_patterns() -> Array:
	return _trader_patterns


func complete_batch(current_wave: int) -> void:
	_trader_wave_number = -1
	_post_trader_first_wave_number = current_wave + 1
	_trader_patterns = []


func spawn_wave(current_wave_rewards: Array, wave_state: Dictionary, spawn_prophecy_patterns: Callable, spawn_fallback: Callable) -> int:
	var spawned: int = 0
	if _trader_patterns != null and not _trader_patterns.is_empty():
		if spawn_prophecy_patterns.is_valid():
			spawned = int(spawn_prophecy_patterns.call(_trader_patterns, true))
	elif spawn_fallback.is_valid():
		spawned = int(spawn_fallback.call("goblin_bandit", 4, true))

	current_wave_rewards.append({
		"custom_id": "trader",
	})
	wave_state["current_wave_rewards"] = current_wave_rewards.duplicate(true)
	return spawned


func build_trader_rewards_tooltip_payload() -> Array:
	var denarii_icon: Texture2D = RewardPresentationRegistryScript.get_reward_icon(0)
	var trader_icon: Texture2D = RewardPresentationRegistryScript.get_trader_icon()
	return [
		{"label": "x10 Denarii", "icon": denarii_icon},
		{"label": "Trader", "icon": trader_icon},
	]


func build_trader_preview_payload(aggregate_func: Callable) -> Dictionary:
	var counts: Dictionary = aggregate_func.call(_trader_patterns)
	var primary_id: String = "goblin_bandit"
	var primary_count: int = 4
	for enemy_id in counts.keys():
		var count: int = int(counts[enemy_id])
		if count > primary_count or primary_id == "":
			primary_id = String(enemy_id)
			primary_count = max(1, count)
	if counts.is_empty():
		counts = {"goblin_bandit": 4}
	return {
		"enemy_id": primary_id,
		"enemy_count": primary_count,
		"mob_counts": counts,
		"wave_title": TRADER_WAVE_TITLE,
		"flag_label": "T",
		"rewards": build_trader_rewards_tooltip_payload(),
	}
