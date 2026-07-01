extends Node
## ForgeCore handles item destruction → forge cores and crafting from cores.
## Orchestrates ForgeCraftingSlots and ForgeItemGenerator; public API is thin wrappers.

const ForgeCraftingSlotsScript := preload("res://core/forge_crafting_slots.gd")
const ForgeItemGeneratorScript := preload("res://core/forge_item_generator.gd")

@warning_ignore("UNUSED_SIGNAL")
signal forge_cores_gained(amount: int)
@warning_ignore("UNUSED_SIGNAL")
signal item_forged(item: Dictionary)

const FORGE_BUILDING_ID: String = "forge"
const RARITY_COSTS := {
    ItemSystem.Rarity.COMMON: 10,
    ItemSystem.Rarity.NORMAL: 20,
    ItemSystem.Rarity.EPIC: 40,
    ItemSystem.Rarity.LEGENDARY: 80,
    ItemSystem.Rarity.COSMIC: 150,
    ItemSystem.Rarity.GOD: 300
}
const MIN_CORE_GAIN: int = 1
const CRAFT_ID_PREFIX: String = "forge_craft_"
const CRAFT_DURATION_SEC: float = 900.0 # 15 minutes
const MAX_CRAFT_SLOTS: int = 6

@warning_ignore("UNUSED_SIGNAL")
signal crafting_started(slot_index: int, time_left: float)
@warning_ignore("UNUSED_SIGNAL")
signal crafting_completed(slot_index: int, item: Dictionary)
@warning_ignore("UNUSED_SIGNAL")
signal crafting_claimed(slot_index: int)
@warning_ignore("UNUSED_SIGNAL")
signal crafting_tick(slot_index: int, time_left: float)

var _slots
var _item_gen

func _ready() -> void:
    print("[ForgeCore] Ready.")
    _slots = ForgeCraftingSlotsScript.new()
    _item_gen = ForgeItemGeneratorScript.new()
    _slots.init(self)
    _item_gen.init(self, _slots)
    _slots.crafting_started.connect(func(si, tl): emit_signal("crafting_started", si, tl))
    _slots.crafting_completed.connect(func(si, item): emit_signal("crafting_completed", si, item))
    _slots.crafting_claimed.connect(func(si): emit_signal("crafting_claimed", si))
    _slots.crafting_tick.connect(func(si, tl): emit_signal("crafting_tick", si, tl))

func _process(delta: float) -> void:
    _slots.tick(delta)

# === Public API — thin wrappers ===

func start_crafting(item_type: ItemSystem.ItemType, rarity: ItemSystem.Rarity) -> int:
    return _slots.start_crafting(item_type, rarity)

func claim_item(slot_index: int) -> bool:
    return _slots.claim_item(slot_index)

func reset() -> void:
    _slots.reset()

func get_slot_info(slot_index: int) -> Dictionary:
    return _slots.get_slot_info(slot_index)

func start_random_rarity_crafting(item_type: ItemSystem.ItemType) -> int:
    return _item_gen.start_random_rarity_crafting(item_type)

func get_rarity_chances() -> Dictionary:
    return _item_gen.get_rarity_chances()

func calculate_rarity_chances(forge_level: int) -> Dictionary:
    return _item_gen.calculate_rarity_chances(forge_level)

func destroy_item(index: int) -> bool:
    if not is_instance_valid(PlayerInventory):
        print("[ForgeCore] PlayerInventory not available.")
        return false
    var items = PlayerInventory.get_items()
    if index < 0 or index >= items.size():
        return false
    var item = items[index]
    var cores = _calculate_core_gain(item)
    PlayerInventory.remove_item_at_index(index)
    EconomyCore.add_forge_cores(cores)
    emit_signal("forge_cores_gained", cores)
    print("[ForgeCore] Destroyed %s for %d forge cores." % [item.id, cores])
    return true

func _calculate_core_gain(item: Dictionary) -> int:
    var power = int(item.get("power", 0))
    var level = _forge_level()
    var data = _forge_data()
    var multiplier = 1.0
    if data:
        multiplier += float(data.forge_core_gain_per_level * level) * 0.02
    var base = max(MIN_CORE_GAIN, int(power * 0.25))
    return int(max(MIN_CORE_GAIN, base * multiplier))

func _get_craft_cost(rarity: ItemSystem.Rarity) -> int:
    var base_cost = RARITY_COSTS.get(rarity, 20)
    var data = _forge_data()
    var reduction = 0.0
    var level = _forge_level()
    if data:
        reduction = data.forge_crafting_cost_reduction_per_level * level
    var discount = clamp(1.0 - reduction, 0.4, 1.0)
    return int(max(1, base_cost * discount))

func get_craft_cost(rarity: ItemSystem.Rarity) -> int:
    return _get_craft_cost(rarity)

func _forge_level() -> int:
    if TownCore:
        return TownCore.get_building_level(FORGE_BUILDING_ID)
    return 0

func _forge_data() -> BuildingData:
    if TownCore:
        return TownCore.get_building_config(FORGE_BUILDING_ID)
    return null

## === SAVE/LOAD ===
func get_save_data() -> Dictionary:
    return {
        "crafting_slots": _slots.crafting_slots
    }

func load_save_data(data: Dictionary) -> void:
    if data.has("crafting_slots"):
        _slots.crafting_slots = data["crafting_slots"].duplicate()
    for i in range(MAX_CRAFT_SLOTS):
        if not _slots.crafting_slots.has(i):
            _slots.crafting_slots[i] = null
