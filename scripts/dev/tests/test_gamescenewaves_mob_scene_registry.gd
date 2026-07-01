extends SceneTree

const MobSceneRegistryScript := preload("res://scripts/game_scene/modules/MobSceneRegistry.gd")


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var registry = MobSceneRegistryScript.new()
	if registry == null:
		push_error("[test_gamescenewaves_mob_scene_registry] failed to instantiate helper")
		quit(1)
		return

	var swordsman_scene: PackedScene = registry.get_mob_scene("goblin_swordsman")
	if swordsman_scene == null or swordsman_scene.resource_path != "res://scenes/mobs/GoblinSwordsman.tscn":
		push_error("[test_gamescenewaves_mob_scene_registry] direct lookup mismatch")
		quit(1)
		return

	var fallback_scene: PackedScene = registry.get_mob_scene("unknown_enemy")
	if fallback_scene == null or fallback_scene.resource_path != "res://scenes/mobs/GoblinBandit.tscn":
		push_error("[test_gamescenewaves_mob_scene_registry] fallback lookup mismatch")
		quit(1)
		return

	var goblin_ids: Array[String] = registry.get_goblin_ids()
	if goblin_ids.is_empty() or goblin_ids[0] != "goblin_bandit":
		push_error("[test_gamescenewaves_mob_scene_registry] goblin ids must stay available")
		quit(1)
		return

	print("[test_gamescenewaves_mob_scene_registry] PASS")
	quit(0)
