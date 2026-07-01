extends SceneTree

const TownSaveFlowScript := preload("res://core/town/TownSaveFlow.gd")


class FakeBuildings:
	extends RefCounted

	var buildings: Dictionary = {"town_hall": {"level": 1}}
	var registry: Array = ["town_hall", "farm"]

	func get_buildings() -> Dictionary:
		return buildings.duplicate(true)

	func set_buildings(value: Dictionary) -> void:
		buildings = value.duplicate(true)

	func get_building_registry() -> Array:
		return registry.duplicate()


class FakePotions:
	extends RefCounted

	var potions: int = 2
	var potion_timer: float = 8.0

	func get_global_potions() -> int:
		return potions

	func set_potions(value: int) -> void:
		potions = value

	func get_potion_timer() -> float:
		return potion_timer

	func set_potion_timer(value: float) -> void:
		potion_timer = value


class FakePerks:
	extends RefCounted

	var unlocked: Array = ["p1"]
	var available: Array = ["p2"]

	func get_unlocked_perks() -> Array:
		return unlocked.duplicate()

	func get_available_perks() -> Array:
		return available.duplicate()

	func set_unlocked_perks(value: Array) -> void:
		unlocked = value.duplicate()

	func set_available_perks(value: Array) -> void:
		available = value.duplicate()


class FakePopulation:
	extends RefCounted

	var statuses: Dictionary = {"a": "idle"}
	var workers: Dictionary = {"farm": ["a"]}
	var init_calls: int = 0
	var max_pop: int = 7

	func get_population_status_dict() -> Dictionary:
		return statuses.duplicate(true)

	func set_population_status(value: Dictionary) -> void:
		statuses = value.duplicate(true)

	func get_worker_assignments() -> Dictionary:
		return workers.duplicate(true)

	func set_worker_assignments(value: Dictionary) -> void:
		workers = value.duplicate(true)

	func initialize_population() -> void:
		init_calls += 1

	func get_population_max() -> int:
		return max_pop


class FakeInventory:
	extends RefCounted

	var save_data: Dictionary = {"items": []}
	var init_calls: int = 0
	var loaded: Dictionary = {}

	func get_save_data() -> Dictionary:
		return save_data.duplicate(true)

	func load_save_data(value: Dictionary) -> void:
		loaded = value.duplicate(true)

	func initialize() -> void:
		init_calls += 1


class FakeShop:
	extends RefCounted

	var reset_calls: int = 0
	var loaded: Dictionary = {}

	func get_save_data() -> Dictionary:
		return {"shop": true}

	func load_save_data(value: Dictionary) -> void:
		loaded = value.duplicate(true)

	func reset() -> void:
		reset_calls += 1


class FakeAlchemy:
	extends RefCounted

	var loaded: Dictionary = {}

	func get_save_data() -> Dictionary:
		return {"alchemy": true}

	func load_save_data(value: Dictionary) -> void:
		loaded = value.duplicate(true)


class FakeMageTower:
	extends RefCounted

	var reset_calls: int = 0
	var loaded: Dictionary = {}

	func get_save_data() -> Dictionary:
		return {"mage": true}

	func load_save_data(value: Dictionary) -> void:
		loaded = value.duplicate(true)

	func reset() -> void:
		reset_calls += 1


class FakeHospital:
	extends RefCounted

	var timer: float = 4.0

	func set_hospital_timer(value: float) -> void:
		timer = value


class FakeBonuses:
	extends RefCounted

	var invalidations: int = 0
	var defense_queries: int = 0

	func invalidate_cache() -> void:
		invalidations += 1

	func get_global_defense_bonus() -> int:
		defense_queries += 1
		return 0


class FakeEmitter:
	extends RefCounted

	var food_events: Array = []
	var population_events: Array = []

	func emit_food_changed(value: float, delta: float) -> void:
		food_events.append([value, delta])

	func emit_population_changed(used: int, max_pop: int) -> void:
		population_events.append([used, max_pop])


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = TownSaveFlowScript.new()
	if flow == null:
		push_error("[test_towncore_save_flow] failed to instantiate helper")
		quit(1)
		return

	var buildings := FakeBuildings.new()
	var potions := FakePotions.new()
	var perks := FakePerks.new()
	var inventory := FakeInventory.new()
	var shop := FakeShop.new()
	var alchemy := FakeAlchemy.new()
	var mage := FakeMageTower.new()
	var hospital := FakeHospital.new()
	var bonuses := FakeBonuses.new()

	var save_data: Dictionary = flow.get_save_data(buildings, potions, perks, inventory, shop, alchemy, mage)
	if not save_data.has("buildings") or not save_data.has("alchemy_craft"):
		push_error("[test_towncore_save_flow] save data missing expected keys")
		quit(1)
		return

	flow.load_save_data(
		{"buildings": {"farm": {"level": 2}}, "potions": 5, "potion_timer": 3.0, "unlocked_perks": ["x"], "available_perks": ["y"], "population_status": {"b": "work"}, "worker_assignments": {"farm": ["b"]}, "inventory": {"items": [1]}, "townhall_shop": {"shop": 1}, "alchemy_craft": {"alchemy": 1}, "mage_tower_upgrades": {"mage": 1}},
		buildings,
		potions,
		perks,
		inventory,
		shop,
		alchemy,
		mage,
		bonuses
	)
	if bonuses.invalidations != 1 or bonuses.defense_queries != 1:
		push_error("[test_towncore_save_flow] load must invalidate and recompute bonuses")
		quit(1)
		return

	flow.reset(buildings, potions, perks, inventory, shop, alchemy, mage, hospital, bonuses)
	if inventory.init_calls != 1 or shop.reset_calls != 1 or mage.reset_calls != 1:
		push_error("[test_towncore_save_flow] reset must clear subsystems")
		quit(1)
		return
	if save_data.has("population_status") or save_data.has("worker_assignments"):
		push_error("[test_towncore_save_flow] legacy population worker data must not be saved anymore")
		quit(1)
		return

	print("[test_towncore_save_flow] PASS")
	quit(0)
