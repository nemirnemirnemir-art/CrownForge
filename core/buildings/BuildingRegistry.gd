@tool
extends Node
class_name BuildingRegistryClass

const BuildingScaleInspectorScript := preload("res://core/buildings/BuildingScaleInspector.gd")
const BuildingCostServiceScript := preload("res://core/buildings/BuildingCostService.gd")
const BuildingIconResolverScript := preload("res://core/buildings/BuildingIconResolver.gd")

signal recipe_changed(building_id: String, new_count: int)

## BuildingRegistry - Autoload singleton that stores all building configurations
## Edit the buildings array directly in the inspector!

## All buildings array - editable in inspector
var _buildings: Array[BuildingConfig] = []
@export var buildings: Array[BuildingConfig] = []:
    get:
        return _buildings
    set(value):
        _buildings = value
        if Engine.is_editor_hint():
            notify_property_list_changed()

## Cache for quick access by ID
var _cache: Dictionary = {}

var _recipe_counts: Dictionary = {}
@export_storage var _placed_building_scale_overrides: Dictionary = {}

var _scale_inspector = BuildingScaleInspectorScript.new()
var _cost_service = BuildingCostServiceScript.new()
var _icon_resolver = BuildingIconResolverScript.new()

const BUILD_COST_STEP_PER_EXISTING: float = 0.20
const SCALE_PROPERTY_PREFIX := "Placed Building Scale/"
const CATEGORY_LABELS := {
    int(BuildingConfig.BuildingCategory.BASIC_PRODUCTION): "Basic Production",
    int(BuildingConfig.BuildingCategory.ESTABLISHED_PRODUCTION): "Established Production",
    int(BuildingConfig.BuildingCategory.ADVANCED_PRODUCTION): "Advanced Production",
    int(BuildingConfig.BuildingCategory.LEVY_BARRACKS): "Levy Barracks",
    int(BuildingConfig.BuildingCategory.VETERAN_BARRACKS): "Veteran Barracks",
    int(BuildingConfig.BuildingCategory.ELITE_BARRACKS): "Elite Barracks",
    int(BuildingConfig.BuildingCategory.KINGDOM_INFRASTRUCTURE): "Kingdom Infrastructure",
    int(BuildingConfig.BuildingCategory.OTHER): "Other",
}

const ROLLOUT_VETERAN_BARRACKS_IDS := {
    "academy_of_fire": true,
    "academy_of_nature": true,
    "barbarian_tent": true,
    "falcons_camp": true,
    "firing_range": true,
    "geese_training_field": true,
    "hive": true,
    "longbowmens_camp": true,
    "minotaur_camp": true,
    "paladins_campus": true,
    "pumpkin_field": true,
    "stables": true,
}
const ROLLOUT_ELITE_BARRACKS_IDS := {
    "academy_of_lightning": true,
    "ballista_factory": true,
    "catapult_factory": true,
    "giants_bedding": true,
    "hydra_pond": true,
    "lion_circus": true,
    "pangolin_stump": true,
    "ram_pasture": true,
    "white_unicorn_field": true,
    "black_unicorn_field": true,
}
const REMOVED_BUILDING_IDS := {
    "blacksmiths_farm": true,
    "boar_feeder": true,
    "cannon": true,
    "dragons_bakery": true,
    "fire_brigade": true,
    "furniture_store": true,
	"phoenix_cannon": true,
	"pyre": true,
	"web_remover": true,
	"worshippers_sanctuary": true,
	"carousel": true,
	"tile_enchanter": true,
	"tile_enchanter_epic": true,
	"tile_enchanter_legendary": true,
}

var _release_mode_enabled: bool = false

func _get_property_list() -> Array[Dictionary]:
    return _scale_inspector.build_property_list(
        buildings,
        Callable(self, "_is_disabled_building_id"),
        Callable(self, "_is_rollout_filtered_out"),
        CATEGORY_LABELS,
        SCALE_PROPERTY_PREFIX
    )

func _get(property: StringName) -> Variant:
    return _scale_inspector.read_scale_property_value(
        property,
        _placed_building_scale_overrides,
        buildings,
        CATEGORY_LABELS,
        SCALE_PROPERTY_PREFIX
    )

func _set(property: StringName, value: Variant) -> bool:
    return _scale_inspector.write_scale_property_value(
        property,
        value,
        _placed_building_scale_overrides,
        buildings,
        CATEGORY_LABELS,
        SCALE_PROPERTY_PREFIX,
        Callable(self, "notify_property_list_changed")
    )

func _validate_property(property: Dictionary) -> void:
    _scale_inspector.apply_property_validation(property, SCALE_PROPERTY_PREFIX)

func _is_disabled_building_id(building_id: String) -> bool:
    # Temporarily disabled (will be implemented later)
    var id := building_id.to_lower()
    if REMOVED_BUILDING_IDS.has(id):
        return true
    return id in [
        "nether_rune_enchantery",
        "ancient_pit",
        "vampire_bar",
        "vampires_mirror",
    ]

func _ready() -> void:
    _rebuild_cache()
    if Engine.is_editor_hint():
        notify_property_list_changed()

func set_release_mode_enabled(enabled: bool) -> void:
    _release_mode_enabled = enabled

func is_release_mode_enabled() -> bool:
    return _release_mode_enabled

func _rebuild_cache() -> void:
    _cache.clear()
    for config in buildings:
        if config == null or config.building_id == "":
            continue
        _try_assign_icon_if_missing(config)
        _cache[config.building_id] = config

func _scan_building_icons() -> void:
    _icon_resolver.scan_building_icons()

func _normalize_key(value: String) -> String:
    return _icon_resolver.normalize_key(value)

func _try_assign_icon_if_missing(config: BuildingConfig) -> void:
    _icon_resolver.try_assign_icon_if_missing(config)

func _is_rollout_filtered_out(config: BuildingConfig) -> bool:
    if config == null:
        return false
    var building_id := String(config.building_id).to_lower()
    match int(config.building_category):
        int(BuildingConfig.BuildingCategory.VETERAN_BARRACKS):
            return not ROLLOUT_VETERAN_BARRACKS_IDS.has(building_id)
        int(BuildingConfig.BuildingCategory.ELITE_BARRACKS):
            return not ROLLOUT_ELITE_BARRACKS_IDS.has(building_id)
        _:
            return false

## Get building config by ID
func get_building(building_id: String) -> BuildingConfig:
    if _is_disabled_building_id(building_id):
        return null
    if _cache.has(building_id):
        var cached := _cache[building_id] as BuildingConfig
        if _is_rollout_filtered_out(cached):
            return null
        return cached
    # Fallback - search in array
    for config in buildings:
        if config != null and config.building_id == building_id:
            if _is_rollout_filtered_out(config):
                return null
            _cache[building_id] = config
            return config
    return null

## Get all building IDs
func get_all_building_ids() -> Array[String]:
    var result: Array[String] = []
    for config in buildings:
        if config == null:
            continue
        if config.building_id == "":
            continue
        if _is_disabled_building_id(config.building_id):
            continue
        if _is_rollout_filtered_out(config):
            continue
        result.append(config.building_id)
    return result

func get_building_ids_for_menu(category: int = -1) -> Array[String]:
    if not _release_mode_enabled:
        if category == -1:
            return get_all_building_ids()
        return _get_building_ids_by_category_raw(category)

    # Release mode: only show buildings that have recipes (>0)
    if category == -1:
        return _get_building_ids_with_recipes_raw()
    return _get_building_ids_by_category_with_recipes_raw(category)

func _get_building_ids_by_category_raw(category: int) -> Array[String]:
    var out: Array[String] = []
    for config in buildings:
        if config == null:
            continue
        if config.building_id == "":
            continue
        if _is_disabled_building_id(config.building_id):
            continue
        if _is_rollout_filtered_out(config):
            continue
        if int(config.building_category) != int(category):
            continue
        out.append(config.building_id)
    return out

func _get_building_ids_with_recipes_raw() -> Array[String]:
    var out: Array[String] = []
    for config in buildings:
        if config == null:
            continue
        if config.building_id == "":
            continue
        if _is_disabled_building_id(config.building_id):
            continue
        if _is_rollout_filtered_out(config):
            continue
        if get_recipe_count(config.building_id) <= 0:
            continue
        out.append(config.building_id)
    return out

func _get_building_ids_by_category_with_recipes_raw(category: int) -> Array[String]:
    var out: Array[String] = []
    for config in buildings:
        if config == null:
            continue
        if config.building_id == "":
            continue
        if _is_disabled_building_id(config.building_id):
            continue
        if _is_rollout_filtered_out(config):
            continue
        if int(config.building_category) != int(category):
            continue
        if get_recipe_count(config.building_id) <= 0:
            continue
        out.append(config.building_id)
    return out

## Get buildings by type
func get_buildings_by_type(type: BuildingConfig.BuildingType) -> Array[BuildingConfig]:
    var result: Array[BuildingConfig] = []
    for config in buildings:
        if config == null:
            continue
        if _is_disabled_building_id(config.building_id):
            continue
        if _is_rollout_filtered_out(config):
            continue
        if config.building_type == type:
            result.append(config)
    return result

## Get buildings by category
func get_buildings_by_category(category: BuildingConfig.BuildingCategory) -> Array[BuildingConfig]:
    var result: Array[BuildingConfig] = []
    for config in buildings:
        if config == null:
            continue
        if _is_disabled_building_id(config.building_id):
            continue
        if _is_rollout_filtered_out(config):
            continue
        if config.building_category == category:
            result.append(config)
    return result

## Get building icon (or null for placeholder)
func get_building_icon(building_id: String) -> Texture2D:
    var config := get_building(building_id)
    if config:
        return config.get_icon_or_placeholder()
    return null

## Get building name
func get_building_name(building_id: String) -> String:
    var config := get_building(building_id)
    if config:
        return config.display_name
    return building_id

func get_placed_building_scale(building_id: String) -> float:
    return _scale_inspector.get_placed_building_scale(
        building_id,
        buildings,
        _placed_building_scale_overrides
    )

func _get_default_placed_building_scale(building_id: String) -> float:
    return _scale_inspector.get_default_placed_building_scale(building_id)

func _get_buildings_grouped_for_scale_inspector() -> Dictionary:
    return _scale_inspector.get_buildings_grouped_for_scale_inspector(
        buildings,
        Callable(self, "_is_disabled_building_id"),
        Callable(self, "_is_rollout_filtered_out"),
        CATEGORY_LABELS
    )

func _get_scale_property_name(config: BuildingConfig) -> String:
    return _scale_inspector.get_scale_property_name(config, CATEGORY_LABELS, SCALE_PROPERTY_PREFIX)

func _get_building_id_from_scale_property(property_name: String) -> String:
    return _scale_inspector.get_building_id_from_scale_property(property_name)

## Check if the building can be afforded
func can_afford_building(building_id: String) -> bool:
    return _cost_service.can_afford_building(
        building_id,
        _get_building_lookup(building_id),
        BUILD_COST_STEP_PER_EXISTING,
        _get_resource_core()
    )

## Pay for construction
func pay_for_building(building_id: String) -> bool:
    return _cost_service.pay_for_building(
        building_id,
        _get_building_lookup(building_id),
        BUILD_COST_STEP_PER_EXISTING,
        _get_resource_core()
    )

func get_next_build_cost(building_id: String) -> Dictionary:
    return _cost_service.get_next_build_cost(
        building_id,
        _get_building_lookup(building_id),
        BUILD_COST_STEP_PER_EXISTING
    )

func get_next_build_markup_percent(building_id: String) -> int:
    return _cost_service.get_next_build_markup_percent(building_id, BUILD_COST_STEP_PER_EXISTING)

func get_placed_building_count(building_id: String) -> int:
    return _cost_service.get_placed_building_count(building_id)

func _get_artifact_build_cost_multiplier() -> float:
    return _cost_service.get_artifact_build_cost_multiplier()

func _get_building_lookup(building_id: String) -> Dictionary:
    var config := get_building(building_id)
    if config == null:
        return {}
    return {String(config.building_id).to_lower(): config}

func _get_resource_core() -> Node:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null or tree.root == null:
        return null
    return tree.root.get_node_or_null("ResourceCore")

func can_build_from_recipe(building_id: String) -> bool:
    if building_id == "":
        return false
    if not _release_mode_enabled:
        return true
    return get_recipe_count(building_id) > 0

func consume_recipe(building_id: String, amount: int = 1) -> void:
    if building_id == "":
        return
    if amount <= 0:
        return
    var current := int(_recipe_counts.get(building_id, 0))
    current = max(0, current - amount)
    _recipe_counts[building_id] = current
    recipe_changed.emit(building_id, current)

## Reload cache (call after changes in editor)
func reload() -> void:
    _rebuild_cache()

func add_recipe(building_id: String, amount: int = 1) -> void:
    if building_id == "":
        return
    if amount <= 0:
        return
    if _is_disabled_building_id(building_id):
        return
    var current := int(_recipe_counts.get(building_id, 0))
    current += amount
    _recipe_counts[building_id] = current
    recipe_changed.emit(building_id, current)

func get_recipe_count(building_id: String) -> int:
    if _is_disabled_building_id(building_id):
        return 0
    return int(_recipe_counts.get(building_id, 0))

func clear_recipes() -> void:
    _recipe_counts.clear()
