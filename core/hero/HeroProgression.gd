extends RefCounted
class_name HeroProgression

## Система прогрессии героев
## XP, левелинг, назначение перков

var _hero_data: HeroData
var _hero_perks: HeroPerks
var _hero_stats: HeroStats
var _hero_mutator: HeroMutator

func _init(hero_data: HeroData, hero_perks: HeroPerks, hero_stats: HeroStats, mutator: HeroMutator = null) -> void:
	_hero_data = hero_data
	_hero_perks = hero_perks
	_hero_stats = hero_stats
	_hero_mutator = mutator

func set_mutator(mutator: HeroMutator) -> void:
	_hero_mutator = mutator

func add_xp_to_hero(hero_id: String, xp_amount: int, active_hero_ids: Array[String]) -> bool:
	if not _hero_data.has_hero(hero_id):
		return false
	
	var hero = _hero_data.get_hero(hero_id)
	var current_level = hero.get("level", 1)
	var max_level = 50 # Cap level
	
	if current_level >= max_level:
		return false
		
	var xp_mult = _hero_stats.get_hero_xp_gain_multiplier(hero_id, active_hero_ids)
	var final_xp = int(xp_amount * xp_mult)
	
	# Use Mutator for modification
	if _hero_mutator:
		_hero_mutator.add_hero_xp(hero_id, final_xp)
	else:
		# Fallback
		var current_xp = hero.get("xp", 0)
		hero["xp"] = current_xp + final_xp
	
	# Check level up
	var xp_needed = get_xp_for_next_level(current_level)
	var current_xp_total = hero.get("xp", 0) # Get updated value
	
	if current_xp_total >= xp_needed:
		_level_up_hero(hero_id)
		return true
		
	return false

func _level_up_hero(hero_id: String) -> void:
	if not _hero_data.has_hero(hero_id):
		return
		
	var hero = _hero_data.get_hero(hero_id)
	var current_level = hero.get("level", 1)
	var new_level = current_level + 1
	
	if _hero_mutator:
		_hero_mutator.set_hero_level(hero_id, new_level)
		
		var xp_cost = get_xp_for_next_level(current_level)
		_hero_mutator.add_hero_xp(hero_id, -xp_cost)
		
		# Increase Stats via Mutator
		var max_hp_increase = 5.0 # Base increase
		var damage_increase = 1.0
		
		_hero_mutator.upgrade_hero_stats(hero_id, max_hp_increase, damage_increase, true)
		
	else:
		hero["level"] = new_level
		hero["xp"] -= get_xp_for_next_level(current_level)
		hero["maxHp"] += 5
		hero["hp"] = hero["maxHp"]
		hero["damage"] += 1
	
	# Assign perks
	var perk = _hero_perks.check_level_up_perks(hero, new_level)
	if perk != "":
		# print("[HeroProgression] Hero %s gained perk %s" % [hero.get("name"), perk])
		pass

func get_xp_for_next_level(level: int) -> int:
	return level * 10
