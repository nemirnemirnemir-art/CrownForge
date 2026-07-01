extends RefCounted
class_name BuildingUpgradeAuditHarness

## Shared audit infrastructure: mock upgrade state + resource tracking + assertions.

var _unlocked_upgrades: Dictionary = {}
var _resources_added: Array[Dictionary] = []
var _castle_repaired: int = 0
var _extra_units_hired: Array[String] = []
var _errors: Array[String] = []

func unlock_upgrade(upgrade_id: String) -> void:
	_unlocked_upgrades[upgrade_id] = true

func clear_state() -> void:
	_unlocked_upgrades.clear()
	_resources_added.clear()
	_castle_repaired = 0
	_extra_units_hired.clear()

func has_building_upgrade(_building_id: String, upgrade_id: String) -> bool:
	return _unlocked_upgrades.has(upgrade_id)

func mock_add_resource(resource_id: String, amount: int) -> void:
	_resources_added.append({"resource_id": resource_id, "amount": amount})

func mock_repair_castle(amount: int) -> void:
	_castle_repaired += amount

func mock_hire_extra(unit_id: String) -> String:
	_extra_units_hired.append(unit_id)
	return "mock_hero_%d" % _extra_units_hired.size()

func get_add_resource_callable() -> Callable:
	return mock_add_resource

func get_repair_castle_callable() -> Callable:
	return mock_repair_castle

func get_hire_extra_callable() -> Callable:
	return mock_hire_extra

func get_has_upgrade_callable() -> Callable:
	return has_building_upgrade

func assert_float_eq(actual: float, expected: float, label: String, tolerance: float = 0.001) -> bool:
	if absf(actual - expected) > tolerance:
		_errors.append("%s: expected %.4f, got %.4f" % [label, expected, actual])
		return false
	return true

func assert_int_eq(actual: int, expected: int, label: String) -> bool:
	if actual != expected:
		_errors.append("%s: expected %d, got %d" % [label, expected, actual])
		return false
	return true

func assert_true(condition: bool, label: String) -> bool:
	if not condition:
		_errors.append("%s: expected true, got false" % label)
		return false
	return true

func assert_not_empty(arr: Array, label: String) -> bool:
	if arr.is_empty():
		_errors.append("%s: expected non-empty array" % label)
		return false
	return true

func get_errors() -> Array[String]:
	return _errors

func has_errors() -> bool:
	return not _errors.is_empty()
