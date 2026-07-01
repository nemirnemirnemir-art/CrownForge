extends RefCounted
class_name HeroHealth

## Управление здоровьем, зельями и усталостью героев

## Hero Health Module
var _hero_data: HeroData
var _hero_perks: HeroPerks
var _hero_mutator: HeroMutator

func _init(hero_data: HeroData, hero_perks: HeroPerks, mutator: HeroMutator = null) -> void:
    _hero_data = hero_data
    _hero_perks = hero_perks
    _hero_mutator = mutator

func set_mutator(mutator: HeroMutator) -> void:
    _hero_mutator = mutator

func heal_hero(hero_id: String, amount: int) -> int:
    if not _hero_data.has_hero(hero_id):
        return 0
    
    var hero = _hero_data.get_hero(hero_id)
    if hero.get("isDead", false):
        return 0
    
    if _hero_mutator:
        var before_hp := float(hero.get("hp", 0.0))
        var after_hp := float(_hero_mutator.modify_hero_hp(hero_id, float(amount)))
        return int(round(maxf(0.0, after_hp - before_hp)))
    else:
        # Fallback to old direct modification if mutator not available (should not happen after init)
        var current_hp = hero.get("hp", 0.0)
        var max_hp = hero.get("maxHp", 10.0)
        var new_hp = min(current_hp + amount, max_hp)
        hero["hp"] = new_hp
        return int(round(new_hp - current_hp))

func give_potion(hero_id: String) -> bool:
    if not _hero_data.has_hero(hero_id):
        return false
    
    var hero = _hero_data.get_hero(hero_id)
    var current = hero.get("potions_carried", 0)
    var base_max = hero.get("max_potions", 1)
    var mods = _hero_perks.get_perk_modifiers(hero)
    var max_p = base_max + mods["max_potions_bonus"]
    
    if current >= max_p:
        return false
    
    if _hero_mutator:
        _hero_mutator.modify_hero_potions(hero_id, 1)
    else:
        _hero_data.update_hero(hero_id, {"potions_carried": current + 1})
        
    return true

func use_potion(hero_id: String) -> bool:
    if not _hero_data.has_hero(hero_id):
        return false
    
    var hero = _hero_data.get_hero(hero_id)
    
    if hero.get("potions_carried", 0) <= 0:
        return false
    
    # Calculate heal amount (Base 10 + modifiers)
    var heal_amount = 10.0
    var mods = _hero_perks.get_perk_modifiers(hero)
    heal_amount *= (1.0 + mods["potion_heal_bonus"])
    
    if _hero_mutator:
        _hero_mutator.modify_hero_potions(hero_id, -1)
        _hero_mutator.modify_hero_hp(hero_id, float(heal_amount))
        return true
    else:
        _hero_data.update_hero(hero_id, {"potions_carried": hero.get("potions_carried", 0) - 1})
        var actual_heal = heal_hero(hero_id, int(heal_amount))
        return actual_heal > 0
