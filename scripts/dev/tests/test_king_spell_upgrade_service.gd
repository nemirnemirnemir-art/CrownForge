extends SceneTree

const SpellUpgradeServiceScript := preload("res://core/king_spell/SpellUpgradeService.gd")

var _failed: bool = false


class FakeEconomyCore:
	extends RefCounted

	var gold: int = 0
	var refunded_gold: float = 0.0

	func can_afford(amount: float) -> bool:
		return gold >= int(amount)

	func spend_gold(amount: float) -> bool:
		var required := int(amount)
		if gold < required:
			return false
		gold -= required
		return true

	func add_gold(amount: float) -> void:
		if amount <= 0.0:
			return
		refunded_gold += amount
		gold += int(amount)


class FakeResourceCore:
	extends RefCounted

	var values: Dictionary = {}
	var failing_resource_id: String = ""
	var refunded_resources: Dictionary = {}

	func get_resource(resource_id: String) -> int:
		return int(values.get(resource_id, 0))

	func consume_resource(resource_id: String, amount: int) -> bool:
		if resource_id == failing_resource_id:
			return false
		var owned := get_resource(resource_id)
		if owned < amount:
			return false
		values[resource_id] = owned - amount
		return true

	func add_resource(resource_id: String, amount: int) -> void:
		if amount <= 0:
			return
		values[resource_id] = get_resource(resource_id) + amount
		refunded_resources[resource_id] = int(refunded_resources.get(resource_id, 0)) + amount


func _init() -> void:
	call_deferred("_run_test")


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error("[test_king_spell_upgrade_service] %s" % message)
	quit(1)


func _assert_true(value: bool, message: String) -> void:
	if not value:
		_fail(message)


func _assert_false(value: bool, message: String) -> void:
	if value:
		_fail(message)


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		_fail("%s (expected: %s, got: %s)" % [message, expected, actual])


func _run_test() -> void:
	var service: Variant = SpellUpgradeServiceScript.new()
	_test_default_upgrade_rules(service)
	if _failed:
		return
	_test_cost_progression(service)
	if _failed:
		return
	_test_purchase_guards(service)
	if _failed:
		return
	_test_purchase_rolls_back_partial_spending(service)
	if _failed:
		return
	_test_purchase_success(service)
	if _failed:
		return
	print("[test_king_spell_upgrade_service] PASS")
	quit(0)


func _test_default_upgrade_rules(service: RefCounted) -> void:
	_assert_equal(int(service.get_max_active_upgrade_level()), 4, "SpellUpgradeService must own the max active upgrade level")
	_assert_equal(service.get_active_upgrade_costs(), [
		{"gold": 250},
		{"crystal": 150, "clay": 150, "grapes": 100, "wine": 100},
		{"flour": 200, "metal": 200},
		{"meat": 250, "fuel": 150},
	], "SpellUpgradeService must own the canonical active upgrade costs")
	var costs: Array = service.get_active_upgrade_costs()
	costs[0] = {"gold": 1}
	_assert_equal(service.get_active_upgrade_costs(), [
		{"gold": 250},
		{"crystal": 150, "clay": 150, "grapes": 100, "wine": 100},
		{"flour": 200, "metal": 200},
		{"meat": 250, "fuel": 150},
	], "SpellUpgradeService must return defensive copies of default upgrade costs")


func _test_cost_progression(service: RefCounted) -> void:
	var max_active_upgrade_level := int(service.get_max_active_upgrade_level())
	var active_upgrade_costs: Array = service.get_active_upgrade_costs()
	_assert_true(service.can_upgrade_active_spells(0, max_active_upgrade_level), "Level 0 must still be upgradeable")
	_assert_equal(service.get_next_upgrade_cost(0, max_active_upgrade_level, active_upgrade_costs), {"gold": 250}, "Level 0 next upgrade cost must stay unchanged")
	_assert_equal(service.get_next_upgrade_cost(1, max_active_upgrade_level, active_upgrade_costs), {"crystal": 150, "clay": 150, "grapes": 100, "wine": 100}, "Level 1 next upgrade cost must stay unchanged")
	_assert_equal(service.get_next_upgrade_cost(2, max_active_upgrade_level, active_upgrade_costs), {"flour": 200, "metal": 200}, "Level 2 next upgrade cost must stay unchanged")
	_assert_equal(service.get_next_upgrade_cost(3, max_active_upgrade_level, active_upgrade_costs), {"meat": 250, "fuel": 150}, "Level 3 next upgrade cost must stay unchanged")
	_assert_false(service.can_upgrade_active_spells(4, max_active_upgrade_level), "Level 4 must still be maxed out")
	_assert_equal(service.get_next_upgrade_cost(4, max_active_upgrade_level, active_upgrade_costs), {}, "Maxed-out upgrades must not have a next cost")


func _test_purchase_guards(service: RefCounted) -> void:
	var max_active_upgrade_level := int(service.get_max_active_upgrade_level())
	var active_upgrade_costs: Array = service.get_active_upgrade_costs()
	var economy := FakeEconomyCore.new()
	economy.gold = 249
	var resources := FakeResourceCore.new()
	var gold_result: Dictionary = service.try_purchase_active_upgrade(0, max_active_upgrade_level, active_upgrade_costs, economy, resources)
	_assert_false(bool(gold_result.get("purchased", false)), "Purchase must fail when gold is insufficient")
	_assert_equal(int(gold_result.get("next_level", -1)), 0, "Failed gold purchase must not change upgrade level")
	_assert_equal(economy.gold, 249, "Failed gold purchase must not spend any gold")

	resources.values = {"crystal": 150, "clay": 150, "grapes": 99, "wine": 100}
	var resource_result: Dictionary = service.try_purchase_active_upgrade(1, max_active_upgrade_level, active_upgrade_costs, economy, resources)
	_assert_false(bool(resource_result.get("purchased", false)), "Purchase must fail when any required resource is missing")
	_assert_equal(int(resource_result.get("next_level", -1)), 1, "Failed resource purchase must not change upgrade level")
	_assert_equal(resources.get_resource("crystal"), 150, "Failed resource purchase must not consume already-owned materials")
	_assert_equal(resources.get_resource("grapes"), 99, "Failed resource purchase must not consume partial materials")


func _test_purchase_rolls_back_partial_spending(service: RefCounted) -> void:
	var economy := FakeEconomyCore.new()
	economy.gold = 10
	var resources := FakeResourceCore.new()
	resources.values = {"crystal": 5, "clay": 4}
	resources.failing_resource_id = "clay"
	var rollback_costs: Array = [
		{"gold": 10, "crystal": 5, "clay": 4}
	]

	var result: Dictionary = service.try_purchase_active_upgrade(0, 1, rollback_costs, economy, resources)

	_assert_false(bool(result.get("purchased", false)), "Purchase must fail when a later debit errors after earlier debits succeeded")
	_assert_equal(int(result.get("next_level", -1)), 0, "Rolled-back purchase must keep the previous upgrade level")
	_assert_equal(economy.gold, 10, "Rolled-back purchase must restore spent gold")
	_assert_equal(economy.refunded_gold, 10.0, "Rolled-back purchase must refund exactly the spent gold amount")
	_assert_equal(resources.get_resource("crystal"), 5, "Rolled-back purchase must restore earlier consumed resources")
	_assert_equal(int(resources.refunded_resources.get("crystal", 0)), 5, "Rolled-back purchase must refund each earlier consumed resource once")
	_assert_equal(resources.get_resource("clay"), 4, "Failed debit target must remain unchanged after rollback")


func _test_purchase_success(service: RefCounted) -> void:
	var max_active_upgrade_level := int(service.get_max_active_upgrade_level())
	var active_upgrade_costs: Array = service.get_active_upgrade_costs()
	var economy := FakeEconomyCore.new()
	economy.gold = 300
	var resources := FakeResourceCore.new()

	var first_result: Dictionary = service.try_purchase_active_upgrade(0, max_active_upgrade_level, active_upgrade_costs, economy, resources)
	_assert_true(bool(first_result.get("purchased", false)), "Level 0 purchase must succeed when gold is sufficient")
	_assert_equal(int(first_result.get("next_level", -1)), 1, "Successful gold purchase must increment the upgrade level")
	_assert_equal(economy.gold, 50, "Successful gold purchase must spend the same amount as before")

	resources.values = {"crystal": 150, "clay": 150, "grapes": 100, "wine": 100}
	var second_result: Dictionary = service.try_purchase_active_upgrade(1, max_active_upgrade_level, active_upgrade_costs, economy, resources)
	_assert_true(bool(second_result.get("purchased", false)), "Level 1 purchase must succeed when all materials are available")
	_assert_equal(int(second_result.get("next_level", -1)), 2, "Successful material purchase must increment the upgrade level")
	_assert_equal(resources.get_resource("crystal"), 0, "Successful material purchase must consume crystal")
	_assert_equal(resources.get_resource("clay"), 0, "Successful material purchase must consume clay")
	_assert_equal(resources.get_resource("grapes"), 0, "Successful material purchase must consume grapes")
	_assert_equal(resources.get_resource("wine"), 0, "Successful material purchase must consume wine")
