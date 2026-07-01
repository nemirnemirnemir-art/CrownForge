extends SceneTree

const MarketUIScene := preload("res://scenes/ui/town/MarketUI.tscn")
const MarketUIScript := preload("res://scripts/ui/town/MarketUI.gd")
const MapSlotMarketScript := preload("res://scripts/map_slot/MapSlotMarket.gd")

var _failed: bool = false


func _init() -> void:
	call_deferred("_run_test")


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error("[test_market_ui_artifact_unlocks] %s" % message)
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
	var root := Control.new()
	get_root().add_child(root)

	var artifact_core := get_root().get_node_or_null("ArtifactCore")
	if artifact_core == null:
		_fail("ArtifactCore autoload must exist for market unlock test")
		return
	if artifact_core.has_method("reset"):
		artifact_core.call("reset")

	var ui: MarketUIScript = MarketUIScene.instantiate() as MarketUIScript
	root.add_child(ui)
	await process_frame

	var default_trade_ids := _collect_trade_ids(ui)
	_assert_true(default_trade_ids == ["", "wheat", "iron_ore", "flour", "steel"], "default market UI must only expose the base trade set")
	if _failed:
		return

	var market := MapSlotMarketScript.new()
	_assert_false(bool(market.call("has_trade_rate", "clay")), "market runtime must not expose clay trade before suspicious_pile")
	if _failed:
		return

	artifact_core.call("add_artifact", "suspicious_pile", true)
	ui.call("_setup_buttons")

	var unlocked_trade_ids := _collect_trade_ids(ui)
	_assert_true(unlocked_trade_ids.has("clay"), "suspicious_pile must unlock clay trade in market UI")
	if _failed:
		return
	_assert_true(unlocked_trade_ids.has("grapes"), "suspicious_pile must unlock grapes trade in market UI")
	if _failed:
		return
	_assert_true(unlocked_trade_ids.has("crystal"), "suspicious_pile must unlock crystal trade in market UI")
	if _failed:
		return

	_assert_true(bool(market.call("has_trade_rate", "clay")), "market runtime must expose clay trade after suspicious_pile")
	if _failed:
		return
	_assert_true(bool(market.call("has_trade_rate", "grapes")), "market runtime must expose grapes trade after suspicious_pile")
	if _failed:
		return
	_assert_true(bool(market.call("has_trade_rate", "crystal")), "market runtime must expose crystal trade after suspicious_pile")
	if _failed:
		return

	var clay_rate: Dictionary = market.call("get_trade_rate", "clay")
	_assert_equal(String(clay_rate.get("id", "")), "gold", "extended market trade must still convert into gold")
	if _failed:
		return
	_assert_equal(int(clay_rate.get("amount", 0)), 1, "extended market clay trade must use the default 1-to-1 gold rate")
	if _failed:
		return

	print("[test_market_ui_artifact_unlocks] PASS")
	quit(0)


func _collect_trade_ids(ui: MarketUIScript) -> Array[String]:
	var ids: Array[String] = []
	for child in ui._row.get_children():
		var button := child as Button
		if button == null:
			continue
		ids.append(String(button.get_meta("trade_id", "")))
	return ids
