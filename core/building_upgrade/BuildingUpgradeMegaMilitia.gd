## BuildingUpgradeMegaMilitia
## Tracks a GLOBAL counter of militia produced from any militia_camp building.
## After every 4 base militia, the next production yields a mega_militia instead.
##
## Design decisions:
##   - Counter is global across all militia_camp buildings (confirmed)
##   - Upgrade id: militia_camp:2
##   - Base unit: "militia", mega unit: "mega_militia"
##   - Cycle: produce 4 militia → 5th is mega_militia → reset → repeat
##   - Counter persists across save/load

const UPGRADE_ID := "militia_camp:2"
const BUILDING_ID := "militia_camp"
const BASE_UNIT_ID := "militia"
const MEGA_UNIT_ID := "mega_militia"
const TRIGGER_EVERY := 4


## Check if the mega militia upgrade is active and determine which unit to produce.
## Returns the unit_id to use: either MEGA_UNIT_ID or the original produced_unit_id.
## Also increments the counter when a base militia is produced.
## The counter_dict MUST be passed by reference (a Dictionary with "count": int).
static func resolve_produced_unit(
		building_id: String,
		produced_unit_id: String,
		counter_dict: Dictionary,
		has_upgrade_func: Callable
) -> String:
	# Only applies to militia_camp producing militia
	if building_id != BUILDING_ID:
		return produced_unit_id
	if produced_unit_id != BASE_UNIT_ID:
		return produced_unit_id
	if not has_upgrade_func.is_valid():
		return produced_unit_id
	if not has_upgrade_func.call(BUILDING_ID, UPGRADE_ID):
		return produced_unit_id

	var current_count: int = int(counter_dict.get("count", 0))
	if current_count >= TRIGGER_EVERY:
		# This production is the mega one — reset counter
		counter_dict["count"] = 0
		return MEGA_UNIT_ID
	else:
		# Increment counter, produce normal militia
		counter_dict["count"] = current_count + 1
		return produced_unit_id


## Get the current counter value for save/load.
static func get_counter(counter_dict: Dictionary) -> int:
	return int(counter_dict.get("count", 0))


## Restore counter from saved data.
static func set_counter(counter_dict: Dictionary, value: int) -> void:
	counter_dict["count"] = maxi(value, 0)
