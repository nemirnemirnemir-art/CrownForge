extends RefCounted
class_name DamageCalculator

## Static utility class for damage and health calculations
## All methods are static and can be called directly: DamageCalculator.calculate_enemy_hp(5)

## Constants
const BASE_ENEMY_HP: float = 10.0
const BASE_GOLD_REWARD: float = 5.0
const ENEMY_HP_POWER: float = 1.2

## Calculate total click damage
## Formula: base * upgrade_mult * (1 + stars * 0.02) * skill_multiplier + click_damage_bonus
static func calculate_click_damage(base: float, upgrade_mult: float, stars: int, skill_multiplier: float = 1.0, click_damage_bonus: float = 0.0) -> float:
	return base * upgrade_mult * (1.0 + stars * 0.02) * skill_multiplier + click_damage_bonus

## Calculate enemy HP for given stage
## Formula: BASE_ENEMY_HP * (stage ^ ENEMY_HP_POWER)
static func calculate_enemy_hp(stage: int) -> float:
	if stage < 1:
		stage = 1
	return BASE_ENEMY_HP * pow(stage, ENEMY_HP_POWER)

## Calculate gold reward for given stage
## Formula: BASE_GOLD_REWARD * stage
static func calculate_gold_reward(stage: int) -> float:
	if stage < 1:
		stage = 1
	return BASE_GOLD_REWARD * stage


