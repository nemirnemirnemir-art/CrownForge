extends RefCounted
class_name HeroPerks

## Система перков героев
## Управляет загрузкой, хранением и применением перков

var _perk_registry: Dictionary = {}

func _init() -> void:
	_load_perks()

func _load_perks() -> void:
	var dir_path = "res://data/perks/"
	var dir = DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres") or file_name.ends_with(".remap"):
				var clean_name = file_name.replace(".remap", "")
				var res = load(dir_path + clean_name) as PerkData
				if res:
					_perk_registry[res.id] = res
			file_name = dir.get_next()
	else:
		print("[HeroPerks] Failed to open perks directory!")

func get_perk_data(perk_id: String) -> PerkData:
	if _perk_registry.has(perk_id):
		return _perk_registry[perk_id]
	return null

func get_perk_def(perk_id: String) -> PerkData:
	return _perk_registry.get(perk_id)

func get_hero_perks(hero_data: Dictionary) -> Array:
	return hero_data.get("perks", [])

func add_perk_to_hero(hero_data: Dictionary, perk_id: String) -> bool:
	if not _perk_registry.has(perk_id):
		return false
	
	if not hero_data.has("perks"):
		hero_data["perks"] = []
	
	if perk_id in hero_data["perks"]:
		return false
	
	hero_data["perks"].append(perk_id)
	return true

func get_perk_modifiers(hero_data: Dictionary) -> Dictionary:
	var mods = {
		"potion_heal_bonus": 0.0,
		"max_potions_bonus": 0,
		"armor_bonus": 0,
		"damage_bonus_percent": 0.0,
		"damage_bonus_flat": 0,
		"speed_bonus_percent": 0.0,
		"fatigue_rest_reduction": 0.0,
		"xp_bonus_percent": 0.0,
		"team_xp_bonus_percent": 0.0
	}
	
	var perks = get_hero_perks(hero_data)
	for pid in perks:
		var data = _perk_registry.get(pid)
		if data:
			mods["potion_heal_bonus"] += data.potion_heal_bonus_percent
			mods["max_potions_bonus"] += data.max_potions_bonus
			mods["armor_bonus"] += data.armor_bonus
			mods["damage_bonus_percent"] += data.damage_bonus_percent
			mods["damage_bonus_flat"] += data.damage_bonus_flat
			mods["speed_bonus_percent"] += data.speed_bonus_percent
			mods["fatigue_rest_reduction"] += data.fatigue_rest_reduction_percent
			mods["xp_bonus_percent"] += data.xp_bonus_percent
			mods["team_xp_bonus_percent"] += data.team_xp_bonus_percent
	
	return mods

func check_level_up_perks(hero_data: Dictionary, new_level: int) -> String:
	# Pattern: Level 4 (1 pos), 8 (1 pos, 1 neg), 12 (1 pos), 16 (1 pos, 1 neg)...
	# Every 4 levels: get a positive perk.
	# Every 8 levels: get a negative perk too.
	
	var assigned_perk: String = ""
	
	if new_level % 4 == 0:
		assigned_perk = assign_random_perk(hero_data, true)
	
	if new_level % 8 == 0:
		var neg_perk = assign_random_perk(hero_data, false)
		if neg_perk != "":
			assigned_perk = neg_perk
	
	return assigned_perk

func assign_random_perk(hero_data: Dictionary, positive: bool) -> String:
	var candidates = []
	for pid in _perk_registry:
		var data = _perk_registry[pid]
		if data.is_positive == positive:
			# Check availability
			if not is_perk_available_in_pool(pid):
				continue
			
			# Check if hero already has it
			var hero_perks = get_hero_perks(hero_data)
			if not pid in hero_perks:
				candidates.append(pid)
	
	if candidates.size() > 0:
		var rng = RandomNumberGenerator.new()
		rng.randomize()
		var chosen = candidates[rng.randi() % candidates.size()]
		if add_perk_to_hero(hero_data, chosen):
			print("[HeroPerks] Assigned perk %s" % chosen)
			return chosen
	
	return ""

func is_perk_available_in_pool(perk_id: String) -> bool:
	# 1. Check if unlocked globally via TownCore
	if TownCore and TownCore.is_perk_unlocked(perk_id):
		return true
	
	# 2. Check if it's a base perk (not locked behind any building)
	var lockable_perks = [
		"shield_wall", "vanguard", "dragonslayer",
		"steel_grip", "powerful_thrust", "duelist",
		"fast_learner", "mentor"
	]
	
	if perk_id in lockable_perks:
		return false # It's a lockable perk, and we already checked is_perk_unlocked above
	
	return true # It's a base perk

