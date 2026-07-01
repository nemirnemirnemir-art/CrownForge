extends Resource
class_name HeroRegistry

@export var available_heroes: Array[HeroDefinition] = []

func get_hero_by_id(id: String) -> HeroDefinition:
	for hero in available_heroes:
		if hero.id == id:
			return hero
	return null

func get_all_heroes() -> Array[HeroDefinition]:
	return available_heroes
