extends RefCounted
class_name TownPopulationFlow


func get_population_max(population) -> int:
	return population.get_population_max() if population else 0


func get_population_used(population) -> int:
	return population.get_population_used() if population else 0


func get_building_workers(population, building_id: String) -> Array:
	return population.get_building_workers(building_id) if population else []


func get_available_workers(population) -> Array:
	return population.get_available_workers() if population else []


func assign_worker(population, building_id: String, person_id: String) -> bool:
	return population.assign_worker(building_id, person_id) if population else false


func remove_worker(population, building_id: String, person_id: String) -> bool:
	return population.remove_worker(building_id, person_id) if population else false


func convert_citizen_to_hero(population, person_id: String) -> bool:
	return population.convert_citizen_to_hero(person_id) if population else false


func kill_citizen(population, person_id: String) -> void:
	if population:
		population.kill_citizen(person_id)


func set_person_status(population, person_id: String, status: String) -> void:
	if population:
		population.set_person_status(person_id, status)


func get_population_status(population, person_id: String) -> String:
	return population.get_population_status(person_id) if population else ""


func get_free_person(population) -> String:
	return population.get_free_person() if population else ""


func add_test_population(population, amount: int) -> void:
	if population:
		population.add_test_population(amount)
