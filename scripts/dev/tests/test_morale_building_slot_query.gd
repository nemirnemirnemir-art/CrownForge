extends SceneTree

const BuildingSlotQueryScript := preload("res://scripts/systems/morale/BuildingSlotQuery.gd")


class FakeArenaHandler:
	extends RefCounted

	var morale_bonus: int = 0

	func get_morale_bonus() -> int:
		return morale_bonus


class FakeSlot:
	extends Node

	var current_building_id: String = ""
	var vzor_active: bool = false
	var _special_handler: Variant = null

	func is_effectively_vzor_active() -> bool:
		return vzor_active


class FakeMapLayout:
	extends Node

	var slots: Array = []


class FakeGameScene:
	extends Node2D

	var map_layout_node: Variant = null


class FakeHero:
	extends Node2D

	var is_dead: bool = false


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var query = BuildingSlotQueryScript.new()
	if query == null:
		push_error("[test_morale_building_slot_query] failed to instantiate helper")
		quit(1)
		return

	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		push_error("[test_morale_building_slot_query] scene tree is unavailable")
		quit(1)
		return

	var tavern_slot := FakeSlot.new()
	tavern_slot.current_building_id = "tavern"
	tavern_slot.vzor_active = true

	var inactive_tavern_slot := FakeSlot.new()
	inactive_tavern_slot.current_building_id = "tavern"
	inactive_tavern_slot.vzor_active = false

	var arena_handler := FakeArenaHandler.new()
	arena_handler.morale_bonus = 7
	var arena_slot := FakeSlot.new()
	arena_slot.current_building_id = "arena"
	arena_slot._special_handler = arena_handler

	var other_slot := FakeSlot.new()
	other_slot.current_building_id = "mine"

	var map_layout := FakeMapLayout.new()
	map_layout.slots = [inactive_tavern_slot, tavern_slot, arena_slot, other_slot]

	var game_scene := FakeGameScene.new()
	game_scene.name = "FakeGameScene"
	game_scene.map_layout_node = map_layout
	game_scene.add_to_group("game_scene")
	tree.root.add_child(game_scene)
	tree.current_scene = game_scene

	var alive_hero := FakeHero.new()
	alive_hero.add_to_group("hero")
	game_scene.add_child(alive_hero)

	var dead_hero := FakeHero.new()
	dead_hero.is_dead = true
	dead_hero.add_to_group("hero")
	game_scene.add_child(dead_hero)

	var persistent_off_scene_hero := FakeHero.new()
	persistent_off_scene_hero.add_to_group("hero")
	tree.root.add_child(persistent_off_scene_hero)
	await process_frame

	if not query.has_active_tavern():
		push_error("[test_morale_building_slot_query] active tavern should be detected")
		quit(1)
		return
	if query.get_active_arena_morale_bonus() != 7:
		push_error("[test_morale_building_slot_query] arena morale aggregation mismatch")
		quit(1)
		return
	if query.get_warrior_count_on_field() != 1:
		push_error("[test_morale_building_slot_query] warrior count must include only living heroes on the active game scene and ignore off-scene hero group members")
		quit(1)
		return

	tavern_slot.vzor_active = false
	if query.has_active_tavern():
		push_error("[test_morale_building_slot_query] inactive tavern should not count")
		quit(1)
		return

	map_layout.slots = [other_slot]
	if query.get_active_arena_morale_bonus() != 0:
		push_error("[test_morale_building_slot_query] missing arena should return zero bonus")
		quit(1)
		return

	game_scene.remove_from_group("game_scene")
	if query.get_warrior_count_on_field() != 0:
		push_error("[test_morale_building_slot_query] warrior count must be zero outside the active game scene")
		quit(1)
		return

	print("[test_morale_building_slot_query] PASS")
	quit(0)
