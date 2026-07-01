extends SceneTree

const HeroPersistenceFlowScript := preload("res://core/hero/HeroPersistenceFlow.gd")


class FakeHeroData:
	extends RefCounted

	var heroes: Dictionary = {}
	var validated: Array[String] = []
	var revalidated: int = 0

	func has_hero(hero_id: String) -> bool:
		return heroes.has(hero_id)

	func get_hero(hero_id: String) -> Dictionary:
		return heroes.get(hero_id, {})

	func get_all_hero_ids() -> Array:
		return heroes.keys()

	func update_hero(hero_id: String, patch: Dictionary) -> void:
		if not heroes.has(hero_id):
			return
		for key in patch.keys():
			heroes[hero_id][key] = patch[key]

	func validate_equipment_structure(hero_id: String) -> void:
		validated.append(hero_id)

	func revalidate_all_heroes() -> void:
		revalidated += 1


class FakeSquad:
	extends RefCounted

	var active_hero_ids: Array[String] = []


class FakeBuffs:
	extends RefCounted

	var hero_buffs: Dictionary = {}


class FakeEmitter:
	extends RefCounted

	var squad_changed_calls: int = 0

	func emit_squad_changed() -> void:
		squad_changed_calls += 1


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = HeroPersistenceFlowScript.new()
	if flow == null:
		push_error("[test_herocore_persistence_flow] failed to instantiate helper")
		quit(1)
		return

	var hero_data := FakeHeroData.new()
	var squad := FakeSquad.new()
	var buffs := FakeBuffs.new()
	var emitter := FakeEmitter.new()

	hero_data.heroes = {
		"alive": {"id": "alive", "isDead": false},
		"dead": {"id": "dead", "isDead": true}
	}
	squad.active_hero_ids = ["alive"]
	buffs.hero_buffs = {"alive": {"x": 1}}

	var save_data: Dictionary = flow.get_save_data(hero_data, squad, buffs)
	if save_data.get("active_hero_ids", []).size() != 1:
		push_error("[test_herocore_persistence_flow] save data mismatch")
		quit(1)
		return

	flow.load_save_data(
		{"heroes": hero_data.heroes, "active_hero_ids": ["alive", "dead"], "hero_buffs": {"alive": {"x": 1}}},
		hero_data,
		squad,
		buffs,
		Callable(emitter, "emit_squad_changed")
	)
	if squad.active_hero_ids != ["alive"]:
		push_error("[test_herocore_persistence_flow] dead heroes must be filtered from active squad")
		quit(1)
		return
	if hero_data.revalidated != 1 or emitter.squad_changed_calls != 1:
		push_error("[test_herocore_persistence_flow] post-load revalidation/signal mismatch")
		quit(1)
		return

	print("[test_herocore_persistence_flow] PASS")
	quit(0)
