extends SceneTree

const CrowdBuilderScript = preload("res://scripts/dev/ten_kings/TenKingsCrowdBuilder.gd")
const PlayerStateScript = preload("res://scripts/dev/ten_kings/TenKingsPlayerState.gd")
const CardLib = preload("res://scripts/dev/ten_kings/TenKingsCardLibrary.gd")
const ArenaGeometryServiceScript = preload("res://scripts/dev/ten_kings/TenKingsArenaGeometryService.gd")

var _failed: bool = false


func _init() -> void:
	call_deferred("_run_test")


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("[test_ten_kings_crowd_builder_attack_entry_windup] %s" % message)
	_failed = true


func _run_test() -> void:
	_test_builder_assigns_non_zero_attack_entry_windup()
	if _failed:
		quit(1)
		return
	print("[test_ten_kings_crowd_builder_attack_entry_windup] PASS")
	quit(0)


func _test_builder_assigns_non_zero_attack_entry_windup() -> void:
	var player := PlayerStateScript.new("Player", false)
	_assert_true(player.board.place_card(Vector2i(1, 2), CardLib.CARD_SOLDIER), "soldier must be placeable")

	var builder := CrowdBuilderScript.new()
	builder.seed_rng(12345)
	var arena_geometry := ArenaGeometryServiceScript.new()
	arena_geometry.setup_from_dimensions(920.0, 520.0, Vector2.ZERO)
	var soldiers: Array = builder.expand_stacks_to_soldiers(player.board, 0, arena_geometry)

	_assert_true(not soldiers.is_empty(), "builder must create soldier entries")
	if soldiers.is_empty():
		return

	var first_soldier: Dictionary = soldiers[0]
	_assert_true(float(first_soldier.get("attack_entry_windup", 0.0)) > 0.0, "soldiers must have non-zero initial attack windup")
