extends RefCounted
## BuildingUpgradeLionCircus
## Lion Circus Versatility (lion_circus:0):
## - Griffin takes the BEST single bonus from ALL classes (highest HP mult, highest damage mult)
##   instead of only using CHAMPION+FLYING class bonuses.
## - Production cost +100% (multiplier 2.0).
##
## Normal behavior: Griffin (CHAMPION+FLYING) gets sum of CHAMPION+FLYING bonuses.
## Versatility: Griffin gets the SINGLE BEST class bonus (highest individual) for each stat.
## This means it picks max(GRUNT, WARRIOR, RANGED, RIDER, CHAMPION, FLYING, ARCANE, UNDEAD)
## for HP and separately for DAMAGE, instead of summing CHAMPION+FLYING.

## Returns the cost multiplier for lion_circus production when the upgrade is active.
## 2.0 means double cost (+100%).
static func get_production_cost_multiplier(has_upgrade_func: Callable) -> float:
    if not has_upgrade_func.is_valid():
        return 1.0
    var has_it: bool = has_upgrade_func.call("lion_circus", "lion_circus:0")
    if not has_it:
        return 1.0
    return 2.0

## Returns whether the Versatility upgrade is active for lion_circus.
static func is_versatility_active(has_upgrade_func: Callable) -> bool:
    if not has_upgrade_func.is_valid():
        return false
    return has_upgrade_func.call("lion_circus", "lion_circus:0")

## Calculate the HP multiplier for griffin under Versatility.
## Instead of summing CHAMPION+FLYING HP bonuses, takes the single highest
## class HP bonus across ALL 8 classes.
## troop_core: TroopBonusCore autoload object
## Returns the HP multiplier (1.0 + best_single_class_bonus).
static func get_versatility_hp_multiplier(troop_core: Object) -> float:
    if troop_core == null or not troop_core.has_method("get_bonus_percent"):
        return 1.0
    var best: float = 0.0
    # Check all 8 UnitClass values (0..7)
    for class_idx: int in range(8):
        var bonus: float = float(troop_core.call("get_bonus_percent", class_idx, 0))  # 0 = HP stat
        if bonus > best:
            best = bonus
    return 1.0 + best

## Calculate the DAMAGE multiplier for griffin under Versatility.
## Takes the single highest class DAMAGE bonus across ALL 8 classes.
## troop_core: TroopBonusCore autoload object
## Returns the DAMAGE multiplier (1.0 + best_single_class_bonus).
static func get_versatility_damage_multiplier(troop_core: Object) -> float:
    if troop_core == null or not troop_core.has_method("get_bonus_percent"):
        return 1.0
    var best: float = 0.0
    # Check all 8 UnitClass values (0..7)
    for class_idx: int in range(8):
        var bonus: float = float(troop_core.call("get_bonus_percent", class_idx, 1))  # 1 = DAMAGE stat
        if bonus > best:
            best = bonus
    return 1.0 + best

## Calculate the ATTACK_SPEED multiplier for griffin under Versatility.
## Takes the single highest class ATTACK_SPEED bonus across ALL 8 classes.
static func get_versatility_attack_speed_multiplier(troop_core: Object) -> float:
    if troop_core == null or not troop_core.has_method("get_bonus_percent"):
        return 1.0
    var best: float = 0.0
    for class_idx: int in range(8):
        var bonus: float = float(troop_core.call("get_bonus_percent", class_idx, 2))  # 2 = ATTACK_SPEED stat
        if bonus > best:
            best = bonus
    return 1.0 + best
