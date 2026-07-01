extends RefCounted
class_name BuildingUpgradeTroopStatModifier

## Per-unit-type stat modifiers from building upgrades.
## Maps unit_id -> {building_id, upgrade_id, bonus} for HP, Damage, and Evasion.
## Each bonus is a fractional multiplier (0.5 = +50%, 1.0 = +100%, etc.).
## Evasion values are absolute chances (0.0–1.0).

# ── HP modifier map ──────────────────────────────────────────────────────────
# bonus is additive to a 1.0 base  (0.5 → ×1.5,  2.0 → ×3.0)
const UNIT_HP_MODIFIER_MAP: Dictionary = {
	"militia":          {"building_id": "militia_camp",        "upgrade_id": "militia_camp:0",          "bonus": 0.5},
	"slinger":          {"building_id": "slingers_tree",       "upgrade_id": "slingers_tree:2",         "bonus": 2.0},
	"whipman":          {"building_id": "whipmens_house",      "upgrade_id": "whipmens_house:1",        "bonus": 4.0},
	"paladin":          {"building_id": "paladins_campus",     "upgrade_id": "paladins_campus:2",       "bonus": 1.0},
	"squire":           {"building_id": "stables",             "upgrade_id": "stables:0",               "bonus": 0.4},
	"hydra":            {"building_id": "hydra_pond",          "upgrade_id": "hydra_pond:0",            "bonus": 1.0},
	"pangolin":         {"building_id": "pangolin_stump",      "upgrade_id": "pangolin_stump:0",        "bonus": 0.5},
	"ram":              {"building_id": "ram_pasture",         "upgrade_id": "ram_pasture:0",           "bonus": 0.5},
	"unicorn":          {"building_id": "white_unicorn_field", "upgrade_id": "white_unicorn_field:0",   "bonus": 1.0},
	"peasant":          {"building_id": "peasants_hut",        "upgrade_id": "peasants_hut:2",          "bonus": 0.3},
	"pumpkin_warrior":  {"building_id": "pumpkin_field",       "upgrade_id": "pumpkin_field:1",         "bonus": 0.3},
	"lightning_mage":   {"building_id": "academy_of_lightning","upgrade_id": "academy_of_lightning:1",  "bonus": 0.5},
	"black_swordsman":  {"building_id": "falcons_camp",        "upgrade_id": "falcons_camp:2",          "bonus": 2.0},
}

# ── Damage modifier map ─────────────────────────────────────────────────────
const UNIT_DAMAGE_MODIFIER_MAP: Dictionary = {
	"swordsman":        {"building_id": "swordsmen_barracks",  "upgrade_id": "swordsmen_barracks:0",    "bonus": 1.0},
	"gnome":            {"building_id": "gnome_dome",          "upgrade_id": "gnome_dome:1",            "bonus": 1.0},
	"black_unicorn":    {"building_id": "black_unicorn_field", "upgrade_id": "black_unicorn_field:0",   "bonus": 1.0},
	"longbowman":       {"building_id": "longbowmens_camp",   "upgrade_id": "longbowmens_camp:0",      "bonus": 1.0},
	"peasant":          {"building_id": "peasants_hut",        "upgrade_id": "peasants_hut:2",          "bonus": 0.3},
	"pumpkin_warrior":  {"building_id": "pumpkin_field",       "upgrade_id": "pumpkin_field:1",         "bonus": 0.3},
	"lightning_mage":   {"building_id": "academy_of_lightning","upgrade_id": "academy_of_lightning:1",  "bonus": 0.5},
	"fire_mage":        {"building_id": "academy_of_fire",     "upgrade_id": "academy_of_fire:1",       "bonus": 0.5},
	"barbarian":        {"building_id": "barbarian_tent",      "upgrade_id": "barbarian_tent:2",        "bonus": 1.0},
	"goose_rider":      {"building_id": "geese_training_field","upgrade_id": "geese_training_field:1",  "bonus": 0.6},
	"healer_mage":      {"building_id": "academy_of_nature",   "upgrade_id": "academy_of_nature:1",     "bonus": 0.25},
}

# ── Evasion map ──────────────────────────────────────────────────────────────
# Values are absolute evasion chances (0.0–1.0)
const UNIT_EVASION_MAP: Dictionary = {
	"madman":   {"building_id": "madhouse",        "upgrade_id": "madhouse:0",        "evasion": 0.35},
	"pangolin": {"building_id": "pangolin_stump",  "upgrade_id": "pangolin_stump:2",  "evasion": 0.25},
}

# ── Attack range modifier map ────────────────────────────────────────────────
# bonus is additive to a 1.0 base  (1.0 → ×2.0 = double range)
const UNIT_ATTACK_RANGE_MODIFIER_MAP: Dictionary = {
	"black_swordsman": {"building_id": "falcons_camp", "upgrade_id": "falcons_camp:1", "bonus": 1.0},
}


# ── Static query functions ───────────────────────────────────────────────────

static func get_unit_hp_multiplier(unit_id: String, has_upgrade_func: Callable) -> float:
	## Returns the HP multiplier for a specific unit type (1.0 = no bonus).
	var entry: Variant = UNIT_HP_MODIFIER_MAP.get(unit_id, null)
	if entry == null or not (entry is Dictionary):
		return 1.0
	var data := entry as Dictionary
	var building_id := String(data.get("building_id", ""))
	var upgrade_id := String(data.get("upgrade_id", ""))
	if building_id == "" or upgrade_id == "":
		return 1.0
	if has_upgrade_func.call(building_id, upgrade_id):
		return 1.0 + float(data.get("bonus", 0.0))
	return 1.0


static func get_unit_damage_multiplier(unit_id: String, has_upgrade_func: Callable) -> float:
	## Returns the damage multiplier for a specific unit type (1.0 = no bonus).
	var entry: Variant = UNIT_DAMAGE_MODIFIER_MAP.get(unit_id, null)
	if entry == null or not (entry is Dictionary):
		return 1.0
	var data := entry as Dictionary
	var building_id := String(data.get("building_id", ""))
	var upgrade_id := String(data.get("upgrade_id", ""))
	if building_id == "" or upgrade_id == "":
		return 1.0
	if has_upgrade_func.call(building_id, upgrade_id):
		return 1.0 + float(data.get("bonus", 0.0))
	return 1.0


static func get_unit_evasion_chance(unit_id: String, has_upgrade_func: Callable) -> float:
	## Returns the evasion chance for a specific unit type (0.0 = no evasion).
	var entry: Variant = UNIT_EVASION_MAP.get(unit_id, null)
	if entry == null or not (entry is Dictionary):
		return 0.0
	var data := entry as Dictionary
	var building_id := String(data.get("building_id", ""))
	var upgrade_id := String(data.get("upgrade_id", ""))
	if building_id == "" or upgrade_id == "":
		return 0.0
	if has_upgrade_func.call(building_id, upgrade_id):
		return float(data.get("evasion", 0.0))
	return 0.0


static func get_unit_attack_range_multiplier(unit_id: String, has_upgrade_func: Callable) -> float:
	## Returns the attack range multiplier for a specific unit type (1.0 = no bonus).
	var entry: Variant = UNIT_ATTACK_RANGE_MODIFIER_MAP.get(unit_id, null)
	if entry == null or not (entry is Dictionary):
		return 1.0
	var data := entry as Dictionary
	var building_id := String(data.get("building_id", ""))
	var upgrade_id := String(data.get("upgrade_id", ""))
	if building_id == "" or upgrade_id == "":
		return 1.0
	if has_upgrade_func.call(building_id, upgrade_id):
		return 1.0 + float(data.get("bonus", 0.0))
	return 1.0
