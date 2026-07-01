extends SceneTree

const ArtifactTraderBenefitsScript := preload("res://core/artifacts/ArtifactTraderBenefits.gd")

var _failed: bool = false


func _init() -> void:
	call_deferred("_run_test")


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error("[test_artifact_trader_benefits] %s" % message)
	quit(1)


func _assert_true(value: bool, message: String) -> void:
	if not value:
		_fail(message)


func _assert_false(value: bool, message: String) -> void:
	if value:
		_fail(message)


func _run_test() -> void:
	var flow = ArtifactTraderBenefitsScript.new()
	if flow == null:
		_fail("failed to instantiate artifact trader benefits helper")
		return

	var active: Dictionary = {"free_coupon": true}
	var state: Dictionary = {}

	_assert_true(bool(flow.call("has_free_coupon_charge", active, state)), "free_coupon must expose one initial trader discount charge")
	if _failed:
		return

	_assert_true(bool(flow.call("consume_free_coupon_charge", active, state)), "free_coupon charge must be consumable once")
	if _failed:
		return

	_assert_false(bool(flow.call("has_free_coupon_charge", active, state)), "free_coupon charge must be exhausted after one use")
	if _failed:
		return

	_assert_false(bool(flow.call("consume_free_coupon_charge", active, state)), "free_coupon must not provide a second free purchase")
	if _failed:
		return

	_assert_false(bool(flow.call("has_extended_market_trades", {})), "extended market trades must stay locked without suspicious_pile")
	if _failed:
		return

	_assert_true(bool(flow.call("has_extended_market_trades", {"suspicious_pile": true})), "suspicious_pile must unlock extended market trades")
	if _failed:
		return

	print("[test_artifact_trader_benefits] PASS")
	quit(0)
