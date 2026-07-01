extends RefCounted
class_name BuildingUpgradeAuditMatrix

## Canonical audit matrix for all building upgrades.
## Each entry defines expected runtime behavior for headless verification.
## Source of truth: BuildingPresentationData.gd + actual helper file constants.

enum EffectFamily {
	PRODUCTION_SPEED,
	PRODUCTION_BONUS,
	EFFICIENT_PROCESSING,
	CAPACITY,
	TROOP_STAT,
	COMBAT_HOOK,
	DEATH_REWARD,
	COST_MODIFIER,
	MORALE,
	SPELL_DAMAGE,
	UNIT_AURA,
	PRODUCTION_EVENT,
	MEGA_MILITIA,
	LION_CIRCUS,
	SPECIAL,
	INCONCLUSIVE,
}


static func get_all_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []

	# ── Economy / Production Speed ───────────────────────────────────────
	entries.append(_entry("vineyard", 1, EffectFamily.PRODUCTION_SPEED, {"multiplier": 1.3}))
	entries.append(_entry("market", 1, EffectFamily.PRODUCTION_SPEED, {"multiplier": 1.25}))
	entries.append(_entry("sawmill", 0, EffectFamily.PRODUCTION_SPEED, {"multiplier": 1.25}))
	entries.append(_entry("clay_mine", 1, EffectFamily.PRODUCTION_SPEED, {"multiplier": 1.35}))
	entries.append(_entry("crystal_mine", 1, EffectFamily.PRODUCTION_SPEED, {"multiplier": 1.3}))
	entries.append(_entry("gold_mine", 1, EffectFamily.PRODUCTION_SPEED, {"multiplier": 1.25}))
	entries.append(_entry("iron_mine", 1, EffectFamily.PRODUCTION_SPEED, {"multiplier": 1.3}))
	entries.append(_entry("wheat_field", 0, EffectFamily.PRODUCTION_SPEED, {"multiplier": 1.3}))
	entries.append(_entry("animal_farm", 0, EffectFamily.PRODUCTION_SPEED, {"multiplier": 1.3}))
	entries.append(_entry("fishermans_hut", 0, EffectFamily.PRODUCTION_SPEED, {"multiplier": 1.3}))
	entries.append(_entry("fuel_pump", 0, EffectFamily.PRODUCTION_SPEED, {"multiplier": 1.3}))
	entries.append(_entry("winery", 0, EffectFamily.PRODUCTION_SPEED, {"multiplier": 1.3}))

	# ── Efficient Processing ─────────────────────────────────────────────
	entries.append(_entry("forge", 0, EffectFamily.EFFICIENT_PROCESSING, {"multiplier": 2}))
	entries.append(_entry("mill", 0, EffectFamily.EFFICIENT_PROCESSING, {"multiplier": 2}))

	# ── Production Bonus (resource on cycle) ─────────────────────────────
	entries.append(_entry("gold_mine", 0, EffectFamily.PRODUCTION_BONUS, {"resource": "gold", "amount": 2, "chance": 0.50}))
	entries.append(_entry("wheat_field", 1, EffectFamily.PRODUCTION_BONUS, {"resource": "gold", "amount": 1, "chance": 0.25}))
	entries.append(_entry("fishermans_hut", 1, EffectFamily.PRODUCTION_BONUS, {"resource": "meat", "amount": 2, "chance": 0.50}))
	entries.append(_entry("winery", 1, EffectFamily.PRODUCTION_BONUS, {"resource": "wine", "amount": 1, "chance": 0.50}))
	entries.append(_entry("fuel_pump", 1, EffectFamily.PRODUCTION_BONUS, {"resource": "_random", "amount": 1, "chance": 0.20}))
	entries.append(_entry("clay_mine", 0, EffectFamily.PRODUCTION_BONUS, {"effect": "repair_castle", "amount": 1, "chance": 0.10}))
	# kings_statue:0 bonus production is handled in KingsStatue special — test there
	entries.append(_entry("kings_statue", 0, EffectFamily.SPECIAL, {"desc": "25% chance extra Crystal 1 per cycle"}))

	# ── Neighbour Boost (needs grid layout — INCONCLUSIVE headlessly) ────
	entries.append(_entry("sawmill", 1, EffectFamily.INCONCLUSIVE, {"desc": "+20% production to 4 orthogonal neighbours"}))

	# ── Morale ───────────────────────────────────────────────────────────
	entries.append(_entry("vineyard", 0, EffectFamily.MORALE, {"bonus_per_building": 5, "passive": true}))
	entries.append(_entry("market", 0, EffectFamily.MORALE, {"bonus_per_building": 5, "active": true}))
	entries.append(_entry("tavern", 0, EffectFamily.MORALE, {"bonus_flat": 5}))

	# ── Troop Inspiration (flat 10% class buff) ──────────────────────────
	entries.append(_entry("iron_mine", 0, EffectFamily.TROOP_STAT, {"class": "WARRIOR", "hp_mult": 1.10, "dmg_mult": 1.10, "is_inspiration": true}))
	entries.append(_entry("forge", 1, EffectFamily.TROOP_STAT, {"class": "RANGED", "hp_mult": 1.10, "dmg_mult": 1.10, "is_inspiration": true}))
	entries.append(_entry("mill", 1, EffectFamily.TROOP_STAT, {"class": "FLYING", "hp_mult": 1.10, "dmg_mult": 1.10, "is_inspiration": true}))
	entries.append(_entry("animal_farm", 1, EffectFamily.TROOP_STAT, {"class": "RIDER", "hp_mult": 1.10, "dmg_mult": 1.10, "is_inspiration": true}))
	entries.append(_entry("execution_ground", 1, EffectFamily.TROOP_STAT, {"class": "GRUNT", "hp_mult": 1.10, "dmg_mult": 1.10, "is_inspiration": true}))
	entries.append(_entry("kings_statue", 1, EffectFamily.TROOP_STAT, {"class": "CHAMPION", "hp_mult": 1.10, "dmg_mult": 1.10, "is_inspiration": true}))

	# ── Spell Damage ─────────────────────────────────────────────────────
	entries.append(_entry("crystal_mine", 0, EffectFamily.SPELL_DAMAGE, {"scope": "flat_boolean"}))
	entries.append(_entry("paladins_campus", 1, EffectFamily.SPELL_DAMAGE, {"multiplier": 1.10, "scope": "flat"}))
	entries.append(_entry("ram_pasture", 1, EffectFamily.SPELL_DAMAGE, {"scope": "per_unit"}))
	entries.append(_entry("white_unicorn_field", 1, EffectFamily.SPELL_DAMAGE, {"scope": "per_unit"}))

	# ── Capacity ─────────────────────────────────────────────────────────
	entries.append(_entry("peasants_hut", 0, EffectFamily.CAPACITY, {"bonus": 2}))
	entries.append(_entry("archery", 1, EffectFamily.CAPACITY, {"bonus": 2}))
	entries.append(_entry("gnome_dome", 2, EffectFamily.CAPACITY, {"bonus": 5}))
	entries.append(_entry("hunters", 1, EffectFamily.CAPACITY, {"bonus": 2}))
	entries.append(_entry("madhouse", 1, EffectFamily.CAPACITY, {"bonus": 2}))
	entries.append(_entry("militia_camp", 1, EffectFamily.CAPACITY, {"bonus": 2}))
	entries.append(_entry("slingers_tree", 0, EffectFamily.CAPACITY, {"bonus": 3}))
	entries.append(_entry("swordsmen_barracks", 1, EffectFamily.CAPACITY, {"bonus": 2}))
	entries.append(_entry("whipmens_house", 0, EffectFamily.CAPACITY, {"bonus": 2}))
	entries.append(_entry("academy_of_fire", 2, EffectFamily.CAPACITY, {"bonus": 2}))
	entries.append(_entry("academy_of_nature", 0, EffectFamily.CAPACITY, {"bonus": 1}))
	entries.append(_entry("firing_range", 1, EffectFamily.CAPACITY, {"bonus": 2}))
	entries.append(_entry("geese_training_field", 0, EffectFamily.CAPACITY, {"bonus": 1}))
	entries.append(_entry("hive", 0, EffectFamily.CAPACITY, {"bonus": 2}))
	entries.append(_entry("longbowmens_camp", 2, EffectFamily.CAPACITY, {"bonus": 2}))
	entries.append(_entry("paladins_campus", 0, EffectFamily.CAPACITY, {"bonus": 2}))
	entries.append(_entry("pumpkin_field", 0, EffectFamily.CAPACITY, {"bonus": 3}))
	entries.append(_entry("stables", 1, EffectFamily.CAPACITY, {"bonus": 1}))
	entries.append(_entry("academy_of_lightning", 0, EffectFamily.CAPACITY, {"bonus": 2}))
	entries.append(_entry("ballista_factory", 1, EffectFamily.CAPACITY, {"bonus": 1}))
	entries.append(_entry("catapult_factory", 0, EffectFamily.CAPACITY, {"bonus": 1}))
	entries.append(_entry("hydra_pond", 1, EffectFamily.CAPACITY, {"bonus": 1}))

	# ── Troop Stat Modifiers (per-unit HP/damage/evasion) ────────────────
	# NOTE: unit_id keys match TroopStatModifier maps exactly
	entries.append(_entry("peasants_hut", 2, EffectFamily.TROOP_STAT, {"unit": "peasant", "hp_mult": 1.30, "dmg_mult": 1.30}))
	entries.append(_entry("militia_camp", 0, EffectFamily.TROOP_STAT, {"unit": "militia", "hp_mult": 1.50}))
	entries.append(_entry("slingers_tree", 2, EffectFamily.TROOP_STAT, {"unit": "slinger", "hp_mult": 3.00}))
	entries.append(_entry("swordsmen_barracks", 0, EffectFamily.TROOP_STAT, {"unit": "swordsman", "dmg_mult": 2.00}))
	entries.append(_entry("whipmens_house", 1, EffectFamily.TROOP_STAT, {"unit": "whipman", "hp_mult": 5.00}))
	entries.append(_entry("gnome_dome", 1, EffectFamily.TROOP_STAT, {"unit": "gnome", "dmg_mult": 2.00}))
	entries.append(_entry("academy_of_fire", 1, EffectFamily.TROOP_STAT, {"unit": "fire_mage", "dmg_mult": 1.50}))
	entries.append(_entry("academy_of_nature", 1, EffectFamily.TROOP_STAT, {"unit": "healer_mage", "dmg_mult": 1.25}))
	entries.append(_entry("barbarian_tent", 2, EffectFamily.TROOP_STAT, {"unit": "barbarian", "dmg_mult": 2.00}))
	entries.append(_entry("falcons_camp", 2, EffectFamily.TROOP_STAT, {"unit": "black_swordsman", "hp_mult": 3.00}))
	entries.append(_entry("geese_training_field", 1, EffectFamily.TROOP_STAT, {"unit": "goose_rider", "dmg_mult": 1.60}))
	entries.append(_entry("longbowmens_camp", 0, EffectFamily.TROOP_STAT, {"unit": "longbowman", "dmg_mult": 2.00}))
	entries.append(_entry("pumpkin_field", 1, EffectFamily.TROOP_STAT, {"unit": "pumpkin_warrior", "hp_mult": 1.30, "dmg_mult": 1.30}))
	entries.append(_entry("stables", 0, EffectFamily.TROOP_STAT, {"unit": "squire", "hp_mult": 1.40}))
	entries.append(_entry("academy_of_lightning", 1, EffectFamily.TROOP_STAT, {"unit": "lightning_mage", "hp_mult": 1.50, "dmg_mult": 1.50}))
	entries.append(_entry("black_unicorn_field", 0, EffectFamily.TROOP_STAT, {"unit": "black_unicorn", "dmg_mult": 2.00}))
	entries.append(_entry("hydra_pond", 0, EffectFamily.TROOP_STAT, {"unit": "hydra", "hp_mult": 2.00}))
	entries.append(_entry("pangolin_stump", 0, EffectFamily.TROOP_STAT, {"unit": "pangolin", "hp_mult": 1.50}))
	entries.append(_entry("ram_pasture", 0, EffectFamily.TROOP_STAT, {"unit": "ram", "hp_mult": 1.50}))
	entries.append(_entry("white_unicorn_field", 0, EffectFamily.TROOP_STAT, {"unit": "unicorn", "hp_mult": 2.00}))
	entries.append(_entry("paladins_campus", 2, EffectFamily.TROOP_STAT, {"unit": "paladin", "hp_mult": 2.00}))
	entries.append(_entry("madhouse", 0, EffectFamily.TROOP_STAT, {"unit": "madman", "evasion": 0.35}))
	entries.append(_entry("pangolin_stump", 2, EffectFamily.TROOP_STAT, {"unit": "pangolin", "evasion": 0.25}))
	entries.append(_entry("falcons_camp", 1, EffectFamily.TROOP_STAT, {"unit": "black_swordsman", "attack_range_mult": 2.00}))

	# ── Combat Hooks (on-hit effects) ────────────────────────────────────
	# NOTE: unit_id keys match CombatHook maps exactly
	entries.append(_entry("archery", 0, EffectFamily.COMBAT_HOOK, {"unit": "archer", "type": "crit"}))
	entries.append(_entry("archery", 2, EffectFamily.COMBAT_HOOK, {"unit": "archer", "type": "stun"}))
	entries.append(_entry("hunters", 0, EffectFamily.COMBAT_HOOK, {"unit": "hunter", "type": "dot"}))
	entries.append(_entry("madhouse", 2, EffectFamily.COMBAT_HOOK, {"unit": "madman", "type": "stun"}))
	entries.append(_entry("slingers_tree", 1, EffectFamily.COMBAT_HOOK, {"unit": "slinger", "type": "stun"}))
	entries.append(_entry("academy_of_fire", 0, EffectFamily.COMBAT_HOOK, {"unit": "fire_mage", "type": "dot"}))
	entries.append(_entry("longbowmens_camp", 1, EffectFamily.COMBAT_HOOK, {"unit": "longbowman", "type": "dot"}))
	entries.append(_entry("hive", 1, EffectFamily.COMBAT_HOOK, {"unit": "bumblebee", "type": "dot"}))
	entries.append(_entry("firing_range", 0, EffectFamily.COMBAT_HOOK, {"unit": "musketeer", "type": "crit"}))
	entries.append(_entry("minotaur_camp", 0, EffectFamily.COMBAT_HOOK, {"unit": "minotaur", "type": "lifesteal"}))
	entries.append(_entry("minotaur_camp", 2, EffectFamily.COMBAT_HOOK, {"unit": "minotaur", "type": "stun", "stun_key": "minotaur_stun"}))
	entries.append(_entry("ballista_factory", 0, EffectFamily.COMBAT_HOOK, {"unit": "ballista", "type": "slow"}))
	entries.append(_entry("catapult_factory", 1, EffectFamily.COMBAT_HOOK, {"unit": "catapult", "type": "stun"}))
	entries.append(_entry("ballista_factory", 2, EffectFamily.COMBAT_HOOK, {"unit": "ballista", "type": "long_shot"}))
	entries.append(_entry("catapult_factory", 2, EffectFamily.COMBAT_HOOK, {"unit": "catapult", "type": "long_shot"}))
	entries.append(_entry("pangolin_stump", 1, EffectFamily.COMBAT_HOOK, {"unit": "pangolin", "type": "war_of_attrition"}))
	entries.append(_entry("academy_of_lightning", 2, EffectFamily.COMBAT_HOOK, {"unit": "lightning_mage", "type": "jumping_lightning"}))

	# ── Death Rewards ────────────────────────────────────────────────────
	entries.append(_entry("peasants_hut", 1, EffectFamily.DEATH_REWARD, {"unit": "peasant", "resource": "gold", "amount": 2}))
	entries.append(_entry("gnome_dome", 0, EffectFamily.DEATH_REWARD, {"unit": "gnome", "resource": "gold", "amount": 5}))
	entries.append(_entry("barbarian_tent", 0, EffectFamily.DEATH_REWARD, {"unit": "barbarian", "resource": "metal", "amount": 8}))

	# ── Cost Modifiers ───────────────────────────────────────────────────
	entries.append(_entry("barbarian_tent", 1, EffectFamily.COST_MODIFIER, {"multiplier": 0.50}))
	entries.append(_entry("firing_range", 2, EffectFamily.COST_MODIFIER, {"multiplier": 0.60}))
	entries.append(_entry("geese_training_field", 2, EffectFamily.COST_MODIFIER, {"multiplier": 0.50}))

	# ── Mega Militia ─────────────────────────────────────────────────────
	entries.append(_entry("militia_camp", 2, EffectFamily.MEGA_MILITIA, {"trigger_every": 4}))

	# ── Unit Auras ───────────────────────────────────────────────────────
	entries.append(_entry("black_unicorn_field", 1, EffectFamily.UNIT_AURA, {"type": "morale"}))
	entries.append(_entry("hydra_pond", 2, EffectFamily.UNIT_AURA, {"type": "global_damage"}))
	entries.append(_entry("minotaur_camp", 1, EffectFamily.UNIT_AURA, {"type": "flying_damage"}))
	entries.append(_entry("falcons_camp", 0, EffectFamily.UNIT_AURA, {"type": "grunt_hp"}))

	# ── Production Events ────────────────────────────────────────────────
	entries.append(_entry("giants_bedding", 0, EffectFamily.PRODUCTION_EVENT, {"resource": "wood", "amount": 100}))
	entries.append(_entry("giants_bedding", 1, EffectFamily.PRODUCTION_EVENT, {"resource": "wheat", "amount": 100}))
	entries.append(_entry("ram_pasture", 2, EffectFamily.PRODUCTION_EVENT, {"type": "extra_unit", "chance": 0.10}))

	# ── Lion Circus ──────────────────────────────────────────────────────
	entries.append(_entry("lion_circus", 0, EffectFamily.LION_CIRCUS, {"cost_mult": 2.0, "versatility": true}))

	# ── Special (handled by special/*.gd — need scene integration) ───────
	entries.append(_entry("archmages_university", 0, EffectFamily.SPECIAL, {"desc": "choice instead of random legendary spell"}))
	entries.append(_entry("archmages_university", 1, EffectFamily.SPECIAL, {"desc": "+20% legendary spell gen speed"}))
	entries.append(_entry("arena", 0, EffectFamily.SPECIAL, {"desc": "1 gold / 3s while working"}))
	entries.append(_entry("arena", 1, EffectFamily.SPECIAL, {"desc": "+15 morale"}))
	entries.append(_entry("brick_factory", 0, EffectFamily.SPECIAL, {"desc": "+100% production speed"}))
	entries.append(_entry("brick_factory", 1, EffectFamily.SPECIAL, {"desc": "5 charges -> +1 max HP"}))
	entries.append(_entry("buddhist_temple", 0, EffectFamily.SPECIAL, {"desc": "+5% all production per temple"}))
	entries.append(_entry("buddhist_temple", 1, EffectFamily.SPECIAL, {"desc": "+10% all troop damage per temple"}))
	entries.append(_entry("buddhist_temple", 2, EffectFamily.SPECIAL, {"desc": "+10% spell damage per temple"}))
	entries.append(_entry("concert", 0, EffectFamily.SPECIAL, {"desc": "+10 morale while active under gaze"}))
	entries.append(_entry("concert", 1, EffectFamily.SPECIAL, {"desc": "+5 passive morale"}))
	entries.append(_entry("execution_ground", 0, EffectFamily.SPECIAL, {"desc": "+2 extra Denarii per execution"}))
	entries.append(_entry("fairy_fountain", 0, EffectFamily.SPECIAL, {"desc": "+25% production speed"}))
	entries.append(_entry("fairy_fountain", 1, EffectFamily.SPECIAL, {"desc": "15 dmg per production cycle"}))
	entries.append(_entry("hero_statue", 0, EffectFamily.SPECIAL, {"desc": "+25% troop bonus reward gen speed"}))
	entries.append(_entry("hospital", 0, EffectFamily.SPECIAL, {"desc": "+50% healing"}))
	entries.append(_entry("hospital", 1, EffectFamily.SPECIAL, {"desc": "+5 morale per active hospital"}))
	entries.append(_entry("magic_ball", 0, EffectFamily.SPECIAL, {"desc": "+30% spell damage"}))
	entries.append(_entry("magic_ball", 1, EffectFamily.SPECIAL, {"desc": "+15% Arcane troop damage"}))
	entries.append(_entry("magic_college", 0, EffectFamily.SPECIAL, {"desc": "choice instead of random spell"}))
	entries.append(_entry("magic_college", 1, EffectFamily.SPECIAL, {"desc": "+20% spell gen speed"}))
	entries.append(_entry("magic_school", 0, EffectFamily.SPECIAL, {"desc": "choice instead of random spell"}))
	entries.append(_entry("magic_school", 1, EffectFamily.SPECIAL, {"desc": "+25% spell gen speed"}))
	entries.append(_entry("stables", 2, EffectFamily.SPECIAL, {"desc": "rider continues after horse death"}))
	entries.append(_entry("tesla_tower", 0, EffectFamily.SPECIAL, {"desc": "+40% attack speed"}))
	entries.append(_entry("tesla_tower", 1, EffectFamily.SPECIAL, {"desc": "+1 lightning chain"}))
	entries.append(_entry("tesla_tower", 2, EffectFamily.SPECIAL, {"desc": "+40% damage"}))
	entries.append(_entry("wheel_of_fortune", 0, EffectFamily.SPECIAL, {"desc": "+25% production speed"}))

	return entries


static func _entry(building_id: String, upgrade_index: int, family: EffectFamily, expected: Dictionary) -> Dictionary:
	var upgrade_id := "%s:%d" % [building_id, upgrade_index]
	return {
		"building_id": building_id,
		"upgrade_index": upgrade_index,
		"upgrade_id": upgrade_id,
		"family": family,
		"expected": expected,
	}


static func get_entries_by_family(family: EffectFamily) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: Dictionary in get_all_entries():
		if int(entry.get("family", -1)) == family:
			result.append(entry)
	return result
