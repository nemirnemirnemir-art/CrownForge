extends RefCounted
class_name EncounterParser

## Parses encounters and options into dictionaries and verifies requirements

const EncounterResourcesScript := preload("res://scripts/encounters/modules/EncounterResources.gd")
const EncounterDefsScript := preload("res://scripts/encounters/EncounterDefs.gd")

const VALID_UI_ACTION_IDS := {
    "open_reward_menu_base_production": true,
    "open_reward_menu_established_production": true,
    "open_reward_menu_advanced_production": true,
    "open_reward_menu_levy_barracks": true,
    "open_reward_menu_veteran_barracks": true,
    "open_reward_menu_elite_barracks": true,
    "open_reward_menu_kingdom_infrastructure": true,
    "open_reward_menu_artifacts": true,
    "open_reward_menu_spells": true,
    "open_reward_menu_legendary_spells": true,
    "open_reward_menu_building_upgrades": true,
    "open_reward_menu_troop_bonuses": true,
}

func get_standard_encounter_ids() -> Array[String]:
    return EncounterDefsScript.get_standard_encounter_ids()

func get_encounter(id: String) -> Dictionary:
    return EncounterDefsScript.get_encounter(id)

func sanitize_encounter(encounter: Dictionary, spell_check_callback: Callable) -> Dictionary:
    var encounter_id := String(encounter.get("id", ""))
    var title := String(encounter.get("title", ""))
    var description := String(encounter.get("description", ""))
    if encounter_id == "" or title == "":
        return {}

    var options_var: Variant = encounter.get("options", [])
    if not (options_var is Array):
        return {}

    var valid_options: Array = []
    for raw_option in options_var:
        if not (raw_option is Dictionary):
            continue
        var option: Dictionary = (raw_option as Dictionary).duplicate(true)
        if not _is_option_valid(option, spell_check_callback):
            continue
        valid_options.append(option)

    if valid_options.size() < 2:
        return {}

    return {
        "id": encounter_id,
        "title": title,
        "description": description,
        "options": valid_options,
    }

func _is_option_valid(option: Dictionary, spell_check_callback: Callable) -> bool:
    var option_id := String(option.get("id", ""))
    var label := String(option.get("label", ""))
    if option_id == "" or label == "":
        return false

    var req_var: Variant = option.get("requirements", {})
    if req_var != null and not (req_var is Dictionary):
        return false

    if req_var is Dictionary:
        var requirements: Dictionary = req_var
        if not _are_requirements_valid(requirements):
            return false

    var effects_var: Variant = option.get("effects", [])
    if not (effects_var is Array):
        return false

    for raw_effect in effects_var:
        if not (raw_effect is Dictionary):
            return false
        if not _is_effect_valid(raw_effect as Dictionary, spell_check_callback):
            return false

    return true

func _are_requirements_valid(requirements: Dictionary) -> bool:
    var resources_var: Variant = requirements.get("resources", {})
    if resources_var != null and not (resources_var is Dictionary):
        return false

    if resources_var is Dictionary:
        for raw_id in (resources_var as Dictionary).keys():
            var amount := int((resources_var as Dictionary).get(raw_id, 0))
            if amount <= 0:
                return false
            if not EncounterResourcesScript.resource_exists(String(raw_id)):
                return false

    return true

func _is_effect_valid(effect: Dictionary, spell_check_callback: Callable) -> bool:
    var kind := String(effect.get("kind", ""))
    if kind == "resource_add" or kind == "resource_consume" or kind == "resource_lose":
        var resource_id := String(effect.get("resource_id", ""))
        var amount := int(effect.get("amount", 0))
        if amount <= 0:
            return false
        return EncounterResourcesScript.resource_exists(resource_id)

    if kind == "denarii_add" or kind == "all_resources_add":
        return int(effect.get("amount", 0)) > 0

    if kind == "spell_add":
        var spell_id := String(effect.get("spell_id", ""))
        var spell_amount := int(effect.get("amount", 0))
        if spell_id == "" or spell_amount <= 0:
            return false
        return spell_check_callback.call(spell_id)

    if kind == "ui_action":
        var action_id := String(effect.get("action_id", ""))
        var count := int(effect.get("count", 1))
        var chance_percent := int(effect.get("chance_percent", 100))
        return VALID_UI_ACTION_IDS.has(action_id) and count > 0 and chance_percent > 0 and chance_percent <= 100

    if kind == "troops_add":
        var troop_id := String(effect.get("troop_id", ""))
        var troop_amount := int(effect.get("amount", 0))
        if troop_id == "" or troop_amount <= 0:
            return false
        return true

    if kind == "morale_add":
        var morale_amount := int(effect.get("amount", 0))
        return morale_amount != 0

    if kind == "building_add":
        return String(effect.get("building_id", "")) != "" and int(effect.get("amount", 0)) > 0

    if kind == "spawn_enemy":
        return String(effect.get("enemy_id", "")) != "" and int(effect.get("amount", 0)) > 0

    if kind == "transmute":
        return EncounterResourcesScript.resource_exists(String(effect.get("target_resource", "")))

    if kind in ["lose_troops", "max_hp_add", "gaze_upgrade"]:
        return true

    return false
