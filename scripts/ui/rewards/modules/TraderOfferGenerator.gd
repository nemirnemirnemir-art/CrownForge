extends RefCounted
class_name TraderOfferGenerator

## Generates and rolls offers for the Trader UI

const PathRegistryScript := preload("res://scripts/systems/PathRegistry.gd")
const BuildingConfigScript := preload("res://core/buildings/BuildingConfig.gd")

const BUILDING_CATEGORY_PRICES: Array[int] = [
    30,  ## 0: BASIC_PRODUCTION
    45,  ## 1: ESTABLISHED_PRODUCTION
    60,  ## 2: ADVANCED_PRODUCTION
    30,  ## 3: LEVY_BARRACKS
    35,  ## 4: VETERAN_BARRACKS
    50,  ## 5: ELITE_BARRACKS
    45,  ## 6: KINGDOM_INFRASTRUCTURE
    40,  ## 7: OTHER
]

const UI_RESOURCES: Array[String] = [
    "water", "gold", "wood", "clay", "iron_ore", "steel", "wheat", "flour", "grapes", "wine", "crystal"
]

const EXCLUDED_BUILDING_IDS := {
    "well": true,
}

func get_building_price(building_id: String, fallback_price: int, building_registry: Node) -> int:
    if building_registry == null:
        return fallback_price
    var cfg = building_registry.call("get_building", building_id)
    if cfg == null:
        return fallback_price
    var cat := int(cfg.building_category)
    if cat >= 0 and cat < BUILDING_CATEGORY_PRICES.size():
        return BUILDING_CATEGORY_PRICES[cat]
    return fallback_price

func roll_building_ids(building_registry: Node) -> Array[String]:
    var ids: Array[String] = []
    if building_registry and building_registry.has_method("get_all_building_ids"):
        var raw_ids = building_registry.call("get_all_building_ids")
        if raw_ids is Array:
            for raw in raw_ids:
                var building_id := String(raw)
                if EXCLUDED_BUILDING_IDS.has(building_id):
                    continue
                ids.append(building_id)
    ids.shuffle()
    return ids

func roll_artifact_ids(artifact_catalog: Object, artifact_core: Object) -> Array[String]:
    var pool: Array[String] = []
    if artifact_catalog and artifact_catalog.has_method("get_player_available_ids_sorted"):
        var all_ids = artifact_catalog.call("get_player_available_ids_sorted")
        for raw_id in all_ids:
            var id := String(raw_id)
            if artifact_core and artifact_core.has_method("has_artifact") and artifact_core.call("has_artifact", id):
                continue
            pool.append(id)
    pool.shuffle()
    return pool

func roll_resource_ids() -> Array[String]:
    var pool := UI_RESOURCES.duplicate()
    pool.shuffle()
    return pool

func roll_spell_ids() -> Array[String]:
    var ids := PathRegistryScript.list_spell_config_ids(false)
    ids.shuffle()
    return ids

func roll_building_upgrades(tree: SceneTree, building_upgrade_data_script: Script, building_upgrade_core: Node) -> Array:
    var out: Array = []
    var seen_upgrade_ids: Dictionary = {}
    var gs = tree.get_first_node_in_group("game_scene")
    if gs == null:
        return out
    var map_layout: Variant = gs.get("map_layout_node")
    if map_layout == null:
        return out
    var slots: Variant = map_layout.get("slots")
    if not (slots is Array):
        return out

    for s in slots:
        if s == null:
            continue
        var building_id: Variant = s.get("current_building_id")
        var slot_index: Variant = s.get("slot_index")
        if typeof(building_id) != TYPE_STRING:
            continue
        if typeof(slot_index) != TYPE_INT:
            continue
        var b := String(building_id)
        if b == "":
            continue

        var defs: Array = []
        if building_upgrade_data_script and building_upgrade_data_script.has_method("get_upgrades"):
            defs = building_upgrade_data_script.call("get_upgrades", b)

        if defs.is_empty():
            defs = [
                {"name": "Upgrade 1", "desc": ""},
                {"name": "Upgrade 2", "desc": ""},
                {"name": "Upgrade 3", "desc": ""},
            ]

        for idx in range(defs.size()):
            var upgrade_id := "%s:%d" % [b, idx]
            if seen_upgrade_ids.has(upgrade_id):
                continue
            var applied := false
            if building_upgrade_core and building_upgrade_core.has_method("has_upgrade"):
                applied = building_upgrade_core.call("has_upgrade", int(slot_index), upgrade_id)
            if applied:
                continue
            out.append({"slot_index": int(slot_index), "building_id": b, "upgrade_index": idx, "upgrade_id": upgrade_id})
            seen_upgrade_ids[upgrade_id] = true

    out.shuffle()
    return out
