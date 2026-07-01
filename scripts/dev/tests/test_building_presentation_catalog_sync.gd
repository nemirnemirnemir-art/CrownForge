extends SceneTree

const PRESENTATION_DATA_PATH := "res://scripts/ui/town/buildings/BuildingPresentationData.gd"

const REQUIRED_DESCRIPTION_TOKENS := {
	"sawmill": ["wood"],
	"basic_construction": ["choice", "established production"],
	"archery": ["crossbowmen"],
	"peasants_hut": ["peasants"],
	"falcons_camp": ["black swordsmen"],
	"firing_range": ["musketeers"],
	"academy_of_lightning": ["lightning mages"],
	"catapult_factory": ["catapult", "afar"],
	"giants_bedding": ["giants", "castle", "20 hp"],
	"hospital": ["injured", "troops"],
	"magic_ball": ["spell", "50%"],
	"research_table": ["blueprints", "buildings"],
}

const REQUIRED_UPGRADE_NAMES := {
	"sawmill": ["Sawmill Production", "Friendly Lumberjacks"],
	"archery": ["Precise shots", "Archers' capacity", "Stunning arrows"],
	"gnome_dome": ["Refund", "Damage", "Capacity"],
	"hunters": ["Stinky nets", "Hunters' capacity"],
	"militia_camp": ["Militia HP", "Militia capacity", "Mega dude"],
	"peasants_hut": ["Capacity", "Insurance", "Peasants' power"],
	"slingers_tree": ["Slingers' capacity", "Heavy stones", "Slingers' HP"],
	"swordsmen_barracks": ["Damage dealt by Swordsmen", "Swordsmen's Capacity"],
	"whipmens_house": ["Whipmen's capacity", "Whipmen's HP"],
	"academy_of_fire": ["Combustion", "Damage dealt by Mages", "Fire Mages' Capacity"],
	"academy_of_nature": ["Healer Mages' capacity", "Healer Mage damage"],
	"barbarian_tent": ["Weapon melting", "Cheaper production", "Barbarians' damage"],
	"stables": ["Squires' HP", "Squires' capacity", "Survivor"],
	"falcons_camp": ["Mentoring", "Black Swordsmen's attack range", "Black Swordsmen's HP"],
	"firing_range": ["Critical shots", "Musketeers' capacity", "Cheaper production"],
	"geese_training_field": ["Capacity", "Damage", "Cheaper production"],
	"hive": ["Bumblebees' capacity", "Sting attack"],
	"longbowmens_camp": ["Damage dealt by Longbowmen", "Burning arrows", "Longbowmen's capacity"],
	"minotaur_camp": ["Vampirism", "Trait Upgrade", "Stunning Blow"],
	"paladins_campus": ["Paladins' capacity", "Spell damage buff", "Paladins' HP"],
	"pumpkin_field": ["Pumpkin Warriors' capacity", "HP and Damage"],
	"academy_of_lightning": ["Lightning Mages' capacity", "HP and Damage", "Jumping Lightning"],
	"ballista_factory": ["Damage and slowness", "Ballistae capacity", "Long shot"],
	"black_unicorn_field": ["Damage dealt by Black Unicorns", "Boosters of Morale"],
	"catapult_factory": ["Catapult capacity", "Stun chance", "Long shot"],
	"giants_bedding": ["Sawdust", "Wheat Straws"],
	"hydra_pond": ["Hydras' HP", "Capacity", "Trait Upgrade"],
	"lion_circus": ["Versatility"],
	"pangolin_stump": ["Pangolins' HP", "War of attrition", "Pangolins' evasion"],
	"ram_pasture": ["Rams' HP", "Spell damage", "Twins"],
	"white_unicorn_field": ["Unicorns' HP", "Spell Damage"],
	"brick_factory": ["Repair speed", "Fortifications"],
	"hospital": ["Masters of healing", "Masters of morale"],
	"kings_statue": ["Crystal Clarity", "Troop Inspiration"],
	"magic_ball": ["More spell damage", "Witchcraft"],
}

const FORBIDDEN_UPGRADE_IDS := ["research_table"]

var _failed := false

func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error("[test_building_presentation_catalog_sync] %s" % message)
	quit(1)

func _init() -> void:
	var presentation_script := load(PRESENTATION_DATA_PATH)
	if presentation_script == null:
		_fail("Missing building presentation data script: %s" % PRESENTATION_DATA_PATH)
		return

	for building_id in REQUIRED_DESCRIPTION_TOKENS.keys():
		var text := String(presentation_script.get_description(String(building_id), "")).to_lower()
		if text == "":
			_fail("Missing description for '%s'" % building_id)
			return
		for token_value in REQUIRED_DESCRIPTION_TOKENS[building_id]:
			var token := String(token_value).to_lower()
			if text.find(token) == -1:
				_fail("Description for '%s' must mention '%s'" % [building_id, token])
				return

	for building_id in REQUIRED_UPGRADE_NAMES.keys():
		var upgrades: Array = presentation_script.get_upgrades(String(building_id))
		if upgrades.is_empty():
			_fail("Missing upgrades for '%s'" % building_id)
			return
		var found_names := {}
		for upgrade_data in upgrades:
			if upgrade_data is Dictionary:
				found_names[String((upgrade_data as Dictionary).get("name", ""))] = true
		for expected_name_value in REQUIRED_UPGRADE_NAMES[building_id]:
			var expected_name := String(expected_name_value)
			if not found_names.has(expected_name):
				_fail("Missing upgrade '%s' for '%s'" % [expected_name, building_id])
				return

	for building_id in FORBIDDEN_UPGRADE_IDS:
		if not presentation_script.get_upgrades(String(building_id)).is_empty():
			_fail("'%s' must not define upgrades" % building_id)
			return

	print("[test_building_presentation_catalog_sync] PASS")
	quit(0)
