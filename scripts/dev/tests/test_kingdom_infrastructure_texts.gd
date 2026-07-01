extends SceneTree

const BUILDING_DESCRIPTION_TOKENS := {
	"fairy_fountain": ["random", "resource"],
	"brick_factory": ["repairs", "walls"],
	"arena": ["morale", "active"],
	"execution_ground": ["executes", "denarii"],
	"archmages_university": ["legendary", "spells"],
	"hero_statue": ["troop", "upgrades"],
	"kings_statue": ["cooldown", "active"],
	"research_laboratory": ["blueprints", "buildings"],
	"tavern": ["wine", "morale"],
	"wheel_of_fortune": ["resource", "pack"],
}

const PRESENTATION_DATA_PATH := "res://scripts/ui/town/buildings/BuildingPresentationData.gd"

var _failed := false

func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error("[test_kingdom_infrastructure_texts] %s" % message)
	quit(1)

func _init() -> void:
	var presentation_script := load(PRESENTATION_DATA_PATH)
	if presentation_script == null:
		_fail("Missing presentation data script: %s" % PRESENTATION_DATA_PATH)
		return

	for building_id in BUILDING_DESCRIPTION_TOKENS.keys():
		var text := String(presentation_script.get_description(String(building_id), "")).to_lower()
		for token_value in BUILDING_DESCRIPTION_TOKENS[building_id]:
			var token := String(token_value).to_lower()
			if text.find(token) == -1:
				_fail("%s must mention '%s' in its presentation description" % [building_id, token])
				return

	var upgrade_text := JSON.stringify(presentation_script.DATA).to_lower()
	for required in ["fortifications", "anti-goblin dust", "crystal clarity", "additional chain"]:
		if upgrade_text.find(required) == -1:
			_fail("BuildingPresentationData must include '%s'" % required)
			return

	print("[test_kingdom_infrastructure_texts] PASS")
	quit(0)
