extends SceneTree

const TownPopulationFlowScript := preload("res://core/town/TownPopulationFlow.gd")


class FakePopulation:
	extends RefCounted

	var max_pop: int = 10
	var used: int = 4
	var workers := {"farm": ["a"]}
	var available := ["b", "c"]
	var assigned: Array = []
	var removed: Array = []
	var converted: Array = []
	var killed: Array = []
	var statuses: Dictionary = {"a": "idle"}
	var test_added: int = 0

	func get_population_max() -> int: return max_pop
	func get_population_used() -> int: return used
	func get_building_workers(building_id: String) -> Array: return workers.get(building_id, []).duplicate()
	func get_available_workers() -> Array: return available.duplicate()
	func assign_worker(building_id: String, person_id: String) -> bool: assigned.append([building_id, person_id]); return true
	func remove_worker(building_id: String, person_id: String) -> bool: removed.append([building_id, person_id]); return true
	func convert_citizen_to_hero(person_id: String) -> bool: converted.append(person_id); return true
	func kill_citizen(person_id: String) -> void: killed.append(person_id)
	func set_person_status(person_id: String, status: String) -> void: statuses[person_id] = status
	func get_population_status(person_id: String) -> String: return String(statuses.get(person_id, ""))
	func get_free_person() -> String: return "b"
	func add_test_population(amount: int) -> void: test_added += amount


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = TownPopulationFlowScript.new()
	if flow == null:
		push_error("[test_towncore_population_flow] failed to instantiate helper")
		quit(1)
		return

	var population := FakePopulation.new()
	if flow.get_population_max(population) != 10 or flow.get_population_used(population) != 4:
		push_error("[test_towncore_population_flow] population getters mismatch")
		quit(1)
		return
	if flow.get_building_workers(population, "farm").size() != 1:
		push_error("[test_towncore_population_flow] worker list mismatch")
		quit(1)
		return
	if not flow.assign_worker(population, "farm", "b"):
		push_error("[test_towncore_population_flow] assign_worker should succeed")
		quit(1)
		return
	if not flow.remove_worker(population, "farm", "a"):
		push_error("[test_towncore_population_flow] remove_worker should succeed")
		quit(1)
		return
	if not flow.convert_citizen_to_hero(population, "b"):
		push_error("[test_towncore_population_flow] convert_citizen_to_hero should succeed")
		quit(1)
		return
	flow.kill_citizen(population, "c")
	flow.set_person_status(population, "a", "busy")
	if flow.get_population_status(population, "a") != "busy":
		push_error("[test_towncore_population_flow] status mutation mismatch")
		quit(1)
		return
	if flow.get_free_person(population) != "b":
		push_error("[test_towncore_population_flow] free person mismatch")
		quit(1)
		return
	flow.add_test_population(population, 3)
	if population.test_added != 3:
		push_error("[test_towncore_population_flow] add_test_population mismatch")
		quit(1)
		return

	print("[test_towncore_population_flow] PASS")
	quit(0)
