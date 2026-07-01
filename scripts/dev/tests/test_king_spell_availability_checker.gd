extends SceneTree

const SpellAvailabilityCheckerScript := preload("res://core/king_spell/SpellAvailabilityChecker.gd")

var _failed: bool = false


class FakeEconomyCore:
	extends RefCounted

	var gold: int = 0

	func get_gold() -> int:
		return gold

	func can_afford(amount: float) -> bool:
		return gold >= int(amount)

	func spend_gold(amount: float) -> bool:
		var required := int(amount)
		if gold < required:
			return false
		gold -= required
		return true


class FakeResourceCore:
	extends RefCounted

	var values: Dictionary = {}

	func get_resource(resource_id: String) -> int:
		return int(values.get(resource_id, 0))

	func consume_resource(resource_id: String, amount: int) -> bool:
		var owned := get_resource(resource_id)
		if owned < amount:
			return false
		values[resource_id] = owned - amount
		return true


class FakeCorpseSource:
	extends RefCounted

	var active_corpses: Array = []


class FakeHeroCore:
	extends RefCounted

	var active_heroes: Array = []

	func get_active_heroes() -> Array:
		return active_heroes


class FakeCastleCore:
	extends RefCounted

	var current_hp: float = 0.0
	var max_hp: float = 0.0

	func get_effective_max_hp() -> float:
		return max_hp


class FakeMoraleSystem:
	extends RefCounted

	var total_morale: int = 0

	func get_total_morale() -> int:
		return total_morale


func _init() -> void:
	call_deferred("_run_test")


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error("[test_king_spell_availability_checker] %s" % message)
	quit(1)


func _assert_true(value: bool, message: String) -> void:
	if not value:
		_fail(message)


func _assert_false(value: bool, message: String) -> void:
	if value:
		_fail(message)


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		_fail("%s (expected: %s, got: %s)" % [message, expected, actual])


func _run_test() -> void:
	var checker: Variant = SpellAvailabilityCheckerScript.new()
	_test_default_passive_requirements(checker)
	if _failed:
		return
	_test_active_resource_status_and_spend(checker)
	if _failed:
		return
	_test_active_special_case_reasons(checker)
	if _failed:
		return
	_test_passive_special_case_reasons(checker)
	if _failed:
		return
	print("[test_king_spell_availability_checker] PASS")
	quit(0)


func _test_default_passive_requirements(checker: RefCounted) -> void:
	var requirements: Dictionary = checker.get_default_passive_requirements()
	_assert_equal(requirements, {
		"lumberjack_tree_requirement": 10,
		"reward_boss_requirement": 1,
		"good_reward_boss_requirement": 2,
		"spicy_boys_morale_requirement": 70,
	}, "Default passive requirement payload must stay owned by SpellAvailabilityChecker")
	requirements["lumberjack_tree_requirement"] = 999
	_assert_equal(int(checker.get_default_passive_requirements().get("lumberjack_tree_requirement", 0)), 10, "Default passive requirement payload must be returned as a defensive copy")


func _test_active_resource_status_and_spend(checker: RefCounted) -> void:
	var economy := FakeEconomyCore.new()
	economy.gold = 20
	var resources := FakeResourceCore.new()
	resources.values = {"water": 100, "meat": 50}

	var gold_status: Dictionary = checker.get_active_ability_resource_status("forced_tax", 0, economy, resources)
	_assert_equal(gold_status.get("resource_id", ""), "gold", "Forced Tax must keep gold cost")
	_assert_equal(int(gold_status.get("required", 0)), 35, "Forced Tax gold cost must stay 35")
	_assert_equal(int(gold_status.get("owned", 0)), 20, "Forced Tax owned gold must come from EconomyCore")
	_assert_false(checker.can_afford_active_ability("forced_tax", 0, economy, resources), "Forced Tax must be unavailable without enough gold")
	_assert_equal(checker.get_active_ability_unavailability_reason("forced_tax", 0, economy, resources, null, null), "Requires 35 gold (20/35).", "Forced Tax unavailability text must stay unchanged")
	_assert_false(checker.spend_active_ability_cost("forced_tax", 0, economy, resources), "Forced Tax spend must fail without enough gold")
	_assert_equal(economy.gold, 20, "Failed gold spend must not change EconomyCore state")

	economy.gold = 50
	_assert_true(checker.spend_active_ability_cost("forced_tax", 0, economy, resources), "Forced Tax spend must succeed with enough gold")
	_assert_equal(economy.gold, 15, "Forced Tax spend must deduct the same gold amount as before")

	var water_status: Dictionary = checker.get_active_ability_resource_status("tough_guys", 2, economy, resources)
	_assert_equal(water_status.get("resource_id", ""), "water", "Tough Guys must keep water cost")
	_assert_equal(int(water_status.get("required", 0)), 50, "Tough Guys upgrade cost scaling must stay unchanged")
	_assert_equal(int(water_status.get("owned", 0)), 100, "Tough Guys owned resource amount must come from ResourceCore")
	_assert_true(checker.can_afford_active_ability("tough_guys", 2, economy, resources), "Tough Guys must be affordable with enough water")
	_assert_true(checker.spend_active_ability_cost("tough_guys", 2, economy, resources), "Tough Guys spend must consume water when affordable")
	_assert_equal(resources.get_resource("water"), 50, "Tough Guys spend must deduct the scaled water cost")


func _test_active_special_case_reasons(checker: RefCounted) -> void:
	var economy := FakeEconomyCore.new()
	economy.gold = 999
	var resources := FakeResourceCore.new()
	resources.values = {"water": 100, "meat": 100}
	var corpse_source := FakeCorpseSource.new()
	var hero_core := FakeHeroCore.new()

	_assert_equal(checker.get_active_ability_unavailability_reason("resurrection", 0, economy, resources, corpse_source, hero_core), "Requires at least 1 corpse on the battlefield.", "Resurrection corpse-gating text must stay unchanged")
	_assert_false(checker.can_activate_active_ability("resurrection", 0, economy, resources, corpse_source, hero_core), "Resurrection must stay unavailable without corpses")
	corpse_source.active_corpses.append(RefCounted.new())
	_assert_equal(checker.get_active_ability_unavailability_reason("resurrection", 0, economy, resources, corpse_source, hero_core), "", "Resurrection must become available once at least one corpse exists")

	_assert_equal(checker.get_active_ability_unavailability_reason("training", 0, economy, resources, corpse_source, hero_core), "Requires at least 1 allied unit on the battlefield.", "Training allied-unit gating text must stay unchanged")
	_assert_false(checker.can_activate_active_ability("training", 0, economy, resources, corpse_source, hero_core), "Training must stay unavailable without allied units")
	hero_core.active_heroes.append({"id": "hero_1"})
	_assert_equal(checker.get_active_ability_unavailability_reason("training", 0, economy, resources, corpse_source, hero_core), "", "Training must become available once at least one allied unit exists")


func _test_passive_special_case_reasons(checker: RefCounted) -> void:
	var state := {
		"chopped_tree_count": 0,
		"bosses_killed_count": 0,
	}
	var requirements: Dictionary = checker.get_default_passive_requirements()
	var castle_core := FakeCastleCore.new()
	var morale_system := FakeMoraleSystem.new()

	_assert_equal(checker.get_passive_ability_unavailability_reason("lumberjack", state, castle_core, morale_system, requirements), "Requires 10 chopped trees (0/10).", "Lumberjack requirement text must stay unchanged")
	_assert_equal(checker.get_passive_ability_unavailability_reason("reward", state, castle_core, morale_system, requirements), "Requires 1 boss kill (0/1).", "Reward requirement text must stay unchanged")
	_assert_equal(checker.get_passive_ability_unavailability_reason("good_reward", state, castle_core, morale_system, requirements), "Requires 2 boss kills (0/2).", "Good Reward requirement text must stay unchanged")
	_assert_equal(checker.get_passive_ability_unavailability_reason("last_chance", state, null, morale_system, requirements), "Castle state unavailable.", "Last Chance must still require castle state")

	castle_core.max_hp = 100.0
	castle_core.current_hp = 31.0
	_assert_equal(checker.get_passive_ability_unavailability_reason("last_chance", state, castle_core, morale_system, requirements), "Requires castle HP at or below 30%%.", "Last Chance HP threshold text must stay unchanged")
	castle_core.current_hp = 30.0
	_assert_true(checker.can_activate_passive_ability("last_chance", state, castle_core, morale_system, requirements), "Last Chance must stay available at exactly 30 percent HP")

	morale_system.total_morale = 69
	_assert_equal(checker.get_passive_ability_unavailability_reason("spicy_boys", state, castle_core, morale_system, requirements), "Requires 70 morale (69/70).", "Spicy Boys morale text must stay unchanged")
	_assert_false(checker.can_activate_passive_ability("spicy_boys", state, castle_core, morale_system, requirements), "Spicy Boys must stay unavailable below the morale threshold")
	morale_system.total_morale = 70
	_assert_true(checker.can_activate_passive_ability("spicy_boys", state, castle_core, morale_system, requirements), "Spicy Boys must stay available at the morale threshold")

	state["bosses_killed_count"] = 1
	_assert_true(checker.can_activate_passive_ability("reward", state, castle_core, morale_system, requirements), "Reward must stay available after one boss kill")
	_assert_true(checker.can_activate_passive_ability("spells_for_work", state, castle_core, morale_system, requirements), "Spells for Work must share the Reward boss-kill requirement")
