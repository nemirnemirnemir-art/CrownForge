extends SceneTree

const BuildingConfigScript := preload("res://core/buildings/BuildingConfig.gd")
const BuildingIconResolverScript := preload("res://core/buildings/BuildingIconResolver.gd")


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var resolver = BuildingIconResolverScript.new()

	if resolver.normalize_key(" Wheat Field ") != "wheat_field":
		_fail("expected spaces to normalize to underscores")
		return
	if resolver.normalize_key("IronMine") != "ironmine":
		_fail("expected normalization to preserve current lowercase matching")
		return
	if resolver.normalize_key("gold-mine_active") != "gold_mine_active":
		_fail("expected dashes and underscores to normalize consistently")
		return

	var icon_path_by_key: Dictionary = resolver.scan_building_icons()
	if not icon_path_by_key.has("academy_of_fire"):
		_fail("expected filesystem scan to include academy_of_fire icon")
		return
	if String(icon_path_by_key.get("wheat_field", "")) != "res://assets/environment/buildings/Wheat Field.png":
		_fail("expected normalization to map Wheat Field filename")
		return
	if String(icon_path_by_key.get("ironmine", "")) != "res://assets/environment/buildings/IronMine.png":
		_fail("expected scan to preserve current exact path for IronMine")
		return

	var id_match := BuildingConfigScript.new()
	id_match.building_id = "academy_of_fire"
	id_match.display_name = "Different Name"
	resolver.try_assign_icon_if_missing(id_match, icon_path_by_key)
	if id_match.icon == null:
		_fail("expected icon assignment by normalized building id")
		return

	var name_match := BuildingConfigScript.new()
	name_match.building_id = "missing_icon"
	name_match.display_name = "Wheat Field"
	resolver.try_assign_icon_if_missing(name_match, icon_path_by_key)
	if name_match.icon == null:
		_fail("expected icon assignment fallback by normalized display name")
		return

	var prefilled := BuildingConfigScript.new()
	prefilled.building_id = "academy_of_fire"
	prefilled.display_name = "Academy of Fire"
	prefilled.icon = name_match.icon
	resolver.try_assign_icon_if_missing(prefilled, icon_path_by_key)
	if prefilled.icon != name_match.icon:
		_fail("expected existing icon assignment to stay untouched")
		return

	var missing := BuildingConfigScript.new()
	missing.building_id = "totally_missing"
	missing.display_name = "Totally Missing"
	resolver.try_assign_icon_if_missing(missing, icon_path_by_key)
	if missing.icon != null:
		_fail("expected missing icon assignment to stay null")
		return

	print("[test_building_icon_resolver] PASS")
	quit(0)


func _fail(message: String) -> void:
	push_error("[test_building_icon_resolver] %s" % message)
	quit(1)
