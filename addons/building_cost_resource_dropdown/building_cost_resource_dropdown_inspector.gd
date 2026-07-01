@tool
extends EditorInspectorPlugin

const ResourceCoreScript := preload("res://core/resource_core.gd")

func _can_handle(object: Object) -> bool:
	return object != null and object is BuildingCostEntry

func _parse_property(
	object: Object,
	type: Variant.Type,
	name: String,
	hint_type: PropertyHint,
	hint_string: String,
	usage_flags: int,
	wide: bool
) -> bool:
	if name != "resource_id":
		return false

	var editor := preload("res://addons/building_cost_resource_dropdown/resource_id_property_editor.gd").new()
	editor.setup(object)
	add_property_editor(name, editor)
	return true

func _get_resource_ids() -> Array[String]:
	var ids: Array[String] = []
	if ResourceCoreScript:
		var all := ResourceCoreScript.RESOURCE_IDS
		for v in all:
			if v is String:
				ids.append(v)
	ids.sort()
	return ids
