extends RefCounted
## BuildingUpgradeProductionEvent
## Post-production event hooks for military buildings:
## - giants_bedding:0 -> +100 Wood when Giant is produced
## - giants_bedding:1 -> +100 Wheat when Giant is produced
## - ram_pasture:2 -> 10% chance to produce an extra Ram

## Process post-production events for a military building after a unit is hired.
## Returns an Array of event descriptions for logging/testing.
## add_resource_func: Callable(resource_id: String, amount: int) -> void
## hire_extra_func: Callable(unit_id: String) -> String (returns new hero_id or "")
static func process_military_production_event(
    building_id: String,
    produced_unit_id: String,
    has_upgrade_func: Callable,
    add_resource_func: Callable,
    hire_extra_func: Callable
) -> Array[Dictionary]:
    var events: Array[Dictionary] = []

    # Giants Bedding resource grants
    if building_id == "giants_bedding":
        if has_upgrade_func.is_valid() and has_upgrade_func.call("giants_bedding", "giants_bedding:0"):
            if add_resource_func.is_valid():
                add_resource_func.call("wood", 100)
            events.append({"type": "resource_grant", "resource": "wood", "amount": 100})
        if has_upgrade_func.is_valid() and has_upgrade_func.call("giants_bedding", "giants_bedding:1"):
            if add_resource_func.is_valid():
                add_resource_func.call("wheat", 100)
            events.append({"type": "resource_grant", "resource": "wheat", "amount": 100})

    # Ram Twins: 10% chance to produce an extra Ram
    if building_id == "ram_pasture" and produced_unit_id == "ram":
        if has_upgrade_func.is_valid() and has_upgrade_func.call("ram_pasture", "ram_pasture:2"):
            var roll: float = randf()
            if roll < 0.10:
                if hire_extra_func.is_valid():
                    var extra_id: String = hire_extra_func.call("ram")
                    if extra_id != "":
                        events.append({"type": "extra_unit", "unit_id": "ram", "hero_id": extra_id})

    return events
