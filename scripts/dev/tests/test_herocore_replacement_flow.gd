extends SceneTree

const HeroReplacementFlowScript := preload("res://core/hero/HeroReplacementFlow.gd")


class FakeHeroData:
	extends RefCounted

	var heroes := {
		"dead_horseman": {
			"id": "dead_horseman",
			"icon_id": "horseman",
			"produced_by_building_id": "stables",
			"produced_by_slot_index": 3,
		}
	}

	func has_hero(hero_id: String) -> bool:
		return heroes.has(hero_id)

	func get_hero(hero_id: String) -> Dictionary:
		return heroes.get(hero_id, {}).duplicate(true)


class FakeSquad:
	extends RefCounted

	var active := {"dead_horseman": true}
	var added: Array[String] = []

	func is_in_squad(hero_id: String) -> bool:
		return active.has(hero_id)

	func add_to_squad(hero_id: String) -> void:
		added.append(hero_id)


class FakeBattle:
	extends RefCounted

	var replace_result: bool = true
	var calls: Array = []

	func replace_dead_hero_with(dead_id: String, new_id: String) -> bool:
		calls.append([dead_id, new_id])
		return replace_result


class FakeUpgradeCore:
	extends RefCounted

	func has_upgrade(_slot_index: int, upgrade_id: String) -> bool:
		return upgrade_id == "stables:2"


class FakeCounter:
	extends RefCounted

	var ensured: Array[String] = []
	var hired: Array[String] = []
	var updated: Array[Dictionary] = []
	var emitted: Array = []

	func ensure_template(base_id: String, _name: String = "") -> void:
		ensured.append(base_id)

	func hire_copy(base_id: String) -> String:
		hired.append(base_id)
		return "rider_copy"

	func update_hero(hero_id: String, patch: Dictionary) -> void:
		var payload := patch.duplicate(true)
		payload["hero_id"] = hero_id
		updated.append(payload)

	func emit_replace(dead_id: String, new_id: String) -> void:
		emitted.append([dead_id, new_id])


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = HeroReplacementFlowScript.new()
	if flow == null:
		push_error("[test_herocore_replacement_flow] failed to instantiate helper")
		quit(1)
		return

	var hero_data := FakeHeroData.new()
	var squad := FakeSquad.new()
	var battle := FakeBattle.new()
	var upgrades := FakeUpgradeCore.new()
	var counter := FakeCounter.new()

	var new_id: String = flow.try_spawn_survivor_rider(
		hero_data,
		squad,
		battle,
		upgrades,
		"dead_horseman",
		Callable(counter, "ensure_template"),
		Callable(counter, "hire_copy"),
		Callable(counter, "update_hero"),
		Callable(counter, "emit_replace"),
		Callable(squad, "add_to_squad")
	)
	if new_id != "rider_copy":
		push_error("[test_herocore_replacement_flow] expected rider replacement")
		quit(1)
		return
	if counter.ensured != ["rider"] or counter.hired != ["rider"]:
		push_error("[test_herocore_replacement_flow] template/hire flow mismatch")
		quit(1)
		return
	if battle.calls.size() != 1 or counter.emitted.size() != 1:
		push_error("[test_herocore_replacement_flow] battle replacement event mismatch")
		quit(1)
		return

	print("[test_herocore_replacement_flow] PASS")
	quit(0)
