extends RefCounted
class_name BuildingUpgradeNeighbourBoost

## Handles the sawmill Friendly Lumberjacks neighbour production boost.
## Provides +20% production to 4 orthogonal neighbour tiles.

const SAWMILL_NEIGHBOUR_UPGRADE_ID: String = "sawmill:1"
const NEIGHBOUR_BOOST_MULTIPLIER: float = 1.2
const ORTHOGONAL_OFFSETS: Array[Vector2i] = [
	Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)
]


static func get_neighbour_boost_multiplier(
	slot_grid_pos: Vector2i,
	all_slots_by_grid_pos: Dictionary,
	has_building_upgrade_func: Callable
) -> float:
	## Returns the combined neighbour boost multiplier for a slot at the given grid position.
	## Checks all 4 orthogonal neighbours for sawmills with the Friendly Lumberjacks upgrade.
	var multiplier := 1.0
	for offset: Vector2i in ORTHOGONAL_OFFSETS:
		var neighbour_pos := slot_grid_pos + offset
		var neighbour_data: Variant = all_slots_by_grid_pos.get(neighbour_pos, null)
		if neighbour_data == null or not (neighbour_data is Dictionary):
			continue
		var neighbour_building_id := String((neighbour_data as Dictionary).get("building_id", ""))
		if neighbour_building_id != "sawmill":
			continue
		if not has_building_upgrade_func.call("sawmill", SAWMILL_NEIGHBOUR_UPGRADE_ID):
			continue
		var is_active: bool = bool((neighbour_data as Dictionary).get("is_vzor_active", false))
		if not is_active:
			continue
		multiplier *= NEIGHBOUR_BOOST_MULTIPLIER
	return multiplier
