extends SceneTree

const BuildingConfigScript := preload("res://core/buildings/BuildingConfig.gd")
const BuildingScaleInspectorScript := preload("res://core/buildings/BuildingScaleInspector.gd")
const SCALE_PROPERTY_PREFIX := "Placed Building Scale/"
const CATEGORY_LABELS := {
	int(BuildingConfigScript.BuildingCategory.BASIC_PRODUCTION): "Basic Production",
	int(BuildingConfigScript.BuildingCategory.ESTABLISHED_PRODUCTION): "Established Production",
	int(BuildingConfigScript.BuildingCategory.ADVANCED_PRODUCTION): "Advanced Production",
	int(BuildingConfigScript.BuildingCategory.LEVY_BARRACKS): "Levy Barracks",
	int(BuildingConfigScript.BuildingCategory.VETERAN_BARRACKS): "Veteran Barracks",
	int(BuildingConfigScript.BuildingCategory.ELITE_BARRACKS): "Elite Barracks",
	int(BuildingConfigScript.BuildingCategory.KINGDOM_INFRASTRUCTURE): "Kingdom Infrastructure",
	int(BuildingConfigScript.BuildingCategory.OTHER): "Other",
}


class RefreshCounter:
	extends RefCounted

	var calls: int = 0

	func bump() -> void:
		calls += 1


class RegistryHarness:
	extends RefCounted

	func is_disabled_building_id(building_id: String) -> bool:
		return false

	func is_rollout_filtered_out(_config: BuildingConfig) -> bool:
		return false


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var inspector = BuildingScaleInspectorScript.new()
	var registry := RegistryHarness.new()
	var counter := RefreshCounter.new()
	var buildings: Array[BuildingConfig] = []
	var buddhist_temple := _make_building(
		"buddhist_temple",
		"Buddhist Temple",
		BuildingConfigScript.BuildingCategory.KINGDOM_INFRASTRUCTURE
	)
	var house := _make_building(
		"house",
		"House",
		BuildingConfigScript.BuildingCategory.BASIC_PRODUCTION
	)
	var tavern := _make_building(
		"tavern",
		"Tavern",
		BuildingConfigScript.BuildingCategory.KINGDOM_INFRASTRUCTURE
	)
	buildings = [tavern, null, house, buddhist_temple]

	var grouped: Dictionary = inspector.get_buildings_grouped_for_scale_inspector(buildings, Callable(registry, "is_disabled_building_id"), Callable(registry, "is_rollout_filtered_out"), CATEGORY_LABELS)
	var infra: Array = grouped.get("Kingdom Infrastructure", [])
	if infra.size() != 2:
		_fail("expected 2 infra buildings, got %d" % infra.size())
		return
	if (infra[0] as BuildingConfig).display_name != "Buddhist Temple":
		_fail("expected grouped buildings to be sorted by display name")
		return

	var property_list: Array[Dictionary] = inspector.build_property_list(buildings, Callable(registry, "is_disabled_building_id"), Callable(registry, "is_rollout_filtered_out"), CATEGORY_LABELS, SCALE_PROPERTY_PREFIX)
	if property_list.is_empty():
		_fail("expected property list entries for scale inspector")
		return
	if String(property_list[0].get("name", "")) != "Placed Building Scale":
		_fail("expected top-level scale group property")
		return

	var subgroup_names := _collect_subgroup_names(property_list)
	if subgroup_names != ["Basic Production/", "Kingdom Infrastructure/"]:
		_fail("expected canonical subgroup ordering, got %s" % str(subgroup_names))
		return

	var reordered_buildings: Array[BuildingConfig] = [house, buddhist_temple, tavern]
	var reordered_property_list: Array[Dictionary] = inspector.build_property_list(reordered_buildings, Callable(registry, "is_disabled_building_id"), Callable(registry, "is_rollout_filtered_out"), CATEGORY_LABELS, SCALE_PROPERTY_PREFIX)
	var reordered_subgroup_names := _collect_subgroup_names(reordered_property_list)
	if reordered_subgroup_names != subgroup_names:
		_fail("expected subgroup ordering to stay stable across building array order, got %s" % str(reordered_subgroup_names))
		return

	var buddhist_property: String = inspector.get_scale_property_name(buddhist_temple, CATEGORY_LABELS, SCALE_PROPERTY_PREFIX)
	var house_property: String = inspector.get_scale_property_name(house, CATEGORY_LABELS, SCALE_PROPERTY_PREFIX)
	if inspector.get_building_id_from_scale_property(buddhist_property) != "buddhist_temple":
		_fail("expected property name to round-trip building id")
		return

	var overrides := {"house": 1.75}
	if not is_equal_approx(float(inspector.read_scale_property_value(StringName(house_property), overrides, buildings, CATEGORY_LABELS, SCALE_PROPERTY_PREFIX)), 1.75):
		_fail("expected get_value to read explicit override")
		return
	if not is_equal_approx(float(inspector.read_scale_property_value(StringName(buddhist_property), overrides, buildings, CATEGORY_LABELS, SCALE_PROPERTY_PREFIX)), 1.3):
		_fail("expected get_value to use default buddhist temple scale")
		return

	var refreshed: bool = inspector.write_scale_property_value(StringName(house_property), 1.0, overrides, buildings, CATEGORY_LABELS, SCALE_PROPERTY_PREFIX, Callable(counter, "bump"))
	if not refreshed:
		_fail("expected set_value to handle scale property")
		return
	if overrides.has("house"):
		_fail("expected default scale assignment to clear override")
		return
	if counter.calls != 1:
		_fail("expected clearing override to trigger property refresh callback once")
		return

	counter.calls = 0
	var set_override: bool = inspector.write_scale_property_value(StringName(buddhist_property), 2.25, overrides, buildings, CATEGORY_LABELS, SCALE_PROPERTY_PREFIX, Callable(counter, "bump"))
	if not set_override:
		_fail("expected set_value to accept override assignment")
		return
	if not is_equal_approx(float(overrides.get("buddhist_temple", 0.0)), 2.25):
		_fail("expected override dictionary to be updated")
		return
	if counter.calls != 1:
		_fail("expected setting override to trigger property refresh callback once")
		return

	print("[test_building_scale_inspector] PASS")
	quit(0)
func _make_building(building_id: String, display_name: String, category: int) -> BuildingConfig:
	var config := BuildingConfigScript.new()
	config.building_id = building_id
	config.display_name = display_name
	config.building_category = category
	return config


func _collect_subgroup_names(property_list: Array[Dictionary]) -> Array[String]:
	var subgroup_names: Array[String] = []
	for property in property_list:
		if int(property.get("usage", 0)) != PROPERTY_USAGE_SUBGROUP:
			continue
		subgroup_names.append(String(property.get("name", "")))
	return subgroup_names


func _fail(message: String) -> void:
	push_error("[test_building_scale_inspector] %s" % message)
	quit(1)
