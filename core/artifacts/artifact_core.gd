extends Node

const ArtifactExternalMultiplierBridgeScript := preload("res://core/artifacts/ArtifactExternalMultiplierBridge.gd")
const ArtifactBuildingLifecycleBonusesScript := preload("res://core/artifacts/ArtifactBuildingLifecycleBonuses.gd")
const ArtifactCastleHooksScript := preload("res://core/artifacts/ArtifactCastleHooks.gd")
const ArtifactCombatHooksScript := preload("res://core/artifacts/ArtifactCombatHooks.gd")
const ArtifactProductionHooksScript := preload("res://core/artifacts/ArtifactProductionHooks.gd")
const ArtifactOwnershipFlowScript := preload("res://core/artifacts/ArtifactOwnershipFlow.gd")
const ArtifactPendingRewardFlowScript := preload("res://core/artifacts/ArtifactPendingRewardFlow.gd")
const ArtifactPersistenceFlowScript := preload("res://core/artifacts/ArtifactPersistenceFlow.gd")
const ArtifactProgressionFlowScript := preload("res://core/artifacts/ArtifactProgressionFlow.gd")
const ArtifactBuildingCombatHooksScript := preload("res://core/artifacts/ArtifactBuildingCombatHooks.gd")
const ArtifactRuntimeFlowScript := preload("res://core/artifacts/ArtifactRuntimeFlow.gd")
const ArtifactRuntimeShellFlowScript := preload("res://core/artifacts/ArtifactRuntimeShellFlow.gd")
const ArtifactRuntimeTargetBridgeScript := preload("res://core/artifacts/ArtifactRuntimeTargetBridge.gd")
const ArtifactTraderBenefitsScript := preload("res://core/artifacts/ArtifactTraderBenefits.gd")
const ArtifactWorkingBuildingFlowScript := preload("res://core/artifacts/ArtifactWorkingBuildingFlow.gd")

signal artifact_added(artifact_id: String)
signal artifact_removed(artifact_id: String)
signal artifact_active_changed(artifact_id: String, active: bool)
signal artifacts_changed()

var _owned: Dictionary = {}
var _active: Dictionary = {}
var _state: Dictionary = {}
var _runtime_class_bonus_applied: Dictionary = {}
var _pending_spell_choice_rewards: int = 0
var _pending_legendary_spell_choice_rewards: int = 0
var _external_multiplier_bridge = ArtifactExternalMultiplierBridgeScript.new()
var _building_lifecycle_bonuses = ArtifactBuildingLifecycleBonusesScript.new()
var _castle_hooks = ArtifactCastleHooksScript.new()
var _combat_hooks = ArtifactCombatHooksScript.new()
var _production_hooks = ArtifactProductionHooksScript.new()
var _ownership_flow = ArtifactOwnershipFlowScript.new()
var _pending_reward_flow = ArtifactPendingRewardFlowScript.new()
var _persistence_flow = ArtifactPersistenceFlowScript.new()
var _runtime_flow = ArtifactRuntimeFlowScript.new()
var _runtime_shell_flow = ArtifactRuntimeShellFlowScript.new()
var _runtime_target_bridge = ArtifactRuntimeTargetBridgeScript.new()
var _progression_flow = ArtifactProgressionFlowScript.new()
var _trader_benefits = ArtifactTraderBenefitsScript.new()
var _building_combat_hooks = ArtifactBuildingCombatHooksScript.new()
var _working_building_flow = ArtifactWorkingBuildingFlowScript.new()

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _runtime_shell_flow.connect_event_bus(EventBus, Callable(self, "_on_enemy_killed"), Callable(self, "_on_wave_started"), Callable(self, "_on_hero_died"), Callable(self, "_on_game_loaded"))

func _process(delta: float) -> void:
    _runtime_flow.process_active_effects(_active, _state, delta)
    _process_pending_spell_choice_rewards()

func has_artifact(artifact_id: String) -> bool:
    return _owned.has(artifact_id)

func is_active(artifact_id: String) -> bool:
    return _active.has(artifact_id)

func get_owned_ids() -> Array:
    return _owned.keys()

func get_active_ids() -> Array:
    return _active.keys()

func add_artifact(artifact_id: String, activate: bool = true) -> bool:
    var result := _ownership_flow.add_artifact(
        artifact_id,
        _owned,
        _state,
        _pending_spell_choice_rewards,
        _pending_legendary_spell_choice_rewards,
        Callable(ArtifactCatalog, "has_def"),
        Callable(ArtifactEffectExecutor, "apply_on_pickup"),
        Callable(ArtifactSpellRewards, "queue_spell_choice_rewards")
    )
    if not bool(result.get("added", false)) and not bool(result.get("was_owned", false)):
        return false
    if bool(result.get("added", false)):
        artifact_added.emit(artifact_id)
        _pending_spell_choice_rewards = int(result.get("pending_spell_choice_rewards", _pending_spell_choice_rewards))
        _pending_legendary_spell_choice_rewards = int(result.get("pending_legendary_spell_choice_rewards", _pending_legendary_spell_choice_rewards))
        _enqueue_pending_rewards(result.get("pending_rewards", []))
    
    if activate:
        set_active(artifact_id, true)
    
    artifacts_changed.emit()
    if SaveCore:
        SaveCore.request_save()
    return bool(result.get("added", false))

func remove_artifact(artifact_id: String) -> bool:
    var troop_core := _get_troop_bonus_core()
    var result := _ownership_flow.remove_artifact(
        artifact_id,
        _owned,
        _active,
        _state,
        _runtime_class_bonus_applied,
        troop_core,
        Callable(ArtifactEffectExecutor, "apply_on_activated"),
        Callable(ArtifactEffectExecutor, "apply_on_deactivated")
    )
    if not bool(result.get("removed", false)):
        return false
    if bool(result.get("was_active", false)):
        artifact_active_changed.emit(artifact_id, false)
    artifact_removed.emit(artifact_id)
    artifacts_changed.emit()
    if SaveCore:
        SaveCore.request_save()
    return true

func set_active(artifact_id: String, active: bool) -> void:
    var troop_core := _get_troop_bonus_core()
    var result := _ownership_flow.set_active(
        artifact_id,
        active,
        _owned,
        _active,
        _state,
        _runtime_class_bonus_applied,
        troop_core,
        Callable(ArtifactEffectExecutor, "apply_on_activated"),
        Callable(ArtifactEffectExecutor, "apply_on_deactivated")
    )
    if not bool(result.get("changed", false)):
        return
    artifact_active_changed.emit(artifact_id, bool(result.get("active", false)))
    artifacts_changed.emit()
    if SaveCore:
        SaveCore.request_save()

func toggle_active(artifact_id: String) -> void:
    set_active(artifact_id, not is_active(artifact_id))

func get_unit_limit_bonus() -> int:
    return ArtifactStatQueries.get_unit_limit_bonus(_active)

func get_castle_max_hp_bonus() -> int:
    return ArtifactStatQueries.get_castle_max_hp_bonus(_active)

func get_unit_flat_hp_bonus() -> int:
    return ArtifactStatQueries.get_unit_flat_hp_bonus(_active, _state)

func get_friendly_unit_hp_multiplier() -> float:
    return ArtifactStatQueries.get_friendly_unit_hp_multiplier(_active, _state)

func get_unit_specific_hp_multiplier(unit_id: String) -> float:
    return ArtifactStatQueries.get_unit_specific_hp_multiplier(_active, _state, unit_id)

func get_build_cost_multiplier() -> float:
    return ArtifactStatQueries.get_build_cost_multiplier(_active)

func get_build_refund_percent() -> float:
    return ArtifactStatQueries.get_build_refund_percent(_active)

func get_resource_production_speed_multiplier() -> float:
    var mult := ArtifactStatQueries.get_resource_production_speed_multiplier(_active)
    return _external_multiplier_bridge.apply_resource_production_speed_bridge(mult, BuildingUpgradeCore)

func get_unit_production_speed_multiplier() -> float:
    var mult := ArtifactStatQueries.get_unit_production_speed_multiplier(_active)
    return _external_multiplier_bridge.apply_unit_production_speed_bridge(mult, BuildingUpgradeCore)

func get_friendly_evasion_chance() -> float:
    return ArtifactStatQueries.get_friendly_evasion_chance(_active)

func get_friendly_full_damage_block_chance() -> float:
    return ArtifactStatQueries.get_friendly_full_damage_block_chance(_active)

func get_friendly_unit_damage_multiplier() -> float:
    return ArtifactStatQueries.get_friendly_unit_damage_multiplier(_active, _state)

func get_unit_specific_damage_multiplier(unit_id: String) -> float:
    return ArtifactStatQueries.get_unit_specific_damage_multiplier(_active, _state, unit_id)

func get_unit_move_speed_multiplier(unit_id: String) -> float:
    return ArtifactStatQueries.get_unit_move_speed_multiplier(_active, unit_id)

func get_bonus_projectile_chance() -> float:
    return ArtifactStatQueries.get_bonus_projectile_chance(_active)

func get_morale_flat_bonus() -> int:
    return ArtifactStatQueries.get_morale_flat_bonus(_active, _state)

func get_spell_damage_multiplier() -> float:
    var mult := ArtifactStatQueries.get_spell_damage_multiplier(_active, _state)
    return _external_multiplier_bridge.apply_spell_damage_bridge(mult, BuildingUpgradeCore)

func get_spell_double_cast_chance() -> float:
    return ArtifactStatQueries.get_spell_double_cast_chance(_active)

func get_spell_radius_multiplier() -> float:
    return ArtifactStatQueries.get_spell_radius_multiplier(_active)

func get_attacking_building_damage_multiplier() -> float:
    return ArtifactStatQueries.get_attacking_building_damage_multiplier(_active)

func get_scaled_attacking_building_damage(base_damage: float) -> float:
    if _building_combat_hooks != null and _building_combat_hooks.has_method("get_scaled_attacking_building_damage"):
        return float(_building_combat_hooks.call("get_scaled_attacking_building_damage", base_damage))
    return maxf(0.0, base_damage) * get_attacking_building_damage_multiplier()

func on_working_building_tick(delta: float, building_id: String, slot_index: int) -> void:
    if _working_building_flow != null and _working_building_flow.has_method("process_working_tick"):
        _working_building_flow.call("process_working_tick", delta, building_id, slot_index, _active)

func try_revive_castle_on_zero_hp() -> bool:
    var result := ArtifactEffectExecutor.try_revive_castle(_active, _state)
    if result and SaveCore:
        SaveCore.request_save()
    return result

func apply_build_refund(paid_costs: Array[Dictionary]) -> void:
    var base_refund := ArtifactStatQueries.get_build_refund_percent(_active)
    ArtifactEffectExecutor.apply_build_refund(_active, _state, paid_costs, base_refund)

func on_spell_cast(spell_id: String) -> void:
    var changed := ArtifactEffectExecutor.on_spell_cast(_active, _state, spell_id)
    if changed:
        artifacts_changed.emit()
        if SaveCore:
            SaveCore.request_save()

func get_resource_building_durability_limit(building_config: Variant, base_durability: int) -> int:
    if _building_lifecycle_bonuses != null and _building_lifecycle_bonuses.has_method("get_resource_building_durability"):
        return int(_building_lifecycle_bonuses.call("get_resource_building_durability", _active, building_config, base_durability))
    return base_durability

func get_military_building_unit_limit(building_config: Variant, base_limit: int) -> int:
    if _building_lifecycle_bonuses != null and _building_lifecycle_bonuses.has_method("get_military_building_unit_limit"):
        return int(_building_lifecycle_bonuses.call("get_military_building_unit_limit", _active, building_config, base_limit))
    return base_limit

func on_enemy_spawned(mob: Node) -> void:
    ArtifactEffectExecutor.on_enemy_spawned(mob)

func on_wine_spent(amount: int) -> void:
    var changed := ArtifactEffectExecutor.on_wine_spent(_active, _state, amount)
    if changed:
        artifacts_changed.emit()
        if SaveCore:
            SaveCore.request_save()

func get_reward_reroll_cost(rerolls_done: int) -> int:
    if _active.has("voodoo_beads") and rerolls_done <= 0:
        return 0
    return RerollCost.get_next_reroll_cost(rerolls_done)

func try_pay_reward_reroll(rerolls_done: int) -> bool:
    var cost := get_reward_reroll_cost(rerolls_done)
    if cost <= 0:
        return true
    return EconomyCore != null and EconomyCore.has_method("spend_gold") and bool(EconomyCore.call("spend_gold", float(cost)))

func can_afford_reward_reroll(rerolls_done: int) -> bool:
    var cost := get_reward_reroll_cost(rerolls_done)
    if cost <= 0:
        return true
    return EconomyCore != null and EconomyCore.has_method("can_afford") and bool(EconomyCore.call("can_afford", float(cost)))

func has_trader_free_coupon() -> bool:
    return _trader_benefits.has_free_coupon_charge(_active, _state)

func consume_trader_free_coupon() -> bool:
    var consumed := _trader_benefits.consume_free_coupon_charge(_active, _state)
    if consumed and SaveCore:
        SaveCore.request_save()
    return consumed

func has_extended_market_trades() -> bool:
    return _trader_benefits.has_extended_market_trades(_active)

func on_gaze_upgraded() -> void:
    _progression_flow.on_gaze_upgraded(_active, _state, _get_hero_core())

func get_active_cooldowns_with_artifact_modifiers(cooldowns: Dictionary) -> Dictionary:
    return _progression_flow.apply_active_cooldown_reduction(_active, cooldowns)

func get_troop_building_capacity_bonus(building_config: Variant) -> int:
    return _progression_flow.get_troop_building_capacity_bonus(_active, building_config)

func on_unit_created() -> void:
    _progression_flow.on_unit_created(_active, ResourceCore)

func on_castle_damaged(amount: int) -> void:
    _castle_hooks.on_castle_damaged(_active, amount, EconomyCore)

func on_resource_building_depleted() -> void:
    var changed := _castle_hooks.on_resource_building_depleted(_active, _state, CastleCore)
    if changed and SaveCore:
        SaveCore.request_save()

func on_resource_production_completed(building_id: String, outputs: Array = [], production_count: int = 1) -> void:
    var changed := _production_hooks.on_resource_production_completed(_active, _state, building_id, outputs, production_count, ResourceCore)
    if changed:
        artifacts_changed.emit()
        if SaveCore:
            SaveCore.request_save()

func try_apply_post_hit_stun(target: Variant, unit_id: String, attack_count: int, troop_core: Variant) -> void:
    _combat_hooks.try_apply_post_hit_stun(_active, target, unit_id, attack_count, troop_core)

func _process_pending_spell_choice_rewards() -> void:
    var state := {
        "pending": _pending_spell_choice_rewards,
        "pending_legendary": _pending_legendary_spell_choice_rewards
    }
    _pending_reward_flow.process_pending_rewards(state, _runtime_flow)
    _pending_spell_choice_rewards = int(state.get("pending", 0))
    _pending_legendary_spell_choice_rewards = int(state.get("pending_legendary", 0))

func _reapply_active_effects() -> void:
    var troop_core := _get_troop_bonus_core()
    _persistence_flow.reapply_active_effects(
        _active,
        _runtime_class_bonus_applied,
        troop_core,
        Callable(ArtifactClassBonuses, "reapply_all"),
        Callable(ArtifactEffectExecutor, "_refresh_dependent_systems")
    )

func _on_enemy_killed(enemy_id: String) -> void:
    ArtifactEventHandlers.on_enemy_killed(_active, _state, enemy_id)

func _on_wave_started(wave_number: int) -> void:
    ArtifactEventHandlers.on_wave_started(_active, _state, wave_number)

func _on_hero_died(hero_id: String) -> void:
    ArtifactEventHandlers.on_hero_died(_active, _state, hero_id)

func _on_game_loaded() -> void:
    _reapply_active_effects()
    artifacts_changed.emit()

func get_save_data() -> Dictionary:
    return _persistence_flow.get_save_data(
        _owned,
        _active,
        _state,
        _pending_spell_choice_rewards,
        _pending_legendary_spell_choice_rewards
    )

func load_save_data(data: Dictionary) -> void:
    ArtifactClassBonuses.clear_all(_runtime_class_bonus_applied, _get_troop_bonus_core())
    _runtime_class_bonus_applied.clear()
    var loaded := _persistence_flow.load_save_data(data, Callable(ArtifactCatalog, "has_def"))
    _owned = loaded.get("owned", {})
    _active = loaded.get("active", {})
    _state = loaded.get("state", {})
    _pending_spell_choice_rewards = int(loaded.get("pending_spell_choice_rewards", 0))
    _pending_legendary_spell_choice_rewards = int(loaded.get("pending_legendary_spell_choice_rewards", 0))
    _reapply_active_effects()

func reset() -> void:
    ArtifactClassBonuses.clear_all(_runtime_class_bonus_applied, _get_troop_bonus_core())
    var reset_state := _persistence_flow.reset_state()
    _owned = reset_state.get("owned", {})
    _active = reset_state.get("active", {})
    _state = reset_state.get("state", {})
    _runtime_class_bonus_applied = reset_state.get("runtime_class_bonus_applied", {})
    _pending_spell_choice_rewards = int(reset_state.get("pending_spell_choice_rewards", 0))
    _pending_legendary_spell_choice_rewards = int(reset_state.get("pending_legendary_spell_choice_rewards", 0))
    ArtifactEffectExecutor._refresh_dependent_systems()
    artifacts_changed.emit()

func _get_troop_bonus_core() -> Node:
    var tree := Engine.get_main_loop() as SceneTree
    return _runtime_target_bridge.get_troop_bonus_core(tree)

func _enqueue_pending_rewards(rewards: Variant) -> void:
    var game_scene := _get_game_scene()
    _pending_reward_flow.enqueue_pending_rewards(_runtime_target_bridge, rewards, game_scene)

func _get_game_scene() -> Node:
    var tree := Engine.get_main_loop() as SceneTree
    return _runtime_target_bridge.get_game_scene(tree)

func _get_hero_core() -> Node:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null or tree.root == null:
        return null
    return tree.root.get_node_or_null("HeroCore")
