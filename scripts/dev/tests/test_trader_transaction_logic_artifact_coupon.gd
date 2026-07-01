extends SceneTree

const TraderTransactionLogicScript := preload("res://scripts/ui/rewards/modules/TraderTransactionLogic.gd")

var _failed: bool = false


class FakeTile:
	extends Control

	var price: int = 70
	var kind: String = "artifact"
	var payload: Variant = "free_housing"
	var purchased: bool = false

	func set_purchased(value: bool) -> void:
		purchased = value


class FakeEconomyCore:
	extends Node

	var spend_calls: Array[float] = []

	func spend_gold(amount: float) -> bool:
		spend_calls.append(amount)
		return true


class CallbackCounter:
	extends RefCounted

	var count: int = 0

	func call_me() -> void:
		count += 1


func _init() -> void:
	call_deferred("_run_test")


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error("[test_trader_transaction_logic_artifact_coupon] %s" % message)
	quit(1)


func _assert_true(value: bool, message: String) -> void:
	if not value:
		_fail(message)


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		_fail("%s (expected: %s, got: %s)" % [message, expected, actual])


func _run_test() -> void:
	var logic = TraderTransactionLogicScript.new()
	var root := get_root()

	var economy_core := FakeEconomyCore.new()
	economy_core.name = "EconomyCore"
	root.add_child(economy_core)

	var artifact_core := root.get_node_or_null("ArtifactCore")
	if artifact_core == null:
		_fail("ArtifactCore autoload must exist for trader coupon test")
		return
	if artifact_core.has_method("reset"):
		artifact_core.call("reset")
	if artifact_core.has_method("add_artifact"):
		artifact_core.call("add_artifact", "free_coupon", true)
	_assert_true(bool(artifact_core.call("has_trader_free_coupon")), "free_coupon setup must expose an available coupon before purchase")
	if _failed:
		return

	var tile := FakeTile.new()
	var updates := CallbackCounter.new()
	var upgrades := CallbackCounter.new()
	var troops := CallbackCounter.new()

	logic.buy_tile(
		tile,
		economy_core,
		self,
		Callable(updates, "call_me"),
		Callable(upgrades, "call_me"),
		Callable(troops, "call_me"),
		50
	)

	_assert_equal(economy_core.spend_calls.size(), 1, "trader buy must still go through spend check once")
	if _failed:
		return
	_assert_equal(economy_core.spend_calls[0], 0.0, "free coupon must reduce the current trader purchase cost to zero")
	if _failed:
		return
	_assert_true(not bool(artifact_core.call("has_trader_free_coupon")), "free coupon must be consumed on first trader purchase")
	if _failed:
		return
	_assert_true(bool(artifact_core.call("has_artifact", "free_housing")), "artifact purchase payload must still be granted")
	if _failed:
		return

	tile.purchased = false
	tile.price = 70
	logic.buy_tile(
		tile,
		economy_core,
		self,
		Callable(updates, "call_me"),
		Callable(upgrades, "call_me"),
		Callable(troops, "call_me"),
		50
	)

	_assert_equal(economy_core.spend_calls.size(), 2, "second trader purchase must still spend gold normally")
	if _failed:
		return
	_assert_equal(economy_core.spend_calls[1], 70.0, "normal trader price must return after coupon is spent")
	if _failed:
		return
	_assert_true(not bool(artifact_core.call("has_trader_free_coupon")), "coupon must stay exhausted after the free purchase")
	if _failed:
		return

	print("[test_trader_transaction_logic_artifact_coupon] PASS")
	quit(0)
