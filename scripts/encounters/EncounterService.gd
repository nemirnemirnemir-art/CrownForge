class_name EncounterService
extends Node

const EncounterDefsScript := preload("res://scripts/encounters/EncounterDefs.gd")
const PathRegistryScript := preload("res://scripts/systems/PathRegistry.gd")
const EncounterResourcesScript := preload("res://scripts/encounters/modules/EncounterResources.gd")
const EncounterUIBuilderScript := preload("res://scripts/encounters/modules/EncounterUIBuilder.gd")

const EncounterParserScript := preload("res://scripts/encounters/modules/EncounterParser.gd")
const EncounterStateBuilderScript := preload("res://scripts/encounters/modules/EncounterStateBuilder.gd")
const EncounterRewardApplicatorScript := preload("res://scripts/encounters/modules/EncounterRewardApplicator.gd")

var _rng: RandomNumberGenerator
var _encounter_cache: Dictionary = {}
var _standard_ids: Array[String] = []
var _last_encounter_id: String = ""

var _parser: EncounterParser
var _state_builder: EncounterStateBuilder
var _applicator: EncounterRewardApplicator

func _init() -> void:
    _rng = RandomNumberGenerator.new()
    _rng.randomize()
    _parser = EncounterParserScript.new()
    _state_builder = EncounterStateBuilderScript.new()
    _applicator = EncounterRewardApplicatorScript.new(_rng)
    _reload_standard_pool()

func get_standard_encounter_ids() -> Array[String]:
    if _standard_ids.is_empty():
        _reload_standard_pool()
    return _standard_ids.duplicate()

func build_random_encounter() -> Dictionary:
    if _standard_ids.is_empty():
        _reload_standard_pool()
    if _standard_ids.is_empty():
        return {}

    var picked_index := _rng.randi_range(0, _standard_ids.size() - 1)
    var encounter_id := _standard_ids[picked_index]
    if _standard_ids.size() > 1 and encounter_id == _last_encounter_id:
        picked_index = (picked_index + 1) % _standard_ids.size()
        encounter_id = _standard_ids[picked_index]

    _last_encounter_id = encounter_id
    return build_encounter_by_id(encounter_id)

func build_encounter_by_id(encounter_id: String) -> Dictionary:
    if _encounter_cache.is_empty():
        _reload_standard_pool()

    var raw: Variant = _encounter_cache.get(encounter_id, null)
    if raw == null or not (raw is Dictionary):
        return {}

    var encounter: Dictionary = (raw as Dictionary).duplicate(true)
    encounter["options"] = _state_builder.decorate_options_for_ui(encounter.get("options", []), _get_resource_core())
    return encounter

func find_option(encounter: Dictionary, option_id: String) -> Dictionary:
    var options_var: Variant = encounter.get("options", [])
    if not (options_var is Array):
        return {}

    for raw_option in options_var:
        if not (raw_option is Dictionary):
            continue
        var option: Dictionary = raw_option
        if String(option.get("id", "")) == option_id:
            return option.duplicate(true)
    return {}

func apply_encounter_option(encounter_id: String, option_id: String) -> bool:
    var encounter: Dictionary = build_encounter_by_id(encounter_id)
    if encounter.is_empty():
        return false

    var option: Dictionary = find_option(encounter, option_id)
    if option.is_empty():
        return false

    return apply_option(option)

func apply_option(option: Dictionary) -> bool:
    if not _can_consume_all(option):
        return false
    return _applicator.apply_option(option, Callable(self, "_consume_all"), _parser.VALID_UI_ACTION_IDS)

func _can_consume_all(option: Dictionary) -> bool:
    var resource_core := _get_resource_core()
    if resource_core == null:
        return false
    var consume_map: Dictionary = _collect_consumption_map(option)
    for raw_id in consume_map.keys():
        var resource_id := EncounterResourcesScript.normalize_resource_id(String(raw_id))
        var amount := int(consume_map.get(raw_id, 0))
        if amount <= 0:
            continue
        if not bool(resource_core.call("has_resource", resource_id, amount)):
            return false
    return true

func consume_pending_ui_actions() -> Array[String]:
    return _applicator.consume_pending_ui_actions()

func _reload_standard_pool() -> void:
    _encounter_cache.clear()
    _standard_ids.clear()

    for encounter_id in _parser.get_standard_encounter_ids():
        var candidate: Dictionary = _parser.get_encounter(encounter_id)
        var sanitized: Dictionary = _parser.sanitize_encounter(candidate, Callable(self, "_spell_exists"))
        if sanitized.is_empty():
            continue
        _encounter_cache[encounter_id] = sanitized
        _standard_ids.append(encounter_id)

func _consume_all(option: Dictionary) -> bool:
    var resource_core := _get_resource_core()
    if resource_core == null:
        return false

    var consume_map: Dictionary = _collect_consumption_map(option)
    for raw_id in consume_map.keys():
        var resource_id := EncounterResourcesScript.normalize_resource_id(String(raw_id))
        var amount := int(consume_map.get(raw_id, 0))
        if amount <= 0:
            continue
        if not bool(resource_core.call("consume_resource", resource_id, amount)):
            return false
    return true

func _collect_consumption_map(option: Dictionary) -> Dictionary:
    var consume_map: Dictionary = {}

    var req_var: Variant = option.get("requirements", {})
    if req_var is Dictionary:
        var requirements: Dictionary = req_var
        var consume_on_select := bool(requirements.get("consume_on_select", false))
        if consume_on_select:
            var resources_var: Variant = requirements.get("resources", {})
            if resources_var is Dictionary:
                for raw_id in (resources_var as Dictionary).keys():
                    var normalized_id := EncounterResourcesScript.normalize_resource_id(String(raw_id))
                    var amount := int((resources_var as Dictionary).get(raw_id, 0))
                    consume_map[normalized_id] = int(consume_map.get(normalized_id, 0)) + amount

    var effects_var: Variant = option.get("effects", [])
    if effects_var is Array:
        for raw_effect in effects_var:
            if not (raw_effect is Dictionary):
                continue
            var effect: Dictionary = raw_effect
            var kind := String(effect.get("kind", ""))
            if kind != "resource_consume" and kind != "resource_lose":
                continue
            var resource_id := EncounterResourcesScript.normalize_resource_id(String(effect.get("resource_id", "")))
            var amount := int(effect.get("amount", 0))
            consume_map[resource_id] = int(consume_map.get(resource_id, 0)) + amount

    return consume_map

func _spell_exists(spell_id: String) -> bool:
    if spell_id == "":
        return false
    return PathRegistryScript.spell_config_exists(spell_id)

func _get_resource_core() -> Node:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null or tree.root == null:
        return null
    return tree.root.get_node_or_null("ResourceCore")

func _get_spell_core() -> Node:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null or tree.root == null:
        return null
    return tree.root.get_node_or_null("SpellCore")

func _get_economy_core() -> Node:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null or tree.root == null:
        return null
    return tree.root.get_node_or_null("EconomyCore")

func _get_building_registry() -> Node:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null or tree.root == null:
        return null
    return tree.root.get_node_or_null("BuildingRegistry")

func _get_hero_core() -> Node:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null or tree.root == null:
        return null
    return tree.root.get_node_or_null("HeroCore")

func _get_morale_system() -> Node:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null or tree.root == null:
        return null
    return tree.root.get_node_or_null("MoraleSystem")

func _get_spell_panel() -> Node:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null:
        return null
    return tree.get_first_node_in_group("spell_panel")
