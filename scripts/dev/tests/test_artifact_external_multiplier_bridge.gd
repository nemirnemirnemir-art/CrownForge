extends SceneTree

const BridgeScript := preload("res://core/artifacts/ArtifactExternalMultiplierBridge.gd")


class FakeBuildingUpgradeCore:
	extends RefCounted

	func get_buddhist_temple_production_speed_multiplier() -> float:
		return 1.25

	func get_buddhist_temple_spell_damage_multiplier() -> float:
		return 1.5

	func get_magic_ball_spell_damage_multiplier() -> float:
		return 1.2

	func get_active_tesla_tower_spell_damage_multiplier() -> float:
		return 1.1


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var bridge = BridgeScript.new()
	if bridge == null:
		push_error("[test_artifact_external_multiplier_bridge] failed to instantiate helper")
		quit(1)
		return

	var building_upgrade_core := FakeBuildingUpgradeCore.new()
	if absf(bridge.apply_resource_production_speed_bridge(2.0, building_upgrade_core) - 2.5) > 0.001:
		push_error("[test_artifact_external_multiplier_bridge] resource production bridge mismatch")
		quit(1)
		return
	if absf(bridge.apply_unit_production_speed_bridge(2.0, building_upgrade_core) - 2.5) > 0.001:
		push_error("[test_artifact_external_multiplier_bridge] unit production bridge mismatch")
		quit(1)
		return
	if absf(bridge.apply_spell_damage_bridge(2.0, building_upgrade_core) - 2.8) > 0.001:
		push_error("[test_artifact_external_multiplier_bridge] spell damage bridge mismatch (expected additive 2.8)")
		quit(1)
		return
	if absf(bridge.apply_spell_damage_bridge(2.0, null) - 2.0) > 0.001:
		push_error("[test_artifact_external_multiplier_bridge] spell damage without external core should stay unchanged")
		quit(1)
		return

	print("[test_artifact_external_multiplier_bridge] PASS")
	quit(0)
