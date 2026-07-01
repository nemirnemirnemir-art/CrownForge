extends RefCounted
class_name MoraleCalculator


const WINE_MORALE_FULL: int = 30
const WINE_MORALE_LOW: int = 15
const TAVERN_WINE_CONSUMPTION_MULTIPLIER: float = 0.5
const TAVERN_WINE_STOCK_BONUS: int = 20


func calculate_morale(input: Dictionary) -> Dictionary:
	var total := 0
	var breakdown: Dictionary = {}

	var wine_stock_bonus := int(input.get("wine_stock_morale_bonus", 0))
	if wine_stock_bonus > 0:
		total += wine_stock_bonus
		breakdown["Wine Stock"] = wine_stock_bonus
	var additional_wine_bonus := int(input.get("additional_wine_stock_morale_bonus", 0))
	if additional_wine_bonus > 0:
		total += additional_wine_bonus
		breakdown["Tavern (wine bonus)"] = additional_wine_bonus

	# TODO: unit diversity - another story for different kings
	# var diversity_bonus := int(input.get("unit_diversity_bonus", 0))
	# total += diversity_bonus
	# breakdown["Unit Diversity"] = diversity_bonus

	var artifact_bonus := int(input.get("artifact_bonus", 0))
	total += artifact_bonus
	breakdown["Artifacts"] = artifact_bonus

	var building_sources: Dictionary = input.get("building_sources", {})
	for source_key: String in building_sources:
		var bv: int = int(building_sources[source_key])
		if bv > 0:
			total += bv
			breakdown[source_key] = bv

	var arena_bonus := int(input.get("arena_bonus", 0))
	if arena_bonus > 0:
		total += arena_bonus
		breakdown["Arena"] = arena_bonus

	var debug_bonus := int(input.get("debug_bonus", 0))
	if debug_bonus > 0:
		total += debug_bonus
		breakdown["Debug Bonus"] = debug_bonus

	return {
		"total": total,
		"breakdown": breakdown,
	}


func get_wine_morale_bonus(wine: int, warriors: int) -> int:
	if wine <= 0:
		return 0
	if warriors > 0 and wine < warriors:
		return WINE_MORALE_LOW
	return WINE_MORALE_FULL


func get_wine_consumption_multiplier(has_active_tavern: bool) -> float:
	if has_active_tavern:
		return TAVERN_WINE_CONSUMPTION_MULTIPLIER
	return 1.0


func get_additional_wine_stock_morale_bonus(has_active_tavern: bool) -> int:
	if has_active_tavern:
		return TAVERN_WINE_STOCK_BONUS
	return 0


func get_damage_modifier(total_morale: int) -> float:
	return float(total_morale) * 0.005


func get_productivity_modifier(total_morale: int) -> float:
	return float(total_morale) * 0.0025
