extends RefCounted
## BuildingUpgradeUnitAura
## Unit-count-dependent auras from building upgrades:
## - black_unicorn_field:1 -> +5 morale per Black Unicorn on field
## - hydra_pond:2 -> +10% damage per Hydra on field, capped at 50%
## - minotaur_camp:1 -> +3% damage to Flying troops per Minotaur on field, capped at 30%
## - falcons_camp:0 -> +100% HP to all Grunt troops if at least 1 Black Swordsman on field

const BuildingUpgradeUnitCounterScript := preload("res://core/building_upgrade/BuildingUpgradeUnitCounter.gd")

## Black Unicorn morale: +5 per Black Unicorn on the battlefield.
## Returns an integer morale bonus.
static func get_black_unicorn_morale_bonus(has_upgrade_func: Callable) -> int:
    if not has_upgrade_func.is_valid():
        return 0
    var has_it: bool = has_upgrade_func.call("black_unicorn_field", "black_unicorn_field:1")
    if not has_it:
        return 0
    var count: int = BuildingUpgradeUnitCounterScript.count_active_units("black_unicorn")
    return count * 5

## Hydra global damage aura: +10% damage per Hydra on the field, capped at +50%.
## Returns a damage multiplier (1.0 = no bonus).
static func get_hydra_global_damage_multiplier(has_upgrade_func: Callable) -> float:
    if not has_upgrade_func.is_valid():
        return 1.0
    var has_it: bool = has_upgrade_func.call("hydra_pond", "hydra_pond:2")
    if not has_it:
        return 1.0
    var hydra_count: int = BuildingUpgradeUnitCounterScript.count_active_units("hydra")
    if hydra_count <= 0:
        return 1.0
    var bonus: float = minf(0.10 * float(hydra_count), 0.50)
    return 1.0 + bonus

## Minotaur Flying buff: +3% damage to Flying troops per Minotaur on the field, capped at 30%.
## Returns a damage multiplier for Flying-class units only (1.0 = no bonus).
static func get_minotaur_flying_damage_multiplier(has_upgrade_func: Callable) -> float:
    if not has_upgrade_func.is_valid():
        return 1.0
    var has_it: bool = has_upgrade_func.call("minotaur_camp", "minotaur_camp:1")
    if not has_it:
        return 1.0
    var minotaur_count: int = BuildingUpgradeUnitCounterScript.count_active_units("minotaur")
    if minotaur_count <= 0:
        return 1.0
    var bonus: float = minf(0.03 * float(minotaur_count), 0.30)
    return 1.0 + bonus

## Falcon Mentoring: +100% HP to all Grunt troops when at least 1 Black Swordsman is on the field.
## Returns HP multiplier (2.0 if active, 1.0 otherwise). This is DYNAMIC — recalculated each stat query.
static func get_falcon_mentoring_hp_multiplier(has_upgrade_func: Callable) -> float:
    if not has_upgrade_func.is_valid():
        return 1.0
    var has_it: bool = has_upgrade_func.call("falcons_camp", "falcons_camp:0")
    if not has_it:
        return 1.0
    var bs_present: bool = BuildingUpgradeUnitCounterScript.has_active_unit("black_swordsman")
    if bs_present:
        return 2.0
    return 1.0
