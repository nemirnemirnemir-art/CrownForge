extends SceneTree


class FakeHeroCore:
	extends Node

	var active_hero_ids: Array[String] = []
	var heroes: Dictionary = {}

	func get_hero(hero_id: String) -> Dictionary:
		return heroes.get(hero_id, {})


class FakePopulationCore:
	extends Node

	var max_population: int = 5

	func get_max_population() -> int:
		return max_population


func _init() -> void:
	call_deferred("_run_test")


func _fail(message: String) -> void:
	push_error("[test_population_battlefield_query] %s" % message)
	quit(1)


func _run_test() -> void:
	var script := load("res://core/population/PopulationBattlefieldQuery.gd") as Script
	if script == null:
		_fail("PopulationBattlefieldQuery script must exist")
		return
	var query = script.new()

	var hero_core := FakeHeroCore.new()
	hero_core.active_hero_ids = ["n1", "n2", "n3", "n4", "s1"]
	hero_core.heroes = {
		"n1": {"id": "n1", "isDead": false, "is_summon": false},
		"n2": {"id": "n2", "isDead": false, "is_summon": false},
		"n3": {"id": "n3", "isDead": false, "is_summon": false},
		"n4": {"id": "n4", "isDead": false, "is_summon": false},
		"s1": {"id": "s1", "isDead": false, "is_summon": true},
	}
	var population_core := FakePopulationCore.new()

	if int(query.call("get_battlefield_occupied_count", hero_core)) != 5:
		_fail("occupied battlefield count must include active summons")
		return
	if bool(query.call("has_field_capacity", hero_core, population_core)):
		_fail("field must be treated as full when summons already consume the last visible slot")
		return
	var limited: Array = query.call("limit_hero_ids_to_available_capacity", ["reserve_a", "reserve_b"], hero_core, population_core)
	if not limited.is_empty():
		_fail("normal deploy candidates must be trimmed to zero when battlefield is already full")
		return

	print("[test_population_battlefield_query] PASS")
	quit(0)
