extends SceneTree

const GameSceneBuildingDragScript := preload("res://scripts/game_scene/GameSceneBuildingDrag.gd")


class FakeSprite:
	extends RefCounted

	var modulate: Color = Color(1, 1, 1, 0.2)


class FakeSlot:
	extends RefCounted

	var slot_index: int = -1
	var sprite := FakeSprite.new()
	var set_building_calls: Array[String] = []
	var move_calls: Array[int] = []
	var unit_count: int = 2
	var moved_unit_count: int = -1

	func set_building(building_id: String) -> void:
		set_building_calls.append(building_id)

	func move_building_to_slot(target_slot) -> void:
		move_calls.append(int(target_slot.slot_index))
		target_slot.moved_unit_count = unit_count


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var drag = GameSceneBuildingDragScript.new()
	if drag == null:
		push_error("[test_gamescene_building_move_state] failed to instantiate helper")
		quit(1)
		return

	var source := FakeSlot.new()
	source.slot_index = 2
	var target := FakeSlot.new()
	target.slot_index = 5

	var moved: bool = false
	if drag.has_method("move_building_between_slots"):
		moved = bool(drag.call("move_building_between_slots", source, target))

	if not moved:
		push_error("[test_gamescene_building_move_state] move helper must report successful state-preserving transfer")
		quit(1)
		return
	if source.move_calls != [5]:
		push_error("[test_gamescene_building_move_state] move helper must delegate to slot state transfer")
		quit(1)
		return
	if target.moved_unit_count != 2:
		push_error("[test_gamescene_building_move_state] move helper must preserve produced unit state through slot transfer")
		quit(1)
		return
	if source.set_building_calls.has(""):
		push_error("[test_gamescene_building_move_state] move helper must not clear source slot through destructive set_building empty path")
		quit(1)
		return
	if abs(source.sprite.modulate.a - 1.0) > 0.001:
		push_error("[test_gamescene_building_move_state] move helper must restore source slot visual alpha")
		quit(1)
		return

	print("[test_gamescene_building_move_state] PASS")
	quit(0)
