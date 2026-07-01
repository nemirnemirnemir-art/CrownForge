extends SceneTree

const HeroBattleFlowScript := preload("res://core/hero/HeroBattleFlow.gd")


class FakeSquad:
	extends RefCounted

	var add_result: bool = true
	var active_hero_ids: Array[String] = ["a"]
	var add_calls: Array[String] = []
	var remove_calls: Array[String] = []

	func add_to_squad(hero_id: String) -> bool:
		add_calls.append(hero_id)
		return add_result

	func remove_from_squad(hero_id: String) -> void:
		remove_calls.append(hero_id)


class FakeBattle:
	extends RefCounted

	var start_result: bool = true
	var end_result: Array[String] = ["a"]
	var replace_result: String = "b"
	var battle_ids: Array = ["a"]
	var active: bool = true

	func start_battle_with_heroes(hero_ids: Array) -> bool:
		battle_ids = hero_ids.duplicate()
		return start_result

	func end_current_battle(_is_victory: bool) -> Array[String]:
		return end_result.duplicate()

	func replace_dead_hero(dead_id: String) -> String:
		return replace_result

	func get_heroes_in_battle() -> Array:
		return battle_ids.duplicate()

	func is_battle_active() -> bool:
		return active


class FakeEmitter:
	extends RefCounted

	var squad_changed_calls: int = 0
	var battle_started_payloads: Array = []
	var battle_ended_payloads: Array = []
	var auto_replaced_payloads: Array = []
	var save_requests: int = 0

	func emit_squad_changed() -> void:
		squad_changed_calls += 1

	func emit_battle_started(payload: Array) -> void:
		battle_started_payloads.append(payload.duplicate())

	func emit_battle_ended(payload: Array) -> void:
		battle_ended_payloads.append(payload.duplicate())

	func emit_auto_replaced(dead_id: String, new_id: String) -> void:
		auto_replaced_payloads.append([dead_id, new_id])

	func request_save() -> void:
		save_requests += 1


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = HeroBattleFlowScript.new()
	if flow == null:
		push_error("[test_herocore_battle_flow] failed to instantiate helper")
		quit(1)
		return

	var squad := FakeSquad.new()
	var battle := FakeBattle.new()
	var emitter := FakeEmitter.new()

	if not flow.add_to_squad(squad, "b", Callable(emitter, "emit_squad_changed"), Callable(emitter, "request_save")):
		push_error("[test_herocore_battle_flow] add_to_squad should succeed")
		quit(1)
		return
	flow.remove_from_squad(squad, "a", Callable(emitter, "emit_squad_changed"), Callable(emitter, "request_save"))
	if emitter.squad_changed_calls != 2 or emitter.save_requests != 2:
		push_error("[test_herocore_battle_flow] squad change side effects mismatch")
		quit(1)
		return

	if not flow.start_battle_with_heroes(battle, ["a", "b"], Callable(emitter, "emit_battle_started"), Callable(emitter, "emit_squad_changed")):
		push_error("[test_herocore_battle_flow] start battle should succeed")
		quit(1)
		return
	flow.end_current_battle(battle, true, Callable(emitter, "emit_battle_ended"), Callable(emitter, "emit_squad_changed"))
	if emitter.battle_started_payloads.is_empty() or emitter.battle_ended_payloads.is_empty():
		push_error("[test_herocore_battle_flow] battle events mismatch")
		quit(1)
		return

	var new_id: String = flow.replace_dead_hero(battle, "a", Callable(emitter, "emit_auto_replaced"))
	if new_id != "b" or emitter.auto_replaced_payloads.is_empty():
		push_error("[test_herocore_battle_flow] replace_dead_hero mismatch")
		quit(1)
		return

	print("[test_herocore_battle_flow] PASS")
	quit(0)
