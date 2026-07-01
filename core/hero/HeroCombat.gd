extends RefCounted
class_name HeroCombat

## Боевая механика героев
## Урон, защита, смерть

var _hero_data: HeroData
var _hero_stats: HeroStats
var _hero_buffs: HeroBuffs

func _init(hero_data: HeroData, hero_stats: HeroStats, hero_buffs: HeroBuffs) -> void:
	_hero_data = hero_data
	_hero_stats = hero_stats
	_hero_buffs = hero_buffs

func take_damage(hero_id: String) -> Dictionary:
	# Returns: {"died": bool, "actual_damage": float}
	var result = {"died": false, "actual_damage": 0.0}
	
	if not _hero_data.has_hero(hero_id):
		return result
	
	var hero = _hero_data.get_hero(hero_id)
	if hero.get("isDead", false):
		return result
	
	# This function should be called with amount, but for now we'll make it a parameter
	# Actually, let's make it take_damage(hero_id, amount)
	return result

func take_damage_with_amount(hero_id: String, amount: float) -> Dictionary:
	# Returns: {"died": bool, "actual_damage": float}
	var result = {"died": false, "actual_damage": 0.0}
	
	if not _hero_data.has_hero(hero_id):
		return result
	
	var hero = _hero_data.get_hero(hero_id)
	if hero.get("isDead", false):
		return result
	
	var current_hp = hero.get("hp", 0)
	
	# Calculate total defense
	var defense = _hero_stats.get_hero_defense(hero_id)
	
	# Apply Buff Damage Reduction
	var buff_mods = _hero_buffs.get_buff_modifiers(hero_id)
	var reduction_pct = buff_mods["damage_reduction_percent"]
	var reduced_amount = amount * (1.0 - reduction_pct)
	
	# Damage formula: Flat reduction, min 1 damage
	var actual_damage = max(1.0, reduced_amount - defense)
	
	current_hp -= actual_damage
	if current_hp < 0:
		current_hp = 0
	
	_hero_data.update_hero(hero_id, {"hp": current_hp})
	result["actual_damage"] = actual_damage
	
	# Check death
	if current_hp <= 0:
		_hero_data.mark_hero_dead(hero_id)
		result["died"] = true
	
	return result

