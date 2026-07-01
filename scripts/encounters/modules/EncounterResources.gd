extends Resource
class_name EncounterResources

const RESOURCE_IDS: Array[String] = [
	"water",
	"gold",
	"wood",
	"clay",
	"iron_ore",
	"steel",
	"wheat",
	"flour",
	"meat",
	"grapes",
	"wine",
	"oil",
	"crystal",
]

const RESOURCE_ICON_FILE_MAP := {
	"wood": "wood_1",
	"gold": "gold_4",
	"clay": "clay_3",
	"wheat": "wheat_7",
	"meat": "meat_9",
	"iron_ore": "iron_ore_5",
	"flour": "flour_8",
	"stone": "stone_2",
	"water": "water_-1",
	"mana": "mana_8",
	"steel": "iron_ingot_6",
	"crystal": "crystal",
	"grapes": "grapes",
	"wine": "wine",
	"oil": "oil",
}

static func normalize_resource_id(resource_id: String) -> String:
	match resource_id:
		"ore":
			return "iron_ore"
		"metal":
			return "steel"
		"fuel":
			return "oil"
		_:
			return resource_id

static func denormalize_alias(resource_id: String) -> String:
	if resource_id == "iron_ore":
		return "ore"
	if resource_id == "steel":
		return "metal"
	if resource_id == "oil":
		return "fuel"
	return resource_id

static func resource_exists(resource_id: String) -> bool:
	return RESOURCE_IDS.has(normalize_resource_id(resource_id))

static func display_name(value: String) -> String:
	var words := value.replace("_", " ").split(" ", false)
	for i in range(words.size()):
		var word := String(words[i])
		if word.length() == 0:
			continue
		words[i] = word[0].to_upper() + word.substr(1, word.length() - 1)
	return " ".join(words)
