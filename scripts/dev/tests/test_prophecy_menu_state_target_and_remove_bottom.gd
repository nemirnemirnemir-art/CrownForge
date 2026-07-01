extends SceneTree

const ProphecyMenuStateScript := preload("res://scripts/ui/prophecy/modules/ProphecyMenuState.gd")

func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var state := ProphecyMenuStateScript.new() as ProphecyMenuState
	if state == null:
		push_error("[test_prophecy_menu_state_target_and_remove_bottom] failed to instantiate ProphecyMenuState")
		quit(1)
		return

	state.setup()
	state.reset(null, 1, 1)

	if state.get_target_slot_index() != 1:
		push_error("[test_prophecy_menu_state_target_and_remove_bottom] expected first unlocked target slot to be 1, got %d" % state.get_target_slot_index())
		quit(1)
		return

	var hard_1 := _make_pattern(ProphecyPattern.DifficultyTier.HARD)
	var mid_1 := _make_pattern(ProphecyPattern.DifficultyTier.MID)
	var easy_1 := _make_pattern(ProphecyPattern.DifficultyTier.EASY)
	var hard_2 := _make_pattern(ProphecyPattern.DifficultyTier.HARD)

	var placed_index := state.try_add_pattern_to_best_slot(1, [hard_1])
	if placed_index != 1:
		push_error("[test_prophecy_menu_state_target_and_remove_bottom] hard should be placed into preferred slot 1, got %d" % placed_index)
		quit(1)
		return

	if not state.try_add_pattern_to_slot(1, [mid_1]):
		push_error("[test_prophecy_menu_state_target_and_remove_bottom] failed to add mid pattern to slot 1")
		quit(1)
		return

	if not state.try_add_pattern_to_slot(1, [easy_1]):
		push_error("[test_prophecy_menu_state_target_and_remove_bottom] failed to add easy pattern to slot 1")
		quit(1)
		return

	var removed := state.remove_bottom_pattern_from_slot(1)
	if removed != easy_1:
		push_error("[test_prophecy_menu_state_target_and_remove_bottom] expected bottom-most pattern removal to return the last added pattern")
		quit(1)
		return

	if state.selected[1].size() != 2:
		push_error("[test_prophecy_menu_state_target_and_remove_bottom] expected slot 1 size to become 2 after bottom removal, got %d" % state.selected[1].size())
		quit(1)
		return

	placed_index = state.try_add_pattern_to_best_slot(1, [hard_2])
	if placed_index != 2:
		push_error("[test_prophecy_menu_state_target_and_remove_bottom] invalid preferred slot should fall back to slot 2, got %d" % placed_index)
		quit(1)
		return

	print("[test_prophecy_menu_state_target_and_remove_bottom] PASS")
	quit(0)


func _make_pattern(tier: int) -> ProphecyPattern:
	var pattern := ProphecyPattern.new()
	pattern.difficulty_tier = tier
	pattern.mob_1_id = "goblin_bandit"
	pattern.mob_1_count = 1
	return pattern
