extends Node

signal building_upgrades_changed(building_id: String, level: int)

const API_VERSION := 2
const BuildingUpgradeSceneBridgeScript := preload("res://core/building_upgrade/BuildingUpgradeSceneBridge.gd")
const BuildingUpgradeSlotQueryScript := preload("res://core/building_upgrade/BuildingUpgradeSlotQuery.gd")
const BuildingUpgradeRegistryFlowScript := preload("res://core/building_upgrade/BuildingUpgradeRegistryFlow.gd")
const BuildingUpgradeBonusFlowScript := preload("res://core/building_upgrade/BuildingUpgradeBonusFlow.gd")
const BuildingUpgradeEffectFlowScript := preload("res://core/building_upgrade/BuildingUpgradeEffectFlow.gd")
const BuildingUpgradeProductionBoostScript := preload("res://core/building_upgrade/BuildingUpgradeProductionBoost.gd")
const BuildingUpgradeProductionBonusScript := preload("res://core/building_upgrade/BuildingUpgradeProductionBonus.gd")
const BuildingUpgradeNeighbourBoostScript := preload("res://core/building_upgrade/BuildingUpgradeNeighbourBoost.gd")
const BuildingUpgradeTroopInspirationScript := preload("res://core/building_upgrade/BuildingUpgradeTroopInspiration.gd")
const BuildingUpgradeCapacityBonusScript := preload("res://core/building_upgrade/BuildingUpgradeCapacityBonus.gd")
const BuildingUpgradeTroopStatModifierScript := preload("res://core/building_upgrade/BuildingUpgradeTroopStatModifier.gd")
const BuildingUpgradeCombatHookScript := preload("res://core/building_upgrade/BuildingUpgradeCombatHook.gd")
const BuildingUpgradeDeathRewardScript := preload("res://core/building_upgrade/BuildingUpgradeDeathReward.gd")
const BuildingUpgradeCostModifierScript := preload("res://core/building_upgrade/BuildingUpgradeCostModifier.gd")
const BuildingUpgradeMegaMilitiaScript := preload("res://core/building_upgrade/BuildingUpgradeMegaMilitia.gd")
const BuildingUpgradeUnitCounterScript := preload("res://core/building_upgrade/BuildingUpgradeUnitCounter.gd")
const BuildingUpgradeSpellDamageBoostScript := preload("res://core/building_upgrade/BuildingUpgradeSpellDamageBoost.gd")
const BuildingUpgradeUnitAuraScript := preload("res://core/building_upgrade/BuildingUpgradeUnitAura.gd")
const BuildingUpgradeProductionEventScript := preload("res://core/building_upgrade/BuildingUpgradeProductionEvent.gd")
const BuildingUpgradeLionCircusScript := preload("res://core/building_upgrade/BuildingUpgradeLionCircus.gd")

var _unlocked_by_building: Dictionary = {}
var _mega_militia_counter: Dictionary = {"count": 0}
var _scene_bridge = null
var _slot_query = null
var _registry_flow = null
var _bonus_flow = null
var _effect_flow = null

func _ready() -> void:
    _scene_bridge = BuildingUpgradeSceneBridgeScript.new()
    _slot_query = BuildingUpgradeSlotQueryScript.new()
    _registry_flow = BuildingUpgradeRegistryFlowScript.new()
    _bonus_flow = BuildingUpgradeBonusFlowScript.new()
    _effect_flow = BuildingUpgradeEffectFlowScript.new()
    var tree := Engine.get_main_loop() as SceneTree
    if tree and tree.root:
        var event_bus_node := tree.root.get_node_or_null("EventBus")
        if event_bus_node and event_bus_node.has_signal("hero_died"):
            event_bus_node.hero_died.connect(_on_hero_died_for_rewards)

func _normalize_building_id(building_id: String) -> String:
    return _registry_flow.normalize_building_id(building_id) if _registry_flow else String(building_id).strip_edges().to_lower()

func _extract_building_id_from_upgrade(upgrade_id: String) -> String:
    return _registry_flow.extract_building_id_from_upgrade(upgrade_id) if _registry_flow else ""

func _stringify_upgrade_array(raw: Variant) -> Array[String]:
    return _registry_flow.stringify_upgrade_array(raw) if _registry_flow else []

func _get_map_slots() -> Array:
    return _scene_bridge.get_map_slots() if _scene_bridge else []

func _count_built_buildings(building_id: String) -> int:
    return _slot_query.count_built_buildings(_get_map_slots(), building_id) if _slot_query else 0

func _count_upgraded_buildings(building_id: String, upgrade_id: String) -> int:
    if not has_building_upgrade(building_id, upgrade_id):
        return 0
    return _count_built_buildings(building_id)

func _get_slot_by_index(slot_index: int) -> Node:
    return _slot_query.get_slot_by_index(_get_map_slots(), slot_index) if _slot_query else null

func _get_slot_building_id(slot_index: int) -> String:
    return _slot_query.get_slot_building_id(_get_map_slots(), slot_index) if _slot_query else ""

func _is_slot_building(slot: Node, building_id: String) -> bool:
    return _slot_query.is_slot_building(slot, building_id) if _slot_query else false

func _is_slot_effectively_vzor_active(slot: Node) -> bool:
    return _slot_query.is_slot_effectively_vzor_active(slot) if _slot_query else false

func _get_slot_special_handler(slot: Node) -> RefCounted:
    return _slot_query.get_slot_special_handler(slot) if _slot_query else null

func _count_active_buildings(building_id: String) -> int:
    return _slot_query.count_active_buildings(_get_map_slots(), building_id) if _slot_query else 0

func _count_active_upgraded_buildings(building_id: String, upgrade_id: String) -> int:
    if not has_building_upgrade(building_id, upgrade_id):
        return 0
    return _count_active_buildings(building_id)

func get_building_upgrades(building_id: String) -> Array[String]:
    return _registry_flow.get_building_upgrades(_unlocked_by_building, building_id) if _registry_flow else []

func get_upgrades(slot_index: int) -> Array[String]:
    return get_building_upgrades(_get_slot_building_id(slot_index))

func has_building_upgrade(building_id: String, upgrade_id: String) -> bool:
    return _registry_flow.has_building_upgrade(_unlocked_by_building, building_id, upgrade_id) if _registry_flow else false

func has_upgrade(slot_index: int, upgrade_id: String) -> bool:
    var building_id := _extract_building_id_from_upgrade(upgrade_id)
    if building_id == "":
        building_id = _get_slot_building_id(slot_index)
    return has_building_upgrade(building_id, upgrade_id)

func unlock_building_upgrade(building_id: String, upgrade_id: String) -> void:
    if _registry_flow:
        _registry_flow.unlock_building_upgrade(_unlocked_by_building, building_id, upgrade_id, building_upgrades_changed.emit, SaveCore.request_save if SaveCore else Callable())

func apply_upgrade(slot_index: int, upgrade_id: String) -> void:
    var building_id := _extract_building_id_from_upgrade(upgrade_id)
    if building_id == "":
        building_id = _get_slot_building_id(slot_index)
    if building_id == "" or upgrade_id == "":
        return
    unlock_building_upgrade(building_id, upgrade_id)

func get_building_upgrade_level(building_id: String) -> int:
    return mini(get_building_upgrades(building_id).size(), 3)

func reset_slot(slot_index: int) -> void:
    return

func get_save_data() -> Dictionary:
    var data: Dictionary = _registry_flow.get_save_data(API_VERSION, _unlocked_by_building) if _registry_flow else {}
    data["mega_militia_counter"] = get_mega_militia_counter()
    return data

func load_save_data(data: Dictionary) -> void:
    _unlocked_by_building = _registry_flow.load_save_data(data) if _registry_flow else {}
    if data.has("mega_militia_counter"):
        set_mega_militia_counter(int(data["mega_militia_counter"]))

func get_buddhist_temple_production_speed_multiplier() -> float:
    var temple_count := _count_upgraded_buildings("buddhist_temple", "buddhist_temple:0")
    return _effect_flow.get_buddhist_temple_production_speed_multiplier(temple_count) if _effect_flow else 1.0

func get_buddhist_temple_troop_damage_multiplier() -> float:
    var temple_count := _count_upgraded_buildings("buddhist_temple", "buddhist_temple:1")
    return _effect_flow.get_buddhist_temple_troop_damage_multiplier(temple_count) if _effect_flow else 1.0

func get_buddhist_temple_spell_damage_multiplier() -> float:
    var temple_count := _count_upgraded_buildings("buddhist_temple", "buddhist_temple:2")
    return _effect_flow.get_buddhist_temple_spell_damage_multiplier(temple_count) if _effect_flow else 1.0

func get_concert_slot_production_speed_multiplier(slot_index: int) -> float:
    var target_slot := _get_slot_by_index(slot_index)
    if target_slot == null:
        return 1.0
    if not _is_slot_effectively_vzor_active(target_slot):
        return 1.0
    if _count_active_buildings("concert") <= 0:
        return 1.0
    return 1.3

func get_active_concert_morale_bonus() -> int:
    return _slot_query.get_concert_morale_bonus(_get_map_slots()) if _slot_query else 0

func get_passive_concert_morale_bonus() -> int:
    ## Passive concert morale is now handled by Concert special handler's get_morale_bonus()
    ## This method is kept for backward compatibility but returns 0 since passive is included in handler
    return 0

func get_active_hospital_morale_bonus() -> int:
    return _slot_query.get_active_hospital_morale_bonus(_get_map_slots()) if _slot_query else 0

func get_magic_ball_spell_damage_multiplier() -> float:
    return _bonus_flow.get_magic_ball_spell_damage_multiplier(_count_active_buildings("magic_ball"), has_building_upgrade("magic_ball", "magic_ball:0")) if _bonus_flow else 1.0

func get_active_tesla_tower_spell_damage_multiplier() -> float:
    return _effect_flow.get_active_tesla_tower_spell_damage_multiplier(_count_active_buildings("tesla_tower")) if _effect_flow else 1.0

func get_magic_ball_arcane_damage_multiplier() -> float:
    var count := _count_upgraded_buildings("magic_ball", "magic_ball:1")
    return _bonus_flow.get_scaled_multiplier(count, 0.15) if _bonus_flow else 1.0

func get_kings_statue_champion_hp_multiplier() -> float:
    var count := _count_upgraded_buildings("kings_statue", "kings_statue:1")
    return _bonus_flow.get_scaled_multiplier(count, 0.10) if _bonus_flow else 1.0

func get_kings_statue_champion_damage_multiplier() -> float:
    var count := _count_upgraded_buildings("kings_statue", "kings_statue:1")
    return _bonus_flow.get_scaled_multiplier(count, 0.10) if _bonus_flow else 1.0

func get_production_speed_multiplier(building_id: String) -> float:
    return BuildingUpgradeProductionBoostScript.get_production_multiplier(building_id, has_building_upgrade)

func process_production_bonuses(building_id: String, add_resource_func: Callable, repair_castle_func: Callable) -> Array[Dictionary]:
    return BuildingUpgradeProductionBonusScript.process_production_bonuses(building_id, has_building_upgrade, add_resource_func, repair_castle_func)

func get_neighbour_boost_multiplier(slot_grid_pos: Vector2i, all_slots_by_grid_pos: Dictionary) -> float:
    return BuildingUpgradeNeighbourBoostScript.get_neighbour_boost_multiplier(slot_grid_pos, all_slots_by_grid_pos, has_building_upgrade)

func get_troop_inspiration_damage_multiplier(troop_class_name: String) -> float:
    return BuildingUpgradeTroopInspirationScript.get_troop_class_damage_multiplier(troop_class_name, has_building_upgrade)

func get_troop_inspiration_hp_multiplier(troop_class_name: String) -> float:
    return BuildingUpgradeTroopInspirationScript.get_troop_class_hp_multiplier(troop_class_name, has_building_upgrade)

func get_efficient_processing_multiplier(building_id: String) -> int:
    return BuildingUpgradeProductionBoostScript.get_efficient_processing_multiplier(building_id, has_building_upgrade)

func get_vineyard_passive_morale_bonus() -> int:
    ## Each vineyard with vineyard:0 upgrade provides 5 passive morale.
    return _count_upgraded_buildings("vineyard", "vineyard:0") * 5

func get_market_active_morale_bonus() -> int:
    ## Each active market with market:0 upgrade provides 5 morale.
    if not has_building_upgrade("market", "market:0"):
        return 0
    return _count_active_buildings("market") * 5

func get_tavern_morale_bonus() -> int:
    ## Tavern with tavern:0 upgrade provides 5 additional morale (flat).
    ## Requires at least one built tavern with the upgrade.
    if _count_upgraded_buildings("tavern", "tavern:0") <= 0:
        return 0
    return 5

func get_crystal_mine_spell_damage_multiplier() -> float:
    ## Crystal mine Magic Aura: +10% spell damage if any crystal_mine has crystal_mine:0.
    if not has_building_upgrade("crystal_mine", "crystal_mine:0"):
        return 1.0
    return 1.1

func get_capacity_bonus(building_id: String) -> int:
    var base_bonus := BuildingUpgradeCapacityBonusScript.get_capacity_bonus(building_id, has_building_upgrade)
    var artifact_core: Node = null
    var tree := Engine.get_main_loop() as SceneTree
    if tree and tree.root:
        artifact_core = tree.root.get_node_or_null("ArtifactCore")
    if artifact_core == null or not artifact_core.has_method("get_troop_building_capacity_bonus"):
        return base_bonus
    var building_registry: Node = null
    if tree and tree.root:
        building_registry = tree.root.get_node_or_null("BuildingRegistry")
    if building_registry == null or not building_registry.has_method("get_building"):
        return base_bonus
    var config: Variant = building_registry.call("get_building", building_id)
    if config == null:
        return base_bonus
    return base_bonus + int(artifact_core.call("get_troop_building_capacity_bonus", config))

func get_unit_stat_hp_multiplier(unit_id: String) -> float:
    return BuildingUpgradeTroopStatModifierScript.get_unit_hp_multiplier(unit_id, has_building_upgrade)

func get_unit_stat_damage_multiplier(unit_id: String) -> float:
    return BuildingUpgradeTroopStatModifierScript.get_unit_damage_multiplier(unit_id, has_building_upgrade)

func get_unit_stat_evasion_chance(unit_id: String) -> float:
    return BuildingUpgradeTroopStatModifierScript.get_unit_evasion_chance(unit_id, has_building_upgrade)

func get_on_hit_effects(unit_id: String) -> Array[Dictionary]:
    return BuildingUpgradeCombatHookScript.get_on_hit_effects(unit_id, has_building_upgrade)

func _resolve_unit_id(hero_id: String) -> String:
    var id := hero_id.to_lower()
    if id.contains("_"):
        var parts := id.rsplit("_", true, 1)
        if parts.size() == 2 and String(parts[1]).is_valid_int():
            return String(parts[0])
    return id

func _on_hero_died_for_rewards(hero_id: String) -> void:
    process_hero_death_reward(hero_id)

func process_hero_death_reward(hero_id: String) -> void:
    var unit_id := _resolve_unit_id(hero_id)
    var reward: Dictionary = BuildingUpgradeDeathRewardScript.get_death_reward(unit_id, has_building_upgrade)
    if reward.is_empty():
        return
    var resource_id: String = reward.get("resource_id", "")
    var amount: int = int(reward.get("amount", 0))
    if resource_id == "" or amount <= 0:
        return
    var tree := Engine.get_main_loop() as SceneTree
    if tree and tree.root:
        var resource_core := tree.root.get_node_or_null("ResourceCore")
        if resource_core and resource_core.has_method("add_resource"):
            resource_core.call("add_resource", resource_id, amount)

func get_cost_multiplier(building_id: String) -> float:
    return BuildingUpgradeCostModifierScript.get_cost_multiplier(building_id, has_building_upgrade)

func resolve_mega_militia_unit(building_id: String, produced_unit_id: String) -> String:
    return BuildingUpgradeMegaMilitiaScript.resolve_produced_unit(building_id, produced_unit_id, _mega_militia_counter, has_building_upgrade)

func get_mega_militia_counter() -> int:
    return BuildingUpgradeMegaMilitiaScript.get_counter(_mega_militia_counter)

func set_mega_militia_counter(value: int) -> void:
    BuildingUpgradeMegaMilitiaScript.set_counter(_mega_militia_counter, value)

# ── Phase 2C: Spell Damage ───────────────────────────────────────────────────

func get_paladins_spell_damage_multiplier() -> float:
    return BuildingUpgradeSpellDamageBoostScript.get_paladins_spell_damage_multiplier(has_building_upgrade)

func get_ram_spell_damage_multiplier() -> float:
    return BuildingUpgradeSpellDamageBoostScript.get_ram_spell_damage_multiplier(has_building_upgrade)

func get_unicorn_spell_damage_multiplier() -> float:
    return BuildingUpgradeSpellDamageBoostScript.get_unicorn_spell_damage_multiplier(has_building_upgrade)

# ── Phase 2C: Unit Auras ─────────────────────────────────────────────────────

func get_black_unicorn_morale_bonus() -> int:
    return BuildingUpgradeUnitAuraScript.get_black_unicorn_morale_bonus(has_building_upgrade)

func get_hydra_global_damage_multiplier() -> float:
    return BuildingUpgradeUnitAuraScript.get_hydra_global_damage_multiplier(has_building_upgrade)

func get_minotaur_flying_damage_multiplier() -> float:
    return BuildingUpgradeUnitAuraScript.get_minotaur_flying_damage_multiplier(has_building_upgrade)

func get_falcon_mentoring_hp_multiplier() -> float:
    return BuildingUpgradeUnitAuraScript.get_falcon_mentoring_hp_multiplier(has_building_upgrade)

# ── Phase 2C: Attack Range ───────────────────────────────────────────────────

func get_unit_stat_attack_range_multiplier(unit_id: String) -> float:
    return BuildingUpgradeTroopStatModifierScript.get_unit_attack_range_multiplier(unit_id, has_building_upgrade)

# ── Phase 2C: Production Events ──────────────────────────────────────────────

func process_military_production_event(building_id: String, produced_unit_id: String, add_resource_func: Callable, hire_extra_func: Callable) -> Array[Dictionary]:
    return BuildingUpgradeProductionEventScript.process_military_production_event(building_id, produced_unit_id, has_building_upgrade, add_resource_func, hire_extra_func)

# ── Phase 2C: Lion Circus ────────────────────────────────────────────────────

func get_lion_circus_cost_multiplier() -> float:
    return BuildingUpgradeLionCircusScript.get_production_cost_multiplier(has_building_upgrade)

func is_lion_circus_versatility_active() -> bool:
    return BuildingUpgradeLionCircusScript.is_versatility_active(has_building_upgrade)
