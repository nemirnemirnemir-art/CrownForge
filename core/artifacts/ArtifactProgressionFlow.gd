extends RefCounted
class_name ArtifactProgressionFlow

const MOON_TALISMAN_ID := "moon_talisman"
const ROYAL_RUNE_ID := "royal_rune"
const RUNE_SHARD_RED_ID := "rune_shard_red"
const RUNE_SHARD_BLUE_ID := "rune_shard_blue"
const RUNE_SHARD_GREEN_ID := "rune_shard_green"
const COMFY_BED_ID := "comfy_bed"
const WOODEN_KEY_ID := "wooden_key"

const ACTIVE_COOLDOWN_IDS: Array[String] = [
    "forced_tax",
    "frenzy",
    "training",
]


func on_gaze_upgraded(active: Dictionary, state: Dictionary, hero_core: Variant) -> void:
    if not active.has(MOON_TALISMAN_ID):
        return
    if hero_core == null:
        return
    for _i in range(3):
        _spawn_unit(hero_core, "healer_mage")


func apply_active_cooldown_reduction(active: Dictionary, cooldowns: Dictionary) -> Dictionary:
    var result := cooldowns.duplicate(true)
    if result.is_empty():
        return result

    for i in range(ACTIVE_COOLDOWN_IDS.size()):
        var spell_id := ACTIVE_COOLDOWN_IDS[i]
        if not result.has(spell_id):
            continue
        var cooldown := float(result.get(spell_id, 0.0))
        if active.has(ROYAL_RUNE_ID):
            cooldown *= 0.75
        if i == 0 and active.has(RUNE_SHARD_RED_ID):
            cooldown *= 0.75
        elif i == 1 and active.has(RUNE_SHARD_BLUE_ID):
            cooldown *= 0.75
        elif i == 2 and active.has(RUNE_SHARD_GREEN_ID):
            cooldown *= 0.75
        result[spell_id] = cooldown
    return result


func get_troop_building_capacity_bonus(active: Dictionary, building_config: Variant) -> int:
    if not active.has(COMFY_BED_ID):
        return 0
    if building_config == null:
        return 0
    var building_type := _resolve_building_type(building_config)
    if building_type != int(BuildingConfig.BuildingType.MILITARY):
        return 0
    return 1


func on_unit_created(active: Dictionary, resource_core: Variant) -> void:
    if not active.has(WOODEN_KEY_ID):
        return
    if resource_core == null:
        return
    if resource_core.has_method("add_resource"):
        resource_core.call("add_resource", "wood", 3)


func _spawn_unit(hero_core: Variant, base_unit_id: String) -> void:
    if not hero_core.has_method("ensure_hero_template"):
        return
    hero_core.call("ensure_hero_template", base_unit_id, String(base_unit_id).capitalize().replace("_", " "), 0.0)
    if not hero_core.has_method("hire_hero_copy"):
        return
    var new_id := String(hero_core.call("hire_hero_copy", base_unit_id))
    if new_id == "":
        return
    if hero_core.has_method("add_to_squad"):
        hero_core.call("add_to_squad", new_id)


func _resolve_building_type(building_config: Variant) -> int:
    if building_config is BuildingConfig:
        return int((building_config as BuildingConfig).building_type)
    if building_config is Dictionary:
        return int((building_config as Dictionary).get("building_type", -1))
    return -1
