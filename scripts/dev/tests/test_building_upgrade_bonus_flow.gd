extends SceneTree

const BonusFlowScript := preload("res://core/building_upgrade/BuildingUpgradeBonusFlow.gd")


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = BonusFlowScript.new()
	if flow == null:
		push_error("[test_building_upgrade_bonus_flow] failed to instantiate helper")
		quit(1)
		return

	if absf(flow.get_scaled_multiplier(2, 0.05) - 1.1) > 0.001:
		push_error("[test_building_upgrade_bonus_flow] scaled multiplier mismatch")
		quit(1)
		return
	if absf(flow.get_magic_ball_spell_damage_multiplier(1, true) - 1.8) > 0.001:
		push_error("[test_building_upgrade_bonus_flow] magic ball active multiplier mismatch")
		quit(1)
		return

	print("[test_building_upgrade_bonus_flow] PASS")
	quit(0)
