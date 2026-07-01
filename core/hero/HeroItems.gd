extends RefCounted
class_name HeroItems

## РЈРїСЂР°РІР»РµРЅРёРµ СЌРєРёРїРёСЂРѕРІРєРѕР№ РіРµСЂРѕРµРІ

var _hero_data: HeroData
var _hero_mutator: HeroMutator

func _init(hero_data: HeroData, mutator: HeroMutator = null) -> void:
    _hero_data = hero_data
    _hero_mutator = mutator

func set_mutator(mutator: HeroMutator) -> void:
    _hero_mutator = mutator

func equip_item_to_hero(hero_id: String, item: Dictionary, slot_name: String) -> bool:
    if not _hero_data.has_hero(hero_id):
        return false
    
    if _hero_mutator:
        return _hero_mutator.equip_item_to_hero(hero_id, item, slot_name)

    # Fallback for direct access (should not be used if mutator is present)
    var hero = _hero_data.get_hero(hero_id)
    if not hero.has("equipment"):
        hero["equipment"] = {
            "weapon": null,
            "armor": null,
            "helmet": null,
            "ring": null
        }
    
    hero["equipment"][slot_name] = item
    _hero_data.update_hero(hero_id, {"equipment": hero["equipment"]})
    print("[HeroItems] Hero %s equipped %s in %s" % [hero_id, item.get("id", "unknown"), slot_name])
    return true

func unequip_item_from_hero(hero_id: String, slot_name: String) -> bool:
    if not _hero_data.has_hero(hero_id):
        return false
    
    if _hero_mutator:
        return _hero_mutator.unequip_item_from_hero(hero_id, slot_name)

    var hero = _hero_data.get_hero(hero_id)
    if not hero.has("equipment") or hero["equipment"].get(slot_name, null) == null:
        return false
    
    hero["equipment"][slot_name] = null
    _hero_data.update_hero(hero_id, {"equipment": hero["equipment"]})
    print("[HeroItems] Hero %s unequipped %s" % [hero_id, slot_name])
    return true

