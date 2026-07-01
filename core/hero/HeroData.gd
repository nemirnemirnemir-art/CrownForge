extends RefCounted
class_name HeroData

const PathRegistryScript := preload("res://scripts/systems/PathRegistry.gd")
const INTRINSIC_SPEED_VARIANTS := [0.80, 0.85, 0.90, 0.95, 1.05, 1.10, 1.15, 1.20]

## Hero data management - CRUD operations
var heroes: Dictionary = {}
var registry: HeroRegistry

func _init() -> void:
	var registry_path := "res://scripts/resources/HeroRegistry.tres"
	if ResourceLoader.exists(registry_path):
		registry = load(registry_path)
	else:
		registry = HeroRegistry.new()
	
	initialize_base_heroes()

func initialize_base_heroes() -> void:
	if registry and not registry.available_heroes.is_empty():
		# print("[HeroData] Initializing from Registry with %d heroes." % registry.available_heroes.size())
		for def in registry.available_heroes:
			create_hero_from_def(def)
	else:
		# print("[HeroData] Registry empty or missing. Using hardcoded defaults.")
		_create_hero_from_unit_config("peasant", "Peasant", 200.0)
		_create_hero_from_unit_config("slinger", "Slinger", 100.0)
		_create_hero_from_unit_config("crossbowman", "Crossbowman", 120.0)
		_create_hero_from_unit_config("hunter", "Hunter", 120.0)
		_create_hero_from_unit_config("militia", "Militia", 240.0)
		_create_hero_from_unit_config("swordsman", "Swordsman", 220.0)
		_create_hero_from_unit_config("gnome", "Gnome", 300.0)
		_create_hero_from_unit_config("assassin", "Assassin", 260.0)
		_create_hero_from_unit_config("small_bones", "Small Bones", 150.0)
		_create_hero_from_unit_config("black_swordsman", "Black Swordsman", 350.0)
		_create_hero_from_unit_config("musketeer", "Musketeer", 280.0)
		
		# print("[HeroData] Initialized with 6 heroes.")

func _create_hero_from_unit_config(hero_id: String, display_name: String, cost: float) -> void:
	var hp := 10.0
	var dmg := 5.0
	var unit_cfg := _try_load_unit_config(hero_id)
	if unit_cfg != null:
		if "hp" in unit_cfg:
			hp = float(unit_cfg.hp)
		if "dps" in unit_cfg:
			dmg = float(unit_cfg.dps)
		print("[HeroData] ✅ Loaded %s from UnitConfig: HP=%d, DPS=%d" % [hero_id, hp, dmg])
	else:
		print("[HeroData] ⚠️ UnitConfig NOT found for %s, using defaults (HP=10, DPS=5)" % hero_id)
	create_hero(hero_id, display_name, hero_id, cost, "", hp, dmg)

func _try_load_unit_config(unit_id: String) -> Resource:
	var path := PathRegistryScript.resolve_unit_config_path(unit_id)
	if path != "" and ResourceLoader.exists(path):
		var cfg := load(path)
		if cfg != null:
			return cfg
	if unit_id.strip_edges() != "":
		print("[HeroData] ❌ Failed to load UnitConfig for id: %s" % unit_id)
	return null

func create_hero_from_def(def: HeroDefinition) -> void:
	if def == null:
		return
	var id_lower := def.id.to_lower()
	var name := def.display_name if def.display_name != "" else id_lower.capitalize()
	var icon_id := id_lower
	var cost := def.cost
	var hp := def.base_hp
	var dmg := def.base_damage
	if create_hero(id_lower, name, icon_id, cost, "", hp, dmg):
		heroes[id_lower]["is_ranged"] = def.is_ranged
		heroes[id_lower]["attack_range"] = def.attack_range
		heroes[id_lower]["max_range"] = def.max_range

func create_hero(hero_id: String, name: String, icon_id: String, cost: float, person_id: String = "", base_hp: float = -1.0, base_damage: float = -1.0) -> bool:
	if heroes.has(hero_id):
		return false
	
	# If stats not provided, try to find them from base type
	if base_hp < 0 or base_damage < 0:
		var type = hero_id
		if hero_id.contains("_"):
			type = hero_id.split("_")[0]
		
		var cfg_hp = get_base_hp(type)
		var cfg_dmg = get_base_damage(type)
		
		if base_hp < 0: base_hp = cfg_hp
		if base_damage < 0: base_damage = cfg_dmg

	heroes[hero_id] = {
		"id": hero_id,
		"name": name,
		"icon_id": icon_id,
		"person_id": person_id,
		"level": 1,
		"base_damage": base_damage,
		"base_hp": base_hp,
		"damage": base_damage,
		"maxHp": base_hp,
		"hp": base_hp,
		"damage_multiplier": 1.0,
		"hp_multiplier": 1.0,
		"intrinsic_speed_multiplier": _roll_intrinsic_speed_multiplier(),
		"cost": cost,
		"is_hired": false,
		"equipment": {
			"weapon": null,
			"armor": null,
			"accessory": null
		},
		"buffs": {},
		"potions_carried": 0,
		"max_potions": 1,
		"mood": 50.0,
		"perks": []
	}
	
	return true

## Ensure default heroes exist and have correct stats
func ensure_default_heroes() -> void:
	var defaults = [
		{"id": "peasant", "name": "Peasant", "cost": 200.0},
		{"id": "slinger", "name": "Slinger", "cost": 100.0},
		{"id": "crossbowman", "name": "Crossbowman", "cost": 120.0},
		{"id": "hunter", "name": "Hunter", "cost": 120.0},
		{"id": "militia", "name": "Militia", "cost": 240.0},
		{"id": "swordsman", "name": "Swordsman", "cost": 220.0},
		{"id": "gnome", "name": "Gnome", "cost": 300.0},
		{"id": "assassin", "name": "Assassin", "cost": 260.0},
		{"id": "small_bones", "name": "Small Bones", "cost": 150.0},
	]
	for d in defaults:
		if not heroes.has(d.id):
			create_hero(d.id, d.name, d.id, d.cost)
		else:
			_revalidate_hero_stats(d.id)

func _revalidate_hero_stats(hero_id: String) -> void:
	if not heroes.has(hero_id): return
	var hero = heroes[hero_id]
	var type = hero_id
	if hero_id.contains("_"):
		type = hero_id.split("_")[0]
	
	var base_hp = get_base_hp(type)
	var base_dmg = get_base_damage(type)
	
	# Only update if it's the old 10/5 default or field missing
	if hero.get("base_hp", 10.0) == 10.0 or not hero.has("base_hp"):
		hero["base_hp"] = base_hp
		hero["maxHp"] = base_hp
		hero["hp"] = base_hp
	if hero.get("base_damage", 5.0) == 5.0 or not hero.has("base_damage"):
		hero["base_damage"] = base_dmg
		hero["damage"] = base_dmg
	if not hero.has("intrinsic_speed_multiplier"):
		hero["intrinsic_speed_multiplier"] = _roll_intrinsic_speed_multiplier()

func revalidate_all_heroes() -> void:
	for id in heroes.keys():
		_revalidate_hero_stats(id)


func _roll_intrinsic_speed_multiplier() -> float:
	return float(INTRINSIC_SPEED_VARIANTS[randi() % INTRINSIC_SPEED_VARIANTS.size()])

func get_base_damage(hero_id: String) -> float:
	var base_type := hero_id
	var cfg = _try_load_unit_config(base_type)
	if cfg == null and hero_id.contains("_"):
		base_type = hero_id.split("_")[0]
		cfg = _try_load_unit_config(base_type)
	if cfg and "dps" in cfg:
		return float(cfg.dps)
	
	# 2. Fallback: Local data
	if heroes.has(hero_id):
		return float(heroes[hero_id].get("base_damage", 5.0))
	
	return 5.0
	
func get_base_hp(hero_id: String) -> float:
	var base_type := hero_id
	var cfg = _try_load_unit_config(base_type)
	if cfg == null and hero_id.contains("_"):
		base_type = hero_id.split("_")[0]
		cfg = _try_load_unit_config(base_type)
	if cfg and "hp" in cfg:
		return float(cfg.hp)
		
	# 2. Fallback: Local data
	if heroes.has(hero_id):
		return float(heroes[hero_id].get("base_hp", 10.0))
		
	return 10.0

func get_hero(hero_id: String) -> Dictionary:
	if heroes.has(hero_id):
		return heroes[hero_id]
	return {}

func update_hero(hero_id: String, updates: Dictionary) -> void:
	if not heroes.has(hero_id):
		return
	
	for key in updates:
		heroes[hero_id][key] = updates[key]

func remove_hero(hero_id: String) -> Dictionary:
	if not heroes.has(hero_id):
		return {}
	
	var hero = heroes[hero_id].duplicate()
	heroes.erase(hero_id)
	return hero

func mark_hero_dead(hero_id: String) -> void:
	if heroes.has(hero_id):
		heroes[hero_id]["isDead"] = true
		# print("[HeroData] Marking hero %s as dead" % hero_id)

func clear_all_heroes() -> void:
	heroes.clear()
	# print("[HeroData] All heroes cleared")

func reset() -> void:
	clear_all_heroes()
	initialize_base_heroes()
	# print("[HeroData] Reset complete")

func has_hero(hero_id: String) -> bool:
	return heroes.has(hero_id)

func get_all_hero_ids() -> Array[String]:
	var result: Array[String] = []
	for key in heroes:
		result.append(key)
	return result

func validate_equipment_structure(hero_id: String) -> void:
	if not heroes.has(hero_id):
		return
	
	var hero = heroes[hero_id]
	if not hero.has("equipment"):
		hero["equipment"] = {
			"weapon": null,
			"armor": null,
			"helmet": null,
			"ring": null
		}
