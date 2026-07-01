class_name CharacterCreationSpellCatalog
extends RefCounted

const PathRegistryScript := preload("res://scripts/systems/PathRegistry.gd")

const RESOURCE_ICON_PATHS := {
	"water": "res://assets/items/resources/water_-1.png",
	"gold": "res://assets/items/resources/gold_4.png",
	"wine": "res://assets/items/resources/wine.png",
	"meat": "res://assets/items/resources/meat_9.png",
	"wood": "res://assets/items/resources/wood_1.png",
}

const ACTIVE_RUNTIME_MAPPINGS := {
	"tough_guys": "summon_infernals",
	"resurrection": "necromancy",
	"pocket_demons": "summon_infernals",
	"fast_production": "wrath",
	"forced_tax": "wrath",
	"frenzy": "wrath",
	"boys_at_work": "wrath",
	"training": "wrath",
}

const ACTIVE_BASE_COOLDOWNS := {
	"tough_guys": 100.0,
	"resurrection": 120.0,
	"pocket_demons": 150.0,
	"fast_production": 240.0,
	"forced_tax": 240.0,
	"frenzy": 200.0,
	"boys_at_work": 200.0,
	"training": 180.0,
}

const SPELL_DEFS := {
	"tough_guys": {
		"category": "active",
		"display_name": "Tough Guys",
		"texture": preload("res://assets/Characher_Creation/spells/tough_guys.png"),
		"resource": "water",
		"cost": 30,
		"description": "Summons 3 Peasants (+1 per upgrade).",
		"description_segments": [
			{"text": "Summons "},
			{"unit_face_id": "peasant"},
			{"text": " 3 Peasants (+1 per upgrade)."},
		],
	},
	"resurrection": {
		"category": "active",
		"display_name": "Necromancy",
		"texture": preload("res://assets/Characher_Creation/spells/resurrection.png"),
		"resource": "water",
		"cost": 25,
		"description": "Resurrect up to 2 dead bodies in an area to fight for you (+1 per upgrade).",
	},
	"pocket_demons": {
		"category": "active",
		"display_name": "Demonology",
		"texture": preload("res://assets/Characher_Creation/spells/pocket_demons.png"),
		"resource": "water",
		"cost": 100,
		"description": "Summon 1 Familiar (+25% all base stats per upgrade). Base Familiar stats: 120 HP, 20 DPS.",
		"description_segments": [
			{"text": "Summon 1 "},
			{"unit_face_id": "familiar"},
			{"text": " Familiar (+25% all base stats per upgrade). Base Familiar stats: 120 HP, 20 DPS."},
		],
	},
	"fast_production": {
		"category": "active",
		"display_name": "Fast Production",
		"texture": preload("res://assets/Characher_Creation/spells/fast_production.png"),
		"resource": "gold",
		"cost": 20,
		"description": "Increases all building production by 32% for 25 seconds (+8% per upgrade).",
	},
	"forced_tax": {
		"category": "active",
		"display_name": "Forced Tax",
		"texture": preload("res://assets/Characher_Creation/spells/forced_tax.png"),
		"resource": "gold",
		"cost": 35,
		"description": "Gain 100 resources of your choice (-10 sec cooldown per upgrade).",
	},
	"frenzy": {
		"category": "active",
		"display_name": "Frenzy",
		"texture": preload("res://assets/Characher_Creation/spells/Frenzy.png"),
		"resource": "wine",
		"cost": 10,
		"description": "Gives Wrath to all player units for 6 seconds.",
	},
	"boys_at_work": {
		"category": "active",
		"display_name": "Boys at Work",
		"texture": preload("res://assets/Characher_Creation/spells/Boys at Work.png"),
		"resource": "gold",
		"cost": 20,
		"description": "All buildings work for 15 seconds regardless of their current gaze position.",
	},
	"training": {
		"category": "active",
		"display_name": "Training",
		"texture": preload("res://assets/Characher_Creation/spells/Traning.png"),
		"resource": "meat",
		"cost": 10,
		"description": "Adds 100 HP to each player unit on the battlefield.",
	},
	"lumberjack": {
		"category": "passive",
		"display_name": "Lumberjack",
		"texture": preload("res://assets/Characher_Creation/Passive_spells/Lumberjack.png"),
		"description": "After cutting 10 trees, can get 300 wood.",
	},
	"reward": {
		"category": "passive",
		"display_name": "Reward",
		"texture": preload("res://assets/Characher_Creation/Passive_spells/Reward.png"),
		"description": "After killing a Boss, can get an Established Production building blueprint.",
	},
	"good_reward": {
		"category": "passive",
		"display_name": "Good Reward",
		"texture": preload("res://assets/Characher_Creation/Passive_spells/Good Reward.png"),
		"description": "After killing 2 Bosses, can get a Legendary Artifact.",
	},
	"last_chance": {
		"category": "passive",
		"display_name": "Last Chance",
		"texture": preload("res://assets/Characher_Creation/Passive_spells/last chance.png"),
		"description": "After castle HP drops below 30, can summon 10 Militia to help.",
	},
	"spells_for_work": {
		"category": "passive",
		"display_name": "Spells for Work",
		"texture": preload("res://assets/Characher_Creation/Passive_spells/Spells for work.png"),
		"description": "After killing a Boss, can get 3 choices of Spells.",
	},
	"spicy_boys": {
		"category": "passive",
		"display_name": "Spicy Boys",
		"texture": preload("res://assets/Characher_Creation/Passive_spells/Spicy boys.png"),
		"description": "With 70 morale, can summon 10 Bumblebees.",
	},
}

static func has_spell(spell_id: String) -> bool:
	return SPELL_DEFS.has(String(spell_id).strip_edges().to_lower())

static func get_spell_def(spell_id: String) -> Dictionary:
	var normalized_id := String(spell_id).strip_edges().to_lower()
	var def: Dictionary = SPELL_DEFS.get(normalized_id, {})
	return def.duplicate(true)

static func get_spell_category(spell_id: String) -> String:
	return String(SPELL_DEFS.get(String(spell_id).strip_edges().to_lower(), {}).get("category", ""))

static func get_base_cooldown(spell_id: String) -> float:
	return float(ACTIVE_BASE_COOLDOWNS.get(String(spell_id).strip_edges().to_lower(), 0.0))

static func get_spell_cost_resource_id(spell_id: String) -> String:
	var normalized_id := String(spell_id).strip_edges().to_lower()
	return String(SPELL_DEFS.get(normalized_id, {}).get("resource", ""))

static func get_spell_base_cost(spell_id: String) -> int:
	var normalized_id := String(spell_id).strip_edges().to_lower()
	return int(SPELL_DEFS.get(normalized_id, {}).get("cost", 0))

static func get_spell_cost(spell_id: String, upgrade_level: int = 0) -> int:
	var normalized_id := String(spell_id).strip_edges().to_lower()
	var base_cost := get_spell_base_cost(normalized_id)
	if normalized_id == "tough_guys":
		return base_cost + max(0, upgrade_level) * 10
	return base_cost

static func get_spell_effective_cooldown(spell_id: String, upgrade_level: int = 0) -> float:
	var normalized_id := String(spell_id).strip_edges().to_lower()
	var cooldown := get_base_cooldown(normalized_id)
	if normalized_id == "forced_tax":
		cooldown = maxf(0.0, cooldown - 10.0 * float(max(0, upgrade_level)))
	return cooldown

static func get_spell_description_segments(spell_id: String) -> Array:
	var normalized_id := String(spell_id).strip_edges().to_lower()
	var raw: Variant = SPELL_DEFS.get(normalized_id, {}).get("description_segments", [])
	if raw is Array:
		return (raw as Array).duplicate(true)
	return []

static func get_resource_icon_path(resource_id: String) -> String:
	return String(RESOURCE_ICON_PATHS.get(String(resource_id).strip_edges().to_lower(), ""))

static func is_active_spell(spell_id: String) -> bool:
	return get_spell_category(spell_id) == "active"

static func is_passive_spell(spell_id: String) -> bool:
	return get_spell_category(spell_id) == "passive"

static func create_spell_config(spell_id: String) -> SpellConfig:
	var normalized_id := String(spell_id).strip_edges().to_lower()
	if normalized_id == "":
		return null
	var def: Dictionary = SPELL_DEFS.get(normalized_id, {})
	if def.is_empty():
		return null
	var config := SpellConfig.new()
	config.spell_id = normalized_id
	config.spell_name = String(def.get("display_name", normalized_id.capitalize().replace("_", " ")))
	config.description = String(def.get("description", ""))
	config.icon = def.get("texture", null) as Texture2D
	config.max_stacks = 1
	_apply_runtime_mapping(config, normalized_id)
	return config

static func _apply_runtime_mapping(config: SpellConfig, spell_id: String) -> void:
	var runtime_spell_id := String(ACTIVE_RUNTIME_MAPPINGS.get(spell_id, "")).strip_edges().to_lower()
	if runtime_spell_id == "":
		config.target_type = "self"
		config.target_radius = 0.0
		config.effect_scene = null
		config.duration = 0.0
		config.damage = 0.0
		config.damage_per_second = 0.0
		return
	var runtime_config := PathRegistryScript.load_spell_config(runtime_spell_id) as SpellConfig
	if runtime_config == null:
		config.target_type = "self"
		config.target_radius = 0.0
		config.effect_scene = null
		config.duration = 0.0
		config.damage = 0.0
		config.damage_per_second = 0.0
		return
	config.target_radius = runtime_config.target_radius
	config.target_type = runtime_config.target_type
	config.effect_scene = runtime_config.effect_scene
	config.duration = runtime_config.duration
	config.damage = runtime_config.damage
	config.damage_per_second = runtime_config.damage_per_second
