extends RefCounted
class_name BuildingScaleInspector


func build_property_list(
    buildings: Array,
    is_disabled_building_id: Callable,
    is_rollout_filtered_out: Callable,
    category_labels: Dictionary,
    scale_property_prefix: String
) -> Array[Dictionary]:
    var properties: Array[Dictionary] = []
    var grouped := get_buildings_grouped_for_scale_inspector(
        buildings,
        is_disabled_building_id,
        is_rollout_filtered_out,
        category_labels
    )
    if grouped.is_empty():
        return properties

    properties.append({
        "name": scale_property_prefix.trim_suffix("/"),
        "type": TYPE_NIL,
        "usage": PROPERTY_USAGE_GROUP,
    })

    for category_key in grouped.keys():
        var group_name := String(category_key)
        properties.append({
            "name": "%s/" % group_name,
            "type": TYPE_NIL,
            "usage": PROPERTY_USAGE_SUBGROUP,
        })

        var category_buildings: Array = grouped[category_key]
        for entry in category_buildings:
            var config := entry as BuildingConfig
            if config == null:
                continue
            properties.append({
                "name": get_scale_property_name(config, category_labels, scale_property_prefix),
                "type": TYPE_FLOAT,
                "hint": PROPERTY_HINT_RANGE,
                "hint_string": "0.1,5.0,0.01,or_greater",
                "usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_STORAGE,
            })

    return properties


func read_scale_property_value(
    property: StringName,
    overrides: Dictionary,
    _buildings: Array,
    _category_labels: Dictionary,
    scale_property_prefix: String
) -> Variant:
    var property_name := String(property)
    if not property_name.begins_with(scale_property_prefix):
        return null

    var building_id := get_building_id_from_scale_property(property_name)
    if building_id == "":
        return null
    return get_placed_building_scale(building_id, _buildings, overrides)


func write_scale_property_value(
    property: StringName,
    value: Variant,
    overrides: Dictionary,
    _buildings: Array,
    _category_labels: Dictionary,
    scale_property_prefix: String,
    refresh_callback: Callable = Callable()
) -> bool:
    var property_name := String(property)
    if not property_name.begins_with(scale_property_prefix):
        return false

    var building_id := get_building_id_from_scale_property(property_name)
    if building_id == "":
        return false

    var scale_value := maxf(0.01, float(value))
    var default_scale := get_default_placed_building_scale(building_id)
    if is_equal_approx(scale_value, default_scale):
        overrides.erase(building_id)
    else:
        overrides[building_id] = scale_value

    if refresh_callback.is_valid():
        refresh_callback.call()
    return true


func apply_property_validation(property: Dictionary, scale_property_prefix: String) -> void:
    if String(property.get("name", "")).begins_with(scale_property_prefix):
        property["usage"] = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_STORAGE


func get_placed_building_scale(building_id: String, _buildings: Array, overrides: Dictionary) -> float:
    var normalized_id := String(building_id).to_lower()
    if normalized_id == "":
        return 1.0
    if overrides.has(normalized_id):
        return maxf(0.01, float(overrides[normalized_id]))
    return get_default_placed_building_scale(normalized_id)


func get_default_placed_building_scale(building_id: String) -> float:
    if String(building_id).to_lower() == "buddhist_temple":
        return 1.30
    return 1.0


func get_buildings_grouped_for_scale_inspector(
    buildings: Array,
    is_disabled_building_id: Callable,
    is_rollout_filtered_out: Callable,
    category_labels: Dictionary
) -> Dictionary:
    var grouped: Dictionary = {}
    for entry in buildings:
        var config := entry as BuildingConfig
        if config == null:
            continue
        if config.building_id == "":
            continue
        if is_disabled_building_id.is_valid() and bool(is_disabled_building_id.call(config.building_id)):
            continue
        if is_rollout_filtered_out.is_valid() and bool(is_rollout_filtered_out.call(config)):
            continue

        var category_value := int(config.building_category)
        var category_name := String(category_labels.get(category_value, "Other"))
        if not grouped.has(category_name):
            grouped[category_name] = []
        var category_list: Array = grouped[category_name]
        category_list.append(config)
        grouped[category_name] = category_list

    for category_name in grouped.keys():
        var category_list: Array = grouped[category_name]
        category_list.sort_custom(func(a: BuildingConfig, b: BuildingConfig) -> bool:
            if a == null:
                return false
            if b == null:
                return true
            return a.display_name.naturalnocasecmp_to(b.display_name) < 0
        )
        grouped[category_name] = category_list

    return _order_grouped_categories(grouped, category_labels)


func _order_grouped_categories(grouped: Dictionary, category_labels: Dictionary) -> Dictionary:
    var ordered_grouped: Dictionary = {}
    for category_name in _get_canonical_category_names(category_labels):
        if grouped.has(category_name):
            ordered_grouped[category_name] = grouped[category_name]

    var extra_category_names: Array[String] = []
    for category_name_variant in grouped.keys():
        var category_name := String(category_name_variant)
        if ordered_grouped.has(category_name):
            continue
        extra_category_names.append(category_name)
    extra_category_names.sort_custom(func(a: String, b: String) -> bool:
        return a.naturalnocasecmp_to(b) < 0
    )
    for category_name in extra_category_names:
        ordered_grouped[category_name] = grouped[category_name]

    return ordered_grouped


func _get_canonical_category_names(category_labels: Dictionary) -> Array[String]:
    var category_values: Array[int] = []
    for category_value_variant in category_labels.keys():
        category_values.append(int(category_value_variant))
    category_values.sort()

    var category_names: Array[String] = []
    for category_value in category_values:
        var category_name := String(category_labels.get(category_value, "Other"))
        if category_names.has(category_name):
            continue
        category_names.append(category_name)
    return category_names


func get_scale_property_name(config: BuildingConfig, category_labels: Dictionary, scale_property_prefix: String) -> String:
    var category_name := String(category_labels.get(int(config.building_category), "Other"))
    return "%s%s/%s [%s]" % [scale_property_prefix, category_name, config.display_name, String(config.building_id).to_lower()]


func get_building_id_from_scale_property(property_name: String) -> String:
    var bracket_start := property_name.rfind("[")
    var bracket_end := property_name.rfind("]")
    if bracket_start == -1 or bracket_end == -1 or bracket_end <= bracket_start:
        return ""
    return property_name.substr(bracket_start + 1, bracket_end - bracket_start - 1).to_lower()
