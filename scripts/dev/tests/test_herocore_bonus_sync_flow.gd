extends SceneTree

const HeroBonusSyncFlowScript := preload("res://core/hero/HeroBonusSyncFlow.gd")


class FakeHeroData:
	extends RefCounted

	var heroes := {
		"a": {"maxHp": 10.0, "hp": 7.0},
		"b": {"maxHp": 20.0, "hp": 25.0}
	}
	var updates: Array[Dictionary] = []

	func get_all_hero_ids() -> Array:
		return heroes.keys()

	func get_hero(hero_id: String) -> Dictionary:
		return heroes.get(hero_id, {}).duplicate(true)

	func update_hero(hero_id: String, patch: Dictionary) -> void:
		var payload := patch.duplicate(true)
		payload["hero_id"] = hero_id
		updates.append(payload)
		for key in patch.keys():
			heroes[hero_id][key] = patch[key]


class FakeEmitter:
	extends RefCounted

	var hp_events: Array = []

	func emit_hp_changed(hero_id: String, current_hp: float, max_hp: float) -> void:
		hp_events.append([hero_id, current_hp, max_hp])


class FakeSaveRequester:
	extends RefCounted

	var call_count: int = 0

	func request_save() -> void:
		call_count += 1


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = HeroBonusSyncFlowScript.new()
	if flow == null:
		push_error("[test_herocore_bonus_sync_flow] failed to instantiate helper")
		quit(1)
		return

	var hero_data := FakeHeroData.new()
	var emitter := FakeEmitter.new()
	var save_requester := FakeSaveRequester.new()
	var stats_map := {
		"a": {"maxHp": 15.0, "damage": 9.0},
		"b": {"maxHp": 12.0, "damage": 11.0}
	}

	flow.sync_after_troop_bonus_change(
		hero_data,
		func(hero_id: String) -> Dictionary: return stats_map.get(hero_id, {}),
		Callable(hero_data, "update_hero"),
		Callable(emitter, "emit_hp_changed"),
		Callable(save_requester, "request_save")
	)

	if emitter.hp_events.size() != 2:
		push_error("[test_herocore_bonus_sync_flow] expected hp update events for changed heroes")
		quit(1)
		return
	if absf(hero_data.heroes["a"]["hp"] - 12.0) > 0.01:
		push_error("[test_herocore_bonus_sync_flow] increased max hp must heal by diff")
		quit(1)
		return
	if absf(hero_data.heroes["b"]["hp"] - 12.0) > 0.01:
		push_error("[test_herocore_bonus_sync_flow] decreased max hp must clamp current hp")
		quit(1)
		return
	if save_requester.call_count != 1:
		push_error("[test_herocore_bonus_sync_flow] hp-affecting bonus sync must request save once per sync")
		quit(1)
		return

	print("[test_herocore_bonus_sync_flow] PASS")
	quit(0)
