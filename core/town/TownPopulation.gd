extends RefCounted
class_name TownPopulation

## Управление населением
## Статусы, рабочие, конвертация в героев

var _population_status: Dictionary = {} # person_id -> "FREE" | "WORKER" | "HERO"
var _worker_assignments: Dictionary = {} # building_id -> Array[person_id]
var _buildings_manager: TownBuildings

signal population_changed(used: int, max_pop: int)

func initialize(buildings_manager: TownBuildings) -> void:
	_buildings_manager = buildings_manager

func get_population_max() -> int:
	if not _buildings_manager:
		return 0
	
	var total = 0
	var buildings = _buildings_manager.get_buildings()
	var registry = _buildings_manager.get_building_registry()
	
	for id in buildings:
		var level = buildings[id]["level"]
		var data = registry.get(id)
		if not data:
			continue
		
		var base = data.base_population_capacity
		var per_lvl = data.population_per_level
		if level >= 1 and (base > 0 or per_lvl > 0):
			total += base + (per_lvl * (level - 1))
	return total

func get_population_used() -> int:
	# Return USED population count (HERO + WORKER)
	# Population decreases when citizens become heroes or workers
	var used_count = 0
	for status in _population_status.values():
		if status == "HERO" or status == "WORKER":
			used_count += 1
	return used_count

func initialize_population() -> void:
	var max_pop = get_population_max()
	
	# Fill gaps up to max_pop
	for i in range(1, max_pop + 1):
		var person_id = "person_%d" % i
		if not _population_status.has(person_id):
			_population_status[person_id] = "FREE"
	
	# Also ensure existing assignments are valid
	for building_id in _worker_assignments:
		for person_id in _worker_assignments[building_id]:
			if not _population_status.has(person_id):
				_population_status[person_id] = "WORKER"
			elif _population_status[person_id] == "FREE":
				_population_status[person_id] = "WORKER"

func get_building_workers(building_id: String) -> Array:
	return _worker_assignments.get(building_id, [])

func get_available_workers() -> Array:
	var available = []
	for person_id in _population_status:
		if _population_status[person_id] == "FREE":
			available.append(person_id)
	return available

func assign_worker(building_id: String, person_id: String) -> bool:
	if not _buildings_manager:
		return false
	
	if not _buildings_manager.get_buildings().has(building_id):
		# print("[TownPopulation] assign_worker: Building %s not in _buildings" % building_id)
		return false
	if not _population_status.has(person_id):
		# print("[TownPopulation] assign_worker: Person %s not in _population_status" % person_id)
		return false
	if _population_status[person_id] != "FREE":
		# print("[TownPopulation] assign_worker: Person %s is not FREE (status: %s)" % [person_id, _population_status[person_id]])
		return false
	
	var data = _buildings_manager.get_building_config(building_id)
	if not data:
		# print("[TownPopulation] assign_worker: Building %s not in registry" % building_id)
		return false
	
	var current_workers = _worker_assignments.get(building_id, [])
	# Простая логика: max_workers = level здания
	var max_workers = _buildings_manager.get_building_level(building_id)
	
	if current_workers.size() >= max_workers:
		# print("[TownPopulation] assign_worker: Building %s already at max workers (%d/%d)" % [building_id, current_workers.size(), max_workers])
		return false
	
	# Assign
	if not _worker_assignments.has(building_id):
		_worker_assignments[building_id] = []
	_worker_assignments[building_id].append(person_id)
	_population_status[person_id] = "WORKER"
	
	# print("[TownPopulation] assign_worker: Successfully assigned %s to %s" % [person_id, building_id])
	# Update population UI immediately
	population_changed.emit(get_population_used(), get_population_max())
	if SaveCore:
		SaveCore.request_save()
	return true

func remove_worker(building_id: String, person_id: String) -> bool:
	if not _worker_assignments.has(building_id):
		return false
	
	var workers = _worker_assignments[building_id]
	if person_id in workers:
		workers.erase(person_id)
		_population_status[person_id] = "FREE"
		# Update population UI immediately
		population_changed.emit(get_population_used(), get_population_max())
		if SaveCore:
			SaveCore.request_save()
		return true
	return false

func get_free_person() -> String:
	for person_id in _population_status:
		if _population_status[person_id] == "FREE":
			return person_id
	return ""

func convert_citizen_to_hero(person_id: String) -> bool:
	if not _population_status.has(person_id):
		return false
	if _population_status[person_id] != "FREE":
		return false
	
	_population_status[person_id] = "HERO"
	# Emit population change signal to update UI
	population_changed.emit(get_population_used(), get_population_max())
	if SaveCore:
		SaveCore.request_save()
	return true

func kill_citizen(person_id: String) -> void:
	if _population_status.has(person_id):
		_population_status.erase(person_id)
		# Also remove from workers if assigned (though HERO shouldn't be worker)
		for bid in _worker_assignments:
			if person_id in _worker_assignments[bid]:
				_worker_assignments[bid].erase(person_id)
		
		if SaveCore:
			SaveCore.request_save()

func set_person_status(person_id: String, status: String) -> void:
	if _population_status.has(person_id):
		_population_status[person_id] = status
		if SaveCore:
			SaveCore.request_save()

func get_population_status(person_id: String) -> String:
	return _population_status.get(person_id, "UNKNOWN")

func add_test_population(amount: int) -> void:
	var current_max = get_population_max()
	var start_index = current_max + 1
	
	for i in range(amount):
		var person_id = "person_%d" % (start_index + i)
		if not _population_status.has(person_id):
			_population_status[person_id] = "FREE"
	
	population_changed.emit(get_population_used(), get_population_max())
	if SaveCore:
		SaveCore.request_save()

func get_population_status_dict() -> Dictionary:
	return _population_status

func set_population_status(status: Dictionary) -> void:
	_population_status = status

func get_worker_assignments() -> Dictionary:
	return _worker_assignments

func set_worker_assignments(assignments: Dictionary) -> void:
	_worker_assignments = assignments

