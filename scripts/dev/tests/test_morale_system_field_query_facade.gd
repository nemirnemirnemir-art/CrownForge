extends SceneTree


class FakeBuildingSlotQuery:
	extends RefCounted

	var call_count: int = 0
	var next_count: int = 0

	func has_active_tavern() -> bool:
		return false

	func get_active_arena_morale_bonus() -> int:
		return 0

	func get_warrior_count_on_field() -> int:
		call_count += 1
		return next_count


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		push_error("[test_morale_system_field_query_facade] scene tree is unavailable")
		quit(1)
		return

	var morale_system := tree.root.get_node_or_null("MoraleSystem")
	if morale_system == null:
		push_error("[test_morale_system_field_query_facade] MoraleSystem autoload must exist")
		quit(1)
		return

	var fake_query := FakeBuildingSlotQuery.new()
	fake_query.next_count = 4
	morale_system._building_slot_query = fake_query

	var result: int = morale_system._get_warrior_count_on_field()
	if result != 4:
		push_error("[test_morale_system_field_query_facade] MoraleSystem must delegate warrior count lookup to BuildingSlotQuery")
		quit(1)
		return
	if fake_query.call_count != 1:
		push_error("[test_morale_system_field_query_facade] BuildingSlotQuery should be called exactly once")
		quit(1)
		return

	print("[test_morale_system_field_query_facade] PASS")
	quit(0)
