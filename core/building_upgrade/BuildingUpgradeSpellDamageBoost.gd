extends RefCounted
## BuildingUpgradeSpellDamageBoost
## Spell damage multipliers from building upgrades:
## - paladins_campus:1 -> flat +10% spell damage
## - ram_pasture:1 -> +20% spell damage per Ram on field
## - white_unicorn_field:1 -> +10% spell damage per White Unicorn on field

const BuildingUpgradeUnitCounterScript := preload("res://core/building_upgrade/BuildingUpgradeUnitCounter.gd")

## Paladins Campus: flat +10% spell damage when upgrade is unlocked.
static func get_paladins_spell_damage_multiplier(has_upgrade_func: Callable) -> float:
    if not has_upgrade_func.is_valid():
        return 1.0
    var has_it: bool = has_upgrade_func.call("paladins_campus", "paladins_campus:1")
    if not has_it:
        return 1.0
    return 1.1

## Ram Pasture: +20% spell damage per Ram currently on the battlefield.
static func get_ram_spell_damage_multiplier(has_upgrade_func: Callable) -> float:
    if not has_upgrade_func.is_valid():
        return 1.0
    var has_it: bool = has_upgrade_func.call("ram_pasture", "ram_pasture:1")
    if not has_it:
        return 1.0
    var ram_count: int = BuildingUpgradeUnitCounterScript.count_active_units("ram")
    if ram_count <= 0:
        return 1.0
    return 1.0 + 0.20 * float(ram_count)

## White Unicorn Field: +10% spell damage per White Unicorn on the battlefield.
static func get_unicorn_spell_damage_multiplier(has_upgrade_func: Callable) -> float:
    if not has_upgrade_func.is_valid():
        return 1.0
    var has_it: bool = has_upgrade_func.call("white_unicorn_field", "white_unicorn_field:1")
    if not has_it:
        return 1.0
    var unicorn_count: int = BuildingUpgradeUnitCounterScript.count_active_units("white_unicorn")
    if unicorn_count <= 0:
        return 1.0
    return 1.0 + 0.10 * float(unicorn_count)
