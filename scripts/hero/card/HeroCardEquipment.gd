extends RefCounted
class_name HeroCardEquipment

## РЈРїСЂР°РІР»РµРЅРёРµ СЌРєРёРїРёСЂРѕРІРєРѕР№
## РЎРѕР·РґР°РЅРёРµ Рё РѕР±РЅРѕРІР»РµРЅРёРµ СЃР»РѕС‚РѕРІ СЌРєРёРїРёСЂРѕРІРєРё

const SLOT_SCENE: PackedScene = preload("res://scenes/ui/inventory/InventorySlot.tscn")

var _equipment_container: GridContainer
var _weapon_slot: InventorySlot
var _armor_slot: InventorySlot
var _helmet_slot: InventorySlot
var _ring_slot: InventorySlot

var _selected_slot_index: int = -1
var _hero_id: String = ""

func initialize(equipment_container: GridContainer) -> void:
    _equipment_container = equipment_container
    setup_equipment_slots()

func setup_equipment_slots() -> void:
    if _equipment_container == null:
        return
    
    # Create slots if container is empty
    # вњ… РўРѕР»СЊРєРѕ 4 СЃР»РѕС‚Р°: РћСЂСѓР¶РёРµ в†’ РЁР»РµРј в†’ Р‘СЂРѕРЅСЏ в†’ РљРѕР»СЊС†Рѕ
    if _equipment_container.get_child_count() == 0:
        _weapon_slot = _create_slot("weapon", 0)
        _helmet_slot = _create_slot("helmet", 1)
        _armor_slot = _create_slot("armor", 2)
        _ring_slot = _create_slot("ring", 3)

func _create_slot(_type: String, _index: int) -> InventorySlot:
    var slot = SLOT_SCENE.instantiate()
    # Increase slot size by 50% for HeroCard equipment (default is 62.5)
    slot.custom_minimum_size = Vector2(94, 94)
    _equipment_container.add_child(slot)
    slot.slot_clicked.connect(_on_slot_clicked)
    slot.slot_double_clicked.connect(_on_slot_double_clicked)
    return slot

func _on_slot_clicked(index: int) -> void:
    if _selected_slot_index == index:
        _try_unequip_slot(index)
        return

    if _selected_slot_index != -1:
        _set_slot_selected(_selected_slot_index, false)

    _selected_slot_index = index
    _set_slot_selected(_selected_slot_index, true)

    print("[HeroCardEquipment] Selected slot: %d" % index)

func _on_slot_double_clicked(index: int) -> void:
    _try_unequip_slot(index)

func _try_unequip_slot(index: int) -> void:
    if _hero_id == "":
        return
    var slot := _get_slot_by_index(index)
    if slot == null or slot.item_data.is_empty():
        _set_slot_selected(index, false)
        _selected_slot_index = -1
        return
    var slot_name := _index_to_slot_name(index)
    if slot_name == "":
        return
    HeroCore.unequip_item_from_hero(_hero_id, slot_name)
    update_equipment(_hero_id)

func _index_to_slot_name(index: int) -> String:
    match index:
        0: return "weapon"
        1: return "helmet"
        2: return "armor"
        3: return "ring"
    return ""

func _set_slot_selected(index: int, selected: bool) -> void:
    var slot = _get_slot_by_index(index)
    if slot:
        slot.set_selected(selected)

func _get_slot_by_index(index: int) -> InventorySlot:
    match index:
        0: return _weapon_slot
        1: return _helmet_slot
        2: return _armor_slot
        3: return _ring_slot
    return null

func update_equipment(hero_id: String) -> void:
    _hero_id = hero_id
    var equipment = HeroCore.query.get_hero_equipment(hero_id)
    if not equipment is Dictionary:
        equipment = {}
    
    # Get equipment items, ensuring they are dictionaries or empty dict
    var weapon_item = equipment.get("weapon", null)
    if weapon_item == null or not weapon_item is Dictionary:
        weapon_item = {}
    
    var armor_item = equipment.get("armor", null)
    if armor_item == null or not armor_item is Dictionary:
        armor_item = {}
    
    var helmet_item = equipment.get("helmet", null)
    if helmet_item == null or not helmet_item is Dictionary:
        helmet_item = {}
    
    var ring_item = equipment.get("ring", null)
    if ring_item == null or not ring_item is Dictionary:
        ring_item = {}
    
    # Setup slots with valid dictionaries and empty icons
    # вњ… РџРѕСЂСЏРґРѕРє: РћСЂСѓР¶РёРµ в†’ РЁР»РµРј в†’ Р‘СЂРѕРЅСЏ в†’ РљРѕР»СЊС†Рѕ
    if _weapon_slot:
        _weapon_slot.setup(0, weapon_item, "res://assets/ui/inventoryheroui/dragonWeaponFrame.png")
    if _helmet_slot:
        _helmet_slot.setup(1, helmet_item, "res://assets/ui/inventoryheroui/dragonHeadFrame.png")
    if _armor_slot:
        _armor_slot.setup(2, armor_item, "res://assets/ui/inventoryheroui/dragonArmirFrame.png")
    if _ring_slot:
        _ring_slot.setup(3, ring_item, "res://assets/ui/inventoryheroui/dragonRingFrame.png")
        
    # Restore selection
    if _selected_slot_index != -1:
        _set_slot_selected(_selected_slot_index, true)
