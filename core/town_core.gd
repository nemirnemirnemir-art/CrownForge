extends Node
## TownCore - Autoload singleton for Town System
## Controller coordinating all Town modules

const API_VERSION := 1
const TownBuildFlowScript := preload("res://core/town/TownBuildFlow.gd")
const TownUpgradeFlowScript := preload("res://core/town/TownUpgradeFlow.gd")
const TownAlchemyFlowScript := preload("res://core/town/TownAlchemyFlow.gd")
const TownMageTowerFlowScript := preload("res://core/town/TownMageTowerFlow.gd")
const TownShopFlowScript := preload("res://core/town/TownShopFlow.gd")
const TownSaveFlowScript := preload("res://core/town/TownSaveFlow.gd")

const TOWNHALL_BOTTLE_BASE_PRICE: int = 500
const TOWNHALL_BOTTLE_PRICE_INCREASE: int = 500
const TOWNHALL_BOTTLE_DECAY_PER_MIN: int = 60
const TOWNHALL_BOTTLE_MIN_PRICE: int = 500

const MAGE_TOWER_UPGRADE_BASE_PRICE: float = 500.0
const MAGE_TOWER_UPGRADE_GROWTH: float = 1.12
const MAGE_TOWER_UPGRADE_MAX_LEVEL: int = 50

const MAGE_TOWER_SKILL_PRICES: Array[int] = [500, 1200, 2880, 6912, 16589, 39814, 95552, 229324, 550377, 1320904]

## Modules are globally accessible via class_name

## Signals
signal building_upgraded(building_id: String, new_level: int)
signal potion_produced(current_potions: int)
signal hero_assigned_potion(hero_id: String, current_potions: int)

## Module instances
var _buildings: TownBuildings
var _potions: TownPotions
var _production: TownProduction
var _perks: TownPerks
var _hospital: TownHospital
var _bonuses: TownBonuses
var _inventory: TownInventory

var _alchemy_craft: TownAlchemyCraft

var _shop: TownShop

var _mage_tower: TownMageTower

var _build_config: BuildConfig
var _build_flow = null
var _upgrade_flow = null
var _alchemy_flow = null
var _shop_flow = null
var _mage_tower_flow = null
var _save_flow = null

func _ready() -> void:
    _initialize_modules()
    _potions.potion_produced.connect(_on_potion_produced)
    _potions.hero_assigned_potion.connect(_on_hero_assigned_potion)

func _initialize_modules() -> void:
    _buildings = TownBuildings.new()
    _buildings.initialize()
    
    _potions = TownPotions.new()
    _potions.initialize(_buildings)
    
    _production = TownProduction.new()
    _production.initialize(_buildings)
    
    _perks = TownPerks.new()
    _perks.initialize(_buildings)
    
    _hospital = TownHospital.new()
    _hospital.initialize(_buildings)
    
    _bonuses = TownBonuses.new()
    _bonuses.initialize(_buildings)
    
    _inventory = TownInventory.new()
    _inventory.initialize()

    _alchemy_craft = TownAlchemyCraft.new()
    _alchemy_craft.initialize(_inventory, _buildings)

    _shop = TownShop.new()
    _shop.initialize(_inventory)

    _mage_tower = TownMageTower.new()
    _mage_tower.initialize(_buildings)

    _build_config = load("res://data/build_config.tres") as BuildConfig
    _build_flow = TownBuildFlowScript.new()
    _upgrade_flow = TownUpgradeFlowScript.new()
    _alchemy_flow = TownAlchemyFlowScript.new()
    _shop_flow = TownShopFlowScript.new()
    _mage_tower_flow = TownMageTowerFlowScript.new()
    _save_flow = TownSaveFlowScript.new()
    
    # Initialize default buildings if empty
    if _buildings.get_buildings().is_empty():
        _buildings._init_default_buildings()
    
    # print("[TownCore] ✅ All modules initialized")

func _process(delta: float) -> void:
    var scaled_delta := TickManager.get_scaled_delta(delta) if TickManager else delta
    _production.process_passive_gold(scaled_delta)
    _production.process_passive_damage(scaled_delta)
    _potions.process_potions(scaled_delta)
    _hospital.process_hospital(scaled_delta)

## === PUBLIC API ===

# Buildings
func get_all_building_ids() -> Array:
    return _buildings.get_all_building_ids()

func remove_building(_slot_index: int) -> void:
    # Logic for removing building from slot-based persistence (if added later)
    # For now, we just ensure the call doesn't crash.
    # print("[TownCore] Building removed from slot %d" % _slot_index)
    pass

func get_building_config(building_id: String) -> BuildingData:
    return _buildings.get_building_config(building_id)

func get_building_level(building_id: String) -> int:
    return _buildings.get_building_level(building_id)

func get_building_upgrade_cost(building_id: String) -> int:
    return _buildings.get_building_upgrade_cost(building_id)

func get_building_built_count(building_id: String) -> int:
    return _buildings.get_building_built_count(building_id)

func get_building_slot_state(building_id: String, slot_index: int) -> Dictionary:
    return _build_flow.get_building_slot_state(_buildings, building_id, slot_index) if _build_flow else {}

func set_building_slot_state(building_id: String, slot_index: int, state: Dictionary, request_save: bool = false) -> void:
    if _build_flow:
        _build_flow.set_building_slot_state(_buildings, SaveCore, building_id, slot_index, state, request_save)

func clear_building_slot_state(building_id: String, slot_index: int, request_save: bool = false) -> void:
    if _build_flow:
        _build_flow.clear_building_slot_state(_buildings, SaveCore, building_id, slot_index, request_save)

func get_building_provides(building_id: String) -> Dictionary:
    return _build_flow.get_building_provides(_build_config, building_id) if _build_flow else {}

func get_next_build_cost(building_id: String) -> Dictionary:
    return _build_flow.get_next_build_cost(BuildingRegistry, _buildings, _build_config, building_id) if _build_flow else {}

func can_build(building_id: String) -> bool:
    return _build_flow.can_build(ResourceCore, BuildingRegistry, _buildings, _build_config, building_id) if _build_flow else false

func try_pay_build_cost(building_id: String) -> bool:
    return _build_flow.try_pay_build_cost(_buildings, ResourceCore, BuildingRegistry, _build_config, building_id) if _build_flow else false

func try_upgrade_building(building_id: String) -> bool:
    return _upgrade_flow.try_upgrade_building(
        _buildings,
        _bonuses,
        _perks,
        building_id,
        building_upgraded.emit
    ) if _upgrade_flow else false

func debug_set_building_level(building_id: String, target_level: int) -> bool:
    return _upgrade_flow.debug_set_building_level(
        _buildings,
        _bonuses,
        _perks,
        building_id,
        target_level,
        building_upgraded.emit,
        SaveCore
    ) if _upgrade_flow else false

func debug_unlock_all_mage_tower_skills() -> void:
    if _mage_tower_flow:
        _mage_tower_flow.debug_unlock_all_mage_tower_skills(_mage_tower)

## === Mage Tower Upgrades (Skills + Mana) ===

func get_mage_tower_skill_unlock_level(skill_index: int) -> int:
    return _mage_tower_flow.get_mage_tower_skill_unlock_level(_mage_tower, skill_index) if _mage_tower_flow else max(1, skill_index) * 5

func is_mage_tower_skill_unlocked(skill_index: int) -> bool:
    return _mage_tower_flow.is_mage_tower_skill_unlocked(_mage_tower, skill_index) if _mage_tower_flow else false

func is_mage_tower_skill_purchased(skill_index: int) -> bool:
    return _mage_tower_flow.is_mage_tower_skill_purchased(_mage_tower, skill_index) if _mage_tower_flow else false

func get_mage_tower_skill_price(skill_index: int) -> int:
    return _mage_tower_flow.get_mage_tower_skill_price(_mage_tower, skill_index) if _mage_tower_flow else 0

func try_purchase_mage_tower_skill(skill_index: int) -> bool:
    return _mage_tower_flow.try_purchase_mage_tower_skill(_mage_tower, skill_index) if _mage_tower_flow else false

# Potions
func get_global_potions() -> int:
    return _potions.get_global_potions()

func add_potions(amount: int) -> void:
    _potions.add_potions(amount)

func assign_potion_to_hero(hero_id: String) -> bool:
    return _potions.assign_potion_to_hero(hero_id)

# Production
func get_passive_gold_production() -> float:
    return _production.get_passive_gold_production()

func get_passive_damage() -> float:
    return _production.get_passive_damage()

func get_building_gold_production(building_id: String) -> float:
    return _production.get_building_gold_production(building_id)

# Perks
func get_unlocked_perks() -> Array:
    return _perks.get_unlocked_perks()

func is_perk_unlocked(perk_id: String) -> bool:
    return _perks.is_perk_unlocked(perk_id)

func get_available_perks() -> Array:
    return _perks.get_available_perks()

func purchase_perk(perk_id: String, cost: float = 0.0) -> bool:
    return _perks.purchase_perk(perk_id, cost)

# Bonuses
func get_global_defense_bonus() -> int:
    return _bonuses.get_global_defense_bonus()

func get_global_damage_bonus() -> float:
    return _bonuses.get_global_damage_bonus()

func get_global_xp_bonus() -> float:
    return _bonuses.get_global_xp_bonus()

func get_click_damage_bonus() -> float:
    return _bonuses.get_click_damage_bonus()

# Inventory
func get_town_inventory() -> TownInventory:
    return _inventory

func _alchemy_update_and_autosave() -> void:
    if _alchemy_flow:
        _alchemy_flow.update_and_autosave(_alchemy_craft, SaveCore)

func get_alchemy_potion_defs() -> Dictionary:
    return _alchemy_flow.get_alchemy_potion_defs(_alchemy_craft) if _alchemy_flow else {}

func get_alchemy_queue() -> Array[Dictionary]:
    return _alchemy_flow.get_alchemy_queue(_alchemy_craft, SaveCore) if _alchemy_flow else []

func get_alchemy_active_remaining_sec() -> int:
    return _alchemy_flow.get_alchemy_active_remaining_sec(_alchemy_craft, SaveCore) if _alchemy_flow else 0

func try_enqueue_alchemy(potion_id: String) -> bool:
    return _alchemy_flow.try_enqueue_alchemy(_alchemy_craft, SaveCore, potion_id) if _alchemy_flow else false

func try_cancel_alchemy(index: int) -> bool:
    return _alchemy_flow.try_cancel_alchemy(_alchemy_craft, SaveCore, index) if _alchemy_flow else false

func get_townhall_hollow_bottle_price() -> int:
    return _shop_flow.get_townhall_hollow_bottle_price(_shop, TOWNHALL_BOTTLE_BASE_PRICE) if _shop_flow else TOWNHALL_BOTTLE_BASE_PRICE

func try_buy_townhall_hollow_bottle() -> bool:
    return _shop_flow.try_buy_townhall_hollow_bottle(_shop) if _shop_flow else false

## === SIGNAL HANDLERS ===

func _on_potion_produced(current_potions: int) -> void:
    potion_produced.emit(current_potions)

func _on_hero_assigned_potion(hero_id: String, current_potions: int) -> void:
    hero_assigned_potion.emit(hero_id, current_potions)

## === RESET ===

func reset() -> void:
    if _save_flow:
        _save_flow.reset(
            _buildings,
            _potions,
            _perks,
            _inventory,
            _shop,
            _alchemy_craft,
            _mage_tower,
            _hospital,
            _bonuses
        )

## === SAVE/LOAD ===

func get_save_data() -> Dictionary:
    return _save_flow.get_save_data(_buildings, _potions, _perks, _inventory, _shop, _alchemy_craft, _mage_tower) if _save_flow else {}

func load_save_data(data: Dictionary) -> void:
    if _save_flow:
        _save_flow.load_save_data(data, _buildings, _potions, _perks, _inventory, _shop, _alchemy_craft, _mage_tower, _bonuses)
