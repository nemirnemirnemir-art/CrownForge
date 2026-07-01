extends SceneTree

const ProphecyMenuStateScript := preload("res://scripts/ui/prophecy/modules/ProphecyMenuState.gd")
const ProphecyPatternScript := preload("res://scripts/resources/ProphecyPattern.gd")


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var state = ProphecyMenuStateScript.new()
	state.setup()
	state.reset(null, 1, 0)

	state.selected[0] = [_make_pattern(ProphecyPattern.DifficultyTier.EASY)]
	state.selected[1] = []
	state.selected[2] = []
	if state.can_continue():
		push_error("[test_prophecy_continue_requires_easy] must not continue when any unlocked slot lacks EASY")
		quit(1)
		return

	state.selected[1] = [_make_pattern(ProphecyPattern.DifficultyTier.EASY)]
	state.selected[2] = [_make_pattern(ProphecyPattern.DifficultyTier.EASY)]
	if not state.can_continue():
		push_error("[test_prophecy_continue_requires_easy] must continue when all unlocked slots have EASY")
		quit(1)
		return

	state.reset(null, 1, 1)
	state.selected[0] = []
	state.selected[1] = [_make_pattern(ProphecyPattern.DifficultyTier.EASY)]
	state.selected[2] = []
	if state.can_continue():
		push_error("[test_prophecy_continue_requires_easy] must not continue when unlocked slot 2 lacks EASY even if slot 0 is locked")
		quit(1)
		return

	state.selected[2] = [_make_pattern(ProphecyPattern.DifficultyTier.EASY)]
	if not state.can_continue():
		push_error("[test_prophecy_continue_requires_easy] must continue when every unlocked slot has EASY and locked slot is ignored")
		quit(1)
		return

	print("[test_prophecy_continue_requires_easy] PASS")
	quit(0)


func _make_pattern(tier: int) -> ProphecyPattern:
	var pattern := ProphecyPatternScript.new() as ProphecyPattern
	pattern.difficulty_tier = tier
	pattern.mob_1_id = "goblin_bandit"
	pattern.mob_1_count = 1
	return pattern
