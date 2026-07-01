extends Node
class_name BarracksUnitCollector

const PathRegistryScript := preload("res://scripts/systems/PathRegistry.gd")
const BuildingConfigScript := preload("res://core/buildings/BuildingConfig.gd")

func collect_unit_info() -> Dictionary:
    var cap_by_unit: Dictionary = collect_barracks_capacity_by_unit()

    var unowned_active_by_unit: Dictionary = {}
    var barracks_active_by_unit: Dictionary = {}
    var barracks_in_barracks_by_unit: Dictionary = {}

    if HeroCore:
        for hero in HeroCore.heroes.values():
            if not (hero is Dictionary):
                continue
            if not bool(hero.get("is_hired", false)):
                continue
            if bool(hero.get("is_summon", false)):
                continue
            if bool(hero.get("isDead", false)):
                continue
            var hero_id := str(hero.get("id", ""))
            if hero_id == "":
                continue
            var unit_id := resolve_unit_id(hero_id)
            var produced_type := int(hero.get("produced_by_building_type", -1))
            var is_active := bool(hero.get("isActive", false))

            if produced_type == int(BuildingConfigScript.BuildingType.MILITARY):
                if is_active:
                    barracks_active_by_unit[unit_id] = int(barracks_active_by_unit.get(unit_id, 0)) + 1
                else:
                    barracks_in_barracks_by_unit[unit_id] = int(barracks_in_barracks_by_unit.get(unit_id, 0)) + 1
            else:
                if is_active:
                    unowned_active_by_unit[unit_id] = int(unowned_active_by_unit.get(unit_id, 0)) + 1

    var all_unit_ids: Dictionary = {}
    for k in cap_by_unit.keys():
        all_unit_ids[str(k)] = true
    for k in unowned_active_by_unit.keys():
        all_unit_ids[str(k)] = true
    for k in barracks_active_by_unit.keys():
        all_unit_ids[str(k)] = true
    for k in barracks_in_barracks_by_unit.keys():
        all_unit_ids[str(k)] = true

    var out: Dictionary = {}
    for unit_id in all_unit_ids.keys():
        var unowned_active := int(unowned_active_by_unit.get(unit_id, 0))
        var b_active := int(barracks_active_by_unit.get(unit_id, 0))
        var b_in_barracks := int(barracks_in_barracks_by_unit.get(unit_id, 0))
        var cap := int(cap_by_unit.get(unit_id, 0))
        out[unit_id] = {
            "unowned_active": unowned_active,
            "barracks_active": b_active,
            "barracks_in_barracks": b_in_barracks,
            "barracks_total": b_active + b_in_barracks,
            "capacity": cap
        }
    return out

func collect_barracks_capacity_by_unit() -> Dictionary:
    var cap_by_unit: Dictionary = {}
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null:
        return cap_by_unit
    var scene := tree.current_scene
    if scene == null:
        return cap_by_unit
    var map_layout := scene.get_node_or_null("WorldYSort/MapContainer/MapLayout")
    if map_layout == null:
        return cap_by_unit
    if not ("slots" in map_layout):
        return cap_by_unit

    for slot in map_layout.slots:
        if slot == null or not is_instance_valid(slot):
            continue
        if not ("current_building_id" in slot):
            continue
        var building_id := str(slot.current_building_id)
        if building_id == "":
            continue
        if not BuildingRegistry:
            continue
        var cfg := BuildingRegistry.get_building(building_id) as BuildingConfig
        if cfg == null:
            continue
        if cfg.building_type != BuildingConfig.BuildingType.MILITARY:
            continue
        var unit_id := str(cfg.produced_unit_id)
        if unit_id == "":
            continue
        cap_by_unit[unit_id] = int(cap_by_unit.get(unit_id, 0)) + int(cfg.max_units)

    return cap_by_unit

func resolve_unit_id(hero_id: String) -> String:
    var id := hero_id.to_lower()
    if id.contains("_"):
        var parts := id.rsplit("_", true, 1)
        if parts.size() == 2 and String(parts[1]).is_valid_int():
            return String(parts[0])
    return id

func try_get_unit_config(unit_id: String) -> UnitConfig:
    return PathRegistryScript.load_unit_config(unit_id)

func get_unit_display_name(unit_id: String, cfg: UnitConfig) -> String:
    if cfg != null and cfg.display_name != "":
        return cfg.display_name
    return unit_id.replace("_", " ").capitalize()

func get_unit_primary_class(cfg: UnitConfig) -> String:
    if cfg == null:
        return "Warrior"
    var classes: Array = cfg.get_class_names()
    if classes.size() > 0:
        return str(classes[0])
    return "Warrior"
