extends SceneTree

const MainUIButtonFlowScript := preload("res://scripts/ui/hud/MainUIButtonFlow.gd")
const ScaleButtonScript := preload("res://scripts/ui/widgets/ScaleButton.gd")


class CallbackHost:
	extends RefCounted

	func on_test_gold() -> void:
		pass

	func on_mine() -> void:
		pass

	func on_perks() -> void:
		pass

	func on_forge() -> void:
		pass

	func on_inventory() -> void:
		pass

	func on_alchemy() -> void:
		pass


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = MainUIButtonFlowScript.new()
	if flow == null:
		push_error("[test_mainui_button_flow] failed to instantiate helper")
		quit(1)
		return

	var host := CallbackHost.new()
	var test_gold_button := Button.new()
	var mine_button := ScaleButtonScript.new()
	var forge_button := ScaleButtonScript.new()
	var inventory_button := ScaleButtonScript.new()
	var alchemy_button := ScaleButtonScript.new()

	var grid := Control.new()
	mine_button.name = "MineButton"
	grid.add_child(mine_button)
	var perks := ScaleButtonScript.new()
	perks.name = "PerksTestButton"
	grid.add_child(perks)
	var test_grid := Button.new()
	test_grid.name = "TestGoldButton"
	grid.add_child(test_grid)

	flow.connect_buttons(
		test_gold_button,
		mine_button,
		grid,
		forge_button,
		inventory_button,
		alchemy_button,
		{
			"test_gold": Callable(host, "on_test_gold"),
			"mine": Callable(host, "on_mine"),
			"perks": Callable(host, "on_perks"),
			"forge": Callable(host, "on_forge"),
			"inventory": Callable(host, "on_inventory"),
			"alchemy": Callable(host, "on_alchemy"),
		}
	)

	if not test_gold_button.pressed.is_connected(Callable(host, "on_test_gold")):
		push_error("[test_mainui_button_flow] test gold button should be connected")
		quit(1)
		return
	if not mine_button.pressed.is_connected(Callable(host, "on_mine")):
		push_error("[test_mainui_button_flow] mine button should be connected")
		quit(1)
		return
	var perks_button := grid.get_node_or_null("PerksTestButton") as BaseButton
	if perks_button == null or not perks_button.pressed.is_connected(Callable(host, "on_perks")):
		push_error("[test_mainui_button_flow] perks button should be connected")
		quit(1)
		return
	if not forge_button.pressed.is_connected(Callable(host, "on_forge")):
		push_error("[test_mainui_button_flow] forge button should be connected")
		quit(1)
		return
	if not inventory_button.pressed.is_connected(Callable(host, "on_inventory")):
		push_error("[test_mainui_button_flow] inventory button should be connected")
		quit(1)
		return
	if not alchemy_button.pressed.is_connected(Callable(host, "on_alchemy")):
		push_error("[test_mainui_button_flow] alchemy button should be connected")
		quit(1)
		return

	for button_name in ["MineButton", "PerksTestButton", "TestGoldButton"]:
		var button := grid.get_node_or_null(button_name) as BaseButton
		if button == null or button.visible or button.process_mode != Node.PROCESS_MODE_DISABLED:
			push_error("[test_mainui_button_flow] debug button gating mismatch for %s" % button_name)
			quit(1)
			return

	print("[test_mainui_button_flow] PASS")
	quit(0)
