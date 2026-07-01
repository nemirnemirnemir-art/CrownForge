extends RefCounted
class_name TownBuildFlow


func get_building_slot_state(buildings, building_id: String, slot_index: int) -> Dictionary:
    return buildings.get_slot_state(building_id, slot_index) if buildings else {}


func set_building_slot_state(buildings, save_core, building_id: String, slot_index: int, state: Dictionary, request_save: bool = false) -> void:
    if buildings == null:
        return
    buildings.set_slot_state(building_id, slot_index, state)
    if request_save and save_core and save_core.has_method("request_save"):
        save_core.request_save()


func clear_building_slot_state(buildings, save_core, building_id: String, slot_index: int, request_save: bool = false) -> void:
    if buildings == null:
        return
    buildings.clear_slot_state(building_id, slot_index)
    if request_save and save_core and save_core.has_method("request_save"):
        save_core.request_save()


func get_next_build_cost(building_registry, buildings, build_config, building_id: String) -> Dictionary:
    if building_registry and building_registry.has_method("get_next_build_cost") and building_registry.has_method("get_building"):
        if building_registry.get_building(building_id) != null:
            return building_registry.get_next_build_cost(building_id)

    var hardcoded_costs = {
        "well": {},
        "goldmine": {"wood": 50},
        "ironmine": {"wood": 100, "clay": 70},
        "wheat_field": {"water": 50},
        "sawmill": {"gold": 30},
        "clay_pit": {"wood": 40},
        "vineyard": {"wood": 60, "water": 40},
        "smeltery": {"gold": 100, "iron_ore": 60},
        "windmill": {"wood": 80, "clay": 50},
        "winery": {"wood": 120, "clay": 80},
        "peasant_barracks": {"wood": 60, "clay": 60},
        "slingers_field": {"wood": 100, "clay": 60},
    }
    if hardcoded_costs.has(building_id):
        var hard_base_cost = hardcoded_costs[building_id]
        if hard_base_cost.is_empty():
            return {}
        var hard_count: int = buildings.get_building_built_count(building_id) if buildings else 0
        var hard_factor := pow(1.5, float(hard_count))
        var hard_result: Dictionary = {}
        for res_id in hard_base_cost.keys():
            hard_result[res_id] = int(ceil(hard_base_cost[res_id] * hard_factor))
        return hard_result

    if build_config == null:
        return {}
    var entry = build_config.get_entry(building_id)
    if not entry or bool(entry.free_build):
        return {}
    var base_amounts = entry.base_cost
    if not base_amounts or not base_amounts.has_method("to_dict"):
        return {}
    var base_cost: Dictionary = base_amounts.to_dict()
    if base_cost.is_empty():
        return {}
    var count: int = buildings.get_building_built_count(building_id) if buildings else 0
    var factor := pow(float(entry.growth), float(count))
    var result: Dictionary = {}
    for res_id in base_cost.keys():
        var base_val := int(base_cost[res_id])
        if base_val <= 0:
            continue
        result[res_id] = int(ceil(base_val * factor))
    return result


func can_build(resource_core, building_registry, buildings, build_config, building_id: String) -> bool:
    var cost := get_next_build_cost(building_registry, buildings, build_config, building_id)
    if cost.is_empty():
        return true
    if resource_core == null:
        return false
    for res_id in cost.keys():
        if resource_core.get_resource(res_id) < int(cost[res_id]):
            return false
    return true


func get_building_provides(build_config, building_id: String) -> Dictionary:
    var hardcoded_provides = {
        "well": {"water": 1},
        "goldmine": {"gold": 1},
        "ironmine": {"iron_ore": 1},
        "wheat_field": {"wheat": 1},
        "sawmill": {"wood": 1},
        "clay_pit": {"clay": 1},
        "vineyard": {"grapes": 1},
        "smeltery": {"steel": 1},
        "windmill": {"flour": 1},
        "winery": {"wine": 1},
        "peasant_barracks": {"peasant": 1},
        "slingers_field": {"slinger": 1},
    }
    if hardcoded_provides.has(building_id):
        return hardcoded_provides[building_id]
    if not build_config:
        return {}
    var entry = build_config.get_entry(building_id)
    if not entry:
        return {}
    var amounts = entry.provides
    if not amounts or not amounts.has_method("to_dict"):
        return {}
    return amounts.to_dict()


func try_pay_build_cost(buildings, resource_core, building_registry, build_config, building_id: String) -> bool:
    var cost := get_next_build_cost(building_registry, buildings, build_config, building_id)
    if cost.is_empty():
        if buildings:
            buildings.increment_building_built_count(building_id)
        return true
    if resource_core == null:
        return false
    if not can_build(resource_core, building_registry, buildings, build_config, building_id):
        return false
    for res_id in cost.keys():
        var needed := int(cost[res_id])
        if needed <= 0:
            continue
        resource_core.consume_resource(res_id, needed)
    if buildings:
        buildings.increment_building_built_count(building_id)
    return true
