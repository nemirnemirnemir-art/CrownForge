extends RefCounted
class_name TownHospital

## Больница
## Лечение героев, таймеры

const HOSPITAL_TICK_TIME: float = 5.0

var _hospital_timer: float = 0.0
var _buildings_manager: TownBuildings

func initialize(buildings_manager: TownBuildings) -> void:
	_buildings_manager = buildings_manager

func process_hospital(delta: float) -> void:
	if not _buildings_manager:
		return
	
	var hospital_lvl = _buildings_manager.get_building_level("hospital")
	if hospital_lvl >= 1:
		var data = _buildings_manager.get_building_config("hospital")
		if not data:
			return
		
		var interval = data.base_hospital_heal_interval_sec
		if interval <= 0:
			return
		
		_hospital_timer += delta
		if _hospital_timer >= interval:
			_hospital_timer = 0.0
			_heal_random_hero()

func _heal_random_hero() -> void:
	if not HeroCore:
		return
	
	var injured_heroes = []
	for hero_id in HeroCore.heroes:
		var hero = HeroCore.heroes[hero_id]
		# Лечим только неактивных героев (тех, кто не на поле)
		if not hero.get("isDead", false) and not hero.get("isActive", false) and hero.get("hp", 0) < hero.get("maxHp", 10):
			injured_heroes.append(hero_id)
	
	if injured_heroes.size() > 0:
		var rng = RandomNumberGenerator.new()
		rng.randomize()
		var chosen_id = injured_heroes[rng.randi() % injured_heroes.size()]
		
		# ✅ Heal amount from upgrades
		var heal_amount = 1.0 # Base
		if _buildings_manager:
			var hospital_lvl = _buildings_manager.get_building_level("hospital")
			var data = _buildings_manager.get_building_config("hospital")
			
			if data and hospital_lvl > 0:
				# Formula: base (1) + (level - 1) * heal_per_level
				var per_level = data.heal_per_level
				heal_amount = 1.0 + (float(hospital_lvl - 1) * per_level)
		
		# Round to int for HeroCore
		var final_heal = int(heal_amount)
		HeroCore.heal_hero(chosen_id, final_heal)
		# Signal is emitted by HeroCore on update, but we might want a specific "hospital heal" event for UI
		EventBus.hero_healed_by_hospital.emit(chosen_id, final_heal)

func set_hospital_timer(timer: float) -> void:
	_hospital_timer = timer

