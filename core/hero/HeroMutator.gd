extends RefCounted
class_name HeroMutator

## Safe hero data mutation module (Setter API)
## Responsible for modifying hero state and notifying the system about changes.
## All changes to HP, statuses, equipment must go through this class.

var _hero_data: HeroData
var _hero_core: Node # Reference to HeroCore used to emit signals

func _init(hero_data: HeroData, hero_core: Node) -> void:
    _hero_data = hero_data
    _hero_core = hero_core

# === HEALTH & STATUS ===

## Modify current hero health
## @param hero_id: Hero ID
## @param delta: Health delta (positive = heal, negative = damage)
## @return: New HP value
func modify_hero_hp(hero_id: String, delta: float) -> float:
    if not _hero_data.has_hero(hero_id):
        return 0.0
    
    var hero = _hero_data.get_hero(hero_id)
    var current_hp = hero.get("hp", 0.0)
    var max_hp = hero.get("maxHp", 10.0)
    if _hero_core and _hero_core.has_method("get_hero_total_stats"):
        var total_stats: Dictionary = _hero_core.get_hero_total_stats(hero_id)
        if total_stats is Dictionary and total_stats.has("maxHp"):
            max_hp = float(total_stats.get("maxHp", max_hp))
    
    var new_hp = clamp(current_hp + delta, 0.0, max_hp)
    
    if new_hp != current_hp:
        hero["hp"] = new_hp
        _emit_update(hero_id)
        
        # Specialized signals
        if delta < 0:
            # Damage
            pass 
        elif delta > 0:
            # Healing
            if _hero_core.has_signal("hero_healed"):
                _hero_core.emit_signal("hero_healed", hero_id, int(delta))
        
        # Death check
        if new_hp <= 0 and current_hp > 0:
            _handle_death(hero_id)
            
    return new_hp

## Set hired status
func set_hero_hired(hero_id: String, is_hired: bool) -> void:
    if not _hero_data.has_hero(hero_id):
        return
        
    var hero = _hero_data.get_hero(hero_id)
    if hero.get("is_hired", false) != is_hired:
        hero["is_hired"] = is_hired
        _emit_update(hero_id)
        
        if is_hired and _hero_core.has_signal("hero_created"):
            # Compatibility: legacy code listens for hero_created on hiring
            _hero_core.emit_signal("hero_created", hero_id, hero)

# === INTERNAL HELPERS ===

func _emit_update(hero_id: String) -> void:
    if _hero_core.has_signal("hero_updated"):
        var hero = _hero_data.get_hero(hero_id)
        _hero_core.emit_signal("hero_updated", hero_id, hero)
        
    if _hero_core.has_signal("hero_hp_changed"):
        var hero = _hero_data.get_hero(hero_id)
        _hero_core.emit_signal("hero_hp_changed", hero_id, hero.get("hp", 0.0), hero.get("maxHp", 10.0))

func _handle_death(hero_id: String) -> void:
    _hero_data.mark_hero_dead(hero_id)
    
    if _hero_core.has_signal("hero_died"):
        _hero_core.emit_signal("hero_died", hero_id)
    
    # Delegate removal to HeroCore (complex logic with TownCore/Battle)
    if _hero_core.has_method("remove_hero"):
        _hero_core.remove_hero(hero_id)

# === PROGRESSION ===

## Add XP to hero
## @return: true if level increased
func add_hero_xp(hero_id: String, amount: int) -> bool:
    if not _hero_data.has_hero(hero_id):
        return false
        
    var hero = _hero_data.get_hero(hero_id)
    var current_xp = hero.get("xp", 0)
    
    var new_xp = current_xp + amount
    hero["xp"] = new_xp
    
    _emit_update(hero_id)
    return false

## Set hero level
func set_hero_level(hero_id: String, new_level: int) -> void:
    if not _hero_data.has_hero(hero_id):
        return
        
    var hero = _hero_data.get_hero(hero_id)
    if hero.get("level", 1) != new_level:
        hero["level"] = new_level
        _emit_update(hero_id)

## Upgrade hero stats (typically on level up)
func upgrade_hero_stats(hero_id: String, hp_increase: float, damage_increase: float, full_heal: bool = true) -> void:
    if not _hero_data.has_hero(hero_id):
        return
        
    var hero = _hero_data.get_hero(hero_id)
    
    var current_max_hp = hero.get("maxHp", 10.0)
    var new_max_hp = current_max_hp + hp_increase
    hero["maxHp"] = new_max_hp
    
    if full_heal:
        var healed_hp: float = new_max_hp
        if _hero_core and _hero_core.has_method("get_hero_total_stats"):
            var total_stats: Dictionary = _hero_core.get_hero_total_stats(hero_id)
            if total_stats is Dictionary and total_stats.has("maxHp"):
                healed_hp = float(total_stats.get("maxHp", healed_hp))
        hero["hp"] = healed_hp
        
    var current_damage = hero.get("damage", 1.0)
    hero["damage"] = current_damage + damage_increase
    
    _emit_update(hero_id)

# === ITEMS & POTIONS ===

## Modify potion count
func modify_hero_potions(hero_id: String, delta: int) -> int:
    if not _hero_data.has_hero(hero_id):
        return 0
        
    var hero = _hero_data.get_hero(hero_id)
    var current = hero.get("potions_carried", 0)
    var new_val = max(0, current + delta)
    
    if current != new_val:
        hero["potions_carried"] = new_val
        _emit_update(hero_id)
        
    return new_val

# === EQUIPMENT ===

func equip_item_to_hero(hero_id: String, item: Dictionary, slot_name: String) -> bool:
    if not _hero_data.has_hero(hero_id):
        return false
    
    var hero = _hero_data.get_hero(hero_id)
    if not hero.has("equipment"):
        hero["equipment"] = {
            "weapon": null,
            "armor": null,
            "helmet": null,
            "ring": null
        }
    
    hero["equipment"][slot_name] = item
    _emit_update(hero_id)
    
    var hp_bonus: int = item.get("hp_bonus", 0)
    if hp_bonus > 0:
        modify_hero_hp(hero_id, float(hp_bonus))
    
    return true

func unequip_item_from_hero(hero_id: String, slot_name: String) -> bool:
    if not _hero_data.has_hero(hero_id):
        return false
    
    var hero = _hero_data.get_hero(hero_id)
    if not hero.has("equipment"):
        return false
    
    if hero["equipment"].get(slot_name, null) == null:
        return false
    
    hero["equipment"][slot_name] = null
    
    var max_hp: float = hero.get("maxHp", 10.0)
    if _hero_core and _hero_core.has_method("get_hero_total_stats"):
        var total_stats: Dictionary = _hero_core.get_hero_total_stats(hero_id)
        if total_stats is Dictionary and total_stats.has("maxHp"):
            max_hp = float(total_stats.get("maxHp", max_hp))
    
    var current_hp: float = hero.get("hp", 0.0)
    if current_hp > max_hp:
        hero["hp"] = max_hp
    
    _emit_update(hero_id)
    return true

# === PERKS ===

func add_perk_to_hero(hero_id: String, perk_id: String) -> bool:
    if not _hero_data.has_hero(hero_id):
        return false
        
    var hero = _hero_data.get_hero(hero_id)
    if not hero.has("perks"):
        hero["perks"] = []
    
    if perk_id in hero["perks"]:
        return false
        
    hero["perks"].append(perk_id)
    _emit_update(hero_id)
    return true
