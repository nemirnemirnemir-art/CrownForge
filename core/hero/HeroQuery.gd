extends RefCounted
class_name HeroQuery

## Hero data access (Read-Only)
## Provide safe access to hero data without allowing modification

var _hero_data: HeroData

func _init(hero_data: HeroData) -> void:
    _hero_data = hero_data

## Returns all hero IDs
func get_all_hero_ids() -> Array:
    return _hero_data.heroes.keys()

## Checks if a hero exists
func has_hero(hero_id: String) -> bool:
    if _hero_data == null:
        return false
    return _hero_data.heroes.has(hero_id)

## Returns hero dictionary or empty
func get_hero(hero_id: String) -> Dictionary:
    if not has_hero(hero_id):
        return {}
    return _hero_data.get_hero(hero_id)

## Returns current HP (safe)
func get_hero_hp(hero_id: String) -> float:
    var hero = get_hero(hero_id)
    return hero.get("hp", 0.0)

## Returns max HP (safe)
func get_hero_max_hp(hero_id: String) -> float:
    var hero = get_hero(hero_id)
    return hero.get("maxHp", 10.0)

## Returns damage (safe)
func get_hero_damage(hero_id: String) -> float:
    var hero = get_hero(hero_id)
    return hero.get("damage", 1.0)

## Returns level (safe)
func get_hero_level(hero_id: String) -> int:
    var hero = get_hero(hero_id)
    return hero.get("level", 1)

## Returns XP (safe)
func get_hero_xp(hero_id: String) -> int:
    var hero = get_hero(hero_id)
    return hero.get("xp", 0)

## Returns XP needed for next level (safe)
func get_hero_xp_to_next(hero_id: String) -> int:
    var level = get_hero_level(hero_id)
    return level * 10 # Assuming simple formula for now

## Returns hero mood (safe)
func get_hero_mood(hero_id: String) -> float:
    var hero = get_hero(hero_id)
    return hero.get("mood", 50.0)

## Returns hero name (safe)
func get_hero_name(hero_id: String) -> String:
    var hero = get_hero(hero_id)
    return hero.get("name", "Unknown")

## Returns hero icon ID (safe)
func get_hero_icon_id(hero_id: String) -> String:
    var hero = get_hero(hero_id)
    return hero.get("icon_id", "")

## Checks if hero is dead
func is_hero_dead(hero_id: String) -> bool:
    var hero = get_hero(hero_id)
    return hero.get("isDead", false) or hero.get("hp", 0) <= 0

## Checks if hero is hired
func is_hero_hired(hero_id: String) -> bool:
    var hero = get_hero(hero_id)
    return hero.get("is_hired", false)

## Checks if hero is in active squad
func is_hero_in_squad(hero_id: String) -> bool:
    var hero = get_hero(hero_id)
    return hero.get("isActive", false)

## Returns hero cost (safe)
func get_hero_cost(hero_id: String) -> float:
    var hero = get_hero(hero_id)
    return hero.get("cost", 0.0)

## Returns hero perks list (safe)
func get_hero_perks(hero_id: String) -> Array:
    var hero = get_hero(hero_id)
    return hero.get("perks", [])

## Returns hero equipment dict (safe)
func get_hero_equipment(hero_id: String) -> Dictionary:
    var hero = get_hero(hero_id)
    return hero.get("equipment", {})

## Returns hero potions count (safe)
func get_hero_potions_count(hero_id: String) -> int:
    var hero = get_hero(hero_id)
    return hero.get("potions_carried", 0)

## Returns hero max potions (safe)
func get_hero_max_potions(hero_id: String) -> int:
    var hero = get_hero(hero_id)
    return hero.get("max_potions", 1)
