extends SceneTree

const BuildingsTooltipScene := preload("res://scenes/ui/town/BuildingsTooltip.tscn")
const TARGET_BUILDING_ID := "basic_construction"


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var economy_core := get_root().get_node_or_null("EconomyCore")
	var resource_core := get_root().get_node_or_null("ResourceCore")
	if economy_core and economy_core.has_method("reset_progress"):
		economy_core.call("reset_progress")
		economy_core.call("add_gold", 47.0)
	if resource_core and resource_core.has_method("reset"):
		resource_core.call("reset")

	var tooltip := BuildingsTooltipScene.instantiate() as Control
	if tooltip == null:
		push_error("[test_buildings_tooltip_gold_cost_uses_economy_gold] failed to instantiate tooltip")
		quit(1)
		return

	get_root().add_child(tooltip)
	await process_frame
	tooltip.call("show_building", TARGET_BUILDING_ID)
	await process_frame
	await process_frame

	var costs := tooltip.get_node_or_null("Margin/VBox/NextCostList") as VBoxContainer
	if costs == null or costs.get_child_count() == 0:
		push_error("[test_buildings_tooltip_gold_cost_uses_economy_gold] tooltip did not build cost rows")
		quit(1)
		return

	var first_row := costs.get_child(0) as HBoxContainer
	var value_label := first_row.get_node_or_null("ValueLabel") as Label if first_row else null
	if value_label == null:
		push_error("[test_buildings_tooltip_gold_cost_uses_economy_gold] missing value label")
		quit(1)
		return

	if value_label.text != "47 / 10":
		push_error("[test_buildings_tooltip_gold_cost_uses_economy_gold] expected economy gold in building tooltip, got %s" % value_label.text)
		quit(1)
		return

	print("[test_buildings_tooltip_gold_cost_uses_economy_gold] PASS")
	quit(0)
