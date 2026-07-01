extends RefCounted
class_name MagicDamageScenarioCatalog

## Defines all magic damage test scenarios with expected multipliers.
## Each scenario specifies which buildings to place, their active state,
## which upgrades to unlock, and the expected resulting spell damage multiplier.
##
## All spell damage bonuses stack ADDITIVELY from a 100% base:
##   Magic Ball active:        +50%  (total 1.5)
##   Magic Ball upgrade:       +30%  (additional, total 1.8 with ball active)
##   Crystal Mine Magic Aura:  +10%  (passive, works even when inactive)
##
## Example full combo:  1.0 + 0.5 + 0.3 + 0.1 = 1.9

const BASE_SPELL_DAMAGE := 110.0  # meteorite.tres base damage


## Returns all scenarios as an Array of Dictionaries.
## Each dict has:
##   "id"        : String    — unique scenario identifier
##   "label"     : String    — human-readable name for UI
##   "slots"     : Array[Dictionary] — slot specs for RuntimeProbe
##   "upgrades"  : Array[String]     — upgrade IDs to unlock
##   "expected_multiplier" : float   — expected spell damage multiplier
##   "expected_damage"     : float   — expected final damage (base * multiplier)
##   "notes"     : String           — explanation
static func get_all_scenarios() -> Array[Dictionary]:
	return [
		_baseline(),
		_magic_ball_active(),
		_magic_ball_inactive(),
		_magic_ball_with_upgrade(),
		_magic_aura_only(),
		_full_combo(),
	]


static func get_scenario_by_id(scenario_id: String) -> Dictionary:
	for s: Dictionary in get_all_scenarios():
		if String(s.get("id", "")) == scenario_id:
			return s
	return {}


static func _baseline() -> Dictionary:
	return {
		"id": "baseline",
		"label": "Baseline (no buildings)",
		"slots": [] as Array[Dictionary],
		"upgrades": [] as Array[String],
		"expected_multiplier": 1.0,
		"expected_damage": BASE_SPELL_DAMAGE * 1.0,
		"notes": "No buildings, no upgrades. Pure base damage.",
	}


static func _magic_ball_active() -> Dictionary:
	return {
		"id": "magic_ball_active",
		"label": "Magic Ball (active, no upgrade)",
		"slots": [
			{"slot_index": 0, "building_id": "magic_ball", "active": true},
		] as Array[Dictionary],
		"upgrades": [] as Array[String],
		"expected_multiplier": 1.5,
		"expected_damage": BASE_SPELL_DAMAGE * 1.5,
		"notes": "Magic Ball active = +50% spell damage.",
	}


static func _magic_ball_inactive() -> Dictionary:
	return {
		"id": "magic_ball_inactive",
		"label": "Magic Ball (inactive)",
		"slots": [
			{"slot_index": 0, "building_id": "magic_ball", "active": false},
		] as Array[Dictionary],
		"upgrades": [] as Array[String],
		"expected_multiplier": 1.0,
		"expected_damage": BASE_SPELL_DAMAGE * 1.0,
		"notes": "Magic Ball inactive = no bonus (requires active/gaze).",
	}


static func _magic_ball_with_upgrade() -> Dictionary:
	return {
		"id": "magic_ball_upgraded",
		"label": "Magic Ball (active + upgrade)",
		"slots": [
			{"slot_index": 0, "building_id": "magic_ball", "active": true},
		] as Array[Dictionary],
		"upgrades": ["magic_ball:0"] as Array[String],
		"expected_multiplier": 1.8,
		"expected_damage": BASE_SPELL_DAMAGE * 1.8,
		"notes": "Magic Ball active (+50%) + More Spell Damage upgrade (+30%) = +80%.",
	}


static func _magic_aura_only() -> Dictionary:
	return {
		"id": "magic_aura_only",
		"label": "Crystal Mine Magic Aura (passive)",
		"slots": [
			{"slot_index": 0, "building_id": "crystal_mine", "active": false},
		] as Array[Dictionary],
		"upgrades": ["crystal_mine:0"] as Array[String],
		"expected_multiplier": 1.1,
		"expected_damage": BASE_SPELL_DAMAGE * 1.1,
		"notes": "Crystal Mine Magic Aura is passive (+10%). Works even when mine is inactive.",
	}


static func _full_combo() -> Dictionary:
	return {
		"id": "full_combo",
		"label": "Full Combo (Ball + Aura)",
		"slots": [
			{"slot_index": 0, "building_id": "magic_ball", "active": true},
			{"slot_index": 1, "building_id": "crystal_mine", "active": false},
		] as Array[Dictionary],
		"upgrades": ["magic_ball:0", "crystal_mine:0"] as Array[String],
		"expected_multiplier": 1.9,
		"expected_damage": BASE_SPELL_DAMAGE * 1.9,
		"notes": "Ball active (+50%) + Ball upgrade (+30%) + Mine Aura (+10%) = +90%. Additive stacking.",
	}
