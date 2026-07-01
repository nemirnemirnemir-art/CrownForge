extends Node
## HeroCore - Autoload singleton (Controller)
## Координирует все модули системы героев

const API_VERSION := 1
const HeroReplacementFlowScript := preload("res://core/hero/HeroReplacementFlow.gd")
const HeroPersistenceFlowScript := preload("res://core/hero/HeroPersistenceFlow.gd")
const HeroBonusSyncFlowScript := preload("res://core/hero/HeroBonusSyncFlow.gd")
const HeroDamageFlowScript := preload("res://core/hero/HeroDamageFlow.gd")
const HeroRecruitmentFlowScript := preload("res://core/hero/HeroRecruitmentFlow.gd")
const HeroBattleFlowScript := preload("res://core/hero/HeroBattleFlow.gd")
const HeroCoreEventRouterScript := preload("res://core/hero/HeroCoreEventRouter.gd")
const HeroCoreNotificationBridgeScript := preload("res://core/hero/HeroCoreNotificationBridge.gd")
const HeroEvasionServiceScript := preload("res://core/hero/HeroEvasionService.gd")

## Signals
@warning_ignore("UNUSED_SIGNAL")
signal hero_created(hero_id: String, hero_data: Dictionary)
@warning_ignore("UNUSED_SIGNAL")
signal hero_updated(hero_id: String, hero_data: Dictionary)
@warning_ignore("UNUSED_SIGNAL")
signal hero_hp_changed(hero_id: String, new_hp: float, max_hp: float)
@warning_ignore("UNUSED_SIGNAL")
signal hero_died(hero_id: String)
@warning_ignore("UNUSED_SIGNAL")
signal hero_removed(hero_id: String)
@warning_ignore("UNUSED_SIGNAL")
signal squad_changed()
@warning_ignore("UNUSED_SIGNAL")
signal heroes_cleared()
@warning_ignore("UNUSED_SIGNAL")
signal hero_healed(hero_id: String, amount: int)
@warning_ignore("UNUSED_SIGNAL")
signal buff_added(hero_id: String, buff_id: String)
@warning_ignore("UNUSED_SIGNAL")
signal buff_removed(hero_id: String, buff_id: String)

## Module instances
var _hero_data: HeroData
var _hero_query: HeroQuery
var _hero_mutator: HeroMutator
var _hero_perks: HeroPerks
var _hero_recruitment: HeroRecruitment
var _hero_squad: HeroSquad
var _hero_items: HeroItems
var _hero_health: HeroHealth
var _hero_buffs: HeroBuffs
var _hero_stats: HeroStats
var _hero_progression: HeroProgression
var _hero_combat: HeroCombat
var _hero_battle: HeroBattle
var _replacement_flow = null
var _persistence_flow = null
var _bonus_sync_flow = null
var _damage_flow = null
var _recruitment_flow = null
var _battle_flow = null
var _event_router = null
var _notification_bridge = null
var _evasion_service = null

var _recruitment_service: HeroRecruitmentService

const TROOP_SPAWN_MODE_BATTLEFIELD := 0
const TROOP_SPAWN_MODE_BARRACKS := 1
const TROOP_SPAWN_MODE_TO_CAPACITY := 2
const STABLES_SURVIVOR_UPGRADE_ID := "stables:2"

@warning_ignore("UNUSED_SIGNAL")
signal troop_spawn_mode_changed(mode: int)

var _troop_spawn_mode: int = TROOP_SPAWN_MODE_TO_CAPACITY

## Public accessors for backward compatibility
var heroes: Dictionary:
    get:
        return _hero_data.heroes if _hero_data else {}

var active_hero_ids: Array[String]:
    get:
        return _hero_squad.active_hero_ids if _hero_squad else []

# Access to new Query API
var query: HeroQuery:
    get:
        return _hero_query

# Access to new Mutator API
var mutator: HeroMutator:
    get:
        return _hero_mutator

func get_heroes_in_battle_internal() -> Array[String]:
    return _hero_battle.get_heroes_in_battle() if _hero_battle else []

func _ready() -> void:
    _initialize_modules()
    _event_router = HeroCoreEventRouterScript.new()
    _event_router.setup(self)

func _exit_tree() -> void:
    _save_game_if_available()

func _initialize_modules() -> void:
    # Initialize in dependency order
    _hero_data = HeroData.new()
    _hero_query = HeroQuery.new(_hero_data)
    _hero_mutator = HeroMutator.new(_hero_data, self)
    _hero_perks = HeroPerks.new()
    _hero_recruitment = HeroRecruitment.new(_hero_data)
    _recruitment_service = HeroRecruitmentService.new(_hero_data, _hero_recruitment)
    _hero_squad = HeroSquad.new(_hero_data)
    _hero_items = HeroItems.new(_hero_data, _hero_mutator)
    # _hero_items.set_mutator(_hero_mutator)
    _hero_health = HeroHealth.new(_hero_data, _hero_perks, _hero_mutator)
    # _hero_health.set_mutator(_hero_mutator)
    _hero_buffs = HeroBuffs.new(_hero_data, _hero_health)
    _hero_stats = HeroStats.new(_hero_data, _hero_perks, _hero_buffs)
    _hero_progression = HeroProgression.new(_hero_data, _hero_perks, _hero_stats, _hero_mutator)
    # _hero_progression.set_mutator(_hero_mutator)
    _hero_combat = HeroCombat.new(_hero_data, _hero_stats, _hero_buffs)
    _hero_battle = HeroBattle.new(_hero_data, _hero_squad)
    _replacement_flow = HeroReplacementFlowScript.new()
    _persistence_flow = HeroPersistenceFlowScript.new()
    _bonus_sync_flow = HeroBonusSyncFlowScript.new()
    _damage_flow = HeroDamageFlowScript.new()
    _recruitment_flow = HeroRecruitmentFlowScript.new()
    _battle_flow = HeroBattleFlowScript.new()
    _notification_bridge = HeroCoreNotificationBridgeScript.new()
    _evasion_service = HeroEvasionServiceScript.new()
    
    # Revalidate all hero stats based on UnitConfigs (fix biblically accurate stats)
    if _hero_data:
        _hero_data.revalidate_all_heroes()
    
    # print("[HeroCore] ✅ All modules initialized")

## === PUBLIC API ===

## Perk system
func get_perk_data(perk_id: String) -> PerkData:
    return _hero_perks.get_perk_data(perk_id) if _hero_perks else null

func get_perk_def(perk_id: String) -> PerkData:
    return _hero_perks.get_perk_def(perk_id) if _hero_perks else null

func get_hero_perks(hero_id: String) -> Array:
    if not _hero_data.has_hero(hero_id):
        return []
    var hero = _hero_data.get_hero(hero_id)
    return _hero_perks.get_hero_perks(hero) if _hero_perks else []

func add_perk_to_hero(hero_id: String, perk_id: String) -> void:
    if not _hero_data.has_hero(hero_id):
        return
    var hero = _hero_data.get_hero(hero_id)
    if _hero_perks.add_perk_to_hero(hero, perk_id):
        _emit_updated_hero_and_request_save(hero_id)

func get_perk_modifiers(hero_id: String) -> Dictionary:
    if not _hero_data.has_hero(hero_id):
        return {}
    var hero = _hero_data.get_hero(hero_id)
    return _hero_perks.get_perk_modifiers(hero) if _hero_perks else {}

## Recruitment
func hire_hero_copy(base_id: String) -> String:
    return _recruitment_flow.hire_hero_copy(_hero_data, _recruitment_service, base_id, hero_created.emit, EventBus.hero_recruited.emit, _get_request_save_callable()) if _recruitment_flow else ""

func ensure_hero_template(base_id: String, display_name: String = "", cost: float = 0.0) -> bool:
    return _recruitment_flow.ensure_hero_template(_hero_data, base_id, display_name, cost) if _recruitment_flow else false

func try_recruit_hero(type: String) -> bool:
    return _recruitment_flow.try_recruit_hero(_hero_data, _recruitment_service, type, hero_created.emit, EventBus.hero_recruited.emit, _get_request_save_callable()) if _recruitment_flow else false

func get_recruitment_cost(type: String) -> int:
    return _hero_recruitment.get_recruitment_cost(type) if _hero_recruitment else 0

func generate_random_hero_name(icon_id: String) -> String:
    return _hero_recruitment.generate_random_hero_name(icon_id) if _hero_recruitment else "Герой"

## Hero data
func create_hero(hero_id: String, hero_name: String, icon_id: String, cost: float, person_id: String = "") -> bool:
    if _hero_data.create_hero(hero_id, hero_name, icon_id, cost, person_id):
        var hero = _hero_data.get_hero(hero_id)
        hero_created.emit(hero_id, hero)
        # if SaveCore:
        #     SaveCore.save_game()
        return true
    return false

func get_hero(hero_id: String) -> Dictionary:
    return _hero_data.get_hero(hero_id) if _hero_data else {}

func update_hero(hero_id: String, updates: Dictionary) -> void:
    _hero_data.update_hero(hero_id, updates)
    if _hero_data.has_hero(hero_id):
        _emit_updated_hero(hero_id)

func get_troop_spawn_mode() -> int:
    return _troop_spawn_mode

func set_troop_spawn_mode(mode: int) -> void:
    var m := int(mode)
    if m != TROOP_SPAWN_MODE_BATTLEFIELD and m != TROOP_SPAWN_MODE_BARRACKS and m != TROOP_SPAWN_MODE_TO_CAPACITY:
        return
    if _troop_spawn_mode == m:
        return
    _troop_spawn_mode = m
    troop_spawn_mode_changed.emit(_troop_spawn_mode)

func remove_hero(hero_id: String) -> void:
    if _replacement_flow:
        _replacement_flow.remove_hero(_hero_data, _recruitment_service, _hero_battle, _hero_squad, hero_id, squad_changed.emit, hero_removed.emit, _get_request_save_callable())

func _try_spawn_survivor_rider(dead_hero_id: String) -> String:
    return _replacement_flow.try_spawn_survivor_rider(
        _hero_data,
        _hero_squad,
        _hero_battle,
        BuildingUpgradeCore,
        dead_hero_id,
        Callable(self, "ensure_hero_template"),
        Callable(self, "hire_hero_copy"),
        Callable(self, "update_hero"),
        EventBus.hero_auto_replaced.emit,
        Callable(self, "add_to_squad")
    ) if _replacement_flow else ""

func mark_hero_dead(hero_id: String) -> void:
    _hero_data.mark_hero_dead(hero_id)
    remove_hero(hero_id)

func clear_all_heroes() -> void:
    # Use reset() method for full cleanup
    reset()

func reset() -> void:
    # Chain reset calls to all modules
    if _hero_data: _hero_data.reset()
    if _hero_squad: _hero_squad.reset()
    if _hero_battle: _hero_battle.reset()
    if _hero_buffs: _hero_buffs.reset()
    
    # Emit cleared signal for UI
    heroes_cleared.emit()
    # print("[HeroCore] All heroes and modules reset")

func get_active_heroes() -> Array[Dictionary]:
    return _hero_squad.get_active_heroes() if _hero_squad else []

## Squad management
func add_to_squad(hero_id: String) -> bool:
    return _battle_flow.add_to_squad(_hero_squad, hero_id, squad_changed.emit, _get_request_save_callable()) if _battle_flow else false

func remove_from_squad(hero_id: String) -> void:
    if _battle_flow:
        _battle_flow.remove_from_squad(_hero_squad, hero_id, squad_changed.emit, _get_request_save_callable())

## Progression
func add_xp_to_hero(hero_id: String, xp_amount: int) -> void:
    var active_ids = _hero_squad.active_hero_ids if _hero_squad else []
    if _hero_progression.add_xp_to_hero(hero_id, xp_amount, active_ids):
        _emit_updated_hero_and_request_save(hero_id)

## Items
func equip_item_to_hero(hero_id: String, item: Dictionary, slot_name: String) -> void:
    if _hero_items.equip_item_to_hero(hero_id, item, slot_name):
        _emit_updated_hero_and_request_save(hero_id)

func unequip_item_from_hero(hero_id: String, slot_name: String) -> void:
    if _hero_items.unequip_item_from_hero(hero_id, slot_name):
        _emit_updated_hero_and_request_save(hero_id)

## Health
func heal_hero(hero_id: String, amount: int) -> void:
    var actual_heal = _hero_health.heal_hero(hero_id, amount)
    if actual_heal > 0:
        _emit_updated_hero_and_request_save(hero_id)
        hero_healed.emit(hero_id, actual_heal)

func give_potion(hero_id: String) -> bool:
    return _hero_health.give_potion(hero_id) if _hero_health else false

func use_potion(hero_id: String) -> bool:
    if _hero_health.use_potion(hero_id):
        _emit_updated_hero(hero_id)
        return true
    return false

## Combat
func take_damage(hero_id: String, amount: float) -> void:
    if _damage_flow:
        var died: bool = _damage_flow.apply_damage(
            _hero_combat,
            hero_id,
            amount,
            Callable(self, "_try_apply_evasion_reaction"),
            Callable(self, "_try_spawn_survivor_rider"),
            hero_died.emit,
            EventBus.hero_died.emit,
            Callable(self, "remove_hero"),
            Callable(self, "_emit_updated_hero_after_damage")
        )
        if not died:
            return

func _emit_updated_hero_after_damage(hero_id: String, _payload: Dictionary = {}) -> void:
    _emit_updated_hero_and_request_save(hero_id)

func _try_apply_evasion_reaction(hero_id: String, amount: float) -> bool:
    return _evasion_service.try_apply_evasion_reaction(hero_id, amount, Callable(self, "update_hero")) if _evasion_service else false

func get_hero_defense(hero_id: String) -> int:
    return _hero_stats.get_hero_defense(hero_id) if _hero_stats else 0

## Stats
func get_hero_total_stats(hero_id: String) -> Dictionary:
    return _hero_stats.get_hero_total_stats(hero_id) if _hero_stats else {}

func get_hero_xp_gain_multiplier(hero_id: String) -> float:
    var active_ids = _hero_squad.active_hero_ids if _hero_squad else []
    return _hero_stats.get_hero_xp_gain_multiplier(hero_id, active_ids) if _hero_stats else 1.0

## Buffs
func add_buff(hero_id: String, buff_id: String, duration_battles: int, stats: Dictionary) -> void:
    if _hero_buffs.add_buff(hero_id, buff_id, duration_battles, stats):
        _emit_updated_hero(hero_id)
        buff_added.emit(hero_id, buff_id)

func remove_buff(hero_id: String, buff_id: String) -> void:
    _hero_buffs.remove_buff(hero_id, buff_id)
    if _hero_data.has_hero(hero_id):
        _emit_updated_hero(hero_id)
    buff_removed.emit(hero_id, buff_id)


func _emit_updated_hero(hero_id: String) -> void:
    if _notification_bridge and _notification_bridge.emit_updated(_hero_data, hero_id, hero_updated.emit):
        return
    _emit_updated_hero_fallback(hero_id)


func _emit_updated_hero_and_request_save(hero_id: String) -> void:
    if _notification_bridge and _notification_bridge.emit_updated_and_save(_hero_data, hero_id, hero_updated.emit, _get_request_save_callable()):
        return
    if _emit_updated_hero_fallback(hero_id):
        var request_save := _get_request_save_callable()
        if request_save.is_valid():
            request_save.call()


func _emit_updated_hero_fallback(hero_id: String) -> bool:
    if _hero_data == null:
        return false
    hero_updated.emit(hero_id, _hero_data.get_hero(hero_id))
    return true


func _get_save_core_node() -> Node:
    return get_node_or_null("/root/SaveCore")


func _get_request_save_callable() -> Callable:
    var save_core := _get_save_core_node()
    if save_core != null and save_core.has_method("request_save"):
        return Callable(save_core, "request_save")
    return Callable()


func _save_game_if_available() -> void:
    var save_core := _get_save_core_node()
    if save_core != null and save_core.has_method("save_game"):
        save_core.call("save_game")

func get_hero_buffs(hero_id: String) -> Dictionary:
    return _hero_buffs.get_hero_buffs(hero_id) if _hero_buffs else {}

func get_buff_modifiers(hero_id: String) -> Dictionary:
    return _hero_buffs.get_buff_modifiers(hero_id) if _hero_buffs else {}

## Battle
func get_available_for_battle() -> Array[String]:
    return _hero_battle.get_available_for_battle() if _hero_battle else []

func start_battle_with_heroes(hero_ids: Array) -> bool:
    return _battle_flow.start_battle_with_heroes(_hero_battle, hero_ids, EventBus.battle_started.emit, squad_changed.emit) if _battle_flow else false

func end_current_battle(is_victory: bool = false) -> void:
    if _battle_flow:
        _battle_flow.end_current_battle(_hero_battle, is_victory, EventBus.battle_ended.emit, squad_changed.emit)

func replace_dead_hero(dead_id: String) -> String:
    return _battle_flow.replace_dead_hero(_hero_battle, dead_id, EventBus.hero_auto_replaced.emit) if _battle_flow else ""

func get_heroes_in_battle() -> Array[String]:
    return _hero_battle.get_heroes_in_battle() if _hero_battle else []

func is_battle_active() -> bool:
    return _hero_battle.is_battle_active() if _hero_battle else false

## Save/Load
func get_save_data() -> Dictionary:
    return _persistence_flow.get_save_data(_hero_data, _hero_squad, _hero_buffs) if _persistence_flow else {}

func load_save_data(data: Dictionary) -> void:
    if _persistence_flow:
        _persistence_flow.load_save_data(data, _hero_data, _hero_squad, _hero_buffs, squad_changed.emit)
    # print("[HeroCore] Loaded %d heroes" % (_hero_data.heroes.size() if _hero_data else 0))

## Event handlers
func _on_wave_completed(_wave_number: int) -> void:
    var active_ids = _hero_squad.active_hero_ids if _hero_squad else []
    if _hero_buffs:
        _hero_buffs.on_wave_completed(active_ids)

## Called when global troop bonuses change (e.g. from debug menu or rewards)
func _on_troop_bonuses_changed() -> void:
    if _bonus_sync_flow:
        _bonus_sync_flow.sync_after_troop_bonus_change(_hero_data, Callable(self, "get_hero_total_stats"), Callable(self, "update_hero"), hero_hp_changed.emit, _get_request_save_callable())

## Called when building upgrades change (e.g. slinger HP +200%)
## Recalculates stats for all heroes whose unit type may be affected
func _on_building_upgrades_changed(_building_id: String, _level: int) -> void:
    if _bonus_sync_flow:
        _bonus_sync_flow.sync_after_troop_bonus_change(_hero_data, Callable(self, "get_hero_total_stats"), Callable(self, "update_hero"), hero_hp_changed.emit, _get_request_save_callable())
