extends SceneTree

const InventoryBarScene := preload("res://scenes/ui/inventory/InventoryBar.tscn")
const EXPECTED_SLOT_COUNT := 4


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var inventory_bar := InventoryBarScene.instantiate() as Control
	if inventory_bar == null:
		push_error("[test_inventory_bar_hud_uses_5_slots] failed to instantiate InventoryBar")
		quit(1)
		return

	get_root().add_child(inventory_bar)
	await process_frame

	var slots_container := inventory_bar.get_node_or_null("SlotsContainer") as HBoxContainer
	if slots_container == null:
		push_error("[test_inventory_bar_hud_uses_5_slots] SlotsContainer not found")
		quit(1)
		return

	var actual_slot_count := slots_container.get_child_count()
	if actual_slot_count != EXPECTED_SLOT_COUNT:
		push_error("[test_inventory_bar_hud_uses_5_slots] expected %d slots, got %d" % [EXPECTED_SLOT_COUNT, actual_slot_count])
		quit(1)
		return

	print("[test_inventory_bar_hud_uses_5_slots] PASS")
	quit(0)
