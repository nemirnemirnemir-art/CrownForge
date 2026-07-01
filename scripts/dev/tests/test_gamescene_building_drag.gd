extends SceneTree

const GameSceneBuildingDragScript := preload("res://scripts/game_scene/GameSceneBuildingDrag.gd")


class FakeSprite:
	extends RefCounted

	var modulate: Color = Color(1, 1, 1, 1)


class FakeSlot:
	extends Node2D

	var slot_index: int = -1
	var is_building_slot: bool = true
	var current_building_id: String = ""
	var sprite := FakeSprite.new()
	var set_building_calls: Array[Dictionary] = []
	var move_calls: Array[int] = []

	func set_building(building_id: String, options: Dictionary = {}) -> void:
		set_building_calls.append({"building_id": building_id, "options": options.duplicate(true)})
		current_building_id = building_id

	func move_building_to_slot(target_slot: Node) -> void:
		move_calls.append(int(target_slot.get("slot_index")))
		current_building_id = ""
		target_slot.set("current_building_id", "barracks")


class FakeMapLayout:
	extends Node

	var slots: Array = []


class FakeBuildingMenu:
	extends Node

	var affordability_updates: int = 0

	func _update_affordability() -> void:
		affordability_updates += 1


class FakeGameScene:
	extends Node2D

	var mouse_pos: Vector2 = Vector2.ZERO

	@warning_ignore("native_method_override")
	func get_global_mouse_position() -> Vector2:
		return mouse_pos


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	print("[test_gamescene_building_drag] START")
	var drag := GameSceneBuildingDragScript.new()
	if drag == null:
		push_error("[test_gamescene_building_drag] failed to instantiate helper")
		quit(1)
		return

	var scene := FakeGameScene.new()
	get_root().add_child(scene)

	var layout := FakeMapLayout.new()
	var source := FakeSlot.new()
	source.slot_index = 0
	source.current_building_id = "barracks"
	source.global_position = Vector2(0, 0)
	var target := FakeSlot.new()
	target.slot_index = 1
	target.current_building_id = ""
	target.global_position = Vector2(120, 0)
	layout.slots = [source, target]
	var menu := FakeBuildingMenu.new()

	scene.mouse_pos = Vector2(120, 0)
	drag.initialize(scene, layout)
	drag.on_move_started(0, "barracks")
	drag.handle_drop(menu)

	if source.move_calls != [1]:
		push_error("[test_gamescene_building_drag] move path must delegate to slot state transfer instead of destructive clear")
		quit(1)
		return
	if source.set_building_calls.any(func(call: Dictionary) -> bool: return String(call.get("building_id", "")) == ""):
		push_error("[test_gamescene_building_drag] move path must not clear source slot through destructive empty set_building")
		quit(1)
		return
	if menu.affordability_updates != 1:
		push_error("[test_gamescene_building_drag] successful move must refresh building menu affordability")
		quit(1)
		return

	print("[test_gamescene_building_drag] PASS")
	quit(0)
