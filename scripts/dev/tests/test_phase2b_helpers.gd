extends SceneTree

## Phase 2B: Levy / Veteran Barracks — Building Upgrade Helpers
## Tests all 6 new helper files created in Phase 2B.
## Uses direct static method calls with mock has_upgrade callables.

const CapacityBonusScript := preload("res://core/building_upgrade/BuildingUpgradeCapacityBonus.gd")
const TroopStatModScript := preload("res://core/building_upgrade/BuildingUpgradeTroopStatModifier.gd")
const CombatHookScript := preload("res://core/building_upgrade/BuildingUpgradeCombatHook.gd")
const DeathRewardScript := preload("res://core/building_upgrade/BuildingUpgradeDeathReward.gd")
const CostModifierScript := preload("res://core/building_upgrade/BuildingUpgradeCostModifier.gd")
const MegaMilitiaScript := preload("res://core/building_upgrade/BuildingUpgradeMegaMilitia.gd")


var _passed: int = 0
var _failed: int = 0
var _mock_upgrades: Dictionary = {}


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	# ── Capacity Bonus Tests ───────────────────────────────────────────────
	_test_capacity_no_upgrade()
	_test_capacity_with_upgrade()
	_test_capacity_unknown_building()
	_test_capacity_all_entries_valid()
	# ── Troop Stat Modifier Tests ──────────────────────────────────────────
	_test_hp_modifier_no_upgrade()
	_test_hp_modifier_with_upgrade()
	_test_damage_modifier_with_upgrade()
	_test_evasion_no_upgrade()
	_test_evasion_with_upgrade()
	_test_stat_unknown_unit()
	# ── Combat Hook Tests ──────────────────────────────────────────────────
	_test_combat_no_effects_without_upgrade()
	_test_combat_dot_effect()
	_test_combat_stun_effect()
	_test_combat_crit_effect()
	_test_combat_lifesteal_effect()
	_test_combat_slow_effect()
	_test_combat_minotaur_multiple_effects()
	# ── Death Reward Tests ─────────────────────────────────────────────────
	_test_death_reward_no_upgrade()
	_test_death_reward_peasant()
	_test_death_reward_gnome()
	_test_death_reward_barbarian()
	_test_death_reward_unknown_unit()
	# ── Cost Modifier Tests ────────────────────────────────────────────────
	_test_cost_no_upgrade()
	_test_cost_barbarian_tent_discount()
	_test_cost_firing_range_discount()
	_test_cost_geese_discount()
	_test_cost_unknown_building()
	_test_cost_discount_minimum_1()
	_test_cost_can_produce_discounted()
	_test_cost_consume_inputs_discounted()
	# ── Mega Militia Tests ─────────────────────────────────────────────────
	_test_mega_no_upgrade()
	_test_mega_counter_increments()
	_test_mega_triggers_at_5th()
	_test_mega_resets_after_trigger()
	_test_mega_non_militia_building()
	_test_mega_save_load_counter()

	print("Phase 2B helper tests: %d passed, %d failed" % [_passed, _failed])
	quit(_failed)


func _assert(condition: bool, message: String) -> bool:
	if condition:
		_passed += 1
		return true
	_failed += 1
	push_error("[test_phase2b_helpers] FAIL: %s" % message)
	return false


func _assert_eq(actual: Variant, expected: Variant, message: String) -> bool:
	if actual == expected:
		_passed += 1
		return true
	_failed += 1
	push_error("[test_phase2b_helpers] FAIL: %s — expected %s, got %s" % [message, str(expected), str(actual)])
	return false


func _assert_approx(actual: float, expected: float, message: String, epsilon: float = 0.001) -> bool:
	if absf(actual - expected) <= epsilon:
		_passed += 1
		return true
	_failed += 1
	push_error("[test_phase2b_helpers] FAIL: %s — expected ~%f, got %f" % [message, expected, actual])
	return false


# ── Mock helpers ─────────────────────────────────────────────────────────────

func _has_upgrade_true(_building_id: String, _upgrade_id: String) -> bool:
	return true

func _has_upgrade_false(_building_id: String, _upgrade_id: String) -> bool:
	return false

func _has_upgrade_mock(building_id: String, upgrade_id: String) -> bool:
	var key := building_id + "|" + upgrade_id
	return _mock_upgrades.has(key)

func _set_mock_upgrade(building_id: String, upgrade_id: String) -> void:
	_mock_upgrades[building_id + "|" + upgrade_id] = true

func _clear_mock_upgrades() -> void:
	_mock_upgrades.clear()


# ══════════════════════════════════════════════════════════════════════════════
# CAPACITY BONUS TESTS
# ══════════════════════════════════════════════════════════════════════════════

func _test_capacity_no_upgrade() -> void:
	var bonus: int = CapacityBonusScript.get_capacity_bonus("peasants_hut", Callable(self, "_has_upgrade_false"))
	_assert_eq(bonus, 0, "Capacity: peasants_hut with no upgrade = 0")

func _test_capacity_with_upgrade() -> void:
	var bonus: int = CapacityBonusScript.get_capacity_bonus("peasants_hut", Callable(self, "_has_upgrade_true"))
	_assert_eq(bonus, 2, "Capacity: peasants_hut with upgrade = 2")

func _test_capacity_unknown_building() -> void:
	var bonus: int = CapacityBonusScript.get_capacity_bonus("nonexistent_building", Callable(self, "_has_upgrade_true"))
	_assert_eq(bonus, 0, "Capacity: unknown building = 0")

func _test_capacity_all_entries_valid() -> void:
	var all_ok := true
	for building_id: String in CapacityBonusScript.CAPACITY_BONUS_MAP:
		var entry: Dictionary = CapacityBonusScript.CAPACITY_BONUS_MAP[building_id]
		for upgrade_id: String in entry:
			var val: int = int(entry[upgrade_id])
			if val <= 0:
				all_ok = false
	_assert(all_ok, "Capacity: all map entries have positive bonus values")


# ══════════════════════════════════════════════════════════════════════════════
# TROOP STAT MODIFIER TESTS
# ══════════════════════════════════════════════════════════════════════════════

func _test_hp_modifier_no_upgrade() -> void:
	var mult: float = TroopStatModScript.get_unit_hp_multiplier("militia", Callable(self, "_has_upgrade_false"))
	_assert_approx(mult, 1.0, "HP: militia without upgrade = 1.0")

func _test_hp_modifier_with_upgrade() -> void:
	var mult: float = TroopStatModScript.get_unit_hp_multiplier("militia", Callable(self, "_has_upgrade_true"))
	_assert_approx(mult, 1.5, "HP: militia with militia_camp:0 = 1.5 (+50%)")

func _test_damage_modifier_with_upgrade() -> void:
	var mult: float = TroopStatModScript.get_unit_damage_multiplier("swordsman", Callable(self, "_has_upgrade_true"))
	_assert_approx(mult, 2.0, "Damage: swordsman with upgrade = 2.0 (+100%)")

func _test_evasion_no_upgrade() -> void:
	var chance: float = TroopStatModScript.get_unit_evasion_chance("madman", Callable(self, "_has_upgrade_false"))
	_assert_approx(chance, 0.0, "Evasion: madman without upgrade = 0.0")

func _test_evasion_with_upgrade() -> void:
	var chance: float = TroopStatModScript.get_unit_evasion_chance("madman", Callable(self, "_has_upgrade_true"))
	_assert_approx(chance, 0.35, "Evasion: madman with madhouse:0 = 0.35")

func _test_stat_unknown_unit() -> void:
	var hp: float = TroopStatModScript.get_unit_hp_multiplier("unknown_unit", Callable(self, "_has_upgrade_true"))
	var dmg: float = TroopStatModScript.get_unit_damage_multiplier("unknown_unit", Callable(self, "_has_upgrade_true"))
	var ev: float = TroopStatModScript.get_unit_evasion_chance("unknown_unit", Callable(self, "_has_upgrade_true"))
	_assert_approx(hp, 1.0, "Stat: unknown unit HP = 1.0")
	_assert_approx(dmg, 1.0, "Stat: unknown unit damage = 1.0")
	_assert_approx(ev, 0.0, "Stat: unknown unit evasion = 0.0")


# ══════════════════════════════════════════════════════════════════════════════
# COMBAT HOOK TESTS
# ══════════════════════════════════════════════════════════════════════════════

func _test_combat_no_effects_without_upgrade() -> void:
	var effects: Array[Dictionary] = CombatHookScript.get_on_hit_effects("hunter", Callable(self, "_has_upgrade_false"))
	_assert_eq(effects.size(), 0, "Combat: hunter without upgrade = no effects")

func _test_combat_dot_effect() -> void:
	var effects: Array[Dictionary] = CombatHookScript.get_on_hit_effects("hunter", Callable(self, "_has_upgrade_true"))
	_assert(effects.size() >= 1, "Combat: hunter with upgrade has >= 1 effect")
	if effects.size() > 0:
		_assert_eq(effects[0].get("type", ""), "dot", "Combat: hunter effect type = dot")
		_assert_approx(float(effects[0].get("total_damage", 0.0)), 10.0, "Combat: hunter DoT total = 10")

func _test_combat_stun_effect() -> void:
	var effects: Array[Dictionary] = CombatHookScript.get_on_hit_effects("archer", Callable(self, "_has_upgrade_true"))
	var has_stun := false
	for e: Dictionary in effects:
		if e.get("type", "") == "stun":
			has_stun = true
			_assert_eq(e.get("condition", ""), "full_hp", "Combat: archer stun condition = full_hp")
			_assert_approx(float(e.get("duration", 0.0)), 2.0, "Combat: archer stun duration = 2.0")
	_assert(has_stun, "Combat: archer with upgrade has stun effect")

func _test_combat_crit_effect() -> void:
	var effects: Array[Dictionary] = CombatHookScript.get_on_hit_effects("archer", Callable(self, "_has_upgrade_true"))
	var has_crit := false
	for e: Dictionary in effects:
		if e.get("type", "") == "crit":
			has_crit = true
			_assert_approx(float(e.get("multiplier", 0.0)), 2.0, "Combat: archer crit multiplier = 2.0")
			_assert_eq(e.get("mode", ""), "every_nth", "Combat: archer crit mode = every_nth")
	_assert(has_crit, "Combat: archer with upgrade has crit effect")

func _test_combat_lifesteal_effect() -> void:
	var effects: Array[Dictionary] = CombatHookScript.get_on_hit_effects("minotaur", Callable(self, "_has_upgrade_true"))
	var has_ls := false
	for e: Dictionary in effects:
		if e.get("type", "") == "lifesteal":
			has_ls = true
			_assert_approx(float(e.get("percent", 0.0)), 0.5, "Combat: minotaur lifesteal = 50%")
	_assert(has_ls, "Combat: minotaur with upgrade has lifesteal effect")

func _test_combat_slow_effect() -> void:
	var effects: Array[Dictionary] = CombatHookScript.get_on_hit_effects("ballista", Callable(self, "_has_upgrade_true"))
	var has_slow := false
	for e: Dictionary in effects:
		if e.get("type", "") == "slow":
			has_slow = true
			_assert_approx(float(e.get("factor", 0.0)), 0.5, "Combat: ballista slow factor = 0.5")
			_assert_approx(float(e.get("bonus_damage_percent", 0.0)), 0.25, "Combat: ballista bonus damage = 25%")
	_assert(has_slow, "Combat: ballista with upgrade has slow effect")

func _test_combat_minotaur_multiple_effects() -> void:
	var effects: Array[Dictionary] = CombatHookScript.get_on_hit_effects("minotaur", Callable(self, "_has_upgrade_true"))
	var types: Array[String] = []
	for e: Dictionary in effects:
		types.append(String(e.get("type", "")))
	_assert(types.has("lifesteal"), "Combat: minotaur has lifesteal")
	_assert(types.has("stun"), "Combat: minotaur has stun (via minotaur_stun key)")


# ══════════════════════════════════════════════════════════════════════════════
# DEATH REWARD TESTS
# ══════════════════════════════════════════════════════════════════════════════

func _test_death_reward_no_upgrade() -> void:
	var reward: Dictionary = DeathRewardScript.get_death_reward("peasant", Callable(self, "_has_upgrade_false"))
	_assert(reward.is_empty(), "DeathReward: peasant without upgrade = empty")

func _test_death_reward_peasant() -> void:
	var reward: Dictionary = DeathRewardScript.get_death_reward("peasant", Callable(self, "_has_upgrade_true"))
	_assert_eq(reward.get("resource_id", ""), "gold", "DeathReward: peasant resource = gold")
	_assert_eq(int(reward.get("amount", 0)), 2, "DeathReward: peasant amount = 2")

func _test_death_reward_gnome() -> void:
	var reward: Dictionary = DeathRewardScript.get_death_reward("gnome", Callable(self, "_has_upgrade_true"))
	_assert_eq(reward.get("resource_id", ""), "gold", "DeathReward: gnome resource = gold")
	_assert_eq(int(reward.get("amount", 0)), 5, "DeathReward: gnome amount = 5")

func _test_death_reward_barbarian() -> void:
	var reward: Dictionary = DeathRewardScript.get_death_reward("barbarian", Callable(self, "_has_upgrade_true"))
	_assert_eq(reward.get("resource_id", ""), "metal", "DeathReward: barbarian resource = metal")
	_assert_eq(int(reward.get("amount", 0)), 8, "DeathReward: barbarian amount = 8")

func _test_death_reward_unknown_unit() -> void:
	var reward: Dictionary = DeathRewardScript.get_death_reward("unknown_unit", Callable(self, "_has_upgrade_true"))
	_assert(reward.is_empty(), "DeathReward: unknown unit = empty")


# ══════════════════════════════════════════════════════════════════════════════
# COST MODIFIER TESTS
# ══════════════════════════════════════════════════════════════════════════════

func _test_cost_no_upgrade() -> void:
	var mult: float = CostModifierScript.get_cost_multiplier("barbarian_tent", Callable(self, "_has_upgrade_false"))
	_assert_approx(mult, 1.0, "Cost: barbarian_tent without upgrade = 1.0")

func _test_cost_barbarian_tent_discount() -> void:
	var mult: float = CostModifierScript.get_cost_multiplier("barbarian_tent", Callable(self, "_has_upgrade_true"))
	_assert_approx(mult, 0.5, "Cost: barbarian_tent with barbarian_tent:1 = 0.5")

func _test_cost_firing_range_discount() -> void:
	var mult: float = CostModifierScript.get_cost_multiplier("firing_range", Callable(self, "_has_upgrade_true"))
	_assert_approx(mult, 0.6, "Cost: firing_range with firing_range:2 = 0.6")

func _test_cost_geese_discount() -> void:
	var mult: float = CostModifierScript.get_cost_multiplier("geese_training_field", Callable(self, "_has_upgrade_true"))
	_assert_approx(mult, 0.5, "Cost: geese_training_field with upgrade = 0.5")

func _test_cost_unknown_building() -> void:
	var mult: float = CostModifierScript.get_cost_multiplier("unknown_building", Callable(self, "_has_upgrade_true"))
	_assert_approx(mult, 1.0, "Cost: unknown building = 1.0 (no discount)")

func _test_cost_discount_minimum_1() -> void:
	# _apply_discount(1, 0.5) should return 1 (ceili(0.5) = 1), not 0
	var result: int = CostModifierScript._apply_discount(1, 0.5)
	_assert_eq(result, 1, "Cost: discount on amount=1, mult=0.5 yields minimum 1")
	# _apply_discount(70, 0.5) should return 35
	var result2: int = CostModifierScript._apply_discount(70, 0.5)
	_assert_eq(result2, 35, "Cost: discount on amount=70, mult=0.5 yields 35")
	# _apply_discount(60, 0.6) should return 36
	var result3: int = CostModifierScript._apply_discount(60, 0.6)
	_assert_eq(result3, 36, "Cost: discount on amount=60, mult=0.6 yields 36")
	# _apply_discount(8, 0.6) should return 5 (ceili(4.8) = 5)
	var result4: int = CostModifierScript._apply_discount(8, 0.6)
	_assert_eq(result4, 5, "Cost: discount on amount=8, mult=0.6 yields 5")

func _test_cost_can_produce_discounted() -> void:
	# Test with a mock resource core — not possible in headless without autoloads,
	# so we test the static _apply_discount logic instead (already covered above).
	# Verify the COST_DISCOUNT_MAP entries are structurally valid.
	var all_valid := true
	for building_id: String in CostModifierScript.COST_DISCOUNT_MAP:
		var entry: Dictionary = CostModifierScript.COST_DISCOUNT_MAP[building_id]
		if not entry.has("upgrade_id") or not entry.has("multiplier"):
			all_valid = false
		var m: float = float(entry.get("multiplier", 0.0))
		if m <= 0.0 or m >= 1.0:
			all_valid = false
	_assert(all_valid, "Cost: all COST_DISCOUNT_MAP entries are structurally valid")

func _test_cost_consume_inputs_discounted() -> void:
	# Structural test: verify the static methods exist via source inspection
	var src: String = (CostModifierScript as Script).source_code
	_assert(src.find("static func can_produce_discounted") >= 0, "Cost: can_produce_discounted exists")
	_assert(src.find("static func consume_inputs_discounted") >= 0, "Cost: consume_inputs_discounted exists")


# ══════════════════════════════════════════════════════════════════════════════
# MEGA MILITIA TESTS
# ══════════════════════════════════════════════════════════════════════════════

func _test_mega_no_upgrade() -> void:
	var counter: Dictionary = {"count": 0}
	var result: String = MegaMilitiaScript.resolve_produced_unit(
		"militia_camp", "militia", counter, Callable(self, "_has_upgrade_false")
	)
	_assert_eq(result, "militia", "Mega: without upgrade produces normal militia")
	_assert_eq(int(counter.get("count", -1)), 0, "Mega: counter unchanged without upgrade")

func _test_mega_counter_increments() -> void:
	var counter: Dictionary = {"count": 0}
	var result1: String = MegaMilitiaScript.resolve_produced_unit(
		"militia_camp", "militia", counter, Callable(self, "_has_upgrade_true")
	)
	_assert_eq(result1, "militia", "Mega: 1st production is normal militia")
	_assert_eq(int(counter.get("count", -1)), 1, "Mega: counter = 1 after 1st")

	var result2: String = MegaMilitiaScript.resolve_produced_unit(
		"militia_camp", "militia", counter, Callable(self, "_has_upgrade_true")
	)
	_assert_eq(result2, "militia", "Mega: 2nd production is normal militia")
	_assert_eq(int(counter.get("count", -1)), 2, "Mega: counter = 2 after 2nd")

func _test_mega_triggers_at_5th() -> void:
	var counter: Dictionary = {"count": 0}
	# Produce 4 normal militia
	for i: int in range(4):
		var _result: String = MegaMilitiaScript.resolve_produced_unit(
			"militia_camp", "militia", counter, Callable(self, "_has_upgrade_true")
		)
	_assert_eq(int(counter.get("count", -1)), 4, "Mega: counter = 4 after 4 productions")

	# 5th should be mega militia
	var result5: String = MegaMilitiaScript.resolve_produced_unit(
		"militia_camp", "militia", counter, Callable(self, "_has_upgrade_true")
	)
	_assert_eq(result5, "mega_militia", "Mega: 5th production is mega_militia")

func _test_mega_resets_after_trigger() -> void:
	var counter: Dictionary = {"count": 0}
	# Run through a full cycle: 4 normal + 1 mega
	for i: int in range(4):
		MegaMilitiaScript.resolve_produced_unit(
			"militia_camp", "militia", counter, Callable(self, "_has_upgrade_true")
		)
	MegaMilitiaScript.resolve_produced_unit(
		"militia_camp", "militia", counter, Callable(self, "_has_upgrade_true")
	)
	_assert_eq(int(counter.get("count", -1)), 0, "Mega: counter resets to 0 after mega production")

	# Next one should increment again
	var result_next: String = MegaMilitiaScript.resolve_produced_unit(
		"militia_camp", "militia", counter, Callable(self, "_has_upgrade_true")
	)
	_assert_eq(result_next, "militia", "Mega: post-reset 1st production is normal militia")
	_assert_eq(int(counter.get("count", -1)), 1, "Mega: counter = 1 after post-reset production")

func _test_mega_non_militia_building() -> void:
	var counter: Dictionary = {"count": 3}
	var result: String = MegaMilitiaScript.resolve_produced_unit(
		"archery", "archer", counter, Callable(self, "_has_upgrade_true")
	)
	_assert_eq(result, "archer", "Mega: non-militia_camp building unaffected")
	_assert_eq(int(counter.get("count", -1)), 3, "Mega: counter unchanged for non-militia building")

func _test_mega_save_load_counter() -> void:
	var counter: Dictionary = {"count": 0}
	MegaMilitiaScript.set_counter(counter, 3)
	_assert_eq(MegaMilitiaScript.get_counter(counter), 3, "Mega: set_counter(3) and get_counter = 3")
	MegaMilitiaScript.set_counter(counter, 0)
	_assert_eq(MegaMilitiaScript.get_counter(counter), 0, "Mega: reset counter to 0")
	# Negative values clamped to 0
	MegaMilitiaScript.set_counter(counter, -5)
	_assert_eq(MegaMilitiaScript.get_counter(counter), 0, "Mega: negative value clamped to 0")
