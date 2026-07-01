extends RefCounted
class_name HeroBuffs

## Система баффов героев

var hero_buffs: Dictionary = {}
var _hero_data: HeroData
var _hero_health: HeroHealth

func _init(hero_data: HeroData, hero_health: HeroHealth) -> void:
	_hero_data = hero_data
	_hero_health = hero_health

func add_buff(hero_id: String, buff_id: String, duration_battles: int, stats: Dictionary) -> bool:
	if not _hero_data.has_hero(hero_id):
		return false
	
	if not hero_buffs.has(hero_id):
		hero_buffs[hero_id] = {}
	
	# Check buff slots limit (Base 4)
	var max_slots = 4
	if hero_buffs[hero_id].size() >= max_slots and not hero_buffs[hero_id].has(buff_id):
		print("[HeroBuffs] Buff limit reached for %s" % hero_id)
		return false
	
	hero_buffs[hero_id][buff_id] = {
		"duration": duration_battles,
		"stats": stats
	}
	
	print("[HeroBuffs] Added buff %s to %s (Duration: %d battles)" % [buff_id, hero_id, duration_battles])
	
	# Apply instant effects if any
	if stats.has("instant_heal_percent"):
		var heal_pct = stats["instant_heal_percent"]
		var hero = _hero_data.get_hero(hero_id)
		var max_hp = hero.get("maxHp", 10)
		_hero_health.heal_hero(hero_id, int(max_hp * heal_pct))
	
	return true

func remove_buff(hero_id: String, buff_id: String) -> void:
	if hero_buffs.has(hero_id) and hero_buffs[hero_id].has(buff_id):
		hero_buffs[hero_id].erase(buff_id)
		print("[HeroBuffs] Removed buff %s from %s" % [buff_id, hero_id])

func clear_buffs() -> void:
	hero_buffs.clear()
	# print("[HeroBuffs] All buffs cleared")

func get_hero_buffs(hero_id: String) -> Dictionary:
	if hero_buffs.has(hero_id):
		return hero_buffs[hero_id]
	return {}

func reset() -> void:
	clear_buffs()
	# print("[HeroBuffs] Reset complete")

func get_buff_modifiers(hero_id: String) -> Dictionary:
	var mods = {
		"damage_bonus_percent": 0.0,
		"damage_reduction_percent": 0.0,
		"speed_bonus_percent": 0.0
	}
	
	if hero_buffs.has(hero_id):
		for buff_id in hero_buffs[hero_id]:
			var stats = hero_buffs[hero_id][buff_id]["stats"]
			if stats.has("damage_bonus_percent"):
				mods["damage_bonus_percent"] += stats["damage_bonus_percent"]
			if stats.has("damage_reduction_percent"):
				mods["damage_reduction_percent"] += stats["damage_reduction_percent"]
			if stats.has("speed_bonus_percent"):
				mods["speed_bonus_percent"] += stats["speed_bonus_percent"]
	
	return mods

func on_wave_completed(active_hero_ids: Array[String]) -> void:
	# Decrement buff durations for ACTIVE heroes
	for hero_id in active_hero_ids:
		if hero_buffs.has(hero_id):
			var buffs_to_remove = []
			for buff_id in hero_buffs[hero_id]:
				hero_buffs[hero_id][buff_id]["duration"] -= 1
				if hero_buffs[hero_id][buff_id]["duration"] <= 0:
					buffs_to_remove.append(buff_id)
			
			for buff_id in buffs_to_remove:
				remove_buff(hero_id, buff_id)

