extends RefCounted
class_name GameSceneWaves

## Simplified wave system - spawns Goblins based on WaveTimerBar signals
## Uses MapMarkerService for spawn positions

signal wave_spawned(wave_number: int)
signal wave_completed(wave_number: int)
signal prophecy_batch_finished

const ProphecyWaveGeneratorScript := preload("res://scripts/prophecy/ProphecyWaveGenerator.gd")
const WaveSpawnServiceScript := preload("res://scripts/game_scene/modules/WaveSpawnService.gd")
const WaveRewardBuilderScript := preload("res://scripts/game_scene/modules/WaveRewardBuilder.gd")
const WaveStateFlowScript := preload("res://scripts/game_scene/modules/WaveStateFlow.gd")
const WavePreviewFlowScript := preload("res://scripts/game_scene/modules/WavePreviewFlow.gd")
const SpecialWaveFlowScript := preload("res://scripts/game_scene/modules/SpecialWaveFlow.gd")
const WaveSpawnBranchFlowScript := preload("res://scripts/game_scene/modules/WaveSpawnBranchFlow.gd")
const WavePlaceholderFlowScript := preload("res://scripts/game_scene/modules/WavePlaceholderFlow.gd")
const MobSceneRegistryScript := preload("res://scripts/game_scene/modules/MobSceneRegistry.gd")
const WaveStartFlowScript := preload("res://scripts/game_scene/modules/WaveStartFlow.gd")
const MobContainerQueryScript := preload("res://scripts/game_scene/modules/MobContainerQuery.gd")
const HomeseekerBossScene: PackedScene = preload("res://scenes/mobs/HomeseekerBoss.tscn")

var _game_scene: Node2D
var _map_container: Node2D
var _mob_container: Node2D
var _map_bounds: Rect2
var _wave_timer_bar = null
var _is_paused: bool = false
var _wall_attack_stop_distance: float = -1.0

var _prophecy_spawner: ProphecyWaveSpawner
var _trader_spawner: TraderWaveSpawner
var _timer_controller: WaveTimerController
var _spawn_service: WaveSpawnService
var _reward_builder: WaveRewardBuilder
var _mob_scene_registry: MobSceneRegistry
var _wave_start_flow: WaveStartFlow
var _mob_container_query: MobContainerQuery
var _wave_state_flow = null
var _wave_state: Dictionary = {}
var _preview_flow = null
var _special_wave_flow = null
var _spawn_branch_flow = null
var _placeholder_flow = null

var current_wave: int = 0
var _current_wave_rewards: Array = []
var _current_wave_is_intro: bool = false
var _current_wave_is_prophecy: bool = false
var _current_wave_is_boss: bool = false
var _current_wave_is_placeholder: bool = false
var _current_wave_display_number: int = 0
var _current_wave_use_prophecy_defaults: bool = false
var _current_wave_open_prophecy_after_reward: bool = false
var _current_wave_show_victory_after_reward: bool = false

var _current_wave_is_trader: bool = false
var _wave_active: bool = false
var _alive_wave_mob_ids: Dictionary = {}
var _current_wave_mob_counts: Dictionary = {}

const PORTAL_SPAWN_JITTER := 35.0
const PORTAL_SPAWN_X_OFFSET := -50.0
const MIN_SPAWN_DISTANCE_FROM_WALL := 260.0

func set_paused(paused: bool) -> void:
    _is_paused = paused
    if _wave_timer_bar and _wave_timer_bar.has_method("set_paused"):
        _wave_timer_bar.set_paused(paused)
    print("[GameSceneWaves] Paused: %s" % paused)

func is_paused() -> bool:
    return _is_paused

func initialize(game_scene: Node2D, map_container: Node2D, map_bounds: Rect2, wall_attack_stop_distance: float = -1.0) -> void:
    randomize()
    _prophecy_spawner = ProphecyWaveSpawner.new()
    _prophecy_spawner.setup(game_scene)
    _trader_spawner = TraderWaveSpawner.new()
    _timer_controller = WaveTimerController.new()
    _spawn_service = WaveSpawnServiceScript.new()
    _reward_builder = WaveRewardBuilderScript.new()
    _mob_scene_registry = MobSceneRegistryScript.new()
    _wave_start_flow = WaveStartFlowScript.new()
    _mob_container_query = MobContainerQueryScript.new()
    _wave_state_flow = WaveStateFlowScript.new()
    _wave_state = _wave_state_flow.create_state()
    _preview_flow = WavePreviewFlowScript.new()
    _special_wave_flow = SpecialWaveFlowScript.new()
    _spawn_branch_flow = WaveSpawnBranchFlowScript.new()
    _placeholder_flow = WavePlaceholderFlowScript.new()

    _game_scene = game_scene
    _map_container = map_container
    _map_bounds = map_bounds
    _wall_attack_stop_distance = wall_attack_stop_distance
    
    if _map_container:
        var pivot: Node = _map_container.get_node_or_null("MobPivot")
        if pivot:
            print("[GameSceneWaves] Found MobPivot, using it for spawning")
            _mob_container = pivot
        else:
            print("[GameSceneWaves] MobPivot not found, using MapContainer")
            _mob_container = _map_container

    if _spawn_service:
        _spawn_service.initialize(_mob_container, _map_bounds, _wall_attack_stop_distance, Callable(self, "_get_singleton"))

func connect_wave_timer(wave_timer) -> void:
    if wave_timer:
        _wave_timer_bar = wave_timer
        if _wave_timer_bar.has_method("set_paused"):
            _wave_timer_bar.set_paused(_is_paused)
        var triggered_callable := Callable(self, "_on_wave_triggered")
        if wave_timer.has_signal("wave_triggered"):
            if not wave_timer.wave_triggered.is_connected(triggered_callable):
                wave_timer.wave_triggered.connect(triggered_callable)
        _update_wave_timer_previews()
        print("[GameSceneWaves] Connected to WaveTimerBar")

func update_map_bounds(map_bounds: Rect2) -> void:
    _map_bounds = map_bounds
    if _spawn_service:
        _spawn_service.initialize(_mob_container, _map_bounds, _wall_attack_stop_distance, Callable(self, "_get_singleton"))

func debug_spawn_enemy_id(enemy_id: String, count: int = 1) -> int:
    return _spawn_enemy_id_count(enemy_id, count, false)

func _on_wave_triggered(wave_number: int) -> void:
    if _is_paused:
        print("[GameSceneWaves] Wave %d skipped (paused)" % wave_number)
        return

    var battle_core: Node = _get_singleton("BattleCore")
    var facade_start_state := {
        "current_wave": current_wave,
        "current_wave_is_intro": _current_wave_is_intro,
        "current_wave_is_prophecy": _current_wave_is_prophecy,
        "current_wave_is_trader": _current_wave_is_trader,
        "current_wave_is_boss": _current_wave_is_boss,
        "current_wave_is_placeholder": _current_wave_is_placeholder,
        "current_wave_display_number": _current_wave_display_number,
        "current_wave_use_prophecy_defaults": _current_wave_use_prophecy_defaults,
        "current_wave_open_prophecy_after_reward": _current_wave_open_prophecy_after_reward,
        "current_wave_show_victory_after_reward": _current_wave_show_victory_after_reward,
        "wave_active": _wave_active,
    }
    if _wave_start_flow:
        _wave_start_flow.begin_wave(wave_number, facade_start_state, _wave_state, _wave_timer_bar, battle_core, _trader_spawner, _wave_state_flow)
    current_wave = int(facade_start_state.get("current_wave", wave_number))
    _current_wave_is_intro = bool(facade_start_state.get("current_wave_is_intro", false))
    _current_wave_is_prophecy = bool(facade_start_state.get("current_wave_is_prophecy", false))
    _current_wave_is_trader = bool(facade_start_state.get("current_wave_is_trader", false))
    _current_wave_is_boss = bool(facade_start_state.get("current_wave_is_boss", false))
    _current_wave_is_placeholder = bool(facade_start_state.get("current_wave_is_placeholder", false))
    _current_wave_display_number = int(facade_start_state.get("current_wave_display_number", 0))
    _current_wave_use_prophecy_defaults = bool(facade_start_state.get("current_wave_use_prophecy_defaults", false))
    _current_wave_open_prophecy_after_reward = bool(facade_start_state.get("current_wave_open_prophecy_after_reward", false))
    _current_wave_show_victory_after_reward = bool(facade_start_state.get("current_wave_show_victory_after_reward", false))
    _wave_active = bool(facade_start_state.get("wave_active", false))
    _alive_wave_mob_ids = Dictionary(_wave_state.get("alive_wave_mob_ids", {})).duplicate(true)
    _current_wave_mob_counts = Dictionary(_wave_state.get("current_wave_mob_counts", {})).duplicate(true)
    _current_wave_rewards = Array(_wave_state.get("current_wave_rewards", [])).duplicate(true)

    var spawned_mobs: int = 0
    if _spawn_branch_flow:
        var result: Dictionary = _spawn_branch_flow.dispatch(
            wave_number,
            {
                "intro_pending": _prophecy_spawner.is_intro_wave_pending(),
                "is_trader": _trader_spawner.is_trader_wave(wave_number),
                "has_queue": _prophecy_spawner.has_active_queue(),
                "boss_pending": _prophecy_spawner.has_pending_boss_wave(),
                "boss_victory": _prophecy_spawner.should_show_victory_after_rewards(),
                "pending": _prophecy_spawner.is_selection_pending(),
                "patterns": _prophecy_spawner.get_current_patterns(),
                "display": _prophecy_spawner.get_current_display_number(),
            },
            func(): return _spawn_enemy_id_count("goblin_bandit", 1, true),
            Callable(self, "_spawn_intro_wave"),
            Callable(self, "_spawn_trader_wave"),
            Callable(self, "_spawn_from_prophecy_patterns"),
            Callable(self, "_spawn_final_boss_wave"),
            Callable(self, "_spawn_placeholder_wave"),
            Callable(self, "_spawn_regular_wave")
        )
        spawned_mobs = int(result.get("spawned", 0))
        _current_wave_is_intro = bool(result.get("is_intro", false))
        _current_wave_is_prophecy = bool(result.get("is_prophecy", false))
        _current_wave_is_trader = bool(result.get("is_trader", false))
        _current_wave_is_boss = bool(result.get("is_boss", false))
        _current_wave_is_placeholder = bool(result.get("is_placeholder", false))
        _current_wave_display_number = int(result.get("display_number", 0))
        _current_wave_use_prophecy_defaults = bool(result.get("use_prophecy_defaults", false))
        _current_wave_open_prophecy_after_reward = bool(result.get("open_prophecy_after_reward", false))
        _current_wave_show_victory_after_reward = bool(result.get("show_victory_after_reward", false))
        if _current_wave_is_prophecy:
            _prophecy_spawner.advance_wave()
        elif _current_wave_is_placeholder:
            _prophecy_spawner.record_placeholder_spawn()
            print("[GameSceneWaves] Placeholder wave spawned (waiting for prophecy selection): wave=%d level=%d" % [wave_number, _prophecy_spawner.get_prophecy_level()])

    if spawned_mobs <= 0:
        _wave_active = false

    var event_bus: Node = _get_singleton("EventBus")
    if _wave_start_flow:
        _wave_start_flow.notify_wave_started(
            wave_number,
            _wave_state_flow,
            _wave_state,
            func(spawned_wave_number: int) -> void: wave_spawned.emit(spawned_wave_number),
            func(started_wave_number: int, counts: Dictionary) -> void:
                if event_bus and event_bus.has_signal("wave_started_with_mobs"):
                    event_bus.wave_started_with_mobs.emit(started_wave_number, counts)
        )
    print("[GameSceneWaves] Wave %d: Spawned %d mob(s)" % [wave_number, spawned_mobs])

func _spawn_random_goblin(track_for_wave: bool = false) -> void:
    if _mob_scene_registry == null:
        push_error("[GameSceneWaves] Mob scene registry missing")
        return
    var random_id: String = _mob_scene_registry.get_random_goblin_id()
    if random_id == "":
        push_error("[GameSceneWaves] GOBLIN_IDS is empty!")
        return
    _spawn_enemy_id_count(random_id, 1, track_for_wave)

func _spawn_regular_wave(wave_number: int) -> int:
    var mob_count: int = max(1, wave_number)
    for _i in range(mob_count):
        _spawn_random_goblin(true)
    return mob_count

func _update_wave_timer_previews() -> void:
    var p_level: int = _prophecy_spawner.get_prophecy_level() if _prophecy_spawner else -1
    print("[GameSceneWaves] Updating previews, prophecy_level=%d, intro=%s, boss=%s, selection=%s" % [p_level, _prophecy_spawner.is_intro_wave_pending() if _prophecy_spawner else false, _prophecy_spawner.has_pending_boss_wave() if _prophecy_spawner else false, _prophecy_spawner.is_selection_pending() if _prophecy_spawner else false])
    if _preview_flow:
        var preview_builder := func(patterns: Array, display_number: int) -> Dictionary:
            return _timer_controller.build_preview_payload(patterns, display_number, Callable(self, "_aggregate_mob_counts"))
        var intro_builder := func(prophecy_level: int) -> Dictionary:
            var marker_patterns: Array = []
            var marker_rewards: Array = []
            if _prophecy_spawner != null:
                marker_patterns = _prophecy_spawner.get_intro_patterns_for_level(prophecy_level)
                marker_rewards = _prophecy_spawner.get_intro_reward_bundle_for_level(prophecy_level)
                if marker_patterns.is_empty() and prophecy_level >= 4:
                    marker_patterns = _prophecy_spawner.get_final_boss_patterns_for_level(prophecy_level)
                    marker_rewards = _prophecy_spawner.get_final_boss_rewards_for_level(prophecy_level)
            return _timer_controller.build_prophecy_marker_payload(prophecy_level, marker_patterns, marker_rewards, Callable(self, "_aggregate_mob_counts"))
        var trader_builder := func() -> Dictionary:
            return _trader_spawner.build_trader_preview_payload(Callable(self, "_aggregate_mob_counts"))
        var boss_builder := func() -> Dictionary:
            var payload: Dictionary = _timer_controller.build_boss_preview_payload(_prophecy_spawner.get_final_boss_patterns(), Callable(self, "_aggregate_mob_counts"))
            var prophecy_level: int = _prophecy_spawner.get_prophecy_level()
            payload["wave_title"] = "Prophecy %d Boss" % prophecy_level
            payload["flag_label"] = "P%d" % prophecy_level
            var rewards: Array = _prophecy_spawner.get_final_boss_rewards()
            payload["rewards"] = _build_tooltip_rewards_from_bundle(rewards)
            return payload

        _preview_flow.update_wave_timer_previews(
            _wave_timer_bar,
            current_wave,
            _prophecy_spawner.is_intro_wave_pending(),
            _prophecy_spawner.is_selection_pending(),
            _prophecy_spawner.get_prophecy_level(),
            _prophecy_spawner.get_queue(),
            _prophecy_spawner.get_current_index(),
            _prophecy_spawner.get_display_slots(),
            _prophecy_spawner.get_display_index(),
            _trader_spawner.get_trader_wave_number() >= 0,
            _prophecy_spawner.has_future_boss_wave(),
            preview_builder,
            intro_builder,
            trader_builder,
            boss_builder
        )

func _build_tooltip_rewards_from_bundle(rewards: Array) -> Array:
    var result: Array = []
    for reward in rewards:
        if reward == null or not reward is Dictionary:
            continue
        var reward_dict: Dictionary = reward as Dictionary
        var reward_type: int = int(reward_dict.get("type", -1))
        var amount: int = int(reward_dict.get("amount", 1))
        if reward_type < 0:
            continue
        var icon: Texture2D = _get_reward_icon(reward_type)
        var name: String = _get_reward_name(reward_type)
        if reward_type == 0 or reward_type == 1:  # DENARII or RESOURCE
            result.append({"label": "x%d %s" % [amount, name], "icon": icon})
        else:
            result.append({"label": name, "icon": icon})
    return result

func _get_reward_icon(reward_type: int) -> Texture2D:
    var registry = load("res://scripts/ui/rewards/RewardPresentationRegistry.gd")
    if registry and registry.has_method("get_reward_icon"):
        return registry.get_reward_icon(reward_type)
    return null

func _get_reward_name(reward_type: int) -> String:
    var registry = load("res://scripts/ui/rewards/RewardPresentationRegistry.gd")
    if registry and registry.has_method("get_reward_display_name"):
        return registry.get_reward_display_name(reward_type)
    return ""

func _aggregate_mob_counts(patterns: Array) -> Dictionary:
    var result: Dictionary = {}
    if patterns == null:
        return result
    for p in patterns:
        if p == null:
            continue
        _add_mob_count(result, p.mob_1_id, p.mob_1_count)
        if p.mob_2_enabled and p.mob_2_id != "":
            _add_mob_count(result, p.mob_2_id, p.mob_2_count)
    return result

func _add_mob_count(target: Dictionary, enemy_id: String, amount: int) -> void:
    if enemy_id == "":
        return
    var safe_amount: int = max(0, amount)
    if safe_amount <= 0:
        return
    var key: String = enemy_id.to_lower()
    if target.has(key):
        target[key] = int(target[key]) + safe_amount
    else:
        target[key] = safe_amount

func set_prophecy_queue(selected_waves: Array) -> void:
    _prophecy_spawner.set_queue(selected_waves, _trader_spawner, current_wave)
    _update_wave_timer_previews()

func consume_use_prophecy_defaults_flag() -> bool:
    var result: bool = _current_wave_use_prophecy_defaults
    _current_wave_use_prophecy_defaults = false
    return result

func consume_open_prophecy_after_reward_flag() -> bool:
    var result: bool = _current_wave_open_prophecy_after_reward
    _current_wave_open_prophecy_after_reward = false
    return result

func consume_victory_after_reward_flag() -> bool:
    var result: bool = _current_wave_show_victory_after_reward
    _current_wave_show_victory_after_reward = false
    return result

func _clear_future_wave_previews() -> void:
    if _preview_flow:
        _preview_flow.clear_future_wave_previews(_wave_timer_bar, current_wave)

func get_prophecy_level() -> int:
    return _prophecy_spawner.get_prophecy_level()

func get_locked_prophecy_slot_count() -> int:
    return _prophecy_spawner.get_locked_slot_count()

func get_current_wave_rewards() -> Array:
    return _wave_state_flow.get_current_wave_rewards(_wave_state) if _wave_state_flow else _current_wave_rewards.duplicate(true)

func is_trader_wave_number(wave_number: int) -> bool:
    return _trader_spawner.is_trader_wave(wave_number)

func _spawn_from_prophecy_patterns(patterns: Array, track_for_wave: bool = true) -> int:
    if _spawn_service == null:
        return 0
    return _spawn_service.spawn_prophecy_patterns(
        patterns,
        track_for_wave,
        Callable(self, "_spawn_enemy_id_count"),
        Callable(self, "_collect_rewards_from_pattern"),
        Callable(self, "_spawn_prophecy_fallback")
    )

func _spawn_trader_wave() -> int:
    if _trader_spawner == null:
        return 0
    return _trader_spawner.spawn_wave(
        _current_wave_rewards,
        _wave_state,
        Callable(self, "_spawn_from_prophecy_patterns"),
        Callable(self, "_spawn_enemy_id_count")
    )

func _spawn_intro_wave() -> int:
    _current_wave_rewards = []
    var intro_rewards: Array = _prophecy_spawner.get_intro_reward_bundle().duplicate(true)
    _wave_state["current_wave_rewards"] = intro_rewards.duplicate(true)
    _current_wave_rewards = intro_rewards
    var patterns: Array = _prophecy_spawner.consume_intro_wave()
    if _spawn_service == null:
        return 0
    return _spawn_service.spawn_prophecy_patterns(
        patterns,
        true,
        Callable(self, "_spawn_enemy_id_count"),
        Callable(),
        func() -> int: return _spawn_enemy_id_count("goblin_bandit", 1, true)
    )

func _spawn_final_boss_wave() -> int:
    var boss_rewards: Array = _prophecy_spawner.get_final_boss_rewards().duplicate(true)
    print("[GameSceneWaves] Boss rewards for level %d: %s" % [_prophecy_spawner.get_prophecy_level(), boss_rewards])
    _current_wave_rewards = boss_rewards
    _wave_state["current_wave_rewards"] = _current_wave_rewards.duplicate(true)
    var spawned_total: int = 0
    var patterns: Array = _prophecy_spawner.get_final_boss_patterns()
    print("[GameSceneWaves] Boss patterns count: %d, level: %d" % [patterns.size(), _prophecy_spawner.get_prophecy_level()])
    if _prophecy_spawner.get_prophecy_level() == 4 and HomeseekerBossScene != null and _spawn_service != null:
        var boss: Mob = _spawn_service.spawn_tracked_mob_scene(HomeseekerBossScene, true, _wave_state_flow, _wave_state, Callable(self, "_on_mob_died"))
        if boss != null:
            boss.behavior_target_type = "bridge"
            if _wave_state_flow != null and _wave_state_flow.has_method("register_spawned_count"):
                _wave_state_flow.register_spawned_count(_wave_state, "homeseekerboss", 1)
            if _game_scene != null:
                var boss_bar: Variant = _game_scene.get("boss_hp_bar")
                if boss_bar != null and boss_bar.has_method("set_boss"):
                    boss_bar.set_boss(boss)
            spawned_total += 1
        for pattern in patterns:
            if pattern == null:
                continue
            if pattern.mob_1_id == "homeseekerboss":
                continue
            spawned_total += _spawn_enemy_id_count(pattern.mob_1_id, pattern.mob_1_count, true)
            if pattern.mob_2_enabled and pattern.mob_2_id != "":
                spawned_total += _spawn_enemy_id_count(pattern.mob_2_id, pattern.mob_2_count, true)
        _prophecy_spawner.consume_final_boss_wave()
        print("[GameSceneWaves] Spawned boss wave total: %d mobs" % spawned_total)
        return spawned_total
    var consumed_patterns: Array = _prophecy_spawner.consume_final_boss_wave()
    if _spawn_service == null:
        return 0
    return _spawn_service.spawn_prophecy_patterns(
        consumed_patterns,
        true,
        Callable(self, "_spawn_enemy_id_count"),
        Callable(),
        func() -> int: return _spawn_enemy_id_count("goblin_giant", 1, true)
    )

func _collect_rewards_from_pattern(p: ProphecyPattern) -> void:
    if _reward_builder:
        _reward_builder.collect_rewards_from_pattern(_current_wave_rewards, p)
        _wave_state["current_wave_rewards"] = _current_wave_rewards.duplicate(true)

func _spawn_enemy_id_count(enemy_id: String, count: int, track_for_wave: bool = false) -> int:
    if _spawn_service == null or _mob_scene_registry == null:
        return 0
    var safe_count: int = _spawn_service.spawn_enemy_id_count(
        enemy_id,
        count,
        track_for_wave,
        _mob_scene_registry,
        _wave_state_flow,
        _wave_state,
        Callable(self, "_on_mob_died")
    )
    _alive_wave_mob_ids = _wave_state.get("alive_wave_mob_ids", {}).duplicate(true)
    _current_wave_mob_counts = _wave_state.get("current_wave_mob_counts", {}).duplicate()
    return safe_count

func _spawn_mob_scene(scene: PackedScene, track_for_wave: bool = false) -> void:
    if _spawn_service == null:
        push_error("[GameSceneWaves] Spawn service missing")
        return
    _spawn_service.spawn_tracked_mob_scene(scene, track_for_wave, _wave_state_flow, _wave_state, Callable(self, "_on_mob_died"))
    _alive_wave_mob_ids = _wave_state.get("alive_wave_mob_ids", {}).duplicate(true)

func _on_mob_died(mob: Mob, track_for_wave: bool = false) -> void:
    _wave_state_flow.unregister_mob_from_battle(mob, Callable(self, "_get_singleton"))
    _wave_state_flow.on_mob_died(_wave_state, mob, track_for_wave, wave_completed.emit, Callable(self, "_on_all_enemies_cleared"), current_wave)
    _alive_wave_mob_ids = _wave_state.get("alive_wave_mob_ids", {}).duplicate()
    _wave_active = bool(_wave_state.get("wave_active", false))

func _on_all_enemies_cleared() -> void:
    """Called when the last mob in the current wave dies"""
    print("[GameSceneWaves] All enemies cleared! Wave %d completed" % current_wave)
    
    if _special_wave_flow:
        _special_wave_flow.handle_all_enemies_cleared(
            {
                "current_wave_is_boss": _current_wave_is_boss,
                "current_wave_is_prophecy": _current_wave_is_prophecy,
                "current_wave_is_trader": _current_wave_is_trader,
            },
            current_wave,
            Callable(self, "_update_wave_timer_previews"),
            Callable(_trader_spawner, "complete_batch"),
            Callable(_prophecy_spawner, "complete_batch"),
            Callable(self, "_clear_future_wave_previews"),
            prophecy_batch_finished.emit,
            Callable(self, "_notify_game_scene_enemies_cleared")
        )

func _notify_game_scene_enemies_cleared() -> void:
    if _game_scene and _game_scene.has_method("_on_enemies_cleared"):
        _game_scene._on_enemies_cleared()

# Stubs for compatibility with legacy calls in GameScene
func on_wave_started(_wave_number: int) -> void:
    pass

func clear_mobs() -> void:
    _alive_wave_mob_ids.clear()
    _wave_active = false
    _wave_state["alive_wave_mob_ids"] = {}
    _wave_state["wave_active"] = false
    if _mob_container_query:
        _mob_container_query.clear_mobs(_mob_container)

func debug_set_prophecy_level(level: int) -> void:
    print("[GameSceneWaves] Debug: jumping to prophecy level %d" % level)
    # Reset wave state without triggering mob death callbacks
    _alive_wave_mob_ids.clear()
    _current_wave_mob_counts.clear()
    _wave_active = false
    _current_wave_rewards.clear()
    _wave_state.clear()
    if _wave_state_flow:
        _wave_state = _wave_state_flow.create_state()
    _current_wave_is_intro = false
    _current_wave_is_prophecy = false
    _current_wave_is_trader = false
    _current_wave_is_boss = false
    _current_wave_is_placeholder = false
    _current_wave_display_number = 0
    _current_wave_use_prophecy_defaults = false
    _current_wave_open_prophecy_after_reward = false
    _current_wave_show_victory_after_reward = false
    if _prophecy_spawner:
        _prophecy_spawner.set_prophecy_level(level)
        print("[GameSceneWaves] Prophecy level set to %d, pending=%s, boss=%s, queue=%d" % [_prophecy_spawner.get_prophecy_level(), _prophecy_spawner.is_selection_pending(), _prophecy_spawner.has_pending_boss_wave(), _prophecy_spawner.get_queue_size()])
    if _trader_spawner and _trader_spawner.has_method("clear_cycle"):
        _trader_spawner.clear_cycle()
    # Reset timeline and clear all cached previews
    current_wave = 0
    if _wave_timer_bar != null:
        if _wave_timer_bar.has_method("clear_all_wave_previews"):
            _wave_timer_bar.clear_all_wave_previews()
        if _wave_timer_bar.has_method("reset_wave_timeline"):
            _wave_timer_bar.reset_wave_timeline()
        # Remove wave 0 flag so boss preview goes to wave 1 (only flag visible)
        if _wave_timer_bar.has_method("remove_flag_by_wave_number"):
            _wave_timer_bar.remove_flag_by_wave_number(0)
    _update_wave_timer_previews()

func debug_force_boss_wave() -> void:
    print("[GameSceneWaves] Debug: forcing boss wave")
    _alive_wave_mob_ids.clear()
    _current_wave_mob_counts.clear()
    _wave_active = false
    _current_wave_rewards.clear()
    _wave_state.clear()
    if _wave_state_flow:
        _wave_state = _wave_state_flow.create_state()
    if _prophecy_spawner:
        _prophecy_spawner.force_boss_wave()
    if _trader_spawner and _trader_spawner.has_method("clear_cycle"):
        _trader_spawner.clear_cycle()
    current_wave = 0
    if _wave_timer_bar != null:
        if _wave_timer_bar.has_method("clear_all_wave_previews"):
            _wave_timer_bar.clear_all_wave_previews()
        if _wave_timer_bar.has_method("reset_wave_timeline"):
            _wave_timer_bar.reset_wave_timeline()
        if _wave_timer_bar.has_method("remove_flags_from_wave"):
            _wave_timer_bar.remove_flags_from_wave(1)
    _update_wave_timer_previews()

func debug_skip_to_next_prophecy_level() -> void:
    if _prophecy_spawner:
        _prophecy_spawner.skip_to_next_prophecy_level()
    if _trader_spawner and _trader_spawner.has_method("clear_cycle"):
        _trader_spawner.clear_cycle()
    _update_wave_timer_previews()

func get_alive_mobs() -> Array:
    if _mob_container_query == null:
        return []
    return _mob_container_query.get_alive_mobs(_mob_container)

func get_wave_interval_for_number(wave_number: int) -> float:
    if _timer_controller == null or _trader_spawner == null:
        return 0.0
    return _timer_controller.get_wave_interval_for_number(
        wave_number,
        _trader_spawner.get_trader_wave_number(),
        _trader_spawner.get_post_trader_first_wave_number()
    )

func _spawn_placeholder_wave(wave_number: int, track_for_wave: bool = true) -> int:
    var gen = null
    if ProphecyWaveGeneratorScript != null:
        gen = ProphecyWaveGeneratorScript.new()
    return _placeholder_flow.spawn_placeholder_wave(
        wave_number,
        _prophecy_spawner.get_prophecy_level(),
        gen,
        Callable(self, "_spawn_enemy_id_count"),
        Callable(self, "_spawn_placeholder_fallback"),
        track_for_wave
    ) if _placeholder_flow else _spawn_placeholder_fallback(wave_number, track_for_wave)

func _spawn_placeholder_fallback(wave_number: int, track_for_wave: bool = true) -> int:
    var fallback_count: int = clampi(maxi(1, wave_number), 1, 6)
    return _spawn_enemy_id_count("goblin_bandit", fallback_count, track_for_wave)

func _get_portal_spawn_position(jitter: float = PORTAL_SPAWN_JITTER) -> Vector2:
    if _spawn_service:
        return _spawn_service.get_portal_spawn_position(jitter)
    return Vector2(PORTAL_SPAWN_X_OFFSET, 0.0)

func _get_singleton(name: String) -> Node:
    if _game_scene == null or not is_instance_valid(_game_scene):
        return null
    if not _game_scene.is_inside_tree():
        return null
    var tree := _game_scene.get_tree()
    if tree == null or tree.root == null:
        return null
    return tree.root.get_node_or_null(name)

func set_wall_attack_stop_distance(distance: float) -> void:
    _wall_attack_stop_distance = distance
    if _spawn_service:
        _spawn_service.initialize(_mob_container, _map_bounds, _wall_attack_stop_distance, Callable(self, "_get_singleton"))
    if _mob_container_query:
        _mob_container_query.set_wall_attack_stop_distance(_mob_container, distance)

func _spawn_prophecy_fallback() -> int:
    _spawn_random_goblin(true)
    return 1
