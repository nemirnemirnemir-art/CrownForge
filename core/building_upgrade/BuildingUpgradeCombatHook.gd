extends RefCounted
class_name BuildingUpgradeCombatHook

## On-hit combat effects from building upgrades.
## Returns effect descriptors that HeroAttackingState processes on melee hits.

# ── DoT effects ──────────────────────────────────────────────────────────────
# unit_id -> {building_id, upgrade_id, element, total_damage, ticks, tick_damage, tick_interval}
const DOT_EFFECTS: Dictionary = {
	"hunter": {
		"building_id": "hunters",
		"upgrade_id": "hunters:0",
		"element": "poison",
		"total_damage": 10.0,
		"ticks": 4,
		"tick_damage": 2.5,
		"tick_interval": 1.0,
	},
	"fire_mage": {
		"building_id": "academy_of_fire",
		"upgrade_id": "academy_of_fire:0",
		"element": "fire",
		"total_damage": 15.0,
		"ticks": 3,
		"tick_damage": 5.0,
		"tick_interval": 1.0,
	},
	"bumblebee": {
		"building_id": "hive",
		"upgrade_id": "hive:1",
		"element": "poison",
		"total_damage": 30.0,
		"ticks": 6,
		"tick_damage": 5.0,
		"tick_interval": 1.0,
	},
	"longbowman": {
		"building_id": "longbowmens_camp",
		"upgrade_id": "longbowmens_camp:1",
		"element": "fire",
		"total_damage": 20.0,
		"ticks": 4,
		"tick_damage": 5.0,
		"tick_interval": 1.0,
	},
}

# ── Stun effects ─────────────────────────────────────────────────────────────
# unit_id -> Array of {building_id, upgrade_id, duration, chance, condition}
# condition: "none" | "full_hp" | "every_nth"
const STUN_EFFECTS: Dictionary = {
	"archer": {
		"building_id": "archery",
		"upgrade_id": "archery:2",
		"duration": 2.0,
		"chance": 1.0,
		"condition": "full_hp",
	},
	"slinger": {
		"building_id": "slingers_tree",
		"upgrade_id": "slingers_tree:1",
		"duration": 1.0,
		"chance": 0.03,
		"condition": "none",
	},
	"madman": {
		"building_id": "madhouse",
		"upgrade_id": "madhouse:2",
		"duration": 1.5,
		"chance": 1.0,
		"condition": "none",
	},
	"catapult": {
		"building_id": "catapult_factory",
		"upgrade_id": "catapult_factory:1",
		"duration": 2.0,
		"chance": 0.20,
		"condition": "none",
	},
	"minotaur_stun": {
		"building_id": "minotaur_camp",
		"upgrade_id": "minotaur_camp:2",
		"duration": 1.0,
		"chance": 1.0,
		"condition": "every_nth",
		"n": 5,
	},
}

# ── Crit effects ─────────────────────────────────────────────────────────────
# unit_id -> {building_id, upgrade_id, multiplier, mode, ...}
# mode: "every_nth" | "chance"
const CRIT_EFFECTS: Dictionary = {
	"archer": {
		"building_id": "archery",
		"upgrade_id": "archery:0",
		"multiplier": 2.0,
		"mode": "every_nth",
		"n": 5,
	},
	"musketeer": {
		"building_id": "firing_range",
		"upgrade_id": "firing_range:0",
		"multiplier": 5.0,
		"mode": "chance",
		"chance": 0.10,
	},
}

# ── Lifesteal effects ───────────────────────────────────────────────────────
const LIFESTEAL_EFFECTS: Dictionary = {
	"minotaur": {
		"building_id": "minotaur_camp",
		"upgrade_id": "minotaur_camp:0",
		"percent": 0.50,
	},
}

# ── Slow effects ─────────────────────────────────────────────────────────────
const SLOW_EFFECTS: Dictionary = {
	"ballista": {
		"building_id": "ballista_factory",
		"upgrade_id": "ballista_factory:0",
		"duration": 2.0,
		"factor": 0.50,
		"bonus_damage_percent": 0.25,
	},
}

# ── Long Shot effects ────────────────────────────────────────────────────────
# Linear scaling from +0% at point blank to +100% at max attack range.
# unit_id -> {building_id, upgrade_id, max_bonus_percent}
const LONG_SHOT_EFFECTS: Dictionary = {
	"ballista": {
		"building_id": "ballista_factory",
		"upgrade_id": "ballista_factory:2",
		"max_bonus_percent": 1.0,
	},
	"catapult": {
		"building_id": "catapult_factory",
		"upgrade_id": "catapult_factory:2",
		"max_bonus_percent": 1.0,
	},
}

# ── War of Attrition effects ────────────────────────────────────────────────
# On hit: -30% movement speed AND -30% attack speed for 3 seconds.
# unit_id -> {building_id, upgrade_id, speed_factor, attack_speed_factor, duration}
const WAR_OF_ATTRITION_EFFECTS: Dictionary = {
	"pangolin": {
		"building_id": "pangolin_stump",
		"upgrade_id": "pangolin_stump:1",
		"speed_factor": 0.70,
		"attack_speed_factor": 0.70,
		"duration": 3.0,
	},
}

# ── Jumping Lightning effects ───────────────────────────────────────────────
# On hit: chain to 2 nearby enemies with 50% damage reduction per jump.
# unit_id -> {building_id, upgrade_id, max_chains, damage_decay, chain_range}
const JUMPING_LIGHTNING_EFFECTS: Dictionary = {
	"lightning_mage": {
		"building_id": "academy_of_lightning",
		"upgrade_id": "academy_of_lightning:2",
		"max_chains": 2,
		"damage_decay": 0.50,
		"chain_range": 150.0,
	},
}


# ── Public API ───────────────────────────────────────────────────────────────

static func get_on_hit_effects(unit_id: String, has_upgrade_func: Callable) -> Array[Dictionary]:
	## Returns an array of on-hit effect descriptors for the given unit.
	## Each dict has a "type" key: "dot", "stun", "crit", "lifesteal", "slow".
	var results: Array[Dictionary] = []

	# DoT
	var dot_entry: Variant = DOT_EFFECTS.get(unit_id, null)
	if dot_entry != null and dot_entry is Dictionary:
		var dot := dot_entry as Dictionary
		if has_upgrade_func.call(String(dot.get("building_id", "")), String(dot.get("upgrade_id", ""))):
			results.append({
				"type": "dot",
				"element": String(dot.get("element", "poison")),
				"total_damage": float(dot.get("total_damage", 0.0)),
				"ticks": int(dot.get("ticks", 1)),
				"tick_damage": float(dot.get("tick_damage", 0.0)),
				"tick_interval": float(dot.get("tick_interval", 1.0)),
			})

	# Stun — check both unit_id and unit_id + "_stun" keys (minotaur has separate stun entry)
	var stun_entry: Variant = STUN_EFFECTS.get(unit_id, null)
	if stun_entry != null and stun_entry is Dictionary:
		var stun := stun_entry as Dictionary
		if has_upgrade_func.call(String(stun.get("building_id", "")), String(stun.get("upgrade_id", ""))):
			var effect: Dictionary = {
				"type": "stun",
				"duration": float(stun.get("duration", 1.0)),
				"chance": float(stun.get("chance", 1.0)),
				"condition": String(stun.get("condition", "none")),
			}
			if stun.has("n"):
				effect["n"] = int(stun.get("n", 5))
			results.append(effect)

	# Also check the "_stun" variant key for minotaur (minotaur_stun)
	var stun_key := unit_id + "_stun"
	var stun_entry2: Variant = STUN_EFFECTS.get(stun_key, null)
	if stun_entry2 != null and stun_entry2 is Dictionary:
		var stun2 := stun_entry2 as Dictionary
		if has_upgrade_func.call(String(stun2.get("building_id", "")), String(stun2.get("upgrade_id", ""))):
			var effect2: Dictionary = {
				"type": "stun",
				"duration": float(stun2.get("duration", 1.0)),
				"chance": float(stun2.get("chance", 1.0)),
				"condition": String(stun2.get("condition", "none")),
			}
			if stun2.has("n"):
				effect2["n"] = int(stun2.get("n", 5))
			results.append(effect2)

	# Crit
	var crit_entry: Variant = CRIT_EFFECTS.get(unit_id, null)
	if crit_entry != null and crit_entry is Dictionary:
		var crit := crit_entry as Dictionary
		if has_upgrade_func.call(String(crit.get("building_id", "")), String(crit.get("upgrade_id", ""))):
			var effect3: Dictionary = {
				"type": "crit",
				"multiplier": float(crit.get("multiplier", 2.0)),
				"mode": String(crit.get("mode", "every_nth")),
			}
			if crit.has("n"):
				effect3["n"] = int(crit.get("n", 5))
			if crit.has("chance"):
				effect3["chance"] = float(crit.get("chance", 0.0))
			results.append(effect3)

	# Lifesteal
	var ls_entry: Variant = LIFESTEAL_EFFECTS.get(unit_id, null)
	if ls_entry != null and ls_entry is Dictionary:
		var ls := ls_entry as Dictionary
		if has_upgrade_func.call(String(ls.get("building_id", "")), String(ls.get("upgrade_id", ""))):
			results.append({
				"type": "lifesteal",
				"percent": float(ls.get("percent", 0.0)),
			})

	# Slow
	var slow_entry: Variant = SLOW_EFFECTS.get(unit_id, null)
	if slow_entry != null and slow_entry is Dictionary:
		var slow := slow_entry as Dictionary
		if has_upgrade_func.call(String(slow.get("building_id", "")), String(slow.get("upgrade_id", ""))):
			results.append({
				"type": "slow",
				"duration": float(slow.get("duration", 2.0)),
				"factor": float(slow.get("factor", 0.5)),
				"bonus_damage_percent": float(slow.get("bonus_damage_percent", 0.0)),
			})

	# Long Shot (distance-based damage scaling)
	var ls_shot_entry: Variant = LONG_SHOT_EFFECTS.get(unit_id, null)
	if ls_shot_entry != null and ls_shot_entry is Dictionary:
		var ls_shot := ls_shot_entry as Dictionary
		if has_upgrade_func.call(String(ls_shot.get("building_id", "")), String(ls_shot.get("upgrade_id", ""))):
			results.append({
				"type": "long_shot",
				"max_bonus_percent": float(ls_shot.get("max_bonus_percent", 1.0)),
			})

	# War of Attrition (speed + attack speed debuff)
	var woa_entry: Variant = WAR_OF_ATTRITION_EFFECTS.get(unit_id, null)
	if woa_entry != null and woa_entry is Dictionary:
		var woa := woa_entry as Dictionary
		if has_upgrade_func.call(String(woa.get("building_id", "")), String(woa.get("upgrade_id", ""))):
			results.append({
				"type": "war_of_attrition",
				"speed_factor": float(woa.get("speed_factor", 0.70)),
				"attack_speed_factor": float(woa.get("attack_speed_factor", 0.70)),
				"duration": float(woa.get("duration", 3.0)),
			})

	# Jumping Lightning (chain to nearby enemies on hit)
	var jl_entry: Variant = JUMPING_LIGHTNING_EFFECTS.get(unit_id, null)
	if jl_entry != null and jl_entry is Dictionary:
		var jl := jl_entry as Dictionary
		if has_upgrade_func.call(String(jl.get("building_id", "")), String(jl.get("upgrade_id", ""))):
			results.append({
				"type": "jumping_lightning",
				"max_chains": int(jl.get("max_chains", 2)),
				"damage_decay": float(jl.get("damage_decay", 0.50)),
				"chain_range": float(jl.get("chain_range", 150.0)),
			})

	return results
