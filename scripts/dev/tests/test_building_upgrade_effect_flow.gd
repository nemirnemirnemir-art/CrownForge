extends SceneTree

const EffectFlowScript := preload("res://core/building_upgrade/BuildingUpgradeEffectFlow.gd")


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = EffectFlowScript.new()
	if flow == null:
		push_error("[test_building_upgrade_effect_flow] failed to instantiate helper")
		quit(1)
		return

	if absf(flow.get_buddhist_temple_production_speed_multiplier(2) - 1.1) > 0.001:
		push_error("[test_building_upgrade_effect_flow] temple production multiplier mismatch")
		quit(1)
		return
	if flow.get_active_concert_morale_bonus(3) != 30:
		push_error("[test_building_upgrade_effect_flow] active concert morale mismatch")
		quit(1)
		return
	if flow.get_passive_concert_morale_bonus(2) != 10:
		push_error("[test_building_upgrade_effect_flow] passive concert morale mismatch")
		quit(1)
		return
	if absf(flow.get_active_tesla_tower_spell_damage_multiplier(1) - 1.5) > 0.001:
		push_error("[test_building_upgrade_effect_flow] tesla multiplier mismatch")
		quit(1)
		return

	print("[test_building_upgrade_effect_flow] PASS")
	quit(0)
