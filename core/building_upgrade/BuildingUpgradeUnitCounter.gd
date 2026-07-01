extends RefCounted
## BuildingUpgradeUnitCounter
## Shared utility for counting active heroes on the battlefield by unit_id.
## Uses HeroCore.get_active_heroes() which returns Array[Dictionary] with "id" and "icon_id".
## The icon_id is the base unit type (e.g. "ram", "hydra", "black_swordsman").

## Count how many active heroes of a given base unit type are currently on the battlefield.
static func count_active_units(unit_id: String) -> int:
    var hero_core: Object = _get_hero_core()
    if hero_core == null or not hero_core.has_method("get_active_heroes"):
        return 0
    var active_heroes: Variant = hero_core.call("get_active_heroes")
    if not (active_heroes is Array):
        return 0
    var count: int = 0
    for entry: Variant in active_heroes:
        if entry is Dictionary:
            var icon_id: String = String((entry as Dictionary).get("icon_id", ""))
            if icon_id == unit_id:
                count += 1
    return count

## Check if at least one hero of a given base unit type is active on the battlefield.
static func has_active_unit(unit_id: String) -> bool:
    return count_active_units(unit_id) > 0

## Count active heroes that belong to a specific UnitClass enum value.
## Requires TroopBonusCore to resolve unit classes.
static func count_active_units_by_class(unit_class: int) -> int:
    var hero_core: Object = _get_hero_core()
    if hero_core == null or not hero_core.has_method("get_active_heroes"):
        return 0
    var troop_core: Object = _get_troop_bonus_core()
    if troop_core == null or not troop_core.has_method("get_unit_classes"):
        return 0
    var active_heroes: Variant = hero_core.call("get_active_heroes")
    if not (active_heroes is Array):
        return 0
    var count: int = 0
    for entry: Variant in active_heroes:
        if entry is Dictionary:
            var icon_id: String = String((entry as Dictionary).get("icon_id", ""))
            if icon_id == "":
                continue
            var classes: Variant = troop_core.call("get_unit_classes", icon_id)
            if classes is Array and (classes as Array).has(unit_class):
                count += 1
    return count

static func _get_hero_core() -> Object:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null or tree.root == null:
        return null
    return tree.root.get_node_or_null("HeroCore")

static func _get_troop_bonus_core() -> Object:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null or tree.root == null:
        return null
    return tree.root.get_node_or_null("TroopBonusCore")
