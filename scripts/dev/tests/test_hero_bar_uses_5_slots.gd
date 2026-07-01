extends SceneTree

const HeroBarScene := preload("res://scenes/ui/hud/HeroBar.tscn")
const EXPECTED_SLOT_COUNT := 5
const EXPECTED_COLUMNS := 5
const EXPECTED_SLOT_SIZE := Vector2(96, 96)

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var hero_bar := HeroBarScene.instantiate() as Control
	if hero_bar == null:
		push_error("[test_hero_bar_uses_5_slots] failed to instantiate HeroBar")
		quit(1)
		return

	get_root().add_child(hero_bar)
	await process_frame

	var slots_grid := hero_bar.get_node_or_null("NavigationContainer/SlotsGrid") as GridContainer
	if slots_grid == null:
		push_error("[test_hero_bar_uses_5_slots] SlotsGrid not found")
		quit(1)
		return

	if slots_grid.columns != EXPECTED_COLUMNS:
		push_error("[test_hero_bar_uses_5_slots] expected %d columns, got %d" % [EXPECTED_COLUMNS, slots_grid.columns])
		quit(1)
		return

	var actual_slot_count := slots_grid.get_child_count()
	if actual_slot_count != EXPECTED_SLOT_COUNT:
		push_error("[test_hero_bar_uses_5_slots] expected %d slots, got %d" % [EXPECTED_SLOT_COUNT, actual_slot_count])
		quit(1)
		return

	for child in slots_grid.get_children():
		var slot := child as TextureButton
		if slot == null:
			continue
		if slot.custom_minimum_size != EXPECTED_SLOT_SIZE:
			push_error("[test_hero_bar_uses_5_slots] expected square slot size %s, got %s" % [EXPECTED_SLOT_SIZE, slot.custom_minimum_size])
			quit(1)
			return

	print("[test_hero_bar_uses_5_slots] PASS")
	quit(0)
