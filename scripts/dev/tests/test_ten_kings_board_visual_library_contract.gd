extends SceneTree

const BoardVisualLibraryScript := preload("res://scripts/dev/ten_kings/TenKingsBoardVisualLibrary.gd")
const CardLib := preload("res://scripts/dev/ten_kings/TenKingsCardLibrary.gd")


func _init() -> void:
	var result := _run_tests()
	if result:
		print("PASS: test_ten_kings_board_visual_library_contract")
	else:
		print("FAIL: test_ten_kings_board_visual_library_contract")
	quit(0 if result else 1)


func _run_tests() -> bool:
	var library = BoardVisualLibraryScript.new()

	var castle_texture := library.get_building_texture(CardLib.CARD_CASTLE, 0)
	if castle_texture == null:
		print("  ERROR: Castle building texture missing")
		return false
	print("  Castle building texture found")

	var soldier_frames: Array[Texture2D] = library.get_troop_frames(CardLib.CARD_SOLDIER, 0)
	if soldier_frames.size() < 2:
		print("  ERROR: Soldier troop frames missing")
		return false
	print("  Soldier troop frames found")

	var wildcard_texture := library.get_building_texture(CardLib.CARD_WILDCARD, 0)
	var wildcard_frames: Array[Texture2D] = library.get_troop_frames(CardLib.CARD_WILDCARD, 0)
	if wildcard_texture != null or wildcard_frames.size() > 0:
		print("  ERROR: Wildcard must not claim unsupported on-field art")
		return false
	print("  Unsupported cards correctly use fallback path")

	return true
