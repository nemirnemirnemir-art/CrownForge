class_name BuildingData extends Resource

@export var id: String
@export var display_name: String
@export var description: String
@export var icon: Texture2D

@export_group("Level 1 Stats")
@export var base_food_per_sec: float = 0.0
@export var base_gold_per_sec: float = 0.0
@export var base_population_capacity: int = 0
@export var base_passive_damage_per_sec: float = 0.0
@export var base_potion_production_cycle_sec: float = 0.0
@export var base_potion_heal_amount: float = 0.0
@export var base_hospital_heal_interval_sec: float = 0.0

@export_group("Upgrade Scaling")
@export var food_per_level: float = 0.0
@export var gold_per_level: float = 0.0
@export var population_per_level: int = 0
@export var passive_damage_per_level: float = 0.0
@export var heal_per_level: float = 0.0

@export_group("Upgrade Costs")
@export var base_upgrade_cost_gold: float = 10.0
@export var upgrade_cost_multiplier: float = 1.5

@export_group("Global Bonuses")
## Global defense bonus per level (Barracks)
@export var global_defense_per_level: int = 0
## Global damage bonus percent per level (Training Grounds)
@export var global_damage_percent_per_level: float = 0.0
## Global XP bonus percent per level (Academy)
@export var global_xp_percent_per_level: float = 0.0

@export_group("Mage Tower Skills")
@export var skill1_duration_bonus_per_level: float = 0.0
@export var skill1_cooldown_reduction_per_level: float = 0.0
@export var skill1_autoclick_interval_reduction_per_level: float = 0.0
@export var skill1_extra_autoclicks_per_level: int = 0
@export var skill2_duration_bonus_per_level: float = 0.0
@export var skill2_damage_multiplier_per_level: float = 0.0
## Click damage bonus per level (Mage Tower)
@export var click_damage_bonus_per_level: float = 0.0

@export_group("Forge Bonuses")
@export var forge_core_gain_per_level: int = 0
@export var forge_crafting_cost_reduction_per_level: float = 0.0

@export_group("Perk Unlocks")
## Array of {level: int, perk_id: String} for unlocking perks
@export var unlocked_perks: Array[Dictionary] = []

@export_group("Workers")
## Maximum workers this building can have (usually = level)
@export var max_workers: int = 0
## Production bonus per worker (e.g., 0.5 for +50% per worker)
@export var worker_bonus_per_worker: float = 0.0
