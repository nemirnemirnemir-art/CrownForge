extends RefCounted
class_name TownCoreEventRouter
## Owns all module signal connections wired during town_core startup.


func setup(town_core: Node, population: TownPopulation, potions: TownPotions) -> void:
	population.population_changed.connect(town_core._on_population_changed)
	potions.potion_produced.connect(town_core._on_potion_produced)
	potions.hero_assigned_potion.connect(town_core._on_hero_assigned_potion)
