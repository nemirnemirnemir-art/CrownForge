extends SceneTree

const CrowdBuilderScript = preload("res://scripts/dev/ten_kings/TenKingsCrowdBuilder.gd")
const BoardStateScript = preload("res://scripts/dev/ten_kings/TenKingsBoardState.gd")
const ArenaGeometryScript = preload("res://scripts/dev/ten_kings/TenKingsArenaGeometryService.gd")
const CardLib = preload("res://scripts/dev/ten_kings/TenKingsCardLibrary.gd")


func _init() -> void:
	var result := _run_tests()
	if result:
		print("PASS: test_ten_kings_crowd_deploy_from_board_origins")
	else:
		print("FAIL: test_ten_kings_crowd_deploy_from_board_origins")
	quit(0 if result else 1)


func _run_tests() -> bool:
	var board = BoardStateScript.new()
	board.place_card(Vector2i(2, 2), CardLib.CARD_CASTLE)
	board.place_card(Vector2i(1, 2), CardLib.CARD_SOLDIER)

	var geometry = ArenaGeometryScript.new()
	geometry.setup_from_dimensions(800.0, 400.0)

	var origins = {
		Vector2i(2, 2): Vector2(-420.0, -20.0),
		Vector2i(1, 2): Vector2(-470.0, 30.0),
	}

	var builder = CrowdBuilderScript.new()
	var result: Dictionary = builder.expand_stacks_to_soldiers(board, 0, geometry, origins)
	var soldiers: Array = result.get("soldiers", [])
	var structures: Array = result.get("fixed_structures", [])

	if soldiers.is_empty():
		print("  ERROR: No soldiers were generated")
		return false
	var soldier: Dictionary = soldiers[0]
	if soldier.get("deploy_origin", Vector2.ZERO) != origins[Vector2i(1, 2)]:
		print("  ERROR: Soldier deploy origin does not use slot origin")
		return false
	if soldier.get("position", Vector2.ZERO) != origins[Vector2i(1, 2)]:
		print("  ERROR: Soldier starting position does not use slot origin")
		return false
	if soldier.get("formation_position", Vector2.ZERO) == origins[Vector2i(1, 2)]:
		print("  ERROR: Soldier formation position should differ from slot origin")
		return false
	print("  Soldier deploy metadata uses board-slot origin")

	if structures.is_empty():
		print("  ERROR: No fixed structures were generated")
		return false
	var structure: Dictionary = structures[0]
	if structure.get("deploy_origin", Vector2.ZERO) != origins[Vector2i(2, 2)]:
		print("  ERROR: Structure deploy origin does not use slot origin")
		return false
	if structure.get("formation_position", Vector2.ZERO) == origins[Vector2i(2, 2)]:
		print("  ERROR: Structure formation position should differ from slot origin")
		return false
	print("  Structure deploy metadata uses board-slot origin")

	return true
