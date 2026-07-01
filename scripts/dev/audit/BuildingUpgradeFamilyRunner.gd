extends RefCounted
class_name BuildingUpgradeFamilyRunner

## Runs audit verification for each effect family.
## Returns result string: PASS, FAIL_LOGIC, FAIL_REFRESH, INCONCLUSIVE

const ProductionBoostScript := preload("res://core/building_upgrade/BuildingUpgradeProductionBoost.gd")
const ProductionBonusScript := preload("res://core/building_upgrade/BuildingUpgradeProductionBonus.gd")
const CapacityBonusScript := preload("res://core/building_upgrade/BuildingUpgradeCapacityBonus.gd")
const TroopStatModScript := preload("res://core/building_upgrade/BuildingUpgradeTroopStatModifier.gd")
const CombatHookScript := preload("res://core/building_upgrade/BuildingUpgradeCombatHook.gd")
const DeathRewardScript := preload("res://core/building_upgrade/BuildingUpgradeDeathReward.gd")
const CostModifierScript := preload("res://core/building_upgrade/BuildingUpgradeCostModifier.gd")
const MegaMilitiaScript := preload("res://core/building_upgrade/BuildingUpgradeMegaMilitia.gd")
const TroopInspirationScript := preload("res://core/building_upgrade/BuildingUpgradeTroopInspiration.gd")
const SpellDamageScript := preload("res://core/building_upgrade/BuildingUpgradeSpellDamageBoost.gd")
const UnitAuraScript := preload("res://core/building_upgrade/BuildingUpgradeUnitAura.gd")
const ProductionEventScript := preload("res://core/building_upgrade/BuildingUpgradeProductionEvent.gd")
const LionCircusScript := preload("res://core/building_upgrade/BuildingUpgradeLionCircus.gd")
const AuditMatrixScript := preload("res://scripts/dev/audit/BuildingUpgradeAuditMatrix.gd")
const RuntimeProbeScript := preload("res://scripts/dev/qa/BuildingUpgradeRuntimeProbe.gd")


static func run_entry(entry: Dictionary, harness: RefCounted) -> String:
	return String(run_entry_result(entry, harness).get("status", "MANUAL_CHECK_REQUIRED"))


static func run_entry_result(entry: Dictionary, harness: RefCounted) -> Dictionary:
	var family: int = int(entry.get("family", -1))
	match family:
		# ── Runtime probes (live autoloads, before/after in real game state) ──
		AuditMatrixScript.EffectFamily.TROOP_STAT:
			return _verify_runtime_troop_stat(entry, harness)
		AuditMatrixScript.EffectFamily.MORALE:
			return _verify_runtime_morale(entry)
		AuditMatrixScript.EffectFamily.SPELL_DAMAGE:
			return _verify_runtime_spell_damage(entry)
		AuditMatrixScript.EffectFamily.UNIT_AURA:
			return _verify_runtime_unit_aura(entry)
		AuditMatrixScript.EffectFamily.COST_MODIFIER:
			return _verify_runtime_cost_modifier(entry)
		AuditMatrixScript.EffectFamily.MEGA_MILITIA:
			return _verify_runtime_mega_militia(entry)
		# ── Logic probes (real pure functions via harness, before/after in logic) ──
		AuditMatrixScript.EffectFamily.PRODUCTION_SPEED:
			return _verify_logic_production_speed(entry, harness)
		AuditMatrixScript.EffectFamily.EFFICIENT_PROCESSING:
			return _verify_logic_efficient_processing(entry, harness)
		AuditMatrixScript.EffectFamily.PRODUCTION_BONUS:
			return _verify_logic_production_bonus(entry, harness)
		AuditMatrixScript.EffectFamily.CAPACITY:
			return _verify_logic_capacity(entry, harness)
		AuditMatrixScript.EffectFamily.COMBAT_HOOK:
			return _verify_logic_combat_hook(entry, harness)
		AuditMatrixScript.EffectFamily.DEATH_REWARD:
			return _verify_logic_death_reward(entry, harness)
		AuditMatrixScript.EffectFamily.PRODUCTION_EVENT:
			return _verify_logic_production_event(entry, harness)
		AuditMatrixScript.EffectFamily.LION_CIRCUS:
			return _verify_logic_lion_circus(entry, harness)
		# ── No automated path ──
		AuditMatrixScript.EffectFamily.SPECIAL:
			return _manual_result("special.runtime", entry.get("expected", {}), "No automated runtime probe exists yet for this special building effect")
		AuditMatrixScript.EffectFamily.INCONCLUSIVE:
			return _manual_result("inconclusive.runtime", entry.get("expected", {}), "Neighbour-grid effect requires live map layout — no automated probe")
		_:
			return _manual_result("unknown.family", entry.get("expected", {}), "No verification path for this effect family")


static func _result(status: String, target: String, before: Variant, after: Variant, expected: Variant, reason: String = "") -> Dictionary:
	return {
		"status": status,
		"target": target,
		"before": before,
		"after": after,
		"expected": expected,
		"reason": reason,
	}


static func _manual_result(target: String, expected: Variant, reason: String) -> Dictionary:
	return _result("MANUAL_CHECK_REQUIRED", target, null, null, expected, reason)


static func _fail_fixture(target: String, expected: Variant, reason: String) -> Dictionary:
	return _result("FAIL_FIXTURE", target, null, null, expected, reason)


static func _fail_unchanged(target: String, before: Variant, after: Variant, expected: Variant, reason: String) -> Dictionary:
	return _result("FAIL_RUNTIME_UNCHANGED", target, before, after, expected, reason)


static func _fail_mismatch(target: String, before: Variant, after: Variant, expected: Variant, reason: String) -> Dictionary:
	return _result("FAIL_RUNTIME_MISMATCH", target, before, after, expected, reason)


static func _pass_result(target: String, before: Variant, after: Variant, expected: Variant) -> Dictionary:
	return _result("PASS", target, before, after, expected, "")


static func _logic_pass(target: String, before: Variant, after: Variant, expected: Variant) -> Dictionary:
	return _result("LOGIC_PASS", target, before, after, expected, "")


static func _logic_fail(target: String, before: Variant, after: Variant, expected: Variant, reason: String) -> Dictionary:
	return _result("FAIL_LOGIC", target, before, after, expected, reason)


static func _finalize_probe(probe: RefCounted, result: Dictionary) -> Dictionary:
	if probe != null and probe.has_method("reset_runtime"):
		probe.call("reset_runtime")
	if probe != null and probe.has_method("cleanup"):
		probe.call("cleanup")
	return result


# ── Family verifiers ─────────────────────────────────────────────────────

static func _verify_runtime_morale(entry: Dictionary) -> Dictionary:
	var probe := RuntimeProbeScript.new()
	if probe == null:
		return _fail_fixture("morale.building_bonus", entry.get("expected", {}), "Failed to create runtime probe")
	probe.reset_runtime()
	var expected: Dictionary = entry.get("expected", {})
	var building_id: String = String(entry.get("building_id", ""))
	var upgrade_id: String = String(entry.get("upgrade_id", ""))
	var slots: Array[Dictionary] = []
	match building_id:
		"vineyard":
			slots = [{"slot_index": 1, "building_id": "vineyard", "active": false}]
		"market":
			slots = [{"slot_index": 1, "building_id": "market", "active": true}]
		"tavern":
			slots = [{"slot_index": 1, "building_id": "tavern", "active": true}]
		_:
			return _finalize_probe(probe, _manual_result("morale.building_bonus", expected, "No runtime morale fixture exists for this building"))
	var scene := probe.create_game_scene_with_slots(slots)
	if scene == null:
		return _finalize_probe(probe, _fail_fixture("morale.building_bonus", expected, "Failed to build map-slot fixture"))
	var before: int = int(probe.get_building_bonus_morale())
	probe.unlock_upgrade(upgrade_id)
	var after: int = int(probe.get_building_bonus_morale())
	var expected_total := 0
	if expected.has("bonus_per_building"):
		expected_total = int(expected.get("bonus_per_building", 0)) * slots.size()
	elif expected.has("bonus_flat"):
		expected_total = int(expected.get("bonus_flat", 0))
	if after == before:
		return _finalize_probe(probe, _fail_unchanged("morale.building_bonus", before, after, expected_total, "Upgrade was applied but morale building bonus did not change"))
	if after != expected_total:
		return _finalize_probe(probe, _fail_mismatch("morale.building_bonus", before, after, expected_total, "Morale building bonus does not match expected runtime value"))
	return _finalize_probe(probe, _pass_result("morale.building_bonus", before, after, expected_total))


static func _verify_runtime_troop_stat(entry: Dictionary, harness: RefCounted) -> Dictionary:
	var expected: Dictionary = entry.get("expected", {})
	# Inspiration — real runtime probe through HeroCore/HeroStats (Fix 3: was LOGIC_PASS)
	if bool(expected.get("is_inspiration", false)):
		return _verify_runtime_troop_inspiration(entry)
	if expected.has("evasion") or expected.has("attack_range_mult"):
		return _verify_logic_troop_stat_modifier(entry, harness)
	# HP/DMG per-unit → real runtime probe via HeroCore
	var probe := RuntimeProbeScript.new()
	if probe == null:
		return _fail_fixture("hero_stats", expected, "Failed to create runtime probe")
	probe.reset_runtime()
	var unit_id: String = String(expected.get("unit", ""))
	var upgrade_id: String = String(entry.get("upgrade_id", ""))
	if unit_id == "":
		return _finalize_probe(probe, _fail_fixture("hero_stats", expected, "Missing unit id for troop stat runtime probe"))
	var hero_id := String(probe.create_active_hero(unit_id))
	if hero_id == "":
		return _finalize_probe(probe, _fail_fixture("hero_stats", expected, "Failed to create active hero fixture for %s" % unit_id))
	var before: Dictionary = probe.get_hero_total_stats(hero_id)
	probe.unlock_upgrade(upgrade_id)
	var after: Dictionary = probe.get_hero_total_stats(hero_id)
	if before.is_empty() or after.is_empty():
		return _finalize_probe(probe, _fail_fixture("hero_stats", expected, "HeroStats returned empty runtime data"))
	if before == after:
		return _finalize_probe(probe, _fail_unchanged("hero_stats", before, after, expected, "Upgrade was applied but runtime hero stats did not change"))
	if expected.has("hp_mult"):
		var hp_before := float(before.get("maxHp", 0.0))
		var hp_after := float(after.get("maxHp", 0.0))
		if hp_before <= 0.0:
			return _finalize_probe(probe, _fail_fixture("hero_stats.maxHp", expected, "Invalid pre-upgrade maxHp in runtime probe"))
		var hp_ratio := hp_after / hp_before
		if absf(hp_ratio - float(expected.get("hp_mult", 1.0))) > 0.02:
			return _finalize_probe(probe, _fail_mismatch("hero_stats.maxHp", before, after, expected, "Runtime maxHp multiplier does not match expected value"))
	if expected.has("dmg_mult"):
		var dmg_before := float(before.get("damage", 0.0))
		var dmg_after := float(after.get("damage", 0.0))
		if dmg_before <= 0.0:
			return _finalize_probe(probe, _fail_fixture("hero_stats.damage", expected, "Invalid pre-upgrade damage in runtime probe"))
		var dmg_ratio := dmg_after / dmg_before
		if absf(dmg_ratio - float(expected.get("dmg_mult", 1.0))) > 0.02:
			return _finalize_probe(probe, _fail_mismatch("hero_stats.damage", before, after, expected, "Runtime damage multiplier does not match expected value"))
	return _finalize_probe(probe, _pass_result("hero_stats", before, after, expected))


static func _verify_runtime_spell_damage(entry: Dictionary) -> Dictionary:
	var probe := RuntimeProbeScript.new()
	if probe == null:
		return _fail_fixture("artifact.spell_damage_multiplier", entry.get("expected", {}), "Failed to create runtime probe")
	probe.reset_runtime()
	var expected: Dictionary = entry.get("expected", {})
	var upgrade_id: String = String(entry.get("upgrade_id", ""))
	var scope: String = String(expected.get("scope", "flat"))
	match scope:
		"per_unit":
			if upgrade_id == "ram_pasture:1":
				if String(probe.create_active_hero("ram")) == "":
					return _finalize_probe(probe, _fail_fixture("artifact.spell_damage_multiplier", expected, "Failed to create active ram fixture"))
			elif upgrade_id == "white_unicorn_field:1":
				if String(probe.create_active_hero("white_unicorn", "white_unicorn")) == "":
					return _finalize_probe(probe, _fail_fixture("artifact.spell_damage_multiplier", expected, "Failed to create active white unicorn fixture"))
	var before: float = float(probe.get_spell_damage_multiplier())
	probe.unlock_upgrade(upgrade_id)
	var after: float = float(probe.get_spell_damage_multiplier())
	var expected_mult := 1.0
	match scope:
		"flat_boolean":
			expected_mult = 1.1
		"flat":
			expected_mult = float(expected.get("multiplier", 1.0))
		"per_unit":
			if upgrade_id == "ram_pasture:1":
				expected_mult = 1.2
			elif upgrade_id == "white_unicorn_field:1":
				expected_mult = 1.1
	if is_equal_approx(before, after):
		return _finalize_probe(probe, _fail_unchanged("artifact.spell_damage_multiplier", before, after, expected_mult, "Upgrade was applied but spell damage multiplier did not change"))
	if absf(after - expected_mult) > 0.02:
		return _finalize_probe(probe, _fail_mismatch("artifact.spell_damage_multiplier", before, after, expected_mult, "Runtime spell damage multiplier does not match expected value"))
	return _finalize_probe(probe, _pass_result("artifact.spell_damage_multiplier", before, after, expected_mult))


static func _verify_runtime_unit_aura(entry: Dictionary) -> Dictionary:
	var probe := RuntimeProbeScript.new()
	if probe == null:
		return _fail_fixture("unit_aura.runtime", entry.get("expected", {}), "Failed to create runtime probe")
	probe.reset_runtime()
	var expected: Dictionary = entry.get("expected", {})
	var aura_type: String = String(expected.get("type", ""))
	var upgrade_id: String = String(entry.get("upgrade_id", ""))
	match aura_type:
		"morale":
			if String(probe.create_active_hero("black_unicorn", "black_unicorn")) == "":
				return _finalize_probe(probe, _fail_fixture("morale.building_bonus.black_unicorn", expected, "Failed to create active black unicorn fixture"))
			var morale_before := int(probe.get_building_bonus_morale())
			probe.unlock_upgrade(upgrade_id)
			var morale_after := int(probe.get_building_bonus_morale())
			if morale_after == morale_before:
				return _finalize_probe(probe, _fail_unchanged("morale.building_bonus.black_unicorn", morale_before, morale_after, 5, "Black unicorn morale aura did not reach MoraleSystem building bonus"))
			if morale_after != 5:
				return _finalize_probe(probe, _fail_mismatch("morale.building_bonus.black_unicorn", morale_before, morale_after, 5, "Black unicorn morale aura value is incorrect"))
			return _finalize_probe(probe, _pass_result("morale.building_bonus.black_unicorn", morale_before, morale_after, 5))
		"global_damage":
			var target_hero := String(probe.create_active_hero("peasant"))
			var hydra_hero := String(probe.create_active_hero("hydra", "hydra"))
			if target_hero == "" or hydra_hero == "":
				return _finalize_probe(probe, _fail_fixture("hero_stats.damage.global_aura", expected, "Failed to create target hero or hydra fixture"))
			var damage_before: Dictionary = probe.get_hero_total_stats(target_hero)
			probe.unlock_upgrade(upgrade_id)
			var damage_after: Dictionary = probe.get_hero_total_stats(target_hero)
			var before_value := float(damage_before.get("damage", 0.0))
			var after_value := float(damage_after.get("damage", 0.0))
			if before_value <= 0.0:
				return _finalize_probe(probe, _fail_fixture("hero_stats.damage.global_aura", expected, "Invalid pre-upgrade target damage for hydra aura"))
			if is_equal_approx(before_value, after_value):
				return _finalize_probe(probe, _fail_unchanged("hero_stats.damage.global_aura", damage_before, damage_after, 1.1, "Hydra aura did not change target hero damage"))
			if absf((after_value / before_value) - 1.1) > 0.02:
				return _finalize_probe(probe, _fail_mismatch("hero_stats.damage.global_aura", damage_before, damage_after, 1.1, "Hydra aura damage multiplier is incorrect"))
			return _finalize_probe(probe, _pass_result("hero_stats.damage.global_aura", damage_before, damage_after, 1.1))
		"flying_damage":
			var flying_unit := String(probe.resolve_candidate_with_class(int(UnitConfig.UnitClass.FLYING), ["griffin", "bumblebee", "black_unicorn", "hydra", "white_unicorn", "goose_rider"]))
			if flying_unit == "":
				return _finalize_probe(probe, _fail_fixture("hero_stats.damage.flying_aura", expected, "No flying unit candidate could be resolved from TroopBonusCore"))
			var flying_hero := String(probe.create_active_hero(flying_unit, flying_unit))
			var minotaur_hero := String(probe.create_active_hero("minotaur", "minotaur"))
			if flying_hero == "" or minotaur_hero == "":
				return _finalize_probe(probe, _fail_fixture("hero_stats.damage.flying_aura", expected, "Failed to create flying or minotaur fixture hero"))
			var flying_before: Dictionary = probe.get_hero_total_stats(flying_hero)
			probe.unlock_upgrade(upgrade_id)
			var flying_after: Dictionary = probe.get_hero_total_stats(flying_hero)
			var flying_before_damage := float(flying_before.get("damage", 0.0))
			var flying_after_damage := float(flying_after.get("damage", 0.0))
			if flying_before_damage <= 0.0:
				return _finalize_probe(probe, _fail_fixture("hero_stats.damage.flying_aura", expected, "Invalid pre-upgrade damage for flying target hero"))
			if is_equal_approx(flying_before_damage, flying_after_damage):
				return _finalize_probe(probe, _fail_unchanged("hero_stats.damage.flying_aura", flying_before, flying_after, 1.03, "Minotaur flying aura did not change flying-unit damage"))
			if absf((flying_after_damage / flying_before_damage) - 1.03) > 0.02:
				return _finalize_probe(probe, _fail_mismatch("hero_stats.damage.flying_aura", flying_before, flying_after, 1.03, "Minotaur flying aura damage multiplier is incorrect"))
			return _finalize_probe(probe, _pass_result("hero_stats.damage.flying_aura", flying_before, flying_after, 1.03))
		"grunt_hp":
			var grunt_unit := String(probe.resolve_candidate_with_class(int(UnitConfig.UnitClass.GRUNT), ["militia", "peasant", "black_swordsman", "madman", "barbarian"]))
			if grunt_unit == "":
				return _finalize_probe(probe, _fail_fixture("hero_stats.maxHp.grunt_aura", expected, "No grunt unit candidate could be resolved from TroopBonusCore"))
			var grunt_hero := String(probe.create_active_hero(grunt_unit, grunt_unit))
			var swordsman_hero := String(probe.create_active_hero("black_swordsman", "black_swordsman"))
			if grunt_hero == "" or swordsman_hero == "":
				return _finalize_probe(probe, _fail_fixture("hero_stats.maxHp.grunt_aura", expected, "Failed to create grunt or black swordsman fixture hero"))
			var grunt_before: Dictionary = probe.get_hero_total_stats(grunt_hero)
			probe.unlock_upgrade(upgrade_id)
			var grunt_after: Dictionary = probe.get_hero_total_stats(grunt_hero)
			var grunt_before_hp := float(grunt_before.get("maxHp", 0.0))
			var grunt_after_hp := float(grunt_after.get("maxHp", 0.0))
			if grunt_before_hp <= 0.0:
				return _finalize_probe(probe, _fail_fixture("hero_stats.maxHp.grunt_aura", expected, "Invalid pre-upgrade maxHp for grunt target hero"))
			if is_equal_approx(grunt_before_hp, grunt_after_hp):
				return _finalize_probe(probe, _fail_unchanged("hero_stats.maxHp.grunt_aura", grunt_before, grunt_after, 2.0, "Falcon mentoring aura did not change grunt maxHp"))
			if absf((grunt_after_hp / grunt_before_hp) - 2.0) > 0.02:
				return _finalize_probe(probe, _fail_mismatch("hero_stats.maxHp.grunt_aura", grunt_before, grunt_after, 2.0, "Falcon mentoring aura maxHp multiplier is incorrect"))
			return _finalize_probe(probe, _pass_result("hero_stats.maxHp.grunt_aura", grunt_before, grunt_after, 2.0))
		_:
			return _finalize_probe(probe, _manual_result("unit_aura.runtime", expected, "No automated runtime probe exists yet for this aura type"))


static func _verify_runtime_cost_modifier(entry: Dictionary) -> Dictionary:
	var probe := RuntimeProbeScript.new()
	if probe == null:
		return _fail_fixture("building_upgrade.cost_multiplier", entry.get("expected", {}), "Failed to create runtime probe")
	probe.reset_runtime()
	var expected: Dictionary = entry.get("expected", {})
	var building_id: String = String(entry.get("building_id", ""))
	var upgrade_id: String = String(entry.get("upgrade_id", ""))
	var before: float = float(probe.get_cost_multiplier(building_id))
	probe.unlock_upgrade(upgrade_id)
	var after: float = float(probe.get_cost_multiplier(building_id))
	var expected_mult := float(expected.get("multiplier", 1.0))
	if is_equal_approx(before, after):
		return _finalize_probe(probe, _fail_unchanged("building_upgrade.cost_multiplier", before, after, expected_mult, "Upgrade was applied but runtime cost multiplier did not change"))
	if absf(before - 1.0) > 0.001:
		return _finalize_probe(probe, _fail_mismatch("building_upgrade.cost_multiplier", before, after, expected_mult, "Pre-upgrade runtime cost multiplier must start at 1.0"))
	if absf(after - expected_mult) > 0.02:
		return _finalize_probe(probe, _fail_mismatch("building_upgrade.cost_multiplier", before, after, expected_mult, "Runtime cost multiplier does not match expected value"))
	return _finalize_probe(probe, _pass_result("building_upgrade.cost_multiplier", before, after, expected_mult))


static func _verify_runtime_mega_militia(entry: Dictionary) -> Dictionary:
	var probe := RuntimeProbeScript.new()
	if probe == null:
		return _fail_fixture("building_upgrade.resolve_mega_militia_unit", entry.get("expected", {}), "Failed to create runtime probe")
	probe.reset_runtime()
	var expected: Dictionary = entry.get("expected", {})
	var upgrade_id: String = String(entry.get("upgrade_id", ""))
	var before: Array[String] = []
	for _i: int in range(5):
		before.append(String(probe.resolve_mega_militia_unit("militia_camp", "militia")))
	probe.unlock_upgrade(upgrade_id)
	var after: Array[String] = []
	for _j: int in range(5):
		after.append(String(probe.resolve_mega_militia_unit("militia_camp", "militia")))
	var expected_after: Array[String] = ["militia", "militia", "militia", "militia", "mega_militia"]
	if before == after:
		return _finalize_probe(probe, _fail_unchanged("building_upgrade.resolve_mega_militia_unit", before, after, expected_after, "Upgrade was applied but mega militia runtime output sequence did not change"))
	if before != ["militia", "militia", "militia", "militia", "militia"]:
		return _finalize_probe(probe, _fail_mismatch("building_upgrade.resolve_mega_militia_unit", before, after, expected_after, "Pre-upgrade mega militia sequence is invalid"))
	if after != expected_after:
		return _finalize_probe(probe, _fail_mismatch("building_upgrade.resolve_mega_militia_unit", before, after, expected_after, "Post-upgrade mega militia sequence does not match expected runtime behavior"))
	return _finalize_probe(probe, _pass_result("building_upgrade.resolve_mega_militia_unit", before, after, expected_after))


# ── Logic verifiers (real pure functions, harness mock, LOGIC_PASS status) ─────

static func _verify_logic_production_speed(entry: Dictionary, harness: RefCounted) -> Dictionary:
	var expected: Dictionary = entry.get("expected", {})
	var building_id: String = String(entry.get("building_id", ""))
	var upgrade_id: String = String(entry.get("upgrade_id", ""))
	harness.clear_state()
	var before: float = ProductionBoostScript.get_production_multiplier(building_id, harness.get_has_upgrade_callable())
	if absf(before - 1.0) > 0.001:
		return _logic_fail("production_speed.multiplier", before, before, 1.0, "Pre-upgrade production multiplier must be 1.0")
	harness.unlock_upgrade(upgrade_id)
	var after: float = ProductionBoostScript.get_production_multiplier(building_id, harness.get_has_upgrade_callable())
	var exp_mult: float = float(expected.get("multiplier", 1.0))
	if absf(after - exp_mult) > 0.001:
		return _logic_fail("production_speed.multiplier", before, after, exp_mult, "Production speed multiplier does not match expected value")
	return _logic_pass("production_speed.multiplier", before, after, exp_mult)


static func _verify_logic_efficient_processing(entry: Dictionary, harness: RefCounted) -> Dictionary:
	var expected: Dictionary = entry.get("expected", {})
	var building_id: String = String(entry.get("building_id", ""))
	var upgrade_id: String = String(entry.get("upgrade_id", ""))
	harness.clear_state()
	var before: int = ProductionBoostScript.get_efficient_processing_multiplier(building_id, harness.get_has_upgrade_callable())
	if before != 1:
		return _logic_fail("production_speed.efficient_processing", before, before, 1, "Pre-upgrade efficient processing must be 1")
	harness.unlock_upgrade(upgrade_id)
	var after: int = ProductionBoostScript.get_efficient_processing_multiplier(building_id, harness.get_has_upgrade_callable())
	var exp_mult: int = int(expected.get("multiplier", 1))
	if after != exp_mult:
		return _logic_fail("production_speed.efficient_processing", before, after, exp_mult, "Efficient processing multiplier does not match expected value")
	return _logic_pass("production_speed.efficient_processing", before, after, exp_mult)


static func _verify_logic_production_bonus(entry: Dictionary, harness: RefCounted) -> Dictionary:
	var building_id: String = String(entry.get("building_id", ""))
	var upgrade_id: String = String(entry.get("upgrade_id", ""))
	harness.clear_state()
	var pre_check: Array[Dictionary] = ProductionBonusScript.process_production_bonuses(
		building_id, harness.get_has_upgrade_callable(),
		harness.get_add_resource_callable(), harness.get_repair_castle_callable()
	)
	if not pre_check.is_empty():
		return _logic_fail("production_bonus.triggered", false, false, true, "Pre-upgrade bonus must not trigger")
	harness.unlock_upgrade(upgrade_id)
	var got_result := false
	for _i: int in range(500):
		harness._resources_added.clear()
		harness._castle_repaired = 0
		var results: Array[Dictionary] = ProductionBonusScript.process_production_bonuses(
			building_id, harness.get_has_upgrade_callable(),
			harness.get_add_resource_callable(), harness.get_repair_castle_callable()
		)
		if not results.is_empty():
			got_result = true
			break
	if not got_result:
		return _logic_fail("production_bonus.triggered", false, false, true, "Bonus never triggered in 500 attempts after upgrade")
	return _logic_pass("production_bonus.triggered", false, true, true)


static func _verify_logic_capacity(entry: Dictionary, harness: RefCounted) -> Dictionary:
	var expected: Dictionary = entry.get("expected", {})
	var building_id: String = String(entry.get("building_id", ""))
	var upgrade_id: String = String(entry.get("upgrade_id", ""))
	harness.clear_state()
	var before: int = CapacityBonusScript.get_capacity_bonus(building_id, harness.get_has_upgrade_callable())
	if before != 0:
		return _logic_fail("capacity.bonus", before, before, 0, "Pre-upgrade capacity bonus must be 0")
	harness.unlock_upgrade(upgrade_id)
	var after: int = CapacityBonusScript.get_capacity_bonus(building_id, harness.get_has_upgrade_callable())
	var exp_bonus: int = int(expected.get("bonus", 0))
	if after != exp_bonus:
		return _logic_fail("capacity.bonus", before, after, exp_bonus, "Capacity bonus does not match expected value")
	return _logic_pass("capacity.bonus", before, after, exp_bonus)


static func _verify_logic_combat_hook(entry: Dictionary, harness: RefCounted) -> Dictionary:
	var expected: Dictionary = entry.get("expected", {})
	var upgrade_id: String = String(entry.get("upgrade_id", ""))
	var unit_id: String = String(expected.get("unit", ""))
	var effect_type: String = String(expected.get("type", ""))
	harness.clear_state()
	var before: Array[Dictionary] = CombatHookScript.get_on_hit_effects(unit_id, harness.get_has_upgrade_callable())
	harness.unlock_upgrade(upgrade_id)
	var after: Array[Dictionary] = CombatHookScript.get_on_hit_effects(unit_id, harness.get_has_upgrade_callable())
	if after.is_empty():
		return _logic_fail("combat_hook.effects", before, after, [effect_type], "No on-hit effects registered after upgrade")
	var found := false
	for eff: Dictionary in after:
		if String(eff.get("type", "")) == effect_type:
			found = true
			break
	if not found:
		return _logic_fail("combat_hook.effects", before, after, [effect_type], "Expected effect type '%s' not in results" % effect_type)
	return _logic_pass("combat_hook.effects", before, after, [effect_type])


static func _verify_logic_death_reward(entry: Dictionary, harness: RefCounted) -> Dictionary:
	var expected: Dictionary = entry.get("expected", {})
	var upgrade_id: String = String(entry.get("upgrade_id", ""))
	var unit_id: String = String(expected.get("unit", ""))
	harness.clear_state()
	var before: Dictionary = DeathRewardScript.get_death_reward(unit_id, harness.get_has_upgrade_callable())
	harness.unlock_upgrade(upgrade_id)
	var after: Dictionary = DeathRewardScript.get_death_reward(unit_id, harness.get_has_upgrade_callable())
	if after.is_empty():
		return _logic_fail("death_reward.reward", before, after, expected, "No death reward registered after upgrade")
	if String(after.get("resource_id", "")) != String(expected.get("resource", "")):
		return _logic_fail("death_reward.reward", before, after, expected, "Death reward resource type does not match expected")
	if int(after.get("amount", 0)) != int(expected.get("amount", 0)):
		return _logic_fail("death_reward.reward", before, after, expected, "Death reward amount does not match expected")
	return _logic_pass("death_reward.reward", before, after, expected)


static func _verify_logic_production_event(entry: Dictionary, harness: RefCounted) -> Dictionary:
	var expected: Dictionary = entry.get("expected", {})
	var building_id: String = String(entry.get("building_id", ""))
	var upgrade_id: String = String(entry.get("upgrade_id", ""))
	harness.clear_state()
	var test_unit_id: String = "giant"
	if building_id == "ram_pasture":
		test_unit_id = "ram"
	var before: Array[Dictionary] = ProductionEventScript.process_military_production_event(
		building_id, test_unit_id, harness.get_has_upgrade_callable(),
		harness.get_add_resource_callable(), harness.get_hire_extra_callable()
	)
	if not before.is_empty():
		return _logic_fail("production_event.triggered", false, false, true, "Pre-upgrade event must not trigger")
	harness.unlock_upgrade(upgrade_id)
	if expected.has("resource"):
		harness._resources_added.clear()
		var after: Array[Dictionary] = ProductionEventScript.process_military_production_event(
			building_id, test_unit_id, harness.get_has_upgrade_callable(),
			harness.get_add_resource_callable(), harness.get_hire_extra_callable()
		)
		if after.is_empty():
			return _logic_fail("production_event.triggered", false, false, true, "Production event did not trigger after upgrade")
		return _logic_pass("production_event.triggered", false, true, true)
	elif String(expected.get("type", "")) == "extra_unit":
		var got_extra := false
		for _i: int in range(500):
			harness._extra_units_hired.clear()
			var _r: Array[Dictionary] = ProductionEventScript.process_military_production_event(
				building_id, test_unit_id, harness.get_has_upgrade_callable(),
				harness.get_add_resource_callable(), harness.get_hire_extra_callable()
			)
			if not harness._extra_units_hired.is_empty():
				got_extra = true
				break
		if not got_extra:
			return _logic_fail("production_event.triggered", false, false, true, "Extra unit event never triggered in 500 attempts")
		return _logic_pass("production_event.triggered", false, true, true)
	return _manual_result("production_event.runtime", expected, "Unrecognized production event type")


static func _verify_logic_lion_circus(entry: Dictionary, harness: RefCounted) -> Dictionary:
	var upgrade_id: String = String(entry.get("upgrade_id", ""))
	harness.clear_state()
	var cost_before: float = LionCircusScript.get_production_cost_multiplier(harness.get_has_upgrade_callable())
	var vers_before: bool = LionCircusScript.is_versatility_active(harness.get_has_upgrade_callable())
	var before_state := {"cost": cost_before, "versatile": vers_before}
	var expected_state := {"cost": 2.0, "versatile": true}
	if absf(cost_before - 1.0) > 0.001:
		return _logic_fail("lion_circus.cost_multiplier", before_state, before_state, expected_state, "Pre-upgrade cost multiplier must be 1.0")
	if vers_before:
		return _logic_fail("lion_circus.versatility", before_state, before_state, expected_state, "Pre-upgrade versatility must be inactive")
	harness.unlock_upgrade(upgrade_id)
	var cost_after: float = LionCircusScript.get_production_cost_multiplier(harness.get_has_upgrade_callable())
	var vers_after: bool = LionCircusScript.is_versatility_active(harness.get_has_upgrade_callable())
	var after_state := {"cost": cost_after, "versatile": vers_after}
	if absf(cost_after - 2.0) > 0.001:
		return _logic_fail("lion_circus.cost_multiplier", before_state, after_state, expected_state, "Cost multiplier should be 2.0 after upgrade")
	if not vers_after:
		return _logic_fail("lion_circus.versatility", before_state, after_state, expected_state, "Versatility should be active after upgrade")
	return _logic_pass("lion_circus.cost_multiplier", before_state, after_state, expected_state)


static func _verify_runtime_troop_inspiration(entry: Dictionary) -> Dictionary:
	var expected: Dictionary = entry.get("expected", {})
	var building_id: String = String(entry.get("building_id", ""))
	var upgrade_id: String = String(entry.get("upgrade_id", ""))
	var troop_class: String = String(expected.get("class", ""))
	# Map class name → a representative unit_id of that class
	const CLASS_UNIT_MAP: Dictionary = {
		"WARRIOR": "swordsman",
		"RANGED":  "slinger",
		"FLYING":  "bumblebee",
		"RIDER":   "rider",
		"GRUNT":   "peasant",
		"CHAMPION": "griffin",
	}
	var unit_id: String = String(CLASS_UNIT_MAP.get(troop_class, ""))
	if unit_id == "":
		return _manual_result("hero_stats.class_inspiration", expected, "No representative unit mapped for class '%s'" % troop_class)
	var probe := RuntimeProbeScript.new()
	if probe == null:
		return _fail_fixture("hero_stats.class_inspiration", expected, "Failed to create runtime probe")
	probe.reset_runtime()
	if building_id != "":
		var scene := probe.create_game_scene_with_slots([
			{"slot_index": 1, "building_id": building_id, "active": false}
		])
		if scene == null:
			return _finalize_probe(probe, _fail_fixture("hero_stats.class_inspiration", expected, "Failed to create building fixture for %s" % building_id))
	var hero_id := String(probe.create_active_hero(unit_id))
	if hero_id == "":
		return _finalize_probe(probe, _fail_fixture("hero_stats.class_inspiration", expected, "Failed to create active hero fixture for %s" % unit_id))
	var before: Dictionary = probe.get_hero_total_stats(hero_id)
	probe.unlock_upgrade(upgrade_id)
	var after: Dictionary = probe.get_hero_total_stats(hero_id)
	if before.is_empty() or after.is_empty():
		return _finalize_probe(probe, _fail_fixture("hero_stats.class_inspiration", expected, "HeroStats returned empty runtime data"))
	var hp_before := float(before.get("maxHp", 0.0))
	var hp_after  := float(after.get("maxHp", 0.0))
	var dmg_before := float(before.get("damage", 0.0))
	var dmg_after  := float(after.get("damage", 0.0))
	if hp_before <= 0.0 or dmg_before <= 0.0:
		return _finalize_probe(probe, _fail_fixture("hero_stats.class_inspiration", expected, "Invalid pre-upgrade stats for %s" % unit_id))
	if is_equal_approx(hp_before, hp_after) and is_equal_approx(dmg_before, dmg_after):
		return _finalize_probe(probe, _fail_unchanged("hero_stats.class_inspiration", before, after, expected, "Inspiration upgrade applied but hero stats did not change"))
	var exp_hp_mult  := float(expected.get("hp_mult",  1.1))
	var exp_dmg_mult := float(expected.get("dmg_mult", 1.1))
	if absf((hp_after / hp_before) - exp_hp_mult) > 0.02:
		return _finalize_probe(probe, _fail_mismatch("hero_stats.class_inspiration.hp", before, after, expected, "HP multiplier after inspiration does not match expected %.2f" % exp_hp_mult))
	if absf((dmg_after / dmg_before) - exp_dmg_mult) > 0.02:
		return _finalize_probe(probe, _fail_mismatch("hero_stats.class_inspiration.dmg", before, after, expected, "DMG multiplier after inspiration does not match expected %.2f" % exp_dmg_mult))
	return _finalize_probe(probe, _pass_result("hero_stats.class_inspiration", before, after, expected))


static func _verify_logic_troop_inspiration(entry: Dictionary, harness: RefCounted) -> Dictionary:
	var expected: Dictionary = entry.get("expected", {})
	var upgrade_id: String = String(entry.get("upgrade_id", ""))
	var troop_class: String = String(expected.get("class", ""))
	harness.clear_state()
	var hp_before: float = TroopInspirationScript.get_troop_class_hp_multiplier(troop_class, harness.get_has_upgrade_callable())
	var dmg_before: float = TroopInspirationScript.get_troop_class_damage_multiplier(troop_class, harness.get_has_upgrade_callable())
	var before_state := {"hp": hp_before, "dmg": dmg_before}
	if absf(hp_before - 1.0) > 0.001 or absf(dmg_before - 1.0) > 0.001:
		return _logic_fail("hero_stats.class_inspiration", before_state, before_state, expected, "Pre-upgrade inspiration multipliers must be 1.0")
	harness.unlock_upgrade(upgrade_id)
	var hp_after: float = TroopInspirationScript.get_troop_class_hp_multiplier(troop_class, harness.get_has_upgrade_callable())
	var dmg_after: float = TroopInspirationScript.get_troop_class_damage_multiplier(troop_class, harness.get_has_upgrade_callable())
	var after_state := {"hp": hp_after, "dmg": dmg_after}
	if absf(hp_after - float(expected.get("hp_mult", 1.0))) > 0.001:
		return _logic_fail("hero_stats.class_inspiration.hp", before_state, after_state, expected, "Inspiration HP multiplier does not match expected")
	if absf(dmg_after - float(expected.get("dmg_mult", 1.0))) > 0.001:
		return _logic_fail("hero_stats.class_inspiration.dmg", before_state, after_state, expected, "Inspiration DMG multiplier does not match expected")
	return _logic_pass("hero_stats.class_inspiration", before_state, after_state, expected)


static func _verify_logic_troop_stat_modifier(entry: Dictionary, harness: RefCounted) -> Dictionary:
	var expected: Dictionary = entry.get("expected", {})
	var upgrade_id: String = String(entry.get("upgrade_id", ""))
	var unit_id: String = String(expected.get("unit", ""))
	harness.clear_state()
	harness.unlock_upgrade(upgrade_id)
	if expected.has("evasion"):
		var ev: float = TroopStatModScript.get_unit_evasion_chance(unit_id, harness.get_has_upgrade_callable())
		var exp_ev: float = float(expected["evasion"])
		if absf(ev - exp_ev) > 0.001:
			return _logic_fail("hero_stats.evasion", 0.0, ev, exp_ev, "Evasion chance does not match expected value")
		return _logic_pass("hero_stats.evasion", 0.0, ev, exp_ev)
	if expected.has("attack_range_mult"):
		var ar: float = TroopStatModScript.get_unit_attack_range_multiplier(unit_id, harness.get_has_upgrade_callable())
		var exp_ar: float = float(expected["attack_range_mult"])
		if absf(ar - exp_ar) > 0.001:
			return _logic_fail("hero_stats.attack_range_mult", 1.0, ar, exp_ar, "Attack range multiplier does not match expected value")
		return _logic_pass("hero_stats.attack_range_mult", 1.0, ar, exp_ar)
	return _manual_result("hero_stats.troop_stat", expected, "Unknown sub-type in logic troop stat modifier")


# ── Legacy dead-code verifiers (kept for reference, not called by dispatch) ───

static func _verify_production_speed(entry: Dictionary, harness: RefCounted) -> String:
	var expected: Dictionary = entry.get("expected", {})
	var building_id: String = entry.get("building_id", "")
	var upgrade_id: String = entry.get("upgrade_id", "")
	harness.clear_state()
	# Before unlock: should be 1.0
	var before: float = ProductionBoostScript.get_production_multiplier(building_id, harness.get_has_upgrade_callable())
	if absf(before - 1.0) > 0.001:
		return "FAIL_LOGIC"
	# After unlock: should match expected
	harness.unlock_upgrade(upgrade_id)
	var after: float = ProductionBoostScript.get_production_multiplier(building_id, harness.get_has_upgrade_callable())
	var exp_mult: float = float(expected.get("multiplier", 1.0))
	if absf(after - exp_mult) > 0.001:
		return "FAIL_LOGIC"
	return "PASS"


static func _verify_efficient_processing(entry: Dictionary, harness: RefCounted) -> String:
	var expected: Dictionary = entry.get("expected", {})
	var building_id: String = entry.get("building_id", "")
	var upgrade_id: String = entry.get("upgrade_id", "")
	harness.clear_state()
	var before: int = ProductionBoostScript.get_efficient_processing_multiplier(building_id, harness.get_has_upgrade_callable())
	if before != 1:
		return "FAIL_LOGIC"
	harness.unlock_upgrade(upgrade_id)
	var after: int = ProductionBoostScript.get_efficient_processing_multiplier(building_id, harness.get_has_upgrade_callable())
	var exp_mult: int = int(expected.get("multiplier", 1))
	if after != exp_mult:
		return "FAIL_LOGIC"
	return "PASS"


static func _verify_production_bonus(entry: Dictionary, harness: RefCounted) -> String:
	var building_id: String = entry.get("building_id", "")
	var upgrade_id: String = entry.get("upgrade_id", "")
	harness.clear_state()
	# Before unlock: no bonuses
	var before: Array[Dictionary] = ProductionBonusScript.process_production_bonuses(
		building_id, harness.get_has_upgrade_callable(),
		harness.get_add_resource_callable(), harness.get_repair_castle_callable()
	)
	if not before.is_empty():
		return "FAIL_LOGIC"
	# After unlock: should produce results (RNG-dependent, so run many times)
	harness.unlock_upgrade(upgrade_id)
	var got_result := false
	for i: int in range(500):
		harness._resources_added.clear()
		harness._castle_repaired = 0
		var results: Array[Dictionary] = ProductionBonusScript.process_production_bonuses(
			building_id, harness.get_has_upgrade_callable(),
			harness.get_add_resource_callable(), harness.get_repair_castle_callable()
		)
		if not results.is_empty():
			got_result = true
			break
	if not got_result:
		return "FAIL_LOGIC"
	return "PASS"


static func _verify_capacity(entry: Dictionary, harness: RefCounted) -> String:
	var expected: Dictionary = entry.get("expected", {})
	var building_id: String = entry.get("building_id", "")
	var upgrade_id: String = entry.get("upgrade_id", "")
	harness.clear_state()
	var before: int = CapacityBonusScript.get_capacity_bonus(building_id, harness.get_has_upgrade_callable())
	if before != 0:
		return "FAIL_LOGIC"
	harness.unlock_upgrade(upgrade_id)
	var after: int = CapacityBonusScript.get_capacity_bonus(building_id, harness.get_has_upgrade_callable())
	var exp_bonus: int = int(expected.get("bonus", 0))
	if after != exp_bonus:
		return "FAIL_LOGIC"
	return "PASS"


static func _verify_troop_stat(entry: Dictionary, harness: RefCounted) -> String:
	var expected: Dictionary = entry.get("expected", {})
	var upgrade_id: String = entry.get("upgrade_id", "")
	harness.clear_state()

	if expected.get("is_inspiration", false):
		return _verify_troop_inspiration(entry, harness)

	var unit_id: String = String(expected.get("unit", ""))
	harness.unlock_upgrade(upgrade_id)

	if expected.has("hp_mult"):
		var hp: float = TroopStatModScript.get_unit_hp_multiplier(unit_id, harness.get_has_upgrade_callable())
		if absf(hp - float(expected["hp_mult"])) > 0.001:
			return "FAIL_LOGIC"

	if expected.has("dmg_mult"):
		var dmg: float = TroopStatModScript.get_unit_damage_multiplier(unit_id, harness.get_has_upgrade_callable())
		if absf(dmg - float(expected["dmg_mult"])) > 0.001:
			return "FAIL_LOGIC"

	if expected.has("evasion"):
		var ev: float = TroopStatModScript.get_unit_evasion_chance(unit_id, harness.get_has_upgrade_callable())
		if absf(ev - float(expected["evasion"])) > 0.001:
			return "FAIL_LOGIC"

	if expected.has("attack_range_mult"):
		var ar: float = TroopStatModScript.get_unit_attack_range_multiplier(unit_id, harness.get_has_upgrade_callable())
		if absf(ar - float(expected["attack_range_mult"])) > 0.001:
			return "FAIL_LOGIC"

	return "PASS"


static func _verify_troop_inspiration(entry: Dictionary, harness: RefCounted) -> String:
	var expected: Dictionary = entry.get("expected", {})
	var upgrade_id: String = entry.get("upgrade_id", "")
	var troop_class: String = String(expected.get("class", ""))
	harness.clear_state()

	var hp_before: float = TroopInspirationScript.get_troop_class_hp_multiplier(troop_class, harness.get_has_upgrade_callable())
	var dmg_before: float = TroopInspirationScript.get_troop_class_damage_multiplier(troop_class, harness.get_has_upgrade_callable())
	if absf(hp_before - 1.0) > 0.001 or absf(dmg_before - 1.0) > 0.001:
		return "FAIL_LOGIC"

	harness.unlock_upgrade(upgrade_id)
	var hp_after: float = TroopInspirationScript.get_troop_class_hp_multiplier(troop_class, harness.get_has_upgrade_callable())
	var dmg_after: float = TroopInspirationScript.get_troop_class_damage_multiplier(troop_class, harness.get_has_upgrade_callable())
	if absf(hp_after - float(expected.get("hp_mult", 1.0))) > 0.001:
		return "FAIL_LOGIC"
	if absf(dmg_after - float(expected.get("dmg_mult", 1.0))) > 0.001:
		return "FAIL_LOGIC"
	return "PASS"


static func _verify_combat_hook(entry: Dictionary, harness: RefCounted) -> String:
	var expected: Dictionary = entry.get("expected", {})
	var upgrade_id: String = entry.get("upgrade_id", "")
	var unit_id: String = String(expected.get("unit", ""))
	var effect_type: String = String(expected.get("type", ""))
	harness.clear_state()

	harness.unlock_upgrade(upgrade_id)
	var after: Array[Dictionary] = CombatHookScript.get_on_hit_effects(unit_id, harness.get_has_upgrade_callable())
	# Must have at least one effect after unlock
	if after.is_empty():
		return "FAIL_LOGIC"
	# Check the expected type exists in the results
	var found := false
	for eff: Dictionary in after:
		if String(eff.get("type", "")) == effect_type:
			found = true
			break
	if not found:
		return "FAIL_LOGIC"
	return "PASS"


static func _verify_death_reward(entry: Dictionary, harness: RefCounted) -> String:
	var expected: Dictionary = entry.get("expected", {})
	var upgrade_id: String = entry.get("upgrade_id", "")
	var unit_id: String = String(expected.get("unit", ""))
	harness.clear_state()

	var before: Dictionary = DeathRewardScript.get_death_reward(unit_id, harness.get_has_upgrade_callable())
	if not before.is_empty():
		return "FAIL_LOGIC"

	harness.unlock_upgrade(upgrade_id)
	var after: Dictionary = DeathRewardScript.get_death_reward(unit_id, harness.get_has_upgrade_callable())
	if after.is_empty():
		return "FAIL_LOGIC"
	if String(after.get("resource_id", "")) != String(expected.get("resource", "")):
		return "FAIL_LOGIC"
	if int(after.get("amount", 0)) != int(expected.get("amount", 0)):
		return "FAIL_LOGIC"
	return "PASS"


static func _verify_cost_modifier(entry: Dictionary, harness: RefCounted) -> String:
	var expected: Dictionary = entry.get("expected", {})
	var building_id: String = entry.get("building_id", "")
	var upgrade_id: String = entry.get("upgrade_id", "")
	harness.clear_state()

	var before: float = CostModifierScript.get_cost_multiplier(building_id, harness.get_has_upgrade_callable())
	if absf(before - 1.0) > 0.001:
		return "FAIL_LOGIC"

	harness.unlock_upgrade(upgrade_id)
	var after: float = CostModifierScript.get_cost_multiplier(building_id, harness.get_has_upgrade_callable())
	if absf(after - float(expected.get("multiplier", 1.0))) > 0.001:
		return "FAIL_LOGIC"
	return "PASS"


static func _verify_morale(entry: Dictionary, harness: RefCounted) -> String:
	# Morale uses MoraleSystem which requires scene integration.
	# We verify the upgrade path is wired by checking harness recognizes it.
	var building_id: String = entry.get("building_id", "")
	var upgrade_id: String = entry.get("upgrade_id", "")
	harness.clear_state()
	harness.unlock_upgrade(upgrade_id)
	# Verify the upgrade is registered (uses correct building_id)
	if not harness.has_building_upgrade(building_id, upgrade_id):
		return "FAIL_LOGIC"
	return "PASS"


static func _verify_spell_damage(entry: Dictionary, harness: RefCounted) -> String:
	var expected: Dictionary = entry.get("expected", {})
	var upgrade_id: String = entry.get("upgrade_id", "")
	var scope: String = String(expected.get("scope", "flat"))
	harness.clear_state()

	if scope == "flat_boolean":
		# crystal_mine:0 — handled in BuildingUpgradeCore, just verify unlock path
		harness.unlock_upgrade(upgrade_id)
		return "PASS"
	elif scope == "flat":
		# paladins_campus:1
		harness.unlock_upgrade(upgrade_id)
		var mult: float = SpellDamageScript.get_paladins_spell_damage_multiplier(harness.get_has_upgrade_callable())
		if absf(mult - float(expected.get("multiplier", 1.0))) > 0.001:
			return "FAIL_LOGIC"
		return "PASS"
	elif scope == "per_unit":
		# Per-unit spell damage depends on UnitCounter which needs active heroes
		# Just verify the upgrade unlock path exists
		harness.unlock_upgrade(upgrade_id)
		return "PASS"

	return "INCONCLUSIVE"


static func _verify_unit_aura(entry: Dictionary, harness: RefCounted) -> String:
	var expected: Dictionary = entry.get("expected", {})
	var upgrade_id: String = entry.get("upgrade_id", "")
	harness.clear_state()

	var aura_type: String = String(expected.get("type", ""))
	harness.unlock_upgrade(upgrade_id)

	# Unit auras depend on BuildingUpgradeUnitCounter which reads active heroes.
	# Without real hero scene tree, we can only verify the code path is wired.
	# The functions will return base values (0 or 1.0) since no units are on field.
	match aura_type:
		"morale":
			# get_black_unicorn_morale_bonus returns int >= 0
			var bonus: int = UnitAuraScript.get_black_unicorn_morale_bonus(harness.get_has_upgrade_callable())
			# Without units on field, bonus should be 0 (0 * 5 = 0). That's ok — code path is wired.
			if bonus < 0:
				return "FAIL_LOGIC"
			return "PASS"
		"global_damage":
			var mult: float = UnitAuraScript.get_hydra_global_damage_multiplier(harness.get_has_upgrade_callable())
			if mult < 1.0:
				return "FAIL_LOGIC"
			return "PASS"
		"flying_damage":
			var mult: float = UnitAuraScript.get_minotaur_flying_damage_multiplier(harness.get_has_upgrade_callable())
			if mult < 1.0:
				return "FAIL_LOGIC"
			return "PASS"
		"grunt_hp":
			var mult: float = UnitAuraScript.get_falcon_mentoring_hp_multiplier(harness.get_has_upgrade_callable())
			if mult < 1.0:
				return "FAIL_LOGIC"
			return "PASS"
		_:
			return "INCONCLUSIVE"


static func _verify_production_event(entry: Dictionary, harness: RefCounted) -> String:
	var expected: Dictionary = entry.get("expected", {})
	var building_id: String = entry.get("building_id", "")
	var upgrade_id: String = entry.get("upgrade_id", "")
	harness.clear_state()

	# Determine the unit_id to pass (giants produce "giant", ram produces "ram")
	var test_unit_id: String = "giant"
	if building_id == "ram_pasture":
		test_unit_id = "ram"

	# Before unlock: no events
	var before: Array[Dictionary] = ProductionEventScript.process_military_production_event(
		building_id, test_unit_id, harness.get_has_upgrade_callable(),
		harness.get_add_resource_callable(), harness.get_hire_extra_callable()
	)
	if not before.is_empty():
		return "FAIL_LOGIC"

	harness.unlock_upgrade(upgrade_id)

	if expected.has("resource"):
		# Resource grant events (giants_bedding)
		harness._resources_added.clear()
		var after: Array[Dictionary] = ProductionEventScript.process_military_production_event(
			building_id, test_unit_id, harness.get_has_upgrade_callable(),
			harness.get_add_resource_callable(), harness.get_hire_extra_callable()
		)
		if after.is_empty():
			return "FAIL_LOGIC"
		return "PASS"
	elif String(expected.get("type", "")) == "extra_unit":
		# Ram twins — probabilistic, run many times
		var got_extra := false
		for i: int in range(500):
			harness._extra_units_hired.clear()
			var _result: Array[Dictionary] = ProductionEventScript.process_military_production_event(
				building_id, test_unit_id, harness.get_has_upgrade_callable(),
				harness.get_add_resource_callable(), harness.get_hire_extra_callable()
			)
			if not harness._extra_units_hired.is_empty():
				got_extra = true
				break
		if not got_extra:
			return "FAIL_LOGIC"
		return "PASS"

	return "INCONCLUSIVE"


static func _verify_mega_militia(entry: Dictionary, harness: RefCounted) -> String:
	var upgrade_id: String = entry.get("upgrade_id", "")
	harness.clear_state()

	var counter: Dictionary = {"count": 0}
	harness.unlock_upgrade(upgrade_id)

	# MegaMilitia logic: counter starts at 0, incremented on each normal production.
	# When counter reaches TRIGGER_EVERY (4), the NEXT call produces mega_militia.
	# Calls 1-4 produce normal militia (counter goes 0->1->2->3->4).
	# Call 5 finds count=4 >= TRIGGER_EVERY=4, resets to 0, returns mega_militia.
	for i: int in range(4):
		var result: String = MegaMilitiaScript.resolve_produced_unit("militia_camp", "militia", counter, harness.get_has_upgrade_callable())
		if result != "militia":
			return "FAIL_LOGIC"

	# 5th call should produce mega_militia
	var mega: String = MegaMilitiaScript.resolve_produced_unit("militia_camp", "militia", counter, harness.get_has_upgrade_callable())
	if mega != "mega_militia":
		return "FAIL_LOGIC"

	return "PASS"


static func _verify_lion_circus(entry: Dictionary, harness: RefCounted) -> String:
	var upgrade_id: String = entry.get("upgrade_id", "")
	harness.clear_state()

	var cost_before: float = LionCircusScript.get_production_cost_multiplier(harness.get_has_upgrade_callable())
	if absf(cost_before - 1.0) > 0.001:
		return "FAIL_LOGIC"

	var vers_before: bool = LionCircusScript.is_versatility_active(harness.get_has_upgrade_callable())
	if vers_before:
		return "FAIL_LOGIC"

	harness.unlock_upgrade(upgrade_id)

	var cost_after: float = LionCircusScript.get_production_cost_multiplier(harness.get_has_upgrade_callable())
	if absf(cost_after - 2.0) > 0.001:
		return "FAIL_LOGIC"

	var vers_after: bool = LionCircusScript.is_versatility_active(harness.get_has_upgrade_callable())
	if not vers_after:
		return "FAIL_LOGIC"

	return "PASS"
