extends RefCounted
class_name DebugSpawnMenuCatalog

## Pure data catalog for DebugSpawnMenu.
## No Node dependencies — safe to load headlessly and in tests.

const DEBUG_BARRACKS_DIRS: Array[String] = [
	"res://data/buildings/levy_barracks",
	"res://data/buildings/veteran_barracks",
	"res://data/buildings/elite_barracks",
]

const DEBUG_EXTRA_HERO_IDS: Array[String] = [
	"bone_warrior",
	"familiar",
	"small_bones",
]

const MOB_SCENES: Dictionary = {
	"GoblinBandit": preload("res://scenes/mobs/GoblinBandit.tscn"),
	"BlueSlime": preload("res://scenes/mobs/BlueSlime.tscn"),
	"GoblinCrossbowman": preload("res://scenes/mobs/GoblinCrossbowman.tscn"),
	"GoblinSwordsman": preload("res://scenes/mobs/GoblinSwordsman.tscn"),
	"GoblinShaman": preload("res://scenes/mobs/GoblinShaman.tscn"),
	"GoblinFireMage": preload("res://scenes/mobs/GoblinFireMage.tscn"),
	"GoblinLightningMage": preload("res://scenes/mobs/GoblinLightningMage.tscn"),
	"GoblinLizard": preload("res://scenes/mobs/GoblinLizard.tscn"),
	"GoblinGiant": preload("res://scenes/mobs/GoblinGiant.tscn"),
	"WallBuster": preload("res://scenes/mobs/WallBuster.tscn"),
	"GoblinBatRider": preload("res://scenes/mobs/GoblinBatRider.tscn"),
	"GoblinPig": preload("res://scenes/mobs/GoblinPig.tscn"),
	"CrabRider": preload("res://scenes/mobs/CrabRider.tscn"),
	"StoneGolem": preload("res://scenes/mobs/StoneGolem.tscn"),
	"Sunfaced": preload("res://scenes/mobs/Sunfaced.tscn"),
	"Gnoll": preload("res://scenes/mobs/Gnoll.tscn"),
	"Dragon": preload("res://scenes/mobs/Dragon.tscn"),
}

const SPELL_CONFIGS: Array[String] = [
	# Basic Spells
	"banish", "bladecaster", "bladefall", "blinding_light", "bursting_bunch",
	"chain_lightning", "deforestation", "evasion", "fireworks", "fissure", "frailty",
	"groundfire", "healing_pool", "immortality", "landmine", "meteorite",
	"moonshine_barrel", "necromancy", "poison_puddle", "roots",
	"shields_up", "quicksand", "summon_infernals", "tnt_barrel", "turn_to_sheep", "weakness", "wrath",
	# Legendary Spells
	"armageddon", "freeze", "health_boost", "incineration", "last_stand",
	"legendary_fireworks", "tornado", "thunderstorm",
]
