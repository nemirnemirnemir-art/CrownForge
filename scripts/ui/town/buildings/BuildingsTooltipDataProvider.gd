extends RefCounted
class_name BuildingsTooltipDataProvider

const RESOURCE_DISPLAY_ORDER: Array[String] = [
	"water", "gold", "wood", "clay", "iron_ore", "steel",
	"wheat", "flour", "meat", "grapes", "wine", "oil", "crystal",
]

var _building_registry: Node = null
var _seal_registry: Node = null
var _resource_core: Node = null

func initialize(building_registry: Node, seal_registry: Node, resource_core: Node) -> void:
	_building_registry = building_registry
	_seal_registry = seal_registry
	_resource_core = resource_core

func get_building_data(building_id: String) -> Dictionary:
	if not _building_registry:
		return {}
	var config: BuildingConfig = _building_registry.get_building(building_id)
	if not config:
		return {}

	var produces: Array[Dictionary] = []
	for p in config.produces:
		if p:
			produces.append({"resource_id": p.resource_id, "amount": p.amount})

	var consumes: Array[Dictionary] = []
	for c in config.consumes:
		if c:
			consumes.append({"resource_id": c.resource_id, "amount": c.amount})

	var raw_cost: Dictionary = _building_registry.get_next_build_cost(building_id)
	if raw_cost.is_empty():
		for cost in config.build_costs:
			if cost:
				raw_cost[cost.resource_id] = cost.amount

	var sorted_ids: Array = raw_cost.keys()
	sorted_ids.sort_custom(_sort_resource_ids)

	var build_costs: Array[Dictionary] = []
	for k in sorted_ids:
		build_costs.append({"resource_id": str(k), "amount": raw_cost[k]})

	return {
		"id": config.building_id,
		"display_name": config.display_name,
		"cycle_time": config.cycle_time,
		"building_type": int(config.building_type),
		"produces": produces,
		"consumes": consumes,
		"build_costs": build_costs,
		"max_units": config.max_units,
		"produced_unit_id": str(config.produced_unit_id),
		"description": config.description,
		"markup_percent": _get_markup_percent(building_id),
	}

func get_unit_data(unit_id: String) -> Dictionary:
	return {
		"id": unit_id,
		"display_name": unit_id.replace("_", " "),
	}

func get_resource_amount(res_id: String) -> int:
	if not _resource_core:
		return 0
	return int(_resource_core.get_resource(res_id))

func get_clean_description(desc: String) -> String:
	var lines := desc.split("\n")
	var clean_lines: Array[String] = []
	for line in lines:
		var l := line.to_lower()
		if "cycle" in l or "capacity" in l or "consumes" in l or "requires" in l or "build cost" in l:
			continue
		if line.strip_edges() != "":
			clean_lines.append(line)
	return "\n".join(clean_lines)

func sort_resource_ids(ids: Array) -> Array:
	var sorted := ids.duplicate()
	sorted.sort_custom(_sort_resource_ids)
	return sorted

func _get_markup_percent(building_id: String) -> int:
	if not _building_registry:
		return 0
	if _building_registry.has_method("get_next_build_markup_percent"):
		return int(_building_registry.get_next_build_markup_percent(building_id))
	return 0

func _sort_resource_ids(a: Variant, b: Variant) -> bool:
	var aa := str(a)
	var bb := str(b)
	var ia := RESOURCE_DISPLAY_ORDER.find(aa)
	var ib := RESOURCE_DISPLAY_ORDER.find(bb)
	if ia == -1 and ib == -1:
		return aa < bb
	if ia == -1:
		return false
	if ib == -1:
		return true
	return ia < ib
