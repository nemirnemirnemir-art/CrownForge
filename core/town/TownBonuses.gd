extends RefCounted
class_name TownBonuses

## Глобальные бонусы
## Кэширование и пересчет бонусов (defense, damage, XP)

var _cached_global_defense: int = 0
var _cached_global_damage: float = 0.0
var _cached_global_xp: float = 0.0
var _cache_dirty: bool = true
var _buildings_manager: TownBuildings

func initialize(buildings_manager: TownBuildings) -> void:
	_buildings_manager = buildings_manager

func get_global_defense_bonus() -> int:
	if _cache_dirty:
		_recalculate_global_bonuses()
	return _cached_global_defense

func get_global_damage_bonus() -> float:
	if _cache_dirty:
		_recalculate_global_bonuses()
	return _cached_global_damage

func get_global_xp_bonus() -> float:
	if _cache_dirty:
		_recalculate_global_bonuses()
	return _cached_global_xp

func get_click_damage_bonus() -> float:
	## Returns flat click damage bonus from Mage Tower
	if not _buildings_manager:
		return 0.0
	
	var mage_tower_id = "mage_tower"
	var buildings = _buildings_manager.get_buildings()
	if not buildings.has(mage_tower_id):
		return 0.0
	
	var level = buildings[mage_tower_id]["level"]
	var data = _buildings_manager.get_building_config(mage_tower_id)
	if not data:
		return 0.0
	
	return data.click_damage_bonus_per_level * level

func _recalculate_global_bonuses() -> void:
	if not _buildings_manager:
		return
	
	_cached_global_defense = 0
	_cached_global_damage = 0.0
	_cached_global_xp = 0.0
	
	var buildings = _buildings_manager.get_buildings()
	var registry = _buildings_manager.get_building_registry()
	
	for building_id in buildings:
		var level = buildings[building_id]["level"]
		var data = registry.get(building_id)
		if not data:
			continue
		
		# Defense from Barracks
		if data.global_defense_per_level > 0:
			_cached_global_defense += data.global_defense_per_level * level
		
		# Damage from Training Grounds
		if data.global_damage_percent_per_level > 0:
			_cached_global_damage += data.global_damage_percent_per_level * level
		
		# XP from Academy
		if data.global_xp_percent_per_level > 0:
			_cached_global_xp += data.global_xp_percent_per_level * level
	
	_cache_dirty = false

func invalidate_cache() -> void:
	_cache_dirty = true

