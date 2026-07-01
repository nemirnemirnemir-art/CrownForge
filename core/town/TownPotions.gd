extends RefCounted
class_name TownPotions

## Potion system
## Production, assignment to heroes

const POTION_PRODUCTION_TIME: float = 300.0 # 5 minutes

var _potions_global: int = 0
var _potion_timer: float = 0.0
var _buildings_manager: TownBuildings

signal potion_produced(current_potions: int)
signal hero_assigned_potion(hero_id: String, current_potions: int)

func initialize(buildings_manager: TownBuildings) -> void:
	_buildings_manager = buildings_manager

func get_global_potions() -> int:
	return _potions_global

func assign_potion_to_hero(hero_id: String) -> bool:
	## Assign a potion from global storage to a hero
	## Returns true if successful, false if no potions available or hero cannot take more
	if _potions_global <= 0:
		return false
	
	if not HeroCore:
		return false
	
	# Try to give potion to hero
	if HeroCore.give_potion(hero_id):
		_potions_global -= 1
		var current_potions = HeroCore.heroes.get(hero_id, {}).get("potions_carried", 0)
		hero_assigned_potion.emit(hero_id, current_potions)
		if SaveCore:
			SaveCore.request_save()
		return true
	
	return false

func process_potions(delta: float) -> void:
	if not _buildings_manager:
		return
	
	var alchemist_lvl = _buildings_manager.get_building_level("alchemist")
	if alchemist_lvl < 1:
		return  # No alchemist
	
	# ✅ TEMP: production every 5 seconds (instead of 300)
	var cycle: float = 5.0  # Temporary for testing
	
	_potion_timer += delta
	if _potion_timer >= cycle:
		_potion_timer = 0.0
		_potions_global += 1
		# ✅ TEMP: max 10 potions (instead of 10 * level)
		var cap = 10
		if _potions_global > cap:
			_potions_global = cap
		# print("[TownPotions] ✅ Produced potion! Total: %d (cap: %d, timer reset)" % [_potions_global, cap])
		potion_produced.emit(_potions_global)
		if SaveCore:
			SaveCore.request_save()

func set_potions(potions: int) -> void:
	_potions_global = potions

func add_potions(amount: int) -> void:
	if amount <= 0:
		return
	_potions_global += amount
	potion_produced.emit(_potions_global)
	if SaveCore:
		SaveCore.request_save()

func get_potion_timer() -> float:
	return _potion_timer

func set_potion_timer(timer: float) -> void:
	_potion_timer = timer

