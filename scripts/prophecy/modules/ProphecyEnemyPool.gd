extends RefCounted
class_name ProphecyEnemyPool

## Handles logic for selecting enemies for prophecy patterns

var _power_by_mob_id: Dictionary = {}

const RANGED_IDS: Dictionary = {
    "goblin_crossbowman": true,
    "goblin_fire_mage": true,
    "goblin_lightning_mage": true,
    "goblin_shaman": true,
}

const SLUG_IDS: Dictionary = {
    "blue_slug": true,
    "green_slug": true,
}

func setup(powers: Dictionary) -> void:
    _power_by_mob_id = powers

func get_power(mob_id: String) -> float:
    var k := mob_id.to_lower()
    if _power_by_mob_id.has(k):
        return float(_power_by_mob_id[k])
    return 0.0

func is_ranged(mob_id: String) -> bool:
    return RANGED_IDS.has(mob_id.to_lower())

func is_slug(mob_id: String) -> bool:
    return SLUG_IDS.has(mob_id.to_lower())

func has_slug_pool(prophecy_level: int) -> bool:
    return clamp(prophecy_level, 1, 7) >= 6

func build_slug_pool(prophecy_level: int) -> Array[String]:
    var lvl: int = clamp(prophecy_level, 1, 7)
    var pool: Array[String] = []
    if lvl >= 6:
        pool.append("green_slug")
    if lvl >= 7:
        pool.append("blue_slug")
    return pool

func build_swarm_pool(prophecy_level: int) -> Array[String]:
    var src_level: int = max(1, prophecy_level - 2)
    var base := build_mob_pool(src_level)
    var out: Array[String] = []
    for id in base:
        var mid := String(id)
        if mid == "": continue
        if is_slug(mid): continue
        if is_ranged(mid): continue
        if get_power(mid) > 100.0: continue
        out.append(mid)
    return out

func build_mob_pool(prophecy_level: int) -> Array[String]:
    var lvl: int = clamp(prophecy_level, 1, 7)
    var pool: Array[String] = []
    
    pool.append("goblin_bandit")
    pool.append("goblin_crossbowman")
    pool.append("goblin_swordsman")
    pool.append("goblin_giant")
    pool.append("goblin_shaman")
    
    if lvl >= 2:
        pool.append("goblin_pig")
        pool.append("goblin_lightning_mage")
    if lvl >= 3:
        pool.append("goblin_fire_mage")
        pool.append("goblin_lizard")
    if lvl >= 4:
        pool.append("goblin_bat_rider")
        pool.append("sunfaced")
    if lvl >= 5:
        pool.append("stone_golem")
        pool.append("blue_slime")
        pool.append("wall_buster")
    if lvl >= 6:
        pool.append("mechanical_mammoth")
        pool.append("mechanical_bat")
        pool.append("green_slug")
    if lvl >= 7:
        pool.append("blue_slug")
        pool.append("show_golem")
        pool.append("sand_golem")
    
    pool = _apply_level_bans(pool, lvl)
    return pool

func _apply_level_bans(pool: Array[String], prophecy_level: int) -> Array[String]:
    var banned := {}
    if prophecy_level >= 5:
        banned["goblin_bandit"] = true
    if prophecy_level >= 6:
        banned["goblin_swordsman"] = true
        banned["wall_buster"] = true
    if prophecy_level >= 7:
        banned["goblin_shaman"] = true
        banned.erase("wall_buster")
    
    var out: Array[String] = []
    for id in pool:
        var mid := String(id).to_lower()
        if banned.has(mid):
            continue
        out.append(mid)
    return out
