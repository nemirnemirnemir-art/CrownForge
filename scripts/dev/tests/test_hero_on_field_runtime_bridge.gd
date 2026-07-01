extends SceneTree

const RuntimeBridgeScript := preload("res://scripts/hero/modules/HeroOnFieldRuntimeBridge.gd")


class FakeHeroCore:
	extends Node

	func get_hero(hero_id: String) -> Dictionary:
		return {"hp": 42.0, "damage": 7.0, "id": hero_id}

	func get_hero_total_stats(_hero_id: String) -> Dictionary:
		return {"maxHp": 100.0, "damage": 11.0}


class FakeHero:
	extends Node2D

	var hero_id: String = "militia"


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var bridge = RuntimeBridgeScript.new()
	var hero := FakeHero.new()
	var root := Node.new()
	get_root().add_child(root)
	root.add_child(hero)
	var hero_core := FakeHeroCore.new()

	bridge.setup(hero)
	bridge.set_overrides(hero_core, null, null)
	if absf(bridge.get_current_hp() - 42.0) > 0.01:
		push_error("[test_hero_on_field_runtime_bridge] current HP mismatch")
		quit(1)
		return
	if absf(bridge.get_max_hp() - 100.0) > 0.01:
		push_error("[test_hero_on_field_runtime_bridge] max HP mismatch")
		quit(1)
		return
	if absf(bridge.get_attack_damage() - 11.0) > 0.01:
		push_error("[test_hero_on_field_runtime_bridge] attack damage mismatch")
		quit(1)
		return

	print("[test_hero_on_field_runtime_bridge] PASS")
	quit(0)
