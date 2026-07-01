extends SceneTree

const PRESENTATION_DATA_PATH := "res://scripts/ui/town/buildings/BuildingPresentationData.gd"

const ACTIVE_BUILDING_IDS := [
	"big_well", "grape_bushes", "small_wheat_field", "starter_clay_mine", "starter_crystal_mine", "starter_gold_mine", "starter_iron_mine", "tree", "well",
	"clay_mine", "crystal_mine", "gold_mine", "iron_mine", "sawmill", "vineyard", "wheat_field",
	"animal_farm", "fishermans_hut", "forge", "fuel_pump", "market", "mill", "winery",
	"small_peasants_hut", "peasants_hut", "archery", "gnome_dome", "hunters", "madhouse", "militia_camp", "slingers_tree", "swordsmen_barracks", "whipmens_house",
	"academy_of_fire", "academy_of_nature", "barbarian_tent", "falcons_camp", "firing_range", "geese_training_field", "hive", "longbowmens_camp", "minotaur_camp", "paladins_campus", "pumpkin_field", "stables",
	"academy_of_lightning", "ballista_factory", "black_unicorn_field", "catapult_factory", "giants_bedding", "hydra_pond", "lion_circus", "pangolin_stump", "ram_pasture", "white_unicorn_field",
	"archmages_university", "arena", "brick_factory", "concert", "execution_ground", "fairy_fountain", "hero_statue", "hospital", "kings_statue", "magic_ball", "magic_college", "magic_school", "monument_to_the_kings_gaze", "research_laboratory", "research_table", "tavern", "tesla_tower", "wheel_of_fortune", "buddhist_temple",
	"basic_construction", "clay_gold_mine", "clay_iron_mine", "clay_sawmill", "gold_iron_mine", "gold_sawmill", "goldsmiths_farm", "iron_sawmill", "lumberjacks_farm", "potters_farm",
]

const EXPECTED_UPGRADE_IDS := {
	"clay_mine": true,
	"crystal_mine": true,
	"gold_mine": true,
	"iron_mine": true,
	"sawmill": true,
	"vineyard": true,
	"wheat_field": true,
	"animal_farm": true,
	"fishermans_hut": true,
	"forge": true,
	"fuel_pump": true,
	"market": true,
	"mill": true,
	"winery": true,
	"archery": true,
	"gnome_dome": true,
	"hunters": true,
	"madhouse": true,
	"militia_camp": true,
	"peasants_hut": true,
	"slingers_tree": true,
	"swordsmen_barracks": true,
	"whipmens_house": true,
	"academy_of_fire": true,
	"academy_of_nature": true,
	"barbarian_tent": true,
	"falcons_camp": true,
	"firing_range": true,
	"geese_training_field": true,
	"hive": true,
	"longbowmens_camp": true,
	"minotaur_camp": true,
	"paladins_campus": true,
	"pumpkin_field": true,
	"stables": true,
	"academy_of_lightning": true,
	"ballista_factory": true,
	"black_unicorn_field": true,
	"catapult_factory": true,
	"giants_bedding": true,
	"hydra_pond": true,
	"lion_circus": true,
	"pangolin_stump": true,
	"ram_pasture": true,
	"white_unicorn_field": true,
	"archmages_university": true,
	"arena": true,
	"brick_factory": true,
	"buddhist_temple": true,
	"concert": true,
	"execution_ground": true,
	"fairy_fountain": true,
	"hero_statue": true,
	"hospital": true,
	"kings_statue": true,
	"magic_ball": true,
	"magic_college": true,
	"magic_school": true,
	"tavern": true,
	"tesla_tower": true,
	"wheel_of_fortune": true,
}

var _failed := false

func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error("[test_building_presentation_data] %s" % message)
	quit(1)

func _init() -> void:
	var presentation_script := load(PRESENTATION_DATA_PATH)
	if presentation_script == null:
		_fail("Missing building presentation data script: %s" % PRESENTATION_DATA_PATH)
		return

	var building_ids: Array[String] = []
	for building_id_value in ACTIVE_BUILDING_IDS:
		building_ids.append(String(building_id_value))
	if building_ids.is_empty():
		_fail("ACTIVE_BUILDING_IDS is empty")
		return

	for building_id in building_ids:
		var description := String(presentation_script.get_description(building_id, "")).strip_edges()
		if description == "":
			_fail("Missing presentation description for active building '%s'" % building_id)
			return

	for building_id in EXPECTED_UPGRADE_IDS.keys():
		if building_id not in building_ids:
			_fail("Expected upgradable building '%s' is not active in BuildingRegistry" % building_id)
			return
		var upgrades: Array = presentation_script.get_upgrades(String(building_id))
		if upgrades.is_empty():
			_fail("Missing upgrade presentation data for '%s'" % building_id)
			return

	print("[test_building_presentation_data] PASS")
	quit(0)
