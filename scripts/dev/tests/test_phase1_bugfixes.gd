extends SceneTree

## Phase 1: Systemic Bug Fixes and Data/Runtime Mismatch Repairs
## Tests all 7 fixes from the Building Upgrade Campaign.
## Uses source-code inspection for scripts with autoload dependencies.

const ExecutionGroundScript := preload("res://core/buildings/special/ExecutionGround.gd")
const MagicSchoolScript := preload("res://core/buildings/special/MagicSchool.gd")
const HospitalScript := preload("res://core/buildings/special/Hospital.gd")
const BrickFactoryScript := preload("res://core/buildings/special/BrickFactory.gd")
const FairyFountainScript := preload("res://core/buildings/special/FairyFountain.gd")
const KingsStatueScript := preload("res://core/buildings/special/KingsStatue.gd")
## TraderOfferGenerator is a global class_name, referenced directly.


var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_execution_ground_flag_source()
	_test_execution_ground_no_synthetic_id()
	_test_execution_ground_state_persistence_source()
	_test_magic_school_upgrade_constants()
	_test_magic_school_has_upgrade_and_choice()
	_test_magic_school_speed_upgrade()
	_test_hospital_healing_multiplier()
	_test_hospital_morale_value()
	_test_brick_factory_charges_per_hp()
	_test_fairy_fountain_no_dust_timer()
	_test_fairy_fountain_no_tick_antigoblin_dust()
	_test_fairy_fountain_cycle_damage()
	_test_kings_statue_no_refund_method()
	_test_kings_statue_has_bonus_crystal()
	_test_trader_no_duplicate_upgrade_ids()

	print("Phase 1 bugfix tests: %d passed, %d failed" % [_passed, _failed])
	quit(_failed)


func _assert(condition: bool, message: String) -> bool:
	if condition:
		_passed += 1
		return true
	_failed += 1
	push_error("[test_phase1_bugfixes] FAIL: %s" % message)
	return false


func _get_source(script_res: Variant) -> String:
	var script_obj: Script = script_res as Script
	if script_obj == null:
		return ""
	return script_obj.source_code


# --- Task 1: ExecutionGround ---

func _test_execution_ground_flag_source() -> void:
	var src := _get_source(ExecutionGroundScript)
	_assert(
		src.find("var _troop_inspiration_applied: bool = false") >= 0,
		"ExecutionGround must declare _troop_inspiration_applied field"
	)
	_assert(
		src.find("_troop_inspiration_applied = false") >= 0,
		"ExecutionGround initialize() must reset _troop_inspiration_applied"
	)


func _test_execution_ground_no_synthetic_id() -> void:
	var src := _get_source(ExecutionGroundScript)
	_assert(
		src.find("execution_ground:1:applied") < 0 or src.find("execution_ground:1:applied") == src.rfind("execution_ground:1:applied"),
		"ExecutionGround must not write synthetic upgrade ID (only backward-compat read allowed)"
	)
	_assert(
		src.find("apply_upgrade") < 0,
		"ExecutionGround must not call BuildingUpgradeCore.apply_upgrade"
	)


func _test_execution_ground_state_persistence_source() -> void:
	var src := _get_source(ExecutionGroundScript)
	_assert(
		src.find("\"troop_inspiration_applied\"") >= 0,
		"ExecutionGround get_runtime_state must include troop_inspiration_applied key"
	)
	_assert(
		src.find("state.get(\"troop_inspiration_applied\"") >= 0,
		"ExecutionGround load_runtime_state must read troop_inspiration_applied from state"
	)


# --- Task 2: MagicSchool ---

func _test_magic_school_upgrade_constants() -> void:
	var src := _get_source(MagicSchoolScript)
	_assert(
		src.find("CHOICE_UPGRADE_ID: String = \"magic_school:0\"") >= 0,
		"MagicSchool must have CHOICE_UPGRADE_ID = 'magic_school:0'"
	)
	_assert(
		src.find("SPEED_UPGRADE_ID: String = \"magic_school:1\"") >= 0,
		"MagicSchool must have SPEED_UPGRADE_ID = 'magic_school:1'"
	)


func _test_magic_school_has_upgrade_and_choice() -> void:
	var src := _get_source(MagicSchoolScript)
	_assert(
		src.find("func _has_upgrade(") >= 0,
		"MagicSchool must have _has_upgrade method"
	)
	_assert(
		src.find("func _enqueue_spell_choice_reward(") >= 0,
		"MagicSchool must have _enqueue_spell_choice_reward method"
	)
	_assert(
		src.find("_has_upgrade(CHOICE_UPGRADE_ID)") >= 0,
		"MagicSchool _on_cycle_completed must check CHOICE_UPGRADE_ID"
	)


func _test_magic_school_speed_upgrade() -> void:
	var src := _get_source(MagicSchoolScript)
	_assert(
		src.find("_has_upgrade(SPEED_UPGRADE_ID)") >= 0,
		"MagicSchool _get_effective_cycle_time must check SPEED_UPGRADE_ID"
	)
	_assert(
		src.find("speed_mult *= 1.25") >= 0,
		"MagicSchool speed upgrade must multiply by 1.25"
	)


# --- Task 3: Hospital ---

func _test_hospital_healing_multiplier() -> void:
	var src := _get_source(HospitalScript)
	_assert(
		src.find("heal_amount *= 1.5") >= 0,
		"Hospital healing upgrade must use 1.5 multiplier (+50%%)"
	)
	_assert(
		src.find("heal_amount *= 1.25") < 0,
		"Hospital must NOT have old 1.25 multiplier"
	)
	_assert(
		HospitalScript.BASE_HEAL_PER_TICK == 15,
		"Hospital BASE_HEAL_PER_TICK must be 15"
	)


func _test_hospital_morale_value() -> void:
	var src := _get_source(HospitalScript)
	_assert(
		src.find("return 5") >= 0,
		"Hospital morale bonus must return 5 (matching '+5 morale' text)"
	)
	_assert(
		src.find("return 4") < 0,
		"Hospital must NOT have old morale return value of 4"
	)


# --- Task 4: BrickFactory ---

func _test_brick_factory_charges_per_hp() -> void:
	_assert(
		BrickFactoryScript.FORTIFICATION_CHARGES_PER_HP == 5,
		"BrickFactory FORTIFICATION_CHARGES_PER_HP must be 5 (matching '5 charges -> +1 max HP' text)"
	)


# --- Task 5: FairyFountain ---

func _test_fairy_fountain_no_dust_timer() -> void:
	var src := _get_source(FairyFountainScript)
	_assert(
		src.find("var _dust_timer") < 0,
		"FairyFountain must NOT have _dust_timer field"
	)


func _test_fairy_fountain_no_tick_antigoblin_dust() -> void:
	var src := _get_source(FairyFountainScript)
	_assert(
		src.find("func _tick_antigoblin_dust") < 0,
		"FairyFountain must NOT have _tick_antigoblin_dust method"
	)
	_assert(
		src.find("DUST_DAMAGE_PER_CYCLE") >= 0,
		"FairyFountain must have DUST_DAMAGE_PER_CYCLE constant"
	)


func _test_fairy_fountain_cycle_damage() -> void:
	var src := _get_source(FairyFountainScript)
	_assert(
		src.find("_damage_nearest_enemy(DUST_DAMAGE_PER_CYCLE)") >= 0,
		"FairyFountain _on_cycle_completed must call _damage_nearest_enemy on cycle"
	)


# --- Task 6: KingsStatue ---

func _test_kings_statue_no_refund_method() -> void:
	var src := _get_source(KingsStatueScript)
	_assert(
		src.find("func _should_refund_crystal_cost") < 0,
		"KingsStatue must NOT have _should_refund_crystal_cost method"
	)
	_assert(
		src.find("REFUND_UPGRADE_ID") < 0,
		"KingsStatue must NOT have REFUND_UPGRADE_ID constant"
	)


func _test_kings_statue_has_bonus_crystal() -> void:
	var src := _get_source(KingsStatueScript)
	_assert(
		src.find("func _try_bonus_crystal_production(") >= 0,
		"KingsStatue must have _try_bonus_crystal_production method"
	)
	_assert(
		src.find("CRYSTAL_BONUS_UPGRADE_ID") >= 0,
		"KingsStatue must have CRYSTAL_BONUS_UPGRADE_ID constant"
	)
	_assert(
		src.find("randf() < 0.25") >= 0,
		"KingsStatue bonus crystal must use 25%% chance"
	)
	_assert(
		src.find("\"add_resource\", \"crystal\", 1") >= 0,
		"KingsStatue bonus crystal must add 1 crystal"
	)


# --- Task 7: TraderOfferGenerator duplicate dedup ---

func _test_trader_no_duplicate_upgrade_ids() -> void:
	var generator := TraderOfferGenerator.new()
	_assert(
		generator.has_method("roll_building_upgrades"),
		"TraderOfferGenerator must have roll_building_upgrades method"
	)
	var script_obj: Script = generator.get_script() as Script
	var source: String = script_obj.source_code if script_obj else ""
	_assert(
		source.find("seen_upgrade_ids") >= 0,
		"TraderOfferGenerator must use seen_upgrade_ids dedup dictionary"
	)
	_assert(
		source.find("if seen_upgrade_ids.has(upgrade_id)") >= 0,
		"TraderOfferGenerator must skip already-seen upgrade IDs"
	)
