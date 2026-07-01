extends RefCounted
class_name HeroSpecialBehaviorRules

const PASSIVE_PATROLLERS := {
	"black_sheep": true
}

const HIT_AND_RUN_UNITS := {
	"madman": true,
	"clown": true
}

static func get_base_unit_id(hero_id: String) -> String:
	var id := String(hero_id).strip_edges().to_lower()
	if id == "":
		return ""

	if id.contains("_"):
		var parts := id.rsplit("_", true, 1)
		if parts.size() == 2 and String(parts[1]).is_valid_int():
			id = String(parts[0])

	return id

static func is_passive_patroller_id(hero_id: String) -> bool:
	var base_id := get_base_unit_id(hero_id)
	return PASSIVE_PATROLLERS.has(base_id)

static func is_hit_and_run_id(hero_id: String) -> bool:
	var base_id := get_base_unit_id(hero_id)
	return HIT_AND_RUN_UNITS.has(base_id)
