class_name PerkData extends Resource

@export var id: String
@export var display_name: String
@export var description: String
@export var icon: Texture2D
@export var is_positive: bool = true

@export_group("Effects")
## Bonus percent to potion healing (e.g. 0.25 for +25%)
@export var potion_heal_bonus_percent: float = 0.0
## Bonus to max potions carried
@export var max_potions_bonus: int = 0
## Bonus to armor (flat)
@export var armor_bonus: int = 0
## Bonus percent to damage (e.g. 0.10 for +10%)
@export var damage_bonus_percent: float = 0.0
## Bonus percent to movement speed (e.g. 0.15 for +15%)
@export var speed_bonus_percent: float = 0.0
## Reduction percent for rest time (e.g. 0.25 for -25% rest needed)
@export var fatigue_rest_reduction_percent: float = 0.0

@export_group("Advanced Effects")
## Chance to fully block incoming damage (0.0 to 1.0)
@export var block_chance_percent: float = 0.0
## Flat damage bonus
@export var damage_bonus_flat: int = 0
## Bonus percent to XP gain (self)
@export var xp_bonus_percent: float = 0.0
## Bonus percent to XP gain (team/other heroes)
@export var team_xp_bonus_percent: float = 0.0
## Conditional damage bonus percent (e.g. Duelist)
@export var damage_bonus_percent_conditional: float = 0.0
## Range for conditional check (e.g. Duelist radius)
@export var conditional_check_range: float = 0.0
