extends SceneTree

const KingSpellStateScript := preload("res://core/king_spell_state.gd")

var _failed: bool = false


class FakeAvailabilityChecker:
	extends RefCounted

	var can_activate_calls: int = 0
	var unavailability_reason_calls: int = 0
	var can_activate_result: bool = true
	var unavailability_reason: String = ""

	func can_activate_active_ability(_ability_id: String, _active_upgrade_level: int, _economy_core: Variant, _resource_core: Variant, _corpse_source: Variant, _hero_core: Variant) -> bool:
		can_activate_calls += 1
		return can_activate_result

	func get_active_ability_unavailability_reason(_ability_id: String, _active_upgrade_level: int, _economy_core: Variant, _resource_core: Variant, _corpse_source: Variant, _hero_core: Variant) -> String:
		unavailability_reason_calls += 1
		return unavailability_reason


class FakeCharacterCreationState:
	extends RefCounted

	var selected_active_spell_id: String = "forced_tax"
	var selected_passive_spell_id: String = "lumberjack"


func _init() -> void:
	call_deferred("_run_test")


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error("[test_king_spell_state] %s" % message)
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
	_test_begin_run_accepts_explicit_character_creation_state()
	if _failed:
		return
	_test_active_cooldown_blocks_wrapper_activation_and_reason()
	if _failed:
		return
	print("[test_king_spell_state] PASS")
	quit(0)


func _test_begin_run_accepts_explicit_character_creation_state() -> void:
	var state: Node = KingSpellStateScript.new()
	state.set("selected_active_spell_id", "old_active")
	state.set("selected_passive_spell_id", "old_passive")
	state.set("active_upgrade_level", 3)
	state.set("productivity_bonus_multiplier", 1.5)
	state.set("productivity_bonus_time_left", 9.0)
	state.set("chopped_tree_count", 11)
	state.set("bosses_killed_count", 2)

	var character_creation_state := FakeCharacterCreationState.new()
	state.call("begin_run_from_character_creation", character_creation_state)

	_assert_equal(String(state.get("selected_active_spell_id")), "forced_tax", "KingSpellState must accept an explicit character creation source instead of depending on a hard global identifier")
	_assert_equal(String(state.get("selected_passive_spell_id")), "lumberjack", "KingSpellState must mirror the explicit passive spell selection")
	_assert_equal(int(state.get("active_upgrade_level")), 0, "Beginning a run must still reset active spell upgrade progress")
	_assert_equal(float(state.get("productivity_bonus_multiplier")), 0.0, "Beginning a run must clear any leftover productivity multiplier")
	_assert_equal(float(state.get("productivity_bonus_time_left")), 0.0, "Beginning a run must clear any leftover productivity timer")
	_assert_equal(int(state.get("chopped_tree_count")), 0, "Beginning a run must reset passive progress counters")
	_assert_equal(int(state.get("bosses_killed_count")), 0, "Beginning a run must reset boss counters")


func _test_active_cooldown_blocks_wrapper_activation_and_reason() -> void:
	var state: Node = KingSpellStateScript.new()
	var checker := FakeAvailabilityChecker.new()
	state.set("_availability_checker", checker)

	state.call("set_active_cooldown", "forced_tax", 5.0)
	_assert_false(bool(state.call("can_activate_active_ability", "forced_tax")), "KingSpellState must block active ability activation while cooldown is still running")
	_assert_equal(String(state.call("get_active_ability_unavailability_reason", "forced_tax")), "On cooldown.", "KingSpellState must expose cooldown gating through the active ability reason wrapper")
	_assert_equal(checker.can_activate_calls, 0, "Cooldown-gated activation must not delegate to SpellAvailabilityChecker")
	_assert_equal(checker.unavailability_reason_calls, 0, "Cooldown-gated reason lookup must not delegate to SpellAvailabilityChecker")

	state.call("tick_cooldowns", 5.0)
	checker.can_activate_result = true
	checker.unavailability_reason = ""
	_assert_true(bool(state.call("can_activate_active_ability", "forced_tax")), "KingSpellState must delegate once cooldown expires")
	_assert_equal(String(state.call("get_active_ability_unavailability_reason", "forced_tax")), "", "KingSpellState must clear the cooldown reason once the timer expires")
	_assert_equal(checker.can_activate_calls, 1, "Expired cooldown must fall back to SpellAvailabilityChecker activation rules")
	_assert_equal(checker.unavailability_reason_calls, 1, "Expired cooldown must fall back to SpellAvailabilityChecker reason rules")
