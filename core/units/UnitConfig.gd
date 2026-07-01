extends Resource
class_name UnitConfig

## UnitConfig - Resource for unit stats and traits
## Based on wiki data from thekingiswatching.wiki.gg

enum UnitClass {
	GRUNT,
	WARRIOR,
	RANGED,
	RIDER,
	CHAMPION,
	FLYING,
	ARCANE,
	UNDEAD
}

## === BASIC INFO ===
@export_group("Basic Info")
@export var unit_id: String = ""
@export var display_name: String = "New Unit"
@export var icon: Texture2D = null

## === STATS ===
@export_group("Stats")
@export var hp: int = 100
@export var dps: int = 10

## === COMBAT ===
@export_group("Combat")
@export var attack_range: float = 25.0
@export var max_range: float = 200.0
@export var projectile_speed: float = 400.0
@export var projectile_type: String = "arrow"
@export var projectile_spin_speed_deg: float = 0.0

## === CLASSIFICATION ===
@export_group("Classification")
@export var unit_classes: Array[UnitClass] = []

## === TRAIT ===
@export_group("Trait")
@export_multiline var trait_description: String = ""

## Get class names as string array
func get_class_names() -> Array[String]:
	var names: Array[String] = []
	for uc in unit_classes:
		match uc:
			UnitClass.GRUNT: names.append("Grunt")
			UnitClass.WARRIOR: names.append("Warrior")
			UnitClass.RANGED: names.append("Ranged")
			UnitClass.RIDER: names.append("Rider")
			UnitClass.CHAMPION: names.append("Champion")
			UnitClass.FLYING: names.append("Flying")
			UnitClass.ARCANE: names.append("Arcane")
			UnitClass.UNDEAD: names.append("Undead")
	return names
