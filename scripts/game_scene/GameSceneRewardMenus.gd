extends RefCounted
class_name GameSceneRewardMenus

var _reward_menu_base_production: Node = null
var _reward_menu_levy_barracks: Node = null
var _reward_menu_artifacts: Node = null
var _reward_menu_troop_bonuses: Node = null
var _reward_menu_building_upgrades: Node = null
var _reward_menu_resources: Node = null
var _reward_menu_spells: Node = null
var _reward_menu_legendary_spells: Node = null
var _reward_menu_trader: Node = null
var _prophecy_menu: Node = null
var _prophecy_pattern_pool: Node = null
var _waves_manager: Object = null

func initialize(
    base_production: Node,
    levy_barracks: Node,
    artifacts: Node,
    troop_bonuses: Node,
    building_upgrades: Node,
    resources: Node,
    spells: Node,
    legendary_spells: Node,
    trader: Node,
    prophecy_menu: Node,
    prophecy_pool: Node,
    waves_manager: Object
) -> void:
    _reward_menu_base_production = base_production
    _reward_menu_levy_barracks = levy_barracks
    _reward_menu_artifacts = artifacts
    _reward_menu_troop_bonuses = troop_bonuses
    _reward_menu_building_upgrades = building_upgrades
    _reward_menu_resources = resources
    _reward_menu_spells = spells
    _reward_menu_legendary_spells = legendary_spells
    _reward_menu_trader = trader
    _prophecy_menu = prophecy_menu
    _prophecy_pattern_pool = prophecy_pool
    _waves_manager = waves_manager

func open_base_production() -> void:
    if _reward_menu_base_production and not _reward_menu_base_production.visible:
        _reward_menu_base_production.open()

func open_levy_barracks() -> void:
    if _reward_menu_levy_barracks and not _reward_menu_levy_barracks.visible:
        _reward_menu_levy_barracks.open()

func open_artifacts(next_offered_count: int = 2, next_legendary_only: bool = false) -> void:
    if _reward_menu_artifacts and not _reward_menu_artifacts.visible:
        if _reward_menu_artifacts.has_method("open_with_options"):
            _reward_menu_artifacts.open_with_options(next_offered_count, next_legendary_only)
        else:
            _reward_menu_artifacts.offered_count = next_offered_count
            if _reward_menu_artifacts.has_method("set"):
                _reward_menu_artifacts.set("legendary_only", next_legendary_only)
            _reward_menu_artifacts.open()

func open_troop_bonuses() -> void:
    if _reward_menu_troop_bonuses and not _reward_menu_troop_bonuses.visible:
        _reward_menu_troop_bonuses.open()

func open_building_upgrades() -> void:
    if _reward_menu_building_upgrades and not _reward_menu_building_upgrades.visible:
        _reward_menu_building_upgrades.open()

func open_resources(amount: int = 0) -> void:
    if _reward_menu_resources and not _reward_menu_resources.visible:
        _reward_menu_resources.open(amount)

func open_spells(next_offered_count: int = 2, next_legendary_only: bool = false) -> void:
    if _reward_menu_spells and not _reward_menu_spells.visible:
        if _reward_menu_spells.has_method("open_with_options"):
            _reward_menu_spells.open_with_options(next_offered_count, next_legendary_only)
        else:
            _reward_menu_spells.legendary_only = next_legendary_only
            _reward_menu_spells.offered_count = next_offered_count
            _reward_menu_spells.open()

func open_legendary_spells(next_offered_count: int = 2) -> void:
    if _reward_menu_legendary_spells and not _reward_menu_legendary_spells.visible:
        if _reward_menu_legendary_spells.has_method("open_with_options"):
            _reward_menu_legendary_spells.open_with_options(next_offered_count, true)
        else:
            _reward_menu_legendary_spells.legendary_only = true
            _reward_menu_legendary_spells.offered_count = next_offered_count
            _reward_menu_legendary_spells.open()

func open_trader() -> void:
    if _reward_menu_trader and not _reward_menu_trader.visible:
        _reward_menu_trader.open()

func open_prophecy(pause_state: GameScenePauseState, _pending_open: bool) -> bool:
    if not _prophecy_menu:
        return false
    if _prophecy_menu.visible:
        return false
    if _prophecy_pattern_pool and _prophecy_pattern_pool.has_method("ensure_loaded"):
        _prophecy_pattern_pool.ensure_loaded()
    
    pause_state.apply_prophecy_pause()
    if _waves_manager:
        _waves_manager.set_paused(true)
    
    var lvl: int = 1
    var locked_slots: int = 0
    if _waves_manager and _waves_manager.has_method("get_prophecy_level"):
        lvl = int(_waves_manager.get_prophecy_level())
    if _waves_manager and _waves_manager.has_method("get_locked_prophecy_slot_count"):
        locked_slots = int(_waves_manager.get_locked_prophecy_slot_count())
    
    _prophecy_menu.open(_prophecy_pattern_pool, lvl, locked_slots)
    return true
