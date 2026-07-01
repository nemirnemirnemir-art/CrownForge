extends RefCounted
class_name HeroBattle

## Hero battle management
## Start/end battle and replace fallen heroes

var _heroes_in_battle: Array[String] = []
var _hero_data: HeroData
var _hero_squad: HeroSquad

func _init(hero_data: HeroData, hero_squad: HeroSquad) -> void:
	_hero_data = hero_data
	_hero_squad = hero_squad

func get_available_for_battle() -> Array[String]:
	var available: Array[String] = []
	for hero_id in _hero_data.get_all_hero_ids():
		var hero = _hero_data.get_hero(hero_id)
		
		# Skip dead heroes
		if hero.get("isDead", false):
			continue
		
		# Skip heroes already in battle
		if hero_id in _heroes_in_battle:
			continue
			
		# Skip non-hired heroes (e.g., shop templates)
		if not hero.get("is_hired", false):
			continue
		
		available.append(hero_id)
	
	return available

func start_battle_with_heroes(hero_ids: Array) -> bool:
	if is_battle_active():
		# print("[HeroBattle] ⚠️ Battle already active, cannot start new one")
		return false
	
	if hero_ids.is_empty():
		# print("[HeroBattle] ⚠️ No heroes provided for battle")
		return false
	
	# print("[HeroBattle] DEBUG: Starting battle with IDs: %s" % str(hero_ids))

	_heroes_in_battle.clear()# Clear previous list
	_heroes_in_battle.clear()
	
	# Force clear active squad to ensure it matches battle participants
	_hero_squad.clear_squad()
	
	# Add heroes to battle
	for hero_id in hero_ids:
		if _hero_data.has_hero(hero_id):
			# Skip dead heroes
			if _hero_data.get_hero(hero_id).get("isDead", false):
				# print("[HeroBattle] ⚠️ Skipping dead hero %s for battle" % hero_id)
				continue
			
			_heroes_in_battle.append(hero_id)
			# Add to squad if missing
			if not _hero_squad.is_in_squad(hero_id):
				_hero_squad.add_to_squad(hero_id)
	
	# print("[HeroBattle] ✅ Battle started with %d heroes" % _heroes_in_battle.size())
	print("[HeroBattle] DEBUG: Battle started. Heroes in battle: %s" % str(_heroes_in_battle))
	print("[HeroBattle] DEBUG: Squad active IDs: %s" % str(_hero_squad.active_hero_ids))
	return true

func end_current_battle(is_victory: bool = false) -> Array[String]:
	var surviving: Array[String] = []
	
	if is_battle_active():
		# Collect survivors and remove them from the active squad (leave the field)
		for hero_id in _heroes_in_battle:
			if _hero_data.has_hero(hero_id):
				var hero = _hero_data.get_hero(hero_id)
				if not hero.get("isDead", false):
					surviving.append(hero_id)
					# Remove from active squad so they leave the field
					_hero_squad.remove_from_squad(hero_id)
	
	_heroes_in_battle.clear()
	# print("[HeroBattle] ✅ Battle ended (Victory=%s), %d heroes survived" % [is_victory, surviving.size()])
	return surviving

func replace_dead_hero(dead_id: String) -> String:
	# Ensure the hero was in battle
	if dead_id not in _heroes_in_battle:
		return ""
	
	# Remove dead hero from fighters list
	_heroes_in_battle.erase(dead_id)
	
	# Find replacement
	var available = get_available_for_battle()
	if available.is_empty():
		# print("[HeroBattle] ⚠️ No heroes available to replace %s" % dead_id)
		return ""
	
	# Random pick
	available.shuffle()
	var new_id = available[0]
	
	# Add to battle
	_heroes_in_battle.append(new_id)
	
	# Add to squad
	if not _hero_squad.is_in_squad(new_id):
		_hero_squad.add_to_squad(new_id)
	
	# print("[HeroBattle] ✅ Hero %s replaced by %s" % [dead_id, new_id])
	return new_id

func replace_dead_hero_with(dead_id: String, new_id: String) -> bool:
	if dead_id not in _heroes_in_battle:
		return false
	if new_id == "":
		return false
	if not _hero_data.has_hero(new_id):
		return false

	_heroes_in_battle.erase(dead_id)
	if new_id not in _heroes_in_battle:
		_heroes_in_battle.append(new_id)
	if not _hero_squad.is_in_squad(new_id):
		_hero_squad.add_to_squad(new_id)
	return true

func clear_battle() -> void:
	_heroes_in_battle.clear()
	# print("[HeroBattle] Battle state cleared")

func get_heroes_in_battle() -> Array[String]:
	return _heroes_in_battle.duplicate()

func is_battle_active() -> bool:
	return not _heroes_in_battle.is_empty()

func reset() -> void:
	clear_battle()
	# print("[HeroBattle] Reset complete")

